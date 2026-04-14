# frozen_string_literal: true

require "open3"
require "json"

module News
  class ArticleSummarizer
    SCRIPT_PATH = Rails.root.join("script", "summarize_article.ts").to_s

    def self.call(title:, article_text:)
      new(title:, article_text:).call
    end

    def initialize(title:, article_text:)
      @title = title
      @article_text = article_text
    end

    def call
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
    end

    private

    def parse_output(stdout)
      data = JSON.parse(stdout)

      unless data["title_en"] && data["title_ja"] && data["sentences"].is_a?(Array)
        raise "Invalid summarizer output: missing required fields"
      end

      data.deep_symbolize_keys
    end
  end
end
