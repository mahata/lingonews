# frozen_string_literal: true

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
      response = News::HttpClient.get(@url)

      unless response.is_a?(Net::HTTPSuccess)
        raise "Failed to fetch article: HTTP #{response.code} for #{@url}"
      end

      encode_body(response)
    end

    def encode_body(response)
      body = response.body.dup
      charset = extract_charset(response)
      encoding = find_encoding(charset)

      if encoding
        body.force_encoding(encoding)
      else
        detected = Nokogiri::HTML(body).encoding
        detected_encoding = find_encoding(detected)
        body.force_encoding(detected_encoding) if detected_encoding
      end

      body.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    end

    def find_encoding(charset)
      return nil if charset.nil? || charset.empty?

      Encoding.find(charset)
    rescue ArgumentError
      nil
    end

    def extract_charset(response)
      content_type = response["content-type"]
      return nil unless content_type

      match = content_type.match(/charset=["']?([^\s;"']+)/i)
      match&.[](1)
    end

    def extract_text(html)
      doc = Nokogiri::HTML(html)

      STRIP_ELEMENTS.each { |tag| doc.css(tag).remove }

      content = doc.at_css("article") ||
                doc.at_css('[role="main"]') ||
                doc.at_css(".content--detail-body") ||
                doc.at_css("main") ||
                doc.at_css("body")

      return "" unless content

      content.text.gsub(/\s+/, " ").strip
    end
  end
end
