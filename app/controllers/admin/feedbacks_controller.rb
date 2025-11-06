class Admin::FeedbacksController < ApplicationController
  before_action :require_login
  before_action :require_admin
  before_action :set_feedback, only: [ :show, :destroy ]

  def index
    @feedbacks = Feedback.includes(:user)
                        .by_category(params[:category])
                        .recent

    if params[:search].present?
      @feedbacks = @feedbacks.where(
        "subject ILIKE ? OR message ILIKE ?",
        "%#{params[:search]}%",
        "%#{params[:search]}%"
      )
    end

    @feedbacks = @feedbacks.limit(50)
    @categories = Feedback.categories.keys
  end

  def show
    # @feedback is set by before_action
  end

  def destroy
    @feedback.destroy
    redirect_to admin_feedbacks_path, notice: "Feedback has been deleted."
  end

  private

  def set_feedback
    @feedback = Feedback.find(params[:id])
  end

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user&.admin?
  end
end
