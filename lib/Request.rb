# frozen_string_literal: true

class Request
    attr_reader :content

    def initialize(logger, session)
        @logger = logger
        @content = parse(session)
    end

    def parse(session)
        payload = []

        while (line = session.gets)
            payload << line
            break if line == "\r\n"
        end

        if payload.empty? || !payload[0].include?('HTTP')
            @logger.info('Empty payload or HTTP request.')
            session.close
            return
        end

        content_length = 0
        payload.each do |line|
            if line.downcase.start_with?('content-length:')
                content_length = line.split(':', 2)[1].strip.to_i
                break
            end
        end

        payload << session.read(content_length) if content_length.positive?

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

        cookies = headers.any? { |k, _v| k.downcase == 'cookie' } ? headers['Cookie'].split(';').map(&:strip) : nil

        result['Cookies'] = cookies || []
        result['Headers'] = headers
        result['Body'] = body
        result
    end
end
