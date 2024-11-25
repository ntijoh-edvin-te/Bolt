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

# (1) Server (class) establishes a request/session
# (2) Request (class) handles request - (A) is_allowed? (B) Method? (C) GET--> Resources? + Parameters? || POST--> Request Message Body?
#
# (3) 

class Request
    def initialize(request)
        @request_data = {}
        @allowed_methods = ["GET", "POST"]
    end


    # (A) Request Line      [ex] GET /fruits?type=apple HTTP/1.1
    # (B) Request Headers       [ex] Host: fruits.com
    # (C) Request Message Body      [ex] username=apple&password=kiwi


    def handler
        
    end

    def is_allowed?(request)
        return @allowed_methods.include?(File.read(request).lines.first.split(" ")[0])
    end

    def parser(request)
        File.read(request).each_line.with_index do |line,i|
            if i==0
                @request_data["Method"], @request_data["Resource"], @request_data["Version"] = line.split(" ")
            else
                key, value = line.split(":", 2)
                if key && value
                    @request_data[key.strip] = value.strip
                end
            end
        end
    end

    def method_missing(m, *args, &block)
        header = m.to_s.split("_").join("-").downcase
        matching_key = @request_data.keys.find {|k| k.downcase==header}
        if matching_key 
            return @request_data[matching_key] 
        else
            puts "Method #{matching_key} does not exist. "
        end
    end
end

def get_resource(resource)
    data = []
    keys = []

    IO.read(resource).lines.each_with_index do |line, i|
        if i == 0
            keys = line.strip.split(",").map(&:strip)
        else
            values = line.strip.split(",").map(&:strip)
            data << keys.zip(values).to_h
        end
    end
    data
end



# get_resource('resources\heroes.txt')

Request.new("http_payload.txt")