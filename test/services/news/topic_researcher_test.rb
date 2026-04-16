# frozen_string_literal: true

require "test_helper"

class News::TopicResearcherTest < ActiveSupport::TestCase
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

  test "calls script and parses research context" do
    mock_output = { research_context: "Additional background on the topic found via web research." }.to_json
    mock_status = Data.define(:success?, :exitstatus).new("success?": true, exitstatus: 0)

    stub_run_with_timeout([ mock_output, "", mock_status ]) do
      result = News::TopicResearcher.call(
        title: "東京で桜が満開",
        article_text: "東京都内の桜が14日、満開を迎えました。"
      )

      assert_equal "Additional background on the topic found via web research.", result
    end
  end

  test "raises error when script fails" do
    mock_status = Data.define(:success?, :exitstatus).new("success?": false, exitstatus: 1)

    stub_run_with_timeout([ "", "Something went wrong", mock_status ]) do
      error = assert_raises(RuntimeError) do
        News::TopicResearcher.call(title: "Test", article_text: "Test text")
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
        News::TopicResearcher.call(title: "Test", article_text: "Test text")
      end
    end

    assert_equal 3, call_count, "Expected 1 initial attempt + 2 retries = 3 total calls"
  end

  test "retries on JSON parse error and succeeds on subsequent attempt" do
    mock_status = Data.define(:success?, :exitstatus).new("success?": true, exitstatus: 0)

    valid_output = { research_context: "Some research findings." }.to_json

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
      result = News::TopicResearcher.call(title: "Test", article_text: "Test text")
    end

    assert_equal 2, call_count, "Expected 1 failed attempt + 1 successful retry"
    assert_equal "Some research findings.", result
  end

  test "raises error when research_context is missing" do
    mock_output = { other_field: "no research_context here" }.to_json
    mock_status = Data.define(:success?, :exitstatus).new("success?": true, exitstatus: 0)

    stub_run_with_timeout([ mock_output, "", mock_status ]) do
      error = assert_raises(RuntimeError) do
        News::TopicResearcher.call(title: "Test", article_text: "Test text")
      end
      assert_match(/missing or empty research_context/, error.message)
    end
  end

  test "strips problematic quotation marks from title and article text" do
    mock_output = { research_context: "Research findings." }.to_json
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
      News::TopicResearcher.call(
        title: "\u201C異例の規模\u201Dの訪問団",
        article_text: "\u201Cａ\u201Dｂ\u301Dｃ\u301Eｄ\uFF02ｅ"
      )
    end

    captured_title = captured_args.last
    refute_match(/[\u201C\u201D\u301D\u301E\uFF02]/, captured_title)
    refute_match(/[\u201C\u201D\u301D\u301E\uFF02]/, captured_stdin)
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
        News::TopicResearcher.call(title: "Test", article_text: "Test text")
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
