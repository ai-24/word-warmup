# frozen_string_literal: true

class Memorising < ApplicationRecord
  belongs_to :user
  belongs_to :expression

  validates :user_id, uniqueness: { scope: :expression_id }
end
