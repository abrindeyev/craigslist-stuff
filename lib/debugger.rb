require 'pathname'

class Debugger
  @@p = Pathname.new(__FILE__).dirname.parent
  def debug(msg)
    offender = caller_locations(1,1).first
    STDERR.puts "[DEBUG] [#{ Pathname.new(offender.path).relative_path_from(@@p) }:#{ offender.lineno }] #{msg}" if ENV.include?('DEBUG') and ENV['DEBUG'] != ''
  end
end
