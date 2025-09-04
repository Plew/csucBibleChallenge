class FeedbacksController < ApplicationController
  def new
    @feedback = Feedback.new
  end

  def create
    @feedback = Feedback.new(feedback_params)
    @feedback.user = current_user if logged_in?

    if @feedback.save
      redirect_to feedback_path(@feedback), notice: 'Thank you for your feedback! We appreciate you taking the time to help improve our app.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    @feedback = Feedback.find(params[:id])
    
    # Allow users to view their own feedback or admin to view any
    unless can_view_feedback?(@feedback)
      redirect_to root_path, alert: 'Access denied.'
    end
  end

  private

  def feedback_params
    params.require(:feedback).permit(:category, :subject, :message, :screenshot)
  end

  def can_view_feedback?(feedback)
    return true if current_user&.admin?
    return true if feedback.user == current_user
    return true if feedback.anonymous?
    false
  end
end