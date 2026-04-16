# frozen_string_literal: true

require "net/http"

module News
  module HttpClient
    MAX_REDIRECTS = 3

    def self.get(url, open_timeout: 10, read_timeout: 15)
      uri = URI(url)

      response = http_get(uri, open_timeout:, read_timeout:)

      MAX_REDIRECTS.times do
        break unless response.is_a?(Net::HTTPRedirection)
        uri = URI(response["location"])
        response = http_get(uri, open_timeout:, read_timeout:)
      end

      response
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise "HTTP request failed: #{url} timed out (#{e.class})"
    end

    def self.http_get(uri, open_timeout:, read_timeout:)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout:, read_timeout:) do |http|
        http.get(uri.request_uri)
      end
    end
    private_class_method :http_get
  end
end
