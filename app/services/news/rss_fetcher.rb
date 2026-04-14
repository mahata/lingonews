# frozen_string_literal: true

require "net/http"
require "rss"

module News
  class RssFetcher
    RSS_FEED_URL = "https://www.nhk.or.jp/rss/news/cat0.xml"

    def self.call(feed_url: RSS_FEED_URL)
      new(feed_url:).call
    end

    def initialize(feed_url: RSS_FEED_URL)
      @feed_url = feed_url
    end

    def call
      xml = fetch_feed
      items = parse_feed(xml)
      filter_new_items(items)
    end

    private

    def fetch_feed
      uri = URI(@feed_url)

      response = http_get(uri)

      # Follow redirects (up to 3)
      3.times do
        break unless response.is_a?(Net::HTTPRedirection)
        uri = URI(response["location"])
        response = http_get(uri)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise "Failed to fetch RSS feed: HTTP #{response.code}"
      end

      response.body
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise "Failed to fetch RSS feed: #{@feed_url} timed out (#{e.class})"
    end

    def http_get(uri)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 15) do |http|
        http.get(uri.request_uri)
      end
    end

    def parse_feed(xml)
      feed = RSS::Parser.parse(xml, false)

      feed.items.map do |item|
        {
          title: item.title,
          url: item.link,
          published_at: item.pubDate
        }
      end
    end

    def filter_new_items(items)
      existing_urls = Article.where(source_url: items.map { |i| i[:url] }).pluck(:source_url).to_set
      items.reject { |item| existing_urls.include?(item[:url]) }
    end
  end
end
