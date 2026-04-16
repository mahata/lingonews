# frozen_string_literal: true

require "open3"
require "json"

module News
  class TopicResearcher
    SCRIPT_PATH = Rails.root.join("script", "research_topic.ts").to_s

    PROBLEMATIC_QUOTES = /[\u201C\u201D\u301D\u301E\uFF02]/

    MAX_RETRIES = 2

    def self.call(title:, article_text:)
      new(title:, article_text:).call
    end

    def initialize(title:, article_text:)
      @title = sanitize_text(title)
      @article_text = sanitize_text(article_text)
    end

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
          raise "Research script failed (exit #{status.exitstatus}): #{stderr}"
        end

        parse_output(stdout)
      rescue JSON::ParserError, RuntimeError => e
        if attempts <= MAX_RETRIES && json_error?(e)
          puts "  WARNING: Research JSON parse failed (attempt #{attempts}/#{MAX_RETRIES + 1}), retrying... (#{e.message})"
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

      unless data["research_context"].is_a?(String) && data["research_context"].present?
        raise "Invalid research output: missing or empty research_context"
      end

      data["research_context"]
    end
  end
end
