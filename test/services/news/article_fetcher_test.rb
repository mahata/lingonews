# frozen_string_literal: true

require "test_helper"
require "net/http"
require "minitest/mock"

class News::ArticleFetcherTest < ActiveSupport::TestCase
  test "extracts article text from HTML, stripping non-content elements" do
    html = file_fixture("nhk_article.html").read
    mock_response = mock_http_success(html)

    text = nil
    Net::HTTP.stub :get_response, mock_response do
      text = News::ArticleFetcher.call("https://example.com/article.html")
    end

    # Should contain article content
    assert_includes text, "東京都内の桜が14日"
    assert_includes text, "地球温暖化の影響"

    # Should NOT contain script/style content
    refute_includes text, "tracking"
  end

  test "returns empty string when no content found" do
    html = "<html><body></body></html>"
    mock_response = mock_http_success(html)

    text = nil
    Net::HTTP.stub :get_response, mock_response do
      text = News::ArticleFetcher.call("https://example.com/empty.html")
    end

    assert_equal "", text
  end

  private

  def mock_http_success(body)
    response = Net::HTTPSuccess.allocate
    response.instance_variable_set(:@body, body)
    response.instance_variable_set(:@read, true)
    response
  end
end
