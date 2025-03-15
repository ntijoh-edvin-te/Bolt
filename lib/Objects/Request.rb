# frozen_string_literal: true

class Request
    attr_reader :content

    def initialize(payload, logger)
        @logger = logger
        @content = parse(payload)
    end

    def parse(payload)
        full_request = payload.join
        header_part, body_part = full_request.split("\r\n\r\n", 2)
        header_lines = header_part.split("\r\n")

        result = {}
        headers = {}

        request_line = header_lines.shift
        result['Method'], result['Resource'], result['Version'] = request_line.split(' ')

        header_lines.each do |header|
            key, value = header.split(':', 2)
            headers[key.strip] = value.strip if key && value
        end

        body = {}
        unless body_part.nil? || body_part.empty?
            body_part.split('&').each do |param|
                key, value = param.split('=', 2)
                body[key.strip] = value.strip if key && value
            end
        end

        result['Headers'] = headers
        result['Body'] = body
        result
    end
end
