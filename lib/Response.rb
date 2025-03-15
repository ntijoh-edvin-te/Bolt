class Response
    attr_accessor :status_code, :headers, :body

    def initialize
        @status_code = 200
        @headers = {}
        @body = ''
    end

    def compose
        response = "HTTP/1.1 #{@status_code} OK\r\n"
        @headers.each do |key, value|
            response += "#{key}: #{value}\r\n"
        end
        response += "\r\n"
        response += @body

        response
    end
end
