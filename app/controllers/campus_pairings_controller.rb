require "uri"

class CampusPairingsController < ApplicationController
  before_action :authenticate_user! # Must be logged into andgodsaid

  # GET /campus/pair
  def new
    @campus_name = params[:campus_name]
    @hub_url = params[:hub_url]
    @secret = params[:secret]
    @nonce = params[:nonce]
    @callback_url = params[:callback_url]
    @challenges = current_user.challenges # Challenges this leader manages/joined
    @existing_connection = CampusConnection.find_by(hub_url: @hub_url&.strip&.sub(%r{/+\z}, ""))
  end

  # POST /campus/pair
  def create
    normalized_url = params[:hub_url].to_s.strip.sub(%r{/+\z}, "")
    connection = CampusConnection.find_or_initialize_by(hub_url: normalized_url)
    connection.update!(
      user: current_user,
      campus_name: params[:campus_name],
      sso_secret: params[:secret],
      challenge_id: params[:challenge_id].presence
    )

    challenge = connection.challenge
    redirect_url = URI.parse(params[:callback_url])
    query = URI.decode_www_form(redirect_url.query || "")
    query << [ "status", "success" ]
    query << [ "challenge_id", challenge&.id.to_s ]
    query << [ "challenge_name", challenge&.name.to_s ]
    query << [ "nonce", params[:nonce].to_s ]
    redirect_url.query = URI.encode_www_form(query)

    redirect_to redirect_url.to_s, allow_other_host: true
  end
end
