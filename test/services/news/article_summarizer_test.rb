# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class News::ArticleSummarizerTest < ActiveSupport::TestCase
  setup do
    ENV["GITHUB_TOKEN"] = "test-token"
  end

  teardown do
    ENV.delete("GITHUB_TOKEN")
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

    Open3.stub :capture3, [ mock_output, "", mock_status ] do
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

  test "raises error when script fails" do
    mock_status = Data.define(:success?, :exitstatus).new("success?": false, exitstatus: 1)

    Open3.stub :capture3, [ "", "Something went wrong", mock_status ] do
      error = assert_raises(RuntimeError) do
        News::ArticleSummarizer.call(title: "Test", article_text: "Test text")
      end
      assert_match(/Summarizer script failed/, error.message)
    end
  end

  test "raises error for invalid JSON output" do
    mock_status = Data.define(:success?, :exitstatus).new("success?": true, exitstatus: 0)

    Open3.stub :capture3, [ "not json", "", mock_status ] do
      assert_raises(JSON::ParserError) do
        News::ArticleSummarizer.call(title: "Test", article_text: "Test text")
      end
    end
  end
end
