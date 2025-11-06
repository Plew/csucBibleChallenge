module Api
  module V1
    class GroupStatisticsController < ApplicationController
      # Skip CSRF token verification for API endpoints
      # skip_before_action :verify_authenticity_token
      before_action :set_group

      def pie_data
        day = params[:day].presence || Date.current
        pie_data = PieDataFromGroupDay.new(@group, day).pie_chart_data

        render json: { data: pie_data }
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_content
      end

      private

      def set_group
        @group = current_user.groups.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Group not found" }, status: :not_found
      end
    end
  end
end
