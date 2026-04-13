class Sentence < ApplicationRecord
  belongs_to :article

  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :body_en, presence: true
  validates :body_ja, presence: true
end
