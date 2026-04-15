# frozen_string_literal: true

require "test_helper"

class News::SourcesTest < ActiveSupport::TestCase
  test "loads sources from config file" do
    sources = News::Sources.all

    assert_kind_of Array, sources
    assert_not_empty sources

    nhk = sources.find { |s| s.name == "NHK News" }
    assert_not_nil nhk
    assert_equal "https://www.nhk.or.jp/rss/news/cat0.xml", nhk.url

    itmedia = sources.find { |s| s.name == "ITmedia" }
    assert_not_nil itmedia
    assert_equal "https://rss.itmedia.co.jp/rss/2.0/itmedia_all.xml", itmedia.url
  end

  test "sources are frozen" do
    sources = News::Sources.all
    assert sources.frozen?
  end
end
