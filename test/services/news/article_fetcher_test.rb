# frozen_string_literal: true

require "test_helper"
require "net/http"
require "minitest/mock"

class News::ArticleFetcherTest < ActiveSupport::TestCase
  test "extracts article text from HTML, stripping non-content elements" do
    html = file_fixture("nhk_article.html").read
    mock_response = mock_http_success(html)

    text = nil
    stub_http_start(mock_response) do
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
    stub_http_start(mock_response) do
      text = News::ArticleFetcher.call("https://example.com/empty.html")
    end

    assert_equal "", text
  end

  test "correctly transcodes Shift_JIS body when charset is in Content-Type header" do
    sjis_body = file_fixture("itmedia_article_sjis.html").binread
    mock_response = mock_http_success(sjis_body, content_type: "text/html; charset=Shift_JIS")

    text = nil
    stub_http_start(mock_response) do
      text = News::ArticleFetcher.call("https://example.com/itmedia.html")
    end

    assert text.encoding == Encoding::UTF_8
    assert text.valid_encoding?
    assert_includes text, "ITmediaのテスト記事です"
    assert_includes text, "テスト記事タイトル"
  end

  test "detects encoding from meta tag when Content-Type has no charset" do
    sjis_body = file_fixture("itmedia_article_sjis.html").binread
    mock_response = mock_http_success(sjis_body, content_type: "text/html")

    text = nil
    stub_http_start(mock_response) do
      text = News::ArticleFetcher.call("https://example.com/itmedia.html")
    end

    assert text.encoding == Encoding::UTF_8
    assert text.valid_encoding?
    assert_includes text, "ITmediaのテスト記事です"
  end

  test "replaces invalid bytes instead of raising" do
    # Create a body with invalid UTF-8 bytes mixed in (use +string to make it mutable with frozen_string_literal: true)
    bad_body = +"<!DOCTYPE html><html><body><article><p>Hello \xFF\xFE World</p></article></body></html>"
    bad_body.force_encoding("ASCII-8BIT")
    mock_response = mock_http_success(bad_body, content_type: "text/html; charset=UTF-8")

    text = nil
    stub_http_start(mock_response) do
      text = News::ArticleFetcher.call("https://example.com/bad.html")
    end

    assert text.encoding == Encoding::UTF_8
    assert text.valid_encoding?
    assert_includes text, "Hello"
    assert_includes text, "World"
  end

  test "falls back gracefully when Content-Type has unrecognized charset" do
    html = "<html><body><article><p>Some content here</p></article></body></html>"
    mock_response = mock_http_success(html, content_type: "text/html; charset=unicode-1-1-utf-8")

    text = nil
    stub_http_start(mock_response) do
      text = News::ArticleFetcher.call("https://example.com/weird-charset.html")
    end

    assert text.encoding == Encoding::UTF_8
    assert text.valid_encoding?
    assert_includes text, "Some content here"
  end

  private

  def mock_http_success(body, content_type: "text/html; charset=UTF-8")
    response = Net::HTTPSuccess.allocate
    response.instance_variable_set(:@body, body)
    response.instance_variable_set(:@read, true)
    response.instance_variable_set(:@header, { "content-type" => [ content_type ] })
    response
  end

  def stub_http_start(response, &block)
    mock_http = ->(*, **) { response }
    Net::HTTP.stub :start, mock_http, &block
  end
end
