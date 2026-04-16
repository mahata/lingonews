# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class News::UpdaterTest < ActiveSupport::TestCase
  setup do
    @test_source = News::Sources::Source.new(name: "Test Source", url: "https://example.com/rss.xml")
  end

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
        News::TopicResearcher.stub :call, "Research context from the web." do
          News::ArticleSummarizer.stub :call, summary do
            assert_difference "Article.count", 1 do
              assert_difference "Sentence.count", 2 do
                News::Updater.call(sources: [ @test_source ])
              end
            end
          end
        end
      end
    end

    article = Article.find_by(source_url: "https://example.com/sakura")
    assert_not_nil article
    assert_equal "Cherry Blossoms in Full Bloom in Tokyo", article.title_en
    assert_equal "東京で桜が満開", article.title_ja
    assert_equal "Test Source", article.source
    assert_equal "東京で桜が満開", article.source_title
    assert_equal 2, article.sentences.count
    assert_equal "Cherry blossoms reached full bloom.", article.sentences.first.body_en
  end

  test "skips articles when article text is empty" do
    rss_items = [
      { title: "Empty article", url: "https://example.com/empty", published_at: Time.current }
    ]

    News::RssFetcher.stub :call, rss_items do
      News::ArticleFetcher.stub :call, "" do
        News::TopicResearcher.stub :call, "Research." do
          assert_no_difference "Article.count" do
            News::Updater.call(sources: [ @test_source ])
          end
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
        News::TopicResearcher.stub :call, "Research." do
          News::ArticleSummarizer.stub :call, summary do
            initial_count = Article.count
            error = assert_raises(RuntimeError) do
              News::Updater.call(sources: [ @test_source ])
            end
            assert_match(/1 article\(s\) failed/, error.message)
            assert_equal initial_count + 1, Article.count
          end
        end
      end
    end
  end

  test "processes multiple sources" do
    source_a = News::Sources::Source.new(name: "Source A", url: "https://example.com/a.xml")
    source_b = News::Sources::Source.new(name: "Source B", url: "https://example.com/b.xml")

    items_a = [ { title: "Article A", url: "https://example.com/a1", published_at: Time.current } ]
    items_b = [ { title: "Article B", url: "https://example.com/b1", published_at: Time.current } ]

    fetcher_calls = []
    rss_fetcher = ->(feed_url:) {
      fetcher_calls << feed_url
      feed_url.include?("/a.xml") ? items_a : items_b
    }

    summary = {
      title_en: "Summary",
      title_ja: "要約",
      sentences: [ { body_en: "Text.", body_ja: "テキスト。" } ]
    }

    News::RssFetcher.stub :call, rss_fetcher do
      News::ArticleFetcher.stub :call, "Some text" do
        News::TopicResearcher.stub :call, "Research." do
          News::ArticleSummarizer.stub :call, summary do
            assert_difference "Article.count", 2 do
              News::Updater.call(sources: [ source_a, source_b ])
            end
          end
        end
      end
    end

    assert_includes fetcher_calls, "https://example.com/a.xml"
    assert_includes fetcher_calls, "https://example.com/b.xml"

    article_a = Article.find_by(source_url: "https://example.com/a1")
    article_b = Article.find_by(source_url: "https://example.com/b1")
    assert_equal "Source A", article_a.source
    assert_equal "Source B", article_b.source
  end

  test "processes articles concurrently" do
    items = 6.times.map do |i|
      { title: "Article #{i}", url: "https://example.com/art#{i}", published_at: Time.current }
    end

    mutex = Mutex.new
    thread_ids = Set.new
    arrived = Queue.new
    gate = Queue.new

    article_fetcher = ->(_url) {
      mutex.synchronize { thread_ids << Thread.current.object_id }
      arrived << true
      gate.pop
      "Some text"
    }

    summary = {
      title_en: "Summary",
      title_ja: "要約",
      sentences: [ { body_en: "Text.", body_ja: "テキスト。" } ]
    }

    release_thread = Thread.new do
      News::Updater::MAX_CONCURRENCY.times { arrived.pop }
      items.size.times { gate << true }
    end

    News::RssFetcher.stub :call, items do
      News::ArticleFetcher.stub :call, article_fetcher do
        News::TopicResearcher.stub :call, "Research." do
          News::ArticleSummarizer.stub :call, summary do
            assert_difference "Article.count", 6 do
              News::Updater.call(sources: [ @test_source ])
            end
          end
        end
      end
    end

    release_thread.join(5)

    assert_operator thread_ids.size, :>, 1, "Expected multiple threads to be used"
  end

  test "falls back to no research context when TopicResearcher fails" do
    rss_items = [
      { title: "Test article", url: "https://example.com/test", published_at: Time.current }
    ]

    summary = {
      title_en: "Test Article",
      title_ja: "テスト記事",
      sentences: [
        { body_en: "This is a test.", body_ja: "これはテストです。" }
      ]
    }

    researcher_stub = ->(**_kwargs) { raise "Web search unavailable" }

    captured_research_context = nil
    summarizer_stub = ->(title:, article_text:, research_context: nil) {
      captured_research_context = research_context
      summary
    }

    News::RssFetcher.stub :call, rss_items do
      News::ArticleFetcher.stub :call, "Some article text" do
        News::TopicResearcher.stub :call, researcher_stub do
          News::ArticleSummarizer.stub :call, summarizer_stub do
            assert_difference "Article.count", 1 do
              News::Updater.call(sources: [ @test_source ])
            end
          end
        end
      end
    end

    assert_nil captured_research_context, "Research context should be nil when researcher fails"
    assert_not_nil Article.find_by(source_url: "https://example.com/test")
  end
end
