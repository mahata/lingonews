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
      response = Net::HTTP.get_response(uri)

      unless response.is_a?(Net::HTTPSuccess)
        raise "Failed to fetch RSS feed: HTTP #{response.code}"
      end

      response.body
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
