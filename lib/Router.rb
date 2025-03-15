# frozen_string_literal: true

require 'json'

class Router
    def initialize(logger)
        @logger = logger
        @routes = load_routes
    end

    def load_routes
        JSON.parse(File.read('resources/routes/routes.json'))
    rescue StandardError => e
        @logger.error("Failed to load routes: #{e.message}")
        { 'routes' => {} }
    end

    def route(request)
        http_method = request.content.fetch('Method', 'GET').to_s.upcase
        path = normalize_path(request.content.fetch('Resource', '/'))

        route_info = find_route(http_method, path)
        route_info ||= find_route('GET', '/') || default_route

        {
            controller: route_info['controller'],
            action: route_info['action'],
            middleware: route_info['middleware'] || []
        }
    rescue StandardError => e
        @logger.error("Router error: #{e.message}")
        default_route
    end

    private

    def normalize_path(path)
        normalized = path.gsub(%r{/+$}, '')
        normalized.empty? ? '/' : normalized
    end

    def find_route(http_method, path)
        @routes.dig('routes', http_method, path)
    end

    def default_route
        { controller: 'HomeController', action: 'index', middleware: [] }
    end
end
