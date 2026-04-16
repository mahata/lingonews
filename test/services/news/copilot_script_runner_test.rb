# frozen_string_literal: true

require "test_helper"

class News::CopilotScriptRunnerTest < ActiveSupport::TestCase
  test "kills the child process and raises when it exceeds the timeout" do
    stub_const(News::CopilotScriptRunner, :PROCESS_TIMEOUT_SECONDS, 1) do
      runner = News::CopilotScriptRunner.new(
        script_path: "dummy.ts",
        env: {},
        args: [],
        stdin_data: "test"
      )
      runner.define_singleton_method(:command) { [ "sleep", "30" ] }

      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      error = assert_raises(RuntimeError) do
        runner.run
      end

      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at

      assert_match(/timed out/, error.message)
      assert_match(/Ruby-side process timeout/, error.message)
      assert elapsed < 5, "Should have timed out in ~1s, took #{elapsed.round(1)}s"
    end
  end

  test "returns parsed JSON from successful process" do
    json = '{"title_en":"Test","title_ja":"テスト","sentences":[]}'

    runner = News::CopilotScriptRunner.new(
      script_path: "dummy.ts",
      env: {},
      args: [],
      stdin_data: "test"
    )
    runner.define_singleton_method(:command) { [ "echo", json ] }

    result = runner.run
    assert_equal "Test", result["title_en"]
    assert_equal "テスト", result["title_ja"]
  end

  test "raises error when process exits with non-zero status" do
    runner = News::CopilotScriptRunner.new(
      script_path: "dummy.ts",
      env: {},
      args: [],
      stdin_data: "test"
    )
    runner.define_singleton_method(:command) { [ "sh", "-c", "echo 'something broke' >&2; exit 1" ] }

    error = assert_raises(RuntimeError) do
      runner.run
    end
    assert_match(/Script failed/, error.message)
    assert_match(/something broke/, error.message)
  end

  private

  def stub_const(klass, const_name, value)
    old_value = klass.const_get(const_name)
    klass.send(:remove_const, const_name)
    klass.const_set(const_name, value)
    yield
  ensure
    klass.send(:remove_const, const_name)
    klass.const_set(const_name, old_value)
  end
end
