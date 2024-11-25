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


### Project outline
'''
(1) Server (class) establishes a request/session.
(2) Request (class) checks if request is allowed. 
(3) Request (class) handles GET and POST requests.

(GET) Check routes.
(GET) isRouteAllowed? : isAuthKeyValid?.

(GET ALLOWED) get_resources(resources, parameters).
(GET ALLOWED) Sends resources back to client.

(GET NOT ALLOWED) Echo ERROR to client.
(GET NOT ALLOWED) Link to /login

(POST) username? & password?.
(POST) login_allowed?.
(POST) Send auth_key to client.
'''

### Sidenotes/Ideas
''' 
[1] GET /fruits?bla=2 HTTP/1.1 
    When server recieves this request can we 
    check if client needs to load any HTML
    and if not required can we then send a 
    client specified resource (fruits) data only?
[1]


[2] Auth_key caching
    Store auth_key as a cookie. Reload without sign-in.
[2]


[3] Route allowance
    /login requires no valid auth_key.
    
    / requires valid auth_key.
    /fruits requires valid auth_key.

    [ex]
        GET / HTTP/1.1 
        auth_key=fs3h98f893sfjwfj90w3gm4gshof

        This route is allowed only if 
        auth_key is valid.
    [ex]
[3]

'''

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