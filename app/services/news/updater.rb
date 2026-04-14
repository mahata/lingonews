# frozen_string_literal: true

module News
  class Updater
    def self.call(feed_url: News::RssFetcher::RSS_FEED_URL, limit: nil)
      new(feed_url:, limit:).call
    end

    def initialize(feed_url:, limit:)
      @feed_url = feed_url
      @limit = limit
    end

    def call
      items = News::RssFetcher.call(feed_url: @feed_url)
      items = items.first(@limit) if @limit

      puts "Found #{items.size} new article(s) to process."

      items.each_with_index do |item, index|
        process_item(item, index + 1, items.size)
      rescue => e
        puts "  ERROR: #{e.message}"
      end
    end

    private

    def process_item(item, current, total)
      puts "[#{current}/#{total}] Fetching: #{item[:title]}"

      article_text = News::ArticleFetcher.call(item[:url])

      if article_text.empty?
        puts "  Skipping: could not extract article text."
        return
      end

      puts "  Summarizing with Copilot SDK..."
      summary = News::ArticleSummarizer.call(title: item[:title], article_text: article_text)

      save_article(item, summary)
      puts "  Saved article: #{summary[:title_en]}"
    end

    def save_article(item, summary)
      ActiveRecord::Base.transaction do
        article = Article.create!(
          title_en: summary[:title_en],
          title_ja: summary[:title_ja],
          published_at: item[:published_at] || Time.current,
          source_url: item[:url]
        )

        summary[:sentences].each_with_index do |sentence, index|
          article.sentences.create!(
            position: index + 1,
            body_en: sentence[:body_en],
            body_ja: sentence[:body_ja]
          )
        end
      end
    end
  end
end
