require "socket"

class Server
  def initialize()
      @server = TCPServer.new("localhost",8000)
      start
  end

  def start
      while (session = @server.accept)
          puts "Client connected..."
          payload = [] 
          session.read.each_line {|line| payload << line}
          payload.each {|i| puts "#{i}"}
      end
  end
end