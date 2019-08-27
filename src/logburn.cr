require "regex"
require "colorize"
require "yaml"

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
  {{run("./read", "config/profiles.yml")}}
  logdir = ENV["HOME"]+"/.logburn/logs/"
  Dir.mkdir_p(logdir)
  filename = ""
  Dir.open(logdir) do |dir|
    entries = dir.entries.sort
    old_log = entries.last
    numb = /[0-9]+$/.match(old_log)
    if numb
      filename = "log_#{numb[0].to_i+1}"
    else
      filename = "log_0"
    end
  end
  logfile = File.open(logdir + filename, "w+")

  macro dputs(text)
    puts {{text}}
    logfile.puts {{text}}
  end

  module Profile
    enum Severity
      Moniter
      Low
      Medium
      High
      Critical
    end
    {% for apl, predata in CONFIG %}
      module Profile{{apl.id.capitalize}}
        {% for profile, data in predata %}
          class {{profile.id.capitalize}}
            property match : Regex::MatchData | Nil, line : String, id : String | Nil
            @@name = "{{profile.id.downcase}}"
            SEVERITY = Severity.{{data["severity"].id.capitalize}}
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

  raise "Missing profile! Do \"logburn <profile>\"" if ARGV.empty?
  loop do
    line = STDIN.gets
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
    end
  end
        
  print "\n\n", ("="*20).colorize.bold, "\n\n", " "*7, "REPORT".colorize(:white).bold, " "*7, "\n\n", ("="*20).colorize.bold, "\n\n"

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
            dputs Profile::Profile{{profile.id.capitalize}}::{{type.id.capitalize}}.cprint "Found #{array} #{array == 1? "instance" : "instances"} of errorcode \"#{id}\""
          end
        {% else %}
          dputs Profile::Profile{{profile.id.capitalize}}::{{type.id.capitalize}}.cprint "Found #{records.size} #{records.size == 1? "instance" : "instances"}."
        {% end %}
      {% end %}
    end
  {% end %}
end
