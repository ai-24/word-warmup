# frozen_string_literal: true

class Tagging < ApplicationRecord
  belongs_to :expression
  belongs_to :tag
end
