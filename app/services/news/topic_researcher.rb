# frozen_string_literal: true

module News
  class TopicResearcher
    SCRIPT_PATH = Rails.root.join("script", "research_topic.ts").to_s

    def self.call(title:, article_text:)
      new(title:, article_text:).call
    end

    def initialize(title:, article_text:)
      @title = CopilotScriptRunner.sanitize_text(title)
      @article_text = CopilotScriptRunner.sanitize_text(article_text)
    end

    def call
      runner = CopilotScriptRunner.new(
        script_path: SCRIPT_PATH,
        env: {
          "GITHUB_TOKEN" => ENV.fetch("GITHUB_TOKEN"),
          "RESEARCH_TIMEOUT_MS" => ENV.fetch("RESEARCH_TIMEOUT_MS", "300000")
        },
        args: [ @title ],
        stdin_data: @article_text
      )

      data = runner.run

      unless data["research_context"].is_a?(String) && data["research_context"].present?
        raise "Invalid research output: missing or empty research_context"
      end

      data["research_context"]
    end
  end
end
