module AlertStrategies
  class Discord
    MIN_INTERVAL_SECONDS = 5
    CHAR_LIMIT = 1800
    HEADERS = { 'Content-type' => 'application/json' }

    def initialize(uri: nil)
      @webhook_uri = uri
    end

    def notify(message: nil)
      @message = message

      http, request = build_request

      begin
        http.request(request)
        puts "Alerta enviado"
      rescue => error
        puts "Erro ao enviar, #{error.message}"
      end
    end

    private

    def parsed_uri
      @uri ||= URI.parse(@webhook_uri)
    end

    def payload
      { content: "🚨 **Erro detectado:**\n```#{@message.strip[0..CHAR_LIMIT]}```" }
    end

    def build_request
      http = Net::HTTP.new(parsed_uri.host, parsed_uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(parsed_uri.request_uri, HEADERS)
      request.body = payload.to_json
      [ http, request ]
    end
  end
end
