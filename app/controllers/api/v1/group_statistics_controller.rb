module Api
  module V1
    class GroupStatisticsController < ApplicationController
      # Skip CSRF token verification for API endpoints
      skip_before_action :verify_authenticity_token
      before_action :set_group

      private

      def set_group
        @group = current_user.groups.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Group not found' }, status: :not_found
      end
    end
  end
end 