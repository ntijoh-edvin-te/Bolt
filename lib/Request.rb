# frozen_string_literal: true

require 'uri'
require 'cgi'

class Request
    attr_reader :content

    def initialize(logger, session)
        @logger = logger
        content = parse(session)
    end

    def get?
        content && content['Method'] == 'GET'
    end

    def post?
        content && content['Method'] == 'POST'
    end

    private

    def parse(session)
        payload = []

        while (line = session.gets)
            payload << line
            break if line == "\r\n"
        end

        if payload.empty? || !payload[0].include?('HTTP')
            @logger.info('Empty payload or non-HTTP request.')
            session.close
            return nil
        end

        content_length = payload.find { |line| line.downcase.start_with?('content-length:') }
                                &.split(':', 2)&.[](1)&.strip&.to_i || 0
        payload << session.read(content_length) if content_length.positive?

        full_request = payload.join
        header_part, body_part = full_request.split("\r\n\r\n", 2)
        header_lines = header_part.split("\r\n")

        method, resource, version = header_lines.shift.split(' ')

        headers = {}
        header_lines.each do |header|
            key, value = header.split(':', 2).map(&:strip)
            headers[key] = value if key && value
        end

        body = {}
        if body_part && !body_part.empty?
            body_part.split('&').each do |param|
                key, value = param.split('=', 2).map(&:strip)
                body[key] = value if key && value
            end
        end

        cookie_key = headers.keys.find { |k| k.downcase == 'cookie' }
        cookies = cookie_key ? headers[cookie_key].split(';').map(&:strip) : []

        path, query = resource.split('?', 2)
        query ||= ''

        query_params = {}
        unless query.empty?
            query.split('&').each do |pair|
                key, value = pair.split('=', 2).map(&:strip)
                query_params[key] = value if key && value
            end
        end

        protocol, http_version = version.split('/', 2)

        {
            'Method' => method,
            'Version' => version,
            'Headers' => headers,
            'Body' => body,
            'Cookies' => cookies,
            'Path' => path,
            'Query' => query,
            'QueryParams' => query_params,
            'FullResource' => resource,
            'FullRequest' => full_request,
            'Protocol' => protocol,
            'HttpVersion' => http_version
        }
    end
end
