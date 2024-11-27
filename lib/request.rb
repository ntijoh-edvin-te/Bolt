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
(GET NOT ALLOWED) Link to /login.

(POST) username? & password?.
(POST) login_allowed?.
(POST) Send auth_key to client.
'''

### Sidenotes/Ideas
''' 
[1] GET /fruits?bla=2 HTTP/1.1 
    When server recieves above request can we 
    check if client needs to load any HTML
    and if not required can we then send a 
    client specified resource (fruits) data only?

    Determine with content type? If loading website 
    content type will be text/HTML and if requesting
    resources content type could be application/json
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

# (A) Request Line      [ex] GET /fruits?type=apple HTTP/1.1
# (B) Request Headers       [ex] Host: fruits.com
# (C) Request Message Body      [ex] username=apple&password=kiwi

class Request
    def initialize(request)
        @allowed_methods = ["GET", "POST"]
        parser(request)
    end

    def isAuthKeyValid?(auth_key, auth_keys)
        File.read(auth_keys).lines.each { |key|
            return true if key == auth_key
        }
        return false
    end

    def get_resource(resource)
        route, args = resource.include?("?") ? resource.split("?",2) : [resource, nil]
        route = "./resources"+route
        args = args.split("&",-1).map{|arg| arg.split("=",2)}

        # Extract
        data = read_resource(route)

        # Filter by args 
        data = filter_resource(data,args)
        
    end

    def filter_resource(data, args)
        return data unless args && !args.empty?
        filtered_data = data.select do |name, attributes|
            args.all? { |key, value| attributes[key] == value }
        end
        filtered_data
    end

    def read_resource(route)
        # First line of resource acts as a constructor.
        # Each argument is separated by a comma.
        # First argument will be parent to rest.
        
        data = {}
        keys = []
        IO.read(route).lines.each_with_index do |line, i|
            if i == 0
                keys = line.strip.split(",").map(&:strip)
            else
                d = {}
                values = line.strip.split(",").map(&:strip)
                keys.each_with_index { |key,i|  
                    next if i==0
                    d[key]=values[i]
                }
                data[values[0]]=d
            end
        end
        data
    end

    def parser(request)
        content = get_content(request)
        if content["Method"] == "GET"
            # Authenticate
            auth_key = content["Params"]["auth_key"]

            if isAuthKeyValid?(auth_key,"lib/auth_keys.txt")
                get_resource(content["Resource"])
            end


        elsif content["Method"] == "POST"
            # POST request handling



        else
            # Exception Handling
            puts "Request not allowed."
        end
    end

    def isAllowed?(request)
        return @allowed_methods.include?(File.read(request).lines.first.split(" ")[0])
    end

    def get_content(request)
        # Start-line
        # Headers
        # Empty line
        # Message body
        #
        # Construct a Tuple with Tuples 😱 -->    
        #
        #   content = {
        #       Method=>Method,
        #       Resources=>Resources,
        #       Version=>Version,
        #       Headers => { ... },
        #       Params=> { ... }
        #   }

        content_ex = {
            "Method"=>"GET",
            "Resources"=>"/fruits?type=banana",
            "Version"=>"HTTP/1.1",
            "Headers"=>{"Host"=>"fruits.com", "User-Agents"=>"ExampleBrowser/1.0"},
            "Params"=>{"Password"=>"roblox32!", "Username"=>"sigmawarrior32"}    
        }

        content = {}        
        headers = {}
        params = {}

        empty_line = false
        counter = 0

        File.read(request).each_line.with_index do |line,i|
            empty_line=true if line.length==1
            if i==0
                # Start-line
                content["Method"], content["Resource"], content["Version"] = line.split(" ")
            elsif !empty_line
                # Headers
                # (A) Helper function !!
                key, value = line.split(":", )
                if key && value
                    headers[key.strip] = value.strip
                end
            elsif empty_line&&counter==0
                # Empty line
                counter+=1
            elsif empty_line&&counter==1
                # Params
                # (A) Helper function !!
                p = line.split("&",-1)
                p.each { |param|
                    key, value = param.split("=", 2)
                    if key && value
                        params[key.strip] = value.strip
                    end
                }
            end
        end
        content["Headers"]=headers
        content["Params"]=params
        content
    end
end

Request.new("http_payload.txt")