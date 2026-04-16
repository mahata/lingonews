# frozen_string_literal: true

module News
  class ArticleSummarizer
    SCRIPT_PATH = Rails.root.join("script", "summarize_article.ts").to_s

    def self.call(title:, article_text:, research_context: nil)
      new(title:, article_text:, research_context:).call
    end

    def initialize(title:, article_text:, research_context: nil)
      @title = CopilotScriptRunner.sanitize_text(title)
      @article_text = CopilotScriptRunner.sanitize_text(article_text)
      @research_context = research_context ? CopilotScriptRunner.sanitize_text(research_context) : nil
    end

    def call
      runner = CopilotScriptRunner.new(
        script_path: SCRIPT_PATH,
        env: {
          "GITHUB_TOKEN" => ENV.fetch("GITHUB_TOKEN"),
          "RESEARCH_CONTEXT" => @research_context.to_s,
          "SUMMARIZE_TIMEOUT_MS" => ENV.fetch("SUMMARIZE_TIMEOUT_MS", "300000")
        },
        args: [ @title ],
        stdin_data: @article_text
      )

      data = runner.run

      unless data["title_en"] && data["title_ja"] && data["sentences"].is_a?(Array)
        raise "Invalid summarizer output: missing required fields"
      end

      data.deep_symbolize_keys
    end
  end
end
