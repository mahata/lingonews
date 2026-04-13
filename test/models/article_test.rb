require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  test "has many sentences ordered by position" do
    article = articles(:bullet_train)
    assert_equal 2, article.sentences.count
    assert_equal 1, article.sentences.first.position
    assert_equal 2, article.sentences.last.position
  end

  test "validates presence of required fields" do
    article = Article.new
    assert_not article.valid?
    assert_includes article.errors[:title_en], "can't be blank"
    assert_includes article.errors[:title_ja], "can't be blank"
    assert_includes article.errors[:published_at], "can't be blank"
  end

  test "destroying article destroys associated sentences" do
    article = articles(:bullet_train)
    sentence_count = article.sentences.count
    assert_difference("Sentence.count", -sentence_count) do
      article.destroy
    end
  end
end
