# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class News::UpdaterTest < ActiveSupport::TestCase
  test "creates articles and sentences from RSS feed" do
    rss_items = [
      {
        title: "東京で桜が満開",
        url: "https://example.com/sakura",
        published_at: Time.zone.parse("2026-04-14 09:00:00 +0900")
      }
    ]

    article_text = "東京都内の桜が14日、満開を迎えました。"

    summary = {
      title_en: "Cherry Blossoms in Full Bloom in Tokyo",
      title_ja: "東京で桜が満開",
      sentences: [
        { body_en: "Cherry blossoms reached full bloom.", body_ja: "桜が満開を迎えました。" },
        { body_en: "Blooming came early this year.", body_ja: "今年の開花は早いです。" }
      ]
    }

    News::RssFetcher.stub :call, rss_items do
      News::ArticleFetcher.stub :call, article_text do
        News::ArticleSummarizer.stub :call, summary do
          assert_difference "Article.count", 1 do
            assert_difference "Sentence.count", 2 do
              News::Updater.call
            end
          end
        end
      end
    end

    article = Article.find_by(source_url: "https://example.com/sakura")
    assert_not_nil article
    assert_equal "Cherry Blossoms in Full Bloom in Tokyo", article.title_en
    assert_equal "東京で桜が満開", article.title_ja
    assert_equal 2, article.sentences.count
    assert_equal "Cherry blossoms reached full bloom.", article.sentences.first.body_en
  end

  test "skips articles when article text is empty" do
    rss_items = [
      { title: "Empty article", url: "https://example.com/empty", published_at: Time.current }
    ]

    News::RssFetcher.stub :call, rss_items do
      News::ArticleFetcher.stub :call, "" do
        assert_no_difference "Article.count" do
          News::Updater.call
        end
      end
    end
  end

  test "continues processing remaining articles and raises summary error when one fails" do
    rss_items = [
      { title: "Failing article", url: "https://example.com/fail", published_at: Time.current },
      { title: "Working article", url: "https://example.com/ok", published_at: Time.current }
    ]

    call_count = 0
    article_fetcher = ->(_url) {
      call_count += 1
      if call_count == 1
        raise "Network error"
      else
        "Some article text"
      end
    }

    summary = {
      title_en: "Working Article",
      title_ja: "動作する記事",
      sentences: [
        { body_en: "This works.", body_ja: "これは動きます。" }
      ]
    }

    News::RssFetcher.stub :call, rss_items do
      News::ArticleFetcher.stub :call, article_fetcher do
        News::ArticleSummarizer.stub :call, summary do
          initial_count = Article.count
          error = assert_raises(RuntimeError) do
            News::Updater.call
          end
          assert_match(/1 article\(s\) failed/, error.message)
          assert_equal initial_count + 1, Article.count
        end
      end
    end
  end
end
