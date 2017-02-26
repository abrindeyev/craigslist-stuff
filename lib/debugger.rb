require 'pathname'
require 'find'

class Debugger
  @@p = Pathname.new(__FILE__).dirname.parent
  @@debug_path_width = nil
  @@debug_max_lines = 0

  def calculate_formatting
    return if @@debug_path_width
    ruby_files = []
    Find.find(@@p) do |path|
      ruby_files << path if path =~ /.*\.rb$/ and path !~ /\/spec\//
    end
    @@debug_path_width = 1
    ruby_files.each do |file|
      l = Pathname.new(file).relative_path_from(@@p).to_s.length
      @@debug_path_width = l if @@debug_path_width < l
      lines = File.open(file,'r').readlines.size
      @@debug_max_lines = lines.to_s.length if @@debug_max_lines < lines.to_s.length
    end
    STDERR.puts @@debug_max_lines
  end

  def debug(msg)
    offender = caller_locations(1,1).first
    if ENV.include?('DEBUG') and ENV['DEBUG'] != ''
      calculate_formatting
      STDERR.printf("[DEBUG] [%0#{ @@debug_path_width }s:%-#{ @@debug_max_lines }i] %s\n", Pathname.new(offender.path).relative_path_from(@@p), offender.lineno, msg)
    end
  end
end
