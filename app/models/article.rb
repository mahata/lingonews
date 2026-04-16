class Article < ApplicationRecord
  has_many :sentences, -> { order(:position) }, dependent: :destroy

  validates :title_en, presence: true
  validates :title_ja, presence: true
  validates :published_at, presence: true
  validates :source_url, format: { with: /\Ahttps?:\/\//i, message: "must be an HTTP or HTTPS URL" }, allow_blank: true
end
