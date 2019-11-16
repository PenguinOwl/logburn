require "yaml"
print "CONFIG = ", YAML.parse(File.read(ARGV[0])), "\n"
