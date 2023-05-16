# frozen_string_literal: true

class BookmarkedExpressionsController < ApplicationController
  def index
    @bookmarkings = current_user.bookmarkings if logged_in?
    store_list
  end
end
