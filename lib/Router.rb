# frozen_string_literal: true

class Router
    attr_reader :logger, :routes

    def initialize(logger)
        @logger = logger
        @routes = Hash.new { |h, k| h[k] = [] }
    end

    %i[get post put patch delete].each do |method|
        define_method(method) do |path, to: nil, **options, &handler|
            handler_or_action = to || handler
            add_route(method.to_s.upcase, path, handler_or_action, options)
        end
    end

    def scope(path, &block)
        RouteGroup.new(self, path).instance_eval(&block)
    end

    def resources(name, options = {}, &block)
        base = name.to_s.downcase
        id_format = options[:constraints] || '[^\/]+'

        scope("/#{base}") do
            get('/', as: :index) if block_given?
            get('/new', as: :new)
            post('/', as: :create)
            get('/:id', constraints: { id: id_format }, as: :show)
            get('/:id/edit', constraints: { id: id_format }, as: :edit)
            patch('/:id', constraints: { id: id_format }, as: :update)
            put('/:id', constraints: { id: id_format }, as: :update)
            delete('/:id', constraints: { id: id_format }, as: :destroy)

            instance_eval(&block) if block_given?
        end
    end

    def route(request)
        http_method = request.content['Method'].to_s.upcase
        path = request.content['Path']

        logger.call("Routing #{http_method} #{path}")

        @routes[http_method].each do |route|
            match = route[:pattern].match(path)
            next unless match

            params = extract_params(match, route[:param_names])
            logger.call("Matched #{route[:method]} #{route[:original_path]}")

            if route[:controller] && route[:action]
                controller = route[:controller].new
                return controller.send(route[:action], request, params)
            elsif route[:handler].respond_to?(:call)
                return route[:handler].call(request, params)
            end
        end

        handle_not_found(http_method, path)
    end

    private

    def render_template(template_path, locals = {})
        template = File.read("views/#{template_path}")
        ERB.new(template).result_with_hash(locals)
    end

    def add_route(method, path, handler_or_action, options = {})
        constraints = options[:constraints] || {}
        pattern, param_names = compile_path(path, constraints)

        route = {
            method: method,
            original_path: path,
            pattern: pattern,
            param_names: param_names
        }

        if handler_or_action.is_a?(String) && handler_or_action.include?('#')
            controller_name, action = handler_or_action.split('#')
            controller_class_name = "#{controller_name.capitalize}Controller"
            route[:controller] = Object.const_get(controller_class_name)
            route[:action] = action.to_sym
        elsif handler_or_action.respond_to?(:call)
            route[:handler] = handler_or_action
        end

        route[:as] = options[:as] if options[:as]

        @routes[method] << route
    end

    def compile_path(path, constraints)
        segments = path.split('/').reject(&:empty?)
        param_names = []

        regex_parts = segments.map do |segment|
            parts = segment.split(/(?=:)/)

            parts.map do |part|
                if part.start_with?(':')
                    param_name = part[1..-1].to_sym
                    param_names << param_name
                    constraint = constraints[param_name] || '[^\/]+'
                    "(?<#{param_name}>#{constraint})"
                else
                    part
                end
            end.join
        end

        [%r{\A/#{regex_parts.join('/')}\z}, param_names]
    end

    def extract_params(match_data, param_names)
        param_names.each_with_object({}) do |name, hash|
            hash[name] = match_data[name.to_s]
        end
    end

    def handle_not_found(method, path)
        logger.call("No route found for #{method} #{path}", 1)
        {
            status: 404,
            headers: { 'Content-Type' => 'text/plain', 'Content-Length' => '9' },
            body: 'Not Found'
        }
    end

    class RouteGroup
        def initialize(router, prefix)
            @router = router
            @prefix = prefix
        end

        %i[get post put patch delete resources scope].each do |method|
            define_method(method) do |*args, &block|
                if %i[scope resources].include?(method)
                    process_nested_route(method, *args, &block)
                else
                    path, *options = args
                    options = options.first || {}
                    process_standard_route(method, path, options, &block)
                end
            end
        end

        private

        def process_standard_route(method, path, options = {}, &block)
            full_path = File.join(@prefix, path).gsub(%r{//+}, '/')
            @router.send(method, full_path, **options, &block)
        end

        def process_nested_route(method, path, &block)
            new_prefix = File.join(@prefix, path.to_s)
            RouteGroup.new(@router, new_prefix).instance_eval(&block)
        end
    end
end
