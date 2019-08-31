require "regex"
require "colorize"
require "yaml"
require "option_parser"

{{run("./read", "config/profiles.yml")}}
  
macro colorput(tag, color, color2)
  def cprint(text)
    String.build { |str|
      str << "[{{tag.id.upcase}}]".colorize(:{{color.id}})
      str << " "
      str << text.colorize(:{{color2.id}})
      str << "\n"
    }
  end
  def self.cprint(text)
    String.build { |str|
      str << "[{{tag.id.upcase}}]".colorize(:{{color.id}})
      str << " "
      str << text.colorize(:{{color2.id}})
      str << "\n"
    }
  end
  def print(text)
    String.build { |str|
      str << "[{{tag.id.upcase}}]"
      str << " "
      str << text
      str << "\n"
    }
  end
  def self.print(text)
    String.build { |str|
      str << "[{{tag.id.upcase}}]"
      str << " "
      str << text
      str << "\n"
    }
  end
end

macro log(text)
  if logging
     logfile.puts({{text}})
  end
end

module Logburn
  VERSION = "0.1.0"

  def get_logpath(diff)
    logdir = "/tmp/logburn/"
    Dir.mkdir_p(logdir)
    filename = ""
    Dir.open(logdir) do |dir|
      entries = dir.entries.sort do |filename1, filename2|
        match = /[0-9]+$/.match(filename1)
        match = match ? match[0].to_i : 0
        match2 = /[0-9]+$/.match(filename2)
        match2 = match2 ? match2[0].to_i : 0
        match <=> match2
      end
      entries.delete(".")
      entries.delete("..")
      unless entries.empty?
        old_log = entries.last
        numb = /[0-9]+$/.match(old_log)
      else
        numb = nil
      end
      if numb
        filename = "log_#{numb[0].to_i + diff}"
      else
        filename = "log_0"
      end
    end
    return logdir + filename
  end

  def gen_log
    File.open(get_logpath(1) , "w+")
  end


  module Profile
    enum Severity
      Moniter
      Low
      Medium
      High
      Critical
      Nil
    end
    {% for apl, predata in CONFIG %}
      module Profile{{apl.id.capitalize}}
        {% for profile, data in predata %}
          class {{profile.id.capitalize}}
            property match : Regex::MatchData | Nil, line : String, id : String | Nil, hide : Bool
            name = "{{profile.id.downcase}}"
            @@records = [] of self
            {% if data.keys.includes? "hide" %}
              @hide = true
            {% else %}
              @hide = false
            {% end %}
            def self.records
              @@records
            end

            def self.match(line)
              match = {{data["regex"].id}}.match(line)
              return nil unless match
              obj = new(line)
              obj.match = match
              {% if data.keys.includes? "id" %}
              obj.id = match[{{data["id"].id}}]
              {% end %}
              return obj
            end
            
            def initialize(line)
              @line = line
            end

            def save
              @@records << self
            end
            
            colorput({{profile.id}}, {{data["color"].id}}, light_{{data["color"].id}})
          end
        {% end %}
      end
    {% end %}
  end
end

include Logburn

nolog = false
readfile = ""
hang = true
mid_report = false
reporting = true
report_delay = 5
log_reporting = true
not_all = true
man_log_file = nil
logging = true
report_only = false
help = false

parser = OptionParser.parse! do |parser|
  parser.banner = "Usage: logburn [profile] [arguments]"
  parser.on("-q", "--logging", "Disable logging") { logging = false }
  parser.on("-c", "--no-color", "Displays output without color") { Colorize.enabled = false }
  parser.on("-l", "--inline", "Toggle inline display") { report_only = true }
  parser.on("-o", "--only-errors", "Skip logging of unmatched lines") { nolog = true }
  parser.on("-a", "--all-matches", "Display moniter events in reports") { not_all = false }
  parser.on("-t", "--no-timeout", "Disables hang protection") { hang = false }
  parser.on("-p", "--periodic", "Enable periodic reports") { mid_report = true }
  parser.on("-r", "--no-report", "Disable reporting") { reporting = false }
  parser.on("-l", "--no-log-report", "Disable reporting for logs") { log_reporting = false }
  parser.on("-i NAME", "--input-file=NAME", "Specifies an input file to read from") { |ifile| readfile = File.expand_path ifile }
  parser.on("-d MIN", "--report-delay=5", "Set periodic report delay in minutes") { |delay| report_delay = delay.to_i }
  parser.on("-f FILE", "--log-file=FILE", "Set file for logging") { |file| man_log_file = file }
  parser.on("-h", "--help", "Show this help") { help = true }
  parser.on("-v", "--open-log", "Open the previous log in $EDITOR") { 
    channel = Channel(Bool).new
    system ((ENV.has_key? "EDITOR") ? ENV["EDITOR"] : "nano") + " " + get_logpath 0
    exit 0
  }
  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end

end

if readfile
  report_only = !report_only
end

if help
  puts parser
  exit 0
end

profile_list = [] of String

{% for profile_name, data in CONFIG %}
  profile_list << "{{profile_name.downcase.id}}"
{% end %}

if ARGV.empty?
  STDERR.puts "ERROR: missing profile. Valid profiles are: #{profile_list.join(", ")}"
  STDERR.puts parser
  exit(1)
end

unless profile_list.includes? ARGV[0]
  STDERR.puts "ERROR: #{ARGV[0]} is not a valid profile. Valid profiles are: #{profile_list.join(", ")}"
  STDERR.puts parser
  exit(1)
end

macro report
  if reporting
    report_buffer = [] of Tuple(Profile::Severity, String)
    log_buffer = [] of Tuple(Profile::Severity, String)
    print "\n", ("="*60).colorize.bold, "\n", " "*27, "REPORT".colorize(:white).bold, "\n", ("="*60).colorize.bold, "\n"
    if log_reporting
       log "\nREPORT\n"
    end

    {% for profile, data in CONFIG %}
      if ARGV[0] == "{{profile.id}}"
        {% for type, data2 in data %}
          records = Profile::Profile{{profile.id.capitalize}}::{{type.id.capitalize}}.records
          {% if data2.keys.includes? "id" %}
            record_dict = {} of String | Nil => Int32
            records.each do |ele|
              if record_dict.has_key? ele.id
                record_dict[ele.id] += 1 
              else
                record_dict[ele.id] = 1 
              end
            end
            record_dict.each do |id, array|
              report_buffer << {Profile::Severity::{{data2["severity"].id.capitalize}}, Profile::Profile{{profile.id.capitalize}}::{{type.id.capitalize}}.cprint "Found #{array} #{array == 1? "instance" : "instances"} of errorcode \"#{id}\""}
              log_buffer << {Profile::Severity::{{data2["severity"].id.capitalize}}, Profile::Profile{{profile.id.capitalize}}::{{type.id.capitalize}}.print "Found #{array} #{array == 1? "instance" : "instances"} of errorcode \"#{id}\""}
            end
          {% else %}
            report_buffer << {Profile::Severity::{{data2["severity"].id.capitalize}}, Profile::Profile{{profile.id.capitalize}}::{{type.id.capitalize}}.cprint "Found #{records.size} #{records.size == 1? "instance" : "instances"}."}
            log_buffer << {Profile::Severity::{{data2["severity"].id.capitalize}}, Profile::Profile{{profile.id.capitalize}}::{{type.id.capitalize}}.print "Found #{records.size} #{records.size == 1? "instance" : "instances"}."}
          {% end %}
        {% end %}
      end
    {% end %}
    severity_out = Profile::Severity::Nil
    report_buffer = report_buffer.sort { |e, e2| e[0] <=> e2[0] }.reverse.each do |e|
      if e[0] == Profile::Severity::Moniter
        next
      end
      if e[0] != severity_out
        severity_out = e[0]
        severity_text = severity_out != Profile::Severity::Nil ? severity_out.to_s.downcase : "no"
        puts("\n" + ("With " + severity_text + " severity:").colorize.bold.to_s + "")
      end
      puts e[1]
    end
    severity_out = Profile::Severity::Nil
    if logging
      puts "", "Logfile is at #{logfile.path}".colorize.bold
    end
    if log_reporting
      log_buffer = log_buffer.sort { |e, e2| e[0] <=> e2[0] }.reverse.each do |e|
        if e[0] == Profile::Severity::Moniter && not_all
           log e[1]
          next
        end
        if e[0] != severity_out
          severity_out = e[0]
          severity_text = severity_out != Profile::Severity::Nil ? severity_out.to_s.downcase : "no"
           log "\n" + "With " + severity_text + " severity:"
        end
         log e[1]
      end
    end
  end
end

spawn do
  sleep 2
  if hang
    STDERR.puts "ERROR: IO hang detected. Logburn reads from stdin, so run it with \"command | logburn ...\" or specify an input file with --input-file"
    STDERR.puts parser
    exit(1)
  end
end

logfile : File
if file = man_log_file
  textpath = File.expand_path file
  File.touch(textpath)
  logfile = File.open(textpath, "w+")
else
  logfile = gen_log
end

Signal::INT.trap do
  report
  exit 1
end

if mid_report
  spawn do
    sleep report_delay*60
    report
  end
end

io = case readfile
     when "" then STDIN
     else         File.open(readfile, "r+")
     end
loop do
  line = io.gets
  break unless line
  match = nil
  {% for profile, data in CONFIG %}
    if ARGV[0] == "{{profile.id}}"
      match = case
        {% for type, data2 in data %}
          when Profile::Profile{{profile.id.capitalize}}::{{type.id.capitalize}}.match(line) 
            Profile::Profile{{profile.id.capitalize}}::{{type.id.capitalize}}.match(line)
        {% end %}
      else 
        nil
      end
    end
  {% end %}
  if match
    unless match.hide
      unless report_only 
        puts match.cprint(match.line)
      end
      log match.print(match.line)
    else
      log match.print(match.line)
    end
    match.save
  else
    unless nolog
      log "[UNLOGGED] #{line}"
      unless report_only
        puts "[UNLOGGED] #{line}"
      end
    end
  end
end

report
path = logfile.path
logfile.close
unless logging
  File.delete(path)
end
