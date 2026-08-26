# frozen_string_literal: true

class ActiveChallengesController < ApplicationController
  before_action :require_login

  def update
    challenge = current_user.challenges.find_by(id: params[:challenge_id])

    if challenge
      set_active_challenge(challenge)
      flash[:notice] = "Active challenge set to #{challenge.name}."
    else
      flash[:alert] = "Could not switch challenge."
    end

    @challenge = challenge
    @my_challenges = current_user.challenges.active.order(start_date: :asc) if logged_in?

    destination = resolve_destination(params[:redirect_to].presence, challenge)

    respond_to do |format|
      # If redirect_to explicitly requested root_path or a turbo_stream without page reload
      format.turbo_stream do
        if params[:redirect_to].blank? || params[:redirect_to] == "/" || params[:redirect_to] == root_path
          render :update
        else
          # On challenge-specific pages, redirect to the new challenge's page
          redirect_to destination
        end
      end
      format.html do
        redirect_to destination
      end
    end
  end

  private

  def resolve_destination(destination, new_challenge)
    return reading_path if destination.blank? || !destination.start_with?("/") || destination.start_with?("//")

    # 1. Groups (/groups, /groups/123, /challenges/123/groups) -> /groups
    if destination =~ %r{\A/groups(/\d+)?} || destination =~ %r{\A/challenges/\d+/groups}
      return groups_path
    end

    # 2. Reading (/reading) -> /reading
    if destination =~ %r{\A/reading}
      return reading_path
    end

    # 3. Stats (/stats, /challenges/123/stats) -> /stats
    if destination =~ %r{\A/stats} || destination =~ %r{\A/challenges/\d+/stats}
      return "/stats"
    end

    # 4. Catch-up (/catch_up, /challenges/123/catch_up) -> /catch_up
    if destination =~ %r{\A/catch_up} || destination =~ %r{\A/challenges/\d+/catch_up}
      return catch_up_path
    end

    # 5. Posts / Blog (/posts, /blog, /challenges/123/blog_posts) -> /posts
    if destination =~ %r{\A/(posts|blog)} || destination =~ %r{\A/challenges/\d+/blog_posts}
      return posts_path
    end

    # 6. 7-Day Win / Weekly Winner (/seven_day_win, /challenges/123/seven_day_win) -> /seven_day_win
    if destination =~ %r{\A/seven_day_win} || destination =~ %r{\A/challenges/\d+/seven_day_win}
      return seven_day_win_path
    end

    # 7. Challenge Management (/challenges/123/manage/...)
    if destination =~ %r{\A/challenges/\d+/manage(/.*)?}
      subpath = $1 || ""
      if new_challenge && new_challenge.manageable_by?(current_user)
        return "/challenges/#{new_challenge.id}/manage#{subpath}"
      elsif current_user.directly_managed_challenges.any?
        return manage_chooser_path
      else
        return reading_path
      end
    end

    # 8. Specific Challenge Detail Page (/challenges/123)
    if destination =~ %r{\A/challenges/\d+\z}
      return challenge_path(new_challenge) if new_challenge
    end

    # 9. Generic Pages (/, /account, /challenges/hub, etc.)
    destination
  end
end
