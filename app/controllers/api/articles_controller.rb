module Api
  class ArticlesController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :not_found

    def index
      articles = Article.order(published_at: :desc)
      render json: articles.as_json(only: [:id, :title_en, :title_ja, :published_at])
    end

    def show
      article = Article.includes(:sentences).find(params[:id])
      render json: article.as_json(
        only: [:id, :title_en, :title_ja, :published_at],
        include: {
          sentences: {
            only: [:id, :position, :body_en, :body_ja]
          }
        }
      )
    end

    private

    def not_found
      render json: { error: "Not found" }, status: :not_found
    end
  end
end
