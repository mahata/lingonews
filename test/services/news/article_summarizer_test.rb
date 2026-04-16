# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class News::ArticleSummarizerTest < ActiveSupport::TestCase
  setup do
    @original_github_token = ENV["GITHUB_TOKEN"]
    ENV["GITHUB_TOKEN"] = "test-token"
  end

  teardown do
    if @original_github_token
      ENV["GITHUB_TOKEN"] = @original_github_token
    else
      ENV.delete("GITHUB_TOKEN")
    end
  end

  test "calls script and parses JSON output" do
    mock_output = {
      title_en: "Cherry Blossoms in Full Bloom in Tokyo",
      title_ja: "東京で桜が満開",
      sentences: [
        { body_en: "Cherry blossoms reached full bloom in Tokyo.", body_ja: "東京都内の桜が満開を迎えました。" },
        { body_en: "This year's blooming came five days earlier than usual.", body_ja: "今年の開花は例年より5日早いです。" }
      ]
    }.to_json

    mock_status = Data.define(:success?, :exitstatus).new("success?": true, exitstatus: 0)

    stub_run_with_timeout([ mock_output, "", mock_status ]) do
      result = News::ArticleSummarizer.call(
        title: "東京で桜が満開",
        article_text: "東京都内の桜が14日、満開を迎えました。"
      )

      assert_equal "Cherry Blossoms in Full Bloom in Tokyo", result[:title_en]
      assert_equal "東京で桜が満開", result[:title_ja]
      assert_equal 2, result[:sentences].size
      assert_equal "Cherry blossoms reached full bloom in Tokyo.", result[:sentences][0][:body_en]
    end
  end

  test "passes research context as env var when provided" do
    mock_output = {
      title_en: "Cherry Blossoms in Full Bloom in Tokyo",
      title_ja: "東京で桜が満開",
      sentences: [
        { body_en: "Cherry blossoms reached full bloom.", body_ja: "桜が満開を迎えました。" }
      ]
    }.to_json

    mock_status = Data.define(:success?, :exitstatus).new("success?": true, exitstatus: 0)

    captured_env = nil
    mock_new = ->(script_path:, env:, args:, stdin_data:) {
      captured_env = env
      runner = News::CopilotScriptRunner.allocate
      runner.instance_variable_set(:@script_path, script_path)
      runner.instance_variable_set(:@env, env)
      runner.instance_variable_set(:@args, args)
      runner.instance_variable_set(:@stdin_data, stdin_data)
      runner.define_singleton_method(:run) { JSON.parse(mock_output) }
      runner
    }

    News::CopilotScriptRunner.stub :new, mock_new do
      News::ArticleSummarizer.call(
        title: "東京で桜が満開",
        article_text: "桜が満開を迎えました。",
        research_context: "Additional context from web research."
      )
    end

    assert_equal "Additional context from web research.", captured_env["RESEARCH_CONTEXT"]
  end

  test "passes empty research context env var when not provided" do
    mock_output = {
      title_en: "Test",
      title_ja: "テスト",
      sentences: [ { body_en: "Test.", body_ja: "テスト。" } ]
    }.to_json

    captured_env = nil
    mock_new = ->(script_path:, env:, args:, stdin_data:) {
      captured_env = env
      runner = News::CopilotScriptRunner.allocate
      runner.instance_variable_set(:@script_path, script_path)
      runner.instance_variable_set(:@env, env)
      runner.instance_variable_set(:@args, args)
      runner.instance_variable_set(:@stdin_data, stdin_data)
      runner.define_singleton_method(:run) { JSON.parse(mock_output) }
      runner
    }

    News::CopilotScriptRunner.stub :new, mock_new do
      News::ArticleSummarizer.call(
        title: "Test",
        article_text: "Test text"
      )
    end

    assert_equal "", captured_env["RESEARCH_CONTEXT"]
  end

  test "raises error when script fails" do
    mock_status = Data.define(:success?, :exitstatus).new("success?": false, exitstatus: 1)

    stub_run_with_timeout([ "", "Something went wrong", mock_status ]) do
      error = assert_raises(RuntimeError) do
        News::ArticleSummarizer.call(title: "Test", article_text: "Test text")
      end
      assert_match(/Script failed/, error.message)
    end
  end

  test "raises error for invalid JSON output after exhausting retries" do
    mock_status = Data.define(:success?, :exitstatus).new("success?": true, exitstatus: 0)

    call_count = 0
    mock = ->() {
      call_count += 1
      [ "not json", "", mock_status ]
    }

    stub_run_with_timeout(mock) do
      assert_raises(JSON::ParserError) do
        News::ArticleSummarizer.call(title: "Test", article_text: "Test text")
      end
    end

    assert_equal 3, call_count, "Expected 1 initial attempt + 2 retries = 3 total calls"
  end

  test "retries on JSON parse error and succeeds on subsequent attempt" do
    mock_status = Data.define(:success?, :exitstatus).new("success?": true, exitstatus: 0)

    valid_output = {
      title_en: "Test Title",
      title_ja: "テストタイトル",
      sentences: [
        { body_en: "Test sentence.", body_ja: "テスト文。" }
      ]
    }.to_json

    call_count = 0
    mock = ->() {
      call_count += 1
      if call_count == 1
        [ "not json {broken", "", mock_status ]
      else
        [ valid_output, "", mock_status ]
      end
    }

    result = nil
    stub_run_with_timeout(mock) do
      result = News::ArticleSummarizer.call(title: "Test", article_text: "Test text")
    end

    assert_equal 2, call_count, "Expected 1 failed attempt + 1 successful retry"
    assert_equal "Test Title", result[:title_en]
    assert_equal "テストタイトル", result[:title_ja]
    assert_equal 1, result[:sentences].size
  end

  test "retries on script failure with JSON error in stderr and succeeds" do
    fail_status = Data.define(:success?, :exitstatus).new("success?": false, exitstatus: 1)
    ok_status = Data.define(:success?, :exitstatus).new("success?": true, exitstatus: 0)

    valid_output = {
      title_en: "Test Title",
      title_ja: "テストタイトル",
      sentences: [
        { body_en: "Test sentence.", body_ja: "テスト文。" }
      ]
    }.to_json

    call_count = 0
    mock = ->() {
      call_count += 1
      if call_count == 1
        [ "", "Error: Expected ',' or '}' after property value in JSON at position 136", fail_status ]
      else
        [ valid_output, "", ok_status ]
      end
    }

    result = nil
    stub_run_with_timeout(mock) do
      result = News::ArticleSummarizer.call(title: "Test", article_text: "Test text")
    end

    assert_equal 2, call_count, "Expected 1 failed attempt + 1 successful retry"
    assert_equal "Test Title", result[:title_en]
  end

  test "raises after exhausting retries on script failure with JSON error in stderr" do
    fail_status = Data.define(:success?, :exitstatus).new("success?": false, exitstatus: 1)

    call_count = 0
    mock = ->() {
      call_count += 1
      [ "", "Error: Unexpected end of JSON input", fail_status ]
    }

    stub_run_with_timeout(mock) do
      error = assert_raises(RuntimeError) do
        News::ArticleSummarizer.call(title: "Test", article_text: "Test text")
      end
      assert_match(/Script failed/, error.message)
      assert_match(/JSON/, error.message)
    end

    assert_equal 3, call_count, "Expected 1 initial attempt + 2 retries = 3 total calls"
  end

  test "strips all problematic quotation marks from title and article text" do
    mock_output = {
      title_en: "NATO Ambassadors Visit Japan",
      title_ja: "NATO加盟の30か国の大使らが来日 異例の規模の訪問団",
      sentences: [
        { body_en: "Ambassadors from 30 NATO countries arrived in Japan.", body_ja: "NATO加盟30か国の大使らが来日しました。" }
      ]
    }.to_json

    mock_status = Data.define(:success?, :exitstatus).new("success?": true, exitstatus: 0)

    captured_args = nil
    captured_stdin = nil
    mock_new = ->(script_path:, env:, args:, stdin_data:) {
      captured_args = args
      captured_stdin = stdin_data
      runner = News::CopilotScriptRunner.allocate
      runner.instance_variable_set(:@script_path, script_path)
      runner.instance_variable_set(:@env, env)
      runner.instance_variable_set(:@args, args)
      runner.instance_variable_set(:@stdin_data, stdin_data)
      runner.define_singleton_method(:run) { JSON.parse(mock_output) }
      runner
    }

    News::CopilotScriptRunner.stub :new, mock_new do
      News::ArticleSummarizer.call(
        title: "NATO加盟の30か国の大使らが来日 \u201C異例の規模\u201Dの訪問団",
        article_text: "\u201Cａ\u201Dｂ\u301Dｃ\u301Eｄ\uFF02ｅ"
      )
    end

    captured_title = captured_args.last
    refute_match(/[\u201C\u201D\u301D\u301E\uFF02]/, captured_title,
      "All problematic quotes should be stripped from title")
    refute_match(/[\u201C\u201D\u301D\u301E\uFF02]/, captured_stdin,
      "All problematic quotes should be stripped from article text")
    assert_equal "NATO加盟の30か国の大使らが来日 異例の規模の訪問団", captured_title
    assert_equal "ａｂｃｄｅ", captured_stdin
  end

  test "does not retry on non-JSON errors" do
    mock_status = Data.define(:success?, :exitstatus).new("success?": false, exitstatus: 1)

    call_count = 0
    mock = ->() {
      call_count += 1
      [ "", "Something went wrong", mock_status ]
    }

    stub_run_with_timeout(mock) do
      assert_raises(RuntimeError) do
        News::ArticleSummarizer.call(title: "Test", article_text: "Test text")
      end
    end

    assert_equal 1, call_count, "Should not retry on non-JSON errors"
  end

  private

  def stub_run_with_timeout(response_or_callable)
    original_new = News::CopilotScriptRunner.method(:new)

    mock_new = ->(**kwargs) {
      runner = original_new.call(**kwargs)
      runner.define_singleton_method(:run_with_timeout) do
        if response_or_callable.respond_to?(:call)
          response_or_callable.call
        else
          response_or_callable
        end
      end
      runner
    }

    News::CopilotScriptRunner.stub :new, mock_new do
      yield
    end
  end
end
