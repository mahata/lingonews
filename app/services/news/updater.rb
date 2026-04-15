# frozen_string_literal: true

module News
  class Updater
    def self.call(sources: News::Sources.all, limit: nil)
      new(sources:, limit:).call
    end

    def initialize(sources:, limit:)
      @sources = sources
      @limit = limit
    end

    def call
      all_errors = []

      @sources.each do |source|
        puts "--- Fetching from #{source.name} (#{source.url}) ---"
        process_source(source, all_errors)
      end

      if all_errors.any?
        raise "#{all_errors.size} article(s) failed to process:\n" +
              all_errors.map { |err| "  - [#{err[:source]}] #{err[:title]}: #{err[:error]}" }.join("\n")
      end
    end

    private

    def process_source(source, all_errors)
      items = News::RssFetcher.call(feed_url: source.url)
      items = items.first(@limit) if @limit

      puts "Found #{items.size} new article(s) to process."

      items.each_with_index do |item, index|
        process_item(item, index + 1, items.size, source.name)
      rescue => e
        puts "  ERROR:\n#{e.full_message(highlight: false)}"
        all_errors << { source: source.name, title: item[:title], error: "#{e.class}: #{e.message}" }
      end
    rescue => e
      puts "  ERROR fetching feed: #{e.message}"
      all_errors << { source: source.name, title: "(feed fetch)", error: "#{e.class}: #{e.message}" }
    end

    def process_item(item, current, total, source_name)
      puts "[#{current}/#{total}] Fetching: #{item[:title]}"

      article_text = News::ArticleFetcher.call(item[:url])

      if article_text.empty?
        puts "  Skipping: could not extract article text."
        return
      end

      puts "  Summarizing with Copilot SDK..."
      summary = News::ArticleSummarizer.call(title: item[:title], article_text: article_text)

      save_article(item, summary, source_name)
      puts "  Saved article: #{summary[:title_en]}"
    end

    def save_article(item, summary, source_name)
      ActiveRecord::Base.transaction do
        article = Article.create!(
          title_en: summary[:title_en],
          title_ja: summary[:title_ja],
          published_at: item[:published_at] || Time.current,
          source_url: item[:url],
          source: source_name
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
