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

class Request
    def initialize(http_payload)
      @hash = {}
      parser(http_payload)
    end
  
    def parser(http_payload)
        http_payload.each_line.with_index  do |line,i|
            if i==0
                @hash["Method"] = line.strip
            else
                key, value = line.split(":", 2)
                if key && value
                    @hash[key.strip] = value.strip
                end
            end
        end
    end

    def method_missing(m, *args, &block)
        header = m.to_s.split("_").join("-").downcase

        matching_key = @hash.keys.find {|k| k.downcase==header}
        
        if matching_key 
            return @hash[matching_key] 
        else
            super
        end
    end
end

puts Request.new(IO.read("./http_payload.txt"))