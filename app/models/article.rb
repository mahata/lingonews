class Article < ApplicationRecord
  has_many :sentences, -> { order(:position) }, dependent: :destroy

  validates :title_en, presence: true
  validates :title_ja, presence: true
  validates :published_at, presence: true
end
