class Router
    def initialize(logger)
        @logger = logger
    end

    def route(request)
    end

    private

    def get_path(request)
        request.content[]
    end
end
