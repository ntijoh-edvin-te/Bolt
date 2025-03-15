require 'json'
class Router
    def initialize(logger)
        @logger = logger
        @routes = load_routes
        preprocess_routes
    end

    def route(request)
        method = request.content['Method'].upcase
        path = request.content['Resource'].split('?').first

        route_info = get_route(method, path) || default_route

        {
            controller: route_info['controller'],
            action: route_info['action'],
            allowed_roles: route_info['allowed_roles'],
            params: route_info['params']
        }
    rescue StandardError => e
        @logger.error("Router error: #{e.message}")
        default_route
    end

    private

    def load_routes
        routes_file = File.read('config/routes.json')
        JSON.parse(routes_file)
    rescue StandardError => e
        @logger.error("Error loading routes: #{e.message}")
        {}
    end

    def preprocess_routes
        @routes['routes'].each do |method, routes|
            routes.each do |route|
                path = route['path']
                regex, param_names = build_regex_and_params(path)
                route['path_regex'] = regex
                route['param_names'] = param_names
            end
        end
    end

    def build_regex_and_params(path)
        param_names = []
        parts = []

        path.split('/').each do |segment|
            next if segment.empty?

            if segment.include?(':')
                colon_index = segment.index(':')
                static_part = segment[0...colon_index]
                param_name = segment[(colon_index + 1)..-1]

                parts << "#{Regexp.escape(static_part)}([^/]+)"
                param_names << param_name
            else
                parts << Regexp.escape(segment)
            end
        end

        regex_str = "^/#{parts.join('/')}$"
        [Regexp.new(regex_str), param_names]
    end

    def get_route(method, path)
        return nil unless @routes['routes'][method]

        @routes['routes'][method].each do |route|
            next unless (match = route['path_regex'].match(path))

            params = {}
            route['param_names'].each_with_index do |name, index|
                params[name] = match[index + 1]
            end
            return route.merge('params' => params)
        end
        nil
    end

    def default_route
        {
            'controller' => 'HomeController',
            'action' => 'default',
            'allowed_roles' => ['guest'],
            'params' => {}
        }
    end
end
