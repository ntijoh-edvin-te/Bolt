class BaseController
    def default_headers
        {
            'Content-Type' => 'text/html',
            'Server' => 'bolt/1.0'
        }
    end

    def render_view(view, locals = {})
        view_path = File.join('app', 'views', view)
        view_content = File.read(template_path)
        view_content.gsub!(/<%=(.+?)%>/) { locals[::Regexp.last_match(1).strip.to_sym] }
        view_content
    end

    def build_response(status, body, headers = {})
        headers = default_headers.merge(headers)
        headers['Content-Length'] = body.bytesize.to_s
        "HTTP/1.1 #{status}\r\n" + headers.map { |k, v| "#{k}: #{v}" }.join("\r\n") + "\r\n\r\n" + body
    end
end
