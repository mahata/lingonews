# frozen_string_literal: true

require "open3"
require "json"

module News
  class ArticleSummarizer
    SCRIPT_PATH = Rails.root.join("script", "summarize_article.ts").to_s

    def self.call(title:, article_text:)
      new(title:, article_text:).call
    end

    # Fullwidth quotation marks that LLMs tend to echo back as ASCII
    # double-quotes, breaking JSON output.
    PROBLEMATIC_QUOTES = /[\u201C\u201D\u301D\u301E\uFF02]/

    def initialize(title:, article_text:)
      @title = sanitize_text(title)
      @article_text = sanitize_text(article_text)
    end

    MAX_RETRIES = 2

    def call
      attempts = 0

      begin
        attempts += 1
        stdout, stderr, status = Open3.capture3(
          { "GITHUB_TOKEN" => ENV.fetch("GITHUB_TOKEN") },
          "npx", "--no-install", "tsx", SCRIPT_PATH, @title,
          stdin_data: @article_text,
          chdir: Rails.root.to_s
        )

        unless status.success?
          raise "Summarizer script failed (exit #{status.exitstatus}): #{stderr}"
        end

        parse_output(stdout)
      rescue JSON::ParserError, RuntimeError => e
        if attempts <= MAX_RETRIES && json_error?(e)
          puts "  WARNING: JSON parse failed (attempt #{attempts}/#{MAX_RETRIES + 1}), retrying... (#{e.message})"
          retry
        end
        raise
      end
    end

    private

    def sanitize_text(text)
      text.gsub(PROBLEMATIC_QUOTES, "")
    end

    def json_error?(error)
      return true if error.is_a?(JSON::ParserError)
      error.message.match?(/JSON/i)
    end

    def parse_output(stdout)
      data = JSON.parse(stdout)

      unless data["title_en"] && data["title_ja"] && data["sentences"].is_a?(Array)
        raise "Invalid summarizer output: missing required fields"
      end

      data.deep_symbolize_keys
    end
  end
end
