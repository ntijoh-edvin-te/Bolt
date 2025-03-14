# frozen_string_literal: true

require_relative 'Response'

class MethodError < StandardError; end
class ResourceError < StandardError; end

class Router
    def initialize
        @routes = []
    end

    def add_route(route, requires_auth)
        @routes.push([route, requires_auth]) unless
            @routes.include?([route, requires_auth])
    end

    def route(request, auth)
        method = request.content['Method'] || 'UNKNOWN_METHOD'
        request_route = request.content['Resource']&.split('?')&.first || 'UNKNOWN_ROUTE'
        puts "#{method} #{request_route}"

        response = Response.new

        begin
            route = @routes.find { |route| route[0] == request_route }
            if !route
                raise ResourceError, "Request route not found: #{request_route}"
            elsif route[1] && !auth
                response.unauthorized # Unauthorized
            else
                case method
                when 'GET'
                    response.get(request, auth) # GET
                when 'POST'
                    response.post(request, auth) # POST
                else
                    raise MethodError, "Invalid method: #{method}"
                end
            end
        rescue MethodError => e
            puts "Router error: method not allowed: #{e}"
            response.method_not_allowed # Method not allowed
        rescue ResourceError => e
            puts "Router error: resource not found: #{e}"
            response.route_not_found # Route not found
        rescue Exception => e
            puts "Router error: #{e}"
            response.server_error # Internal server error
        end
    end
end
