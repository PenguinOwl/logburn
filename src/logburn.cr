require "regex"
require "colorize"
require "yaml"
require "option_parser"

{{run("./read", "config/profiles.yml")}}

nolog = false
readfile = ""

parser = OptionParser.parse! do |parser|
  parser.banner = "Usage: logburn [profile] [arguments]"
  parser.on("-n", "--no-color", "Displays output without color") { Colorize.enabled = false }
  parser.on("-i NAME", "--input-file=NAME", "Specifies an input file to read from") { |ifile| readfile = ifile }
  parser.on("-o", "--only-errors", "Skip logging of unmatched lines") { nolog = true }
  parser.on("-h", "--help", "Show this help") { puts parser }
  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

profile_list = [] of String

{% for profile_name, data in CONFIG %}
  profile_list << "{{profile_name.downcase.id}}"
{% end %}

if ARGV.empty?
  STDERR.puts "ERROR: missing profile."
  STDERR.puts parser
  exit(1)
end

unless profile_list.includes? ARGV[0]
  STDERR.puts "ERROR: #{ARGV[0]} is not a valid profile. Valid profiles are: #{profile_list.join(", ")}"
  STDERR.puts parser
  exit(1)
end

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
end

module Logburn
  VERSION = "0.1.0"

  def self.gen_log
    logdir = ENV["HOME"] + "/.logburn/logs/"
    Dir.mkdir_p(logdir)
    filename = ""
    Dir.open(logdir) do |dir|
      entries = dir.entries.sort do |filename, filename2|
        match = /[0-9]+$/.match(filename)
        match = match ? match[0].to_i : 0
        match2 = /[0-9]+$/.match(filename2)
        match2 = match2 ? match2[0].to_i : 0
        match <=> match2
      end
      old_log = entries.last
      numb = /[0-9]+$/.match(old_log)
      if numb
        filename = "log_#{numb[0].to_i + 1}"
      else
        filename = "log_0"
      end
    end
    File.open(logdir + filename, "w+")
  end

  @@logfile : File
  @@logfile = self.gen_log

  macro dputs(text)
    puts {{text}}
    @@logfile.puts ({{text}}).colorize.toggle(false)
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
            property match : Regex::MatchData | Nil, line : String, id : String | Nil
            name = "{{profile.id.downcase}}"
            @@records = [] of self
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

            def print
              cprint("#{line}")
            end
          end
        {% end %}
      end
    {% end %}
  end

  Signal::INT.trap do
    report
    exit 1
  end

  def self.report
    report_buffer = [] of Tuple(Profile::Severity, String)
    print "\n\n", ("="*60).colorize.bold, "\n\n", " "*27, "REPORT".colorize(:white).bold, "\n\n", ("="*60).colorize.bold, "\n\n"

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
            end
          {% else %}
            report_buffer << {Profile::Severity::{{data2["severity"].id.capitalize}}, Profile::Profile{{profile.id.capitalize}}::{{type.id.capitalize}}.cprint "Found #{records.size} #{records.size == 1? "instance" : "instances"}."}
          {% end %}
        {% end %}
      end
    {% end %}
    severity_out = Profile::Severity::Nil
    report_buffer = report_buffer.sort { |e, e2| e[0] <=> e2[0] }.reverse.each do |e|
      if e[0] == Profile::Severity::Moniter
        @@logfile.puts e[1]
        next
      end
      if e[0] != severity_out
        severity_out = e[0]
        severity_text = severity_out != Profile::Severity::Nil ? severity_out.to_s.downcase : "no"
        dputs("\n" + ("With " + severity_text + " severity:").colorize.bold.to_s + "")
      end
      puts e[1]
    end
    puts "", "Logfile is at #{@@logfile.path}".colorize.bold
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
      dputs match.print
      match.save
    else
      unless nolog
        dputs "[UNLOGGED] #{line}"
      end
    end
  end

  report
end
