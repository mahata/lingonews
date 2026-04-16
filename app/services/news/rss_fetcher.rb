# frozen_string_literal: true

require "rss"

module News
  class RssFetcher
    def self.call(feed_url:)
      new(feed_url:).call
    end

    def initialize(feed_url:)
      @feed_url = feed_url
    end

    def call
      xml = fetch_feed
      items = parse_feed(xml)
      filter_new_items(items)
    end

    private

    def fetch_feed
      response = News::HttpClient.get(@feed_url)

      unless response.is_a?(Net::HTTPSuccess)
        raise "Failed to fetch RSS feed: HTTP #{response.code}"
      end

      response.body
    end

    def parse_feed(xml)
      feed = RSS::Parser.parse(xml, false)

      feed.items.map do |item|
        {
          title: item.title.to_s.strip,
          url: item.link.to_s.strip,
          published_at: extract_published_at(item)
        }
      end
    end

    def extract_published_at(item)
      if item.respond_to?(:pubDate) && item.pubDate
        item.pubDate
      elsif item.respond_to?(:dc_date) && item.dc_date
        item.dc_date
      end
    end

    def filter_new_items(items)
      existing_urls = Article.where(source_url: items.map { |i| i[:url] }).pluck(:source_url).to_set
      items.reject { |item| existing_urls.include?(item[:url]) }
    end
  end
end
