# frozen_string_literal: true

require "open3"
require "json"

module News
  class CopilotScriptRunner
    # Fullwidth quotation marks that LLMs tend to echo back as ASCII
    # double-quotes, breaking JSON output.
    PROBLEMATIC_QUOTES = /[\u201C\u201D\u301D\u301E\uFF02]/

    MAX_RETRIES = 2

    def initialize(script_path:, env:, args:, stdin_data:)
      @script_path = script_path
      @env = env
      @args = args
      @stdin_data = sanitize_text(stdin_data)
    end

    def run
      attempts = 0

      begin
        attempts += 1
        stdout, stderr, status = Open3.capture3(
          @env,
          "npx", "--no-install", "tsx", @script_path, *@args,
          stdin_data: @stdin_data,
          chdir: Rails.root.to_s
        )

        unless status.success?
          raise "Script failed (exit #{status.exitstatus}): #{stderr}"
        end

        JSON.parse(stdout)
      rescue JSON::ParserError, RuntimeError => e
        if attempts <= MAX_RETRIES && json_error?(e)
          puts "  WARNING: JSON parse failed (attempt #{attempts}/#{MAX_RETRIES + 1}), retrying... (#{e.message})"
          retry
        end
        raise
      end
    end

    def self.sanitize_text(text)
      text.gsub(PROBLEMATIC_QUOTES, "")
    end

    private

    def sanitize_text(text)
      self.class.sanitize_text(text)
    end

    def json_error?(error)
      return true if error.is_a?(JSON::ParserError)
      error.message.match?(/JSON/i)
    end
  end
end
