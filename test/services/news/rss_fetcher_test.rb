# frozen_string_literal: true

require "test_helper"
require "net/http"
require "minitest/mock"

class News::RssFetcherTest < ActiveSupport::TestCase
  setup do
    @feed_xml = file_fixture("nhk_rss_feed.xml").read
    @rdf_xml = file_fixture("rdf_feed.xml").read
  end

  test "parses RSS 2.0 feed and returns items" do
    mock_response = mock_http_success(@feed_xml)

    stub_http_start(mock_response) do
      items = News::RssFetcher.call(feed_url: "https://example.com/rss.xml")

      assert_equal 2, items.size
      assert_equal "東京で桜が満開 今年は例年より早い開花", items[0][:title]
      assert_equal "https://www3.nhk.or.jp/news/html/20260414/k10014001.html", items[0][:url]
      assert_not_nil items[0][:published_at]
    end
  end

  test "parses RSS 1.0/RDF feed and returns items with dc:date" do
    mock_response = mock_http_success(@rdf_xml)

    stub_http_start(mock_response) do
      items = News::RssFetcher.call(feed_url: "https://example.com/feed.rdf")

      assert_equal 2, items.size
      assert_equal "新型プロセッサが発表される", items[0][:title]
      assert_equal "https://pc.watch.impress.co.jp/docs/news/1001.html", items[0][:url]
      assert_not_nil items[0][:published_at]
    end
  end

  test "filters out articles with existing source_url" do
    Article.create!(
      title_en: "Existing",
      title_ja: "既存",
      published_at: Time.current,
      source_url: "https://www3.nhk.or.jp/news/html/20260414/k10014001.html"
    )

    mock_response = mock_http_success(@feed_xml)

    stub_http_start(mock_response) do
      items = News::RssFetcher.call(feed_url: "https://example.com/rss.xml")

      assert_equal 1, items.size
      assert_equal "https://www3.nhk.or.jp/news/html/20260414/k10014002.html", items[0][:url]
    end
  end

  private

  def mock_http_success(body)
    response = Net::HTTPSuccess.allocate
    response.instance_variable_set(:@body, body)
    response.instance_variable_set(:@read, true)
    response
  end

  def stub_http_start(response, &block)
    mock_http = ->(*, **) { response }
    Net::HTTP.stub :start, mock_http, &block
  end
end
