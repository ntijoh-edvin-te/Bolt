# frozen_string_literal: true

class Router
    attr_reader :logger, :routes

    def initialize(logger)
        @logger = logger
        @routes = Hash.new { |h, k| h[k] = [] }
    end

    %i[get post put patch delete].each do |method|
        define_method(method) do |path, **options, &handler|
            add_route(method.to_s.upcase, path, handler, options)
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
            return route[:handler].call(request, params)
        end

        handle_not_found(http_method, path)
    end

    private

    def render_template(template_path, locals = {})
        template = File.read("views/#{template_path}")
        ERB.new(template).result_with_hash(locals)
    end

    def add_route(method, path, handler, options)
        pattern, param_names = compile_path(path, options[:constraints] || {})

        @routes[method] << {
            method: method,
            original_path: path,
            pattern: pattern,
            param_names: param_names,
            handler: handler,
            name: options[:as]
        }
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
