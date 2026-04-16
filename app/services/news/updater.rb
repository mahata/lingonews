# frozen_string_literal: true

module News
  class Updater
    MAX_CONCURRENCY = 4

    def self.call(sources: News::Sources.all, limit: nil)
      new(sources:, limit:).call
    end

    def initialize(sources:, limit:)
      @sources = sources
      @limit = limit
    end

    def call
      work_items = collect_work_items
      all_errors = process_concurrently(work_items)

      if all_errors.any?
        raise "#{all_errors.size} article(s) failed to process:\n" +
              all_errors.map { |err| "  - [#{err[:source]}] #{err[:title]}: #{err[:error]}" }.join("\n")
      end
    end

    private

    def collect_work_items
      items = []

      @sources.each do |source|
        puts "--- Fetching from #{source.name} (#{source.url}) ---"
        rss_items = News::RssFetcher.call(feed_url: source.url)
        rss_items = rss_items.first(@limit) if @limit
        puts "Found #{rss_items.size} new article(s) to process."
        rss_items.each { |item| items << { item: item, source: source } }
      rescue => e
        puts "  ERROR fetching feed: #{e.message}"
        items << { feed_error: true, source: source, error: e }
      end

      items
    end

    def process_concurrently(work_items)
      return [] if work_items.empty?

      all_errors = []
      mutex = Mutex.new

      feed_errors, processable_items = work_items.partition { |wi| wi[:feed_error] }
      feed_errors.each do |wi|
        e = wi[:error]
        all_errors << { source: wi[:source].name, title: "(feed fetch)", error: "#{e.class}: #{e.message}" }
      end

      pool_size = [ processable_items.size, MAX_CONCURRENCY ].min
      puts "Processing #{processable_items.size} article(s) with #{pool_size} worker(s)..."

      queue = Queue.new
      processable_items.each { |wi| queue << wi }

      threads = pool_size.times.map do
        Thread.new do
          while (work = queue.pop(true) rescue nil)
            process_item(work[:item], work[:source].name, all_errors, mutex)
          end
        end
      end

      threads.each(&:join)
      all_errors
    end

    def process_item(item, source_name, all_errors, mutex)
      mutex.synchronize { puts "Fetching: #{item[:title]}" }

      article_text = News::ArticleFetcher.call(item[:url])

      if article_text.empty?
        mutex.synchronize { puts "  Skipping: could not extract article text." }
        return
      end

      mutex.synchronize { puts "  Summarizing with Copilot SDK..." }
      summary = News::ArticleSummarizer.call(title: item[:title], article_text: article_text)

      save_article(item, summary, source_name)
      mutex.synchronize { puts "  Saved article: #{summary[:title_en]}" }
    rescue => e
      mutex.synchronize do
        puts "  ERROR:\n#{e.full_message(highlight: false)}"
        all_errors << { source: source_name, title: item[:title], error: "#{e.class}: #{e.message}" }
      end
    end

    def save_article(item, summary, source_name)
      ActiveRecord::Base.transaction do
        article = Article.create!(
          title_en: summary[:title_en],
          title_ja: summary[:title_ja],
          published_at: item[:published_at] || Time.current,
          source_url: item[:url],
          source: source_name,
          source_title: item[:title]
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
