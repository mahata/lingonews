require "test_helper"

class Api::ArticlesControllerTest < ActionDispatch::IntegrationTest
  test "index returns all articles as JSON" do
    get "/api/articles"
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal Article.count, json.size
    assert json.first.key?("title_en")
    assert json.first.key?("title_ja")
    assert json.first.key?("published_at")
  end

  test "index returns articles ordered by published_at desc" do
    get "/api/articles"
    json = JSON.parse(response.body)
    dates = json.map { |a| a["published_at"] }
    assert_equal dates.sort.reverse, dates
  end

  test "show returns article with nested sentences" do
    article = articles(:bullet_train)
    get "/api/articles/#{article.id}"
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal article.title_en, json["title_en"]
    assert_equal article.title_ja, json["title_ja"]
    assert json.key?("sentences")
    assert_equal article.sentences.count, json["sentences"].size

    first_sentence = json["sentences"].first
    assert first_sentence.key?("body_en")
    assert first_sentence.key?("body_ja")
    assert first_sentence.key?("position")
  end

  test "show returns 404 for nonexistent article" do
    get "/api/articles/99999"
    assert_response :not_found
  end
end
