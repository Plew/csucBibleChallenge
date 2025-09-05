class PasswordResetsController < ApplicationController
  def new
  end

  def create
    @user = User.find_by(email: params[:email].downcase)
    if @user
      token = @user.create_reset_digest
      UserMailer.password_reset(@user, token).deliver_now
      flash[:info] = "Email sent with password reset instructions"
      redirect_to new_user_session_path
    else
      flash.now[:danger] = "Email address not found"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = User.find_by(reset_digest: params[:token])
    unless @user&.password_reset_valid?
      flash[:danger] = "Password reset link is invalid or has expired"
      redirect_to new_password_reset_path
    end
  end

  def update
    @user = User.find_by(reset_digest: params[:token])
    
    unless @user&.password_reset_valid?
      flash[:danger] = "Password reset link is invalid or has expired"
      redirect_to new_password_reset_path
      return
    end

    if params[:user][:password].present?
      @user.skip_current_password_validation = true
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
      @user.reset_digest = nil
      @user.password_reset_sent_at = nil
      
      if @user.save
        log_in @user
        flash[:success] = "Password has been reset successfully. You are now logged in."
        redirect_to root_path
      else
        render :edit, status: :unprocessable_entity
      end
    else
      @user.errors.add(:password, "can't be blank")
      render :edit, status: :unprocessable_entity
    end
  end
end