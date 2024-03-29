# frozen_string_literal: true

class API::MemorisingsController < API::BaseController
  def index
    @memorisings = current_user.memorisings.order(:created_at, :id)
  end

  def create
    if logged_in?
      result = Memorising.create_bookmarkings_or_memorisings!(current_user.id, memorising_params[:expression_id])

      if result == 'failure'
        head :unprocessable_entity
      elsif result
        head :no_content
      else
        head :created
      end
    else
      head :unauthorized
    end
  end

  private

  def memorising_params
    params.require(:memorising).permit(expression_id: [])
  end
end
