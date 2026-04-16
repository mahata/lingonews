module Api
  class ArticlesController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :not_found

    PER_PAGE = 20

    def index
      requested_page = [ params.fetch(:page, 1).to_i, 1 ].max
      total_count = Article.count
      total_pages = (total_count.to_f / PER_PAGE).ceil
      page = [ requested_page, [ total_pages, 1 ].max ].min
      articles = Article.order(published_at: :desc).offset((page - 1) * PER_PAGE).limit(PER_PAGE)

      render json: {
        articles: articles.as_json(only: [ :id, :title_en, :title_ja, :published_at ]),
        page: page,
        total_pages: total_pages,
        total_count: total_count
      }
    end

    def show
      article = Article.includes(:sentences).find(params[:id])
      render json: article.as_json(
        only: [ :id, :title_en, :title_ja, :published_at, :source_url, :source, :source_title ],
        include: {
          sentences: {
            only: [ :id, :position, :body_en, :body_ja ]
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
