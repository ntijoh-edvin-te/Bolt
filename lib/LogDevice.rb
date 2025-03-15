require 'colorize'

class LogDevice
    def log(msg, log_level = 0, header = nil)
        header ||= File.basename(caller_locations(1, 1)[0].path)
        level, color = log_levels[log_level.to_i]
        composed_msg = "[#{level}](#{header.gsub(/<(.+?)>/, '\1')}): #{msg}"
        puts composed_msg.colorize(color)
    rescue LoadError
        puts composed_msg
    rescue Exception => e
        puts "Error raised while logging: #{e}"
        puts "fallback: #{msg ||= 'No message'}"
    end

    private

    def log_levels
        {
            0 => ['INFO', :green],
            1 => ['WARN', :yellow],
            2 => ['ERROR', :red]
        }
    end
end
