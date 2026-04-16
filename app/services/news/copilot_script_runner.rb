# frozen_string_literal: true

require "open3"
require "json"

module News
  class CopilotScriptRunner
    # Fullwidth quotation marks that LLMs tend to echo back as ASCII
    # double-quotes, breaking JSON output.
    PROBLEMATIC_QUOTES = /[\u201C\u201D\u301D\u301E\uFF02]/

    MAX_RETRIES = 2
    PROCESS_TIMEOUT_SECONDS = 330

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
        stdout, stderr, status = run_with_timeout

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

    def run_with_timeout
      stdin_r, stdin_w = IO.pipe
      stdout_r, stdout_w = IO.pipe
      stderr_r, stderr_w = IO.pipe

      pid = Process.spawn(
        @env,
        *command,
        in: stdin_r, out: stdout_w, err: stderr_w,
        chdir: Rails.root.to_s,
        pgroup: true
      )

      stdin_r.close
      stdout_w.close
      stderr_w.close

      stdin_w.write(@stdin_data)
      stdin_w.close

      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + PROCESS_TIMEOUT_SECONDS

      stdout_output = String.new
      stderr_output = String.new
      readers = [ stdout_r, stderr_r ]

      until readers.empty?
        remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
        if remaining <= 0
          kill_process_group(pid)
          raise "Copilot SDK process timed out after #{PROCESS_TIMEOUT_SECONDS} seconds (Ruby-side process timeout)"
        end

        ready = IO.select(readers, nil, nil, [ remaining, 1 ].min)
        next unless ready

        ready[0].each do |io|
          chunk = io.read_nonblock(16384, exception: false)
          if chunk == :wait_readable
            next
          elsif chunk.nil?
            readers.delete(io)
            io.close
          elsif io == stdout_r
            stdout_output << chunk
          else
            stderr_output << chunk
          end
        end
      end

      _, status = Process.waitpid2(pid)
      [ stdout_output, stderr_output, status ]
    rescue => e
      kill_process_group(pid) if pid
      raise e
    end

    def command
      [ "npx", "--no-install", "tsx", @script_path, *@args ]
    end

    def kill_process_group(pid)
      pgid = Process.getpgid(pid)
      Process.kill("-TERM", pgid)
      sleep 0.1
      Process.kill("-KILL", pgid)
    rescue Errno::ESRCH, Errno::EPERM
      # Process already exited
    ensure
      begin
        Process.waitpid(pid, Process::WNOHANG)
      rescue Errno::ECHILD
        # Already reaped
      end
    end

    def sanitize_text(text)
      self.class.sanitize_text(text)
    end

    def json_error?(error)
      return true if error.is_a?(JSON::ParserError)
      error.message.match?(/JSON/i)
    end
  end
end
