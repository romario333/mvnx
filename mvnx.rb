#!/usr/bin/env ruby
require_relative "shell"
include Shell # TODO: proc?

class MavenOutputColorizer

  def process(line)
    line_color = ""
    if line.start_with?('[ERROR]')
      line_color = red + bold
    elsif line.start_with?('[WARNING]')
      line_color = yellow
    elsif line.start_with?('[INFO] BUILD SUCCESS')
      print green, bold
    elsif line.start_with?('[INFO]')
      line_color = reset
    end
    line_color + line
  end

end

opts = {}
unprocessed_args = []

args = ARGV.reverse()
while arg = args.pop()
  if arg == "--skip-tests"
    opts[:skip_tests] = true
  elsif arg == "--help"
    opts[:help] = true
  else
    unprocessed_args << arg
  end
end

if opts[:help]
  puts "mvnx version 0.1"
  puts
  puts "Options:"
  OPTION_FORMAT = " %-38s %s"
  puts OPTION_FORMAT % ["--skip-tests", "Equivalent to -Dmaven.test.skip=true."]
  puts

  maven_cmd = "mvn --help"
else
  maven_cmd = "mvn -e" # always show stack-traces (-e)

  if unprocessed_args.size > 0
    maven_cmd << " " + unprocessed_args.join(" ")
  end

  if opts[:skip_tests]
    maven_cmd << " -Dmaven.test.skip=true"
  end
end

shell_ex(maven_cmd, :output_filters => [MavenOutputColorizer.new])