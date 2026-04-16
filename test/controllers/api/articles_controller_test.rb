require "test_helper"

class Api::ArticlesControllerTest < ActionDispatch::IntegrationTest
  test "index returns paginated articles as JSON" do
    get "/api/articles"
    assert_response :success

    json = JSON.parse(response.body)
    assert json.key?("articles")
    assert json.key?("page")
    assert json.key?("total_pages")
    assert json.key?("total_count")
    assert_equal 1, json["page"]
    assert_equal Article.count, json["total_count"]
    assert json["articles"].first.key?("title_en")
    assert json["articles"].first.key?("title_ja")
    assert json["articles"].first.key?("published_at")
  end

  test "index returns articles ordered by published_at desc" do
    get "/api/articles"
    json = JSON.parse(response.body)
    dates = json["articles"].map { |a| a["published_at"] }
    assert_equal dates.sort.reverse, dates
  end

  test "index respects page parameter and returns at most PER_PAGE articles" do
    get "/api/articles", params: { page: 1 }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json["page"]
    assert json["articles"].size <= Api::ArticlesController::PER_PAGE
  end

  test "index clamps page to minimum of 1" do
    get "/api/articles", params: { page: -5 }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json["page"]
  end

  test "index clamps page to maximum of total_pages" do
    get "/api/articles", params: { page: 999 }
    assert_response :success

    json = JSON.parse(response.body)
    expected_max = [ (Article.count.to_f / Api::ArticlesController::PER_PAGE).ceil, 1 ].max
    assert_equal expected_max, json["page"]
  end

  test "index returns correct total_pages" do
    expected_pages = (Article.count.to_f / Api::ArticlesController::PER_PAGE).ceil
    get "/api/articles"
    json = JSON.parse(response.body)
    assert_equal expected_pages, json["total_pages"]
  end

  test "show returns article with nested sentences" do
    article = articles(:bullet_train)
    get "/api/articles/#{article.id}"
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal article.title_en, json["title_en"]
    assert_equal article.title_ja, json["title_ja"]
    assert_equal article.source_url, json["source_url"]
    assert_equal article.source, json["source"]
    assert_equal article.source_title, json["source_title"]
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
