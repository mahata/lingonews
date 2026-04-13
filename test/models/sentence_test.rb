require "test_helper"

class SentenceTest < ActiveSupport::TestCase
  test "belongs to article" do
    sentence = sentences(:first_sentence)
    assert_equal articles(:bullet_train), sentence.article
  end

  test "validates presence of required fields" do
    sentence = Sentence.new
    assert_not sentence.valid?
    assert_includes sentence.errors[:body_en], "can't be blank"
    assert_includes sentence.errors[:body_ja], "can't be blank"
    assert_includes sentence.errors[:position], "can't be blank"
  end

  test "validates position is a positive integer" do
    sentence = sentences(:first_sentence)
    sentence.position = -1
    assert_not sentence.valid?

    sentence.position = 0
    assert_not sentence.valid?

    sentence.position = 1
    assert sentence.valid?
  end
end
