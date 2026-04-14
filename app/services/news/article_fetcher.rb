# frozen_string_literal: true

require "net/http"
require "nokogiri"

module News
  class ArticleFetcher
    STRIP_ELEMENTS = %w[script style nav footer aside header iframe noscript].freeze

    def self.call(url)
      new(url).call
    end

    def initialize(url)
      @url = url
    end

    def call
      html = fetch_html
      extract_text(html)
    end

    private

    def fetch_html
      uri = URI(@url)

      response = http_get(uri)

      # Follow redirects (up to 3)
      3.times do
        break unless response.is_a?(Net::HTTPRedirection)
        uri = URI(response["location"])
        response = http_get(uri)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise "Failed to fetch article: HTTP #{response.code} for #{@url}"
      end

      response.body.dup.force_encoding("UTF-8")
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise "Failed to fetch article: #{@url} timed out (#{e.class})"
    end

    def http_get(uri)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 15) do |http|
        http.get(uri.request_uri)
      end
    end

    def extract_text(html)
      doc = Nokogiri::HTML(html)

      STRIP_ELEMENTS.each { |tag| doc.css(tag).remove }

      # Prefer article-specific content containers
      content = doc.at_css("article") ||
                doc.at_css('[role="main"]') ||
                doc.at_css(".content--detail-body") || # NHK-specific
                doc.at_css("main") ||
                doc.at_css("body")

      return "" unless content

      content.text.gsub(/\s+/, " ").strip
    end
  end
end
