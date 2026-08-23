# Self-description for the read-only challenge API. Returned by
# Api::V1::MetaController so that integrations (e.g. a Claude skill) can
# discover the endpoints, field meanings, and current response shape at
# runtime instead of hard-coding them — the skill only needs the base URL,
# the auth scheme, and this endpoint.
class ApiMeta
  def initialize(challenge, base_url:)
    @challenge = challenge
    @base_url = base_url
  end

  def as_json(*)
    {
      api: "And God Said Bible Challenge — Challenge Data API",
      version: "v1",
      description: "Read-only API for challenge organizers to retrieve everything about their challenge. " \
                   "Authenticate every request with the per-challenge API key.",
      auth: auth_block,
      challenge: { id: @challenge.id, name: @challenge.name },
      endpoints: endpoints,
      field_glossary: field_glossary,
      example_report_shape: example_report_shape,
      example_participant_shape: example_participant_shape,
      example_group_shape: example_group_shape,
      example_sprints_shape: example_sprints_shape,
      example_sprint_standings_shape: example_sprint_standings_shape,
      notes: notes,
      generated_at: Time.current.iso8601
    }
  end

  private

  def report_path
    "/api/v1/challenges/#{@challenge.id}/report"
  end

  def participant_path
    "/api/v1/challenges/#{@challenge.id}/participants/:user_id"
  end

  def group_path
    "/api/v1/challenges/#{@challenge.id}/groups/:group_id/report"
  end

  def sprints_path
    "/api/v1/challenges/#{@challenge.id}/sprints"
  end

  def sprint_path
    "/api/v1/challenges/#{@challenge.id}/sprints/:sprint_id"
  end

  def meta_path
    "/api/v1/meta"
  end

  def auth_block
    {
      scheme: "Bearer",
      header: "Authorization: Bearer <api_key>",
      how_to_obtain: "Challenge Console → API Access (challenge creator, organizers, or site admins).",
      scope: "Read-only access to the single challenge that owns the key."
    }
  end

  def endpoints
    [
      {
        method: "GET",
        path: meta_path,
        url: "#{@base_url}#{meta_path}",
        auth_required: true,
        summary: "This document. Describes the endpoints, field meanings, and a sample of the report's current shape."
      },
      {
        method: "GET",
        path: report_path,
        url: "#{@base_url}#{report_path}",
        auth_required: true,
        summary: "Everything about the challenge: metadata, summary stats, the reading schedule with " \
                 "per-reading completion counts, participants with their progress, groups, and the most-liked " \
                 "and most-commented verses."
      },
      {
        method: "GET",
        path: participant_path,
        url: "#{@base_url}#{participant_path}",
        auth_required: true,
        summary: "Full per-participant graph: profile, complete reading history, group memberships, and every " \
                 "verse like and comment they made in this challenge. Get :user_id values from the report's " \
                 "participants[].user_id."
      },
      {
        method: "GET",
        path: group_path,
        url: "#{@base_url}#{group_path}",
        auth_required: true,
        summary: "Full per-group graph: profile, members with their progress, aggregate group stats, and how the " \
                 "group performed in each sprint (completion and on-schedule percentage, and whether it won). " \
                 "Get :group_id values from the report's groups[].id."
      },
      {
        method: "GET",
        path: sprints_path,
        url: "#{@base_url}#{sprints_path}",
        auth_required: true,
        summary: "All sprints in the challenge with their start and end dates, status, and recorded winners."
      },
      {
        method: "GET",
        path: sprint_path,
        url: "#{@base_url}#{sprint_path}",
        auth_required: true,
        summary: "Live ranked standings for one sprint: every group with members ranked 1st, 2nd, 3rd… by " \
                 "reading completion percentage then on-schedule percentage, over the sprint's date range. " \
                 "Get :sprint_id values from the sprints list."
      }
    ]
  end

  def field_glossary
    {
      "challenge.status" => "One of: upcoming, in_progress, past.",
      "challenge.join_url" => "Public invitation URL participants use to join the challenge.",
      "stats.participants" => "Number of enrolled users (challenge enrollments).",
      "stats.completion_rate" => "Value 0–1: total_completions ÷ (participants × readings). 0.0 when there are no participants or readings.",
      "stats.total_completions" => "Total reading completions across all participants.",
      "stats.total_verse_likes" => "Total verse likes across the challenge's readings.",
      "stats.total_verse_comments" => "Total verse comments across the challenge's readings.",
      "readings[].completions" => "Number of participants who marked that reading complete.",
      "readings[].reference" => "Human-readable book and chapter, e.g. 'Romans 8'.",
      "participants[].role" => "Enrollment role: 'member' or 'organizer'.",
      "participants[].readings_completed" => "Count of readings this participant has completed.",
      "participants[].last_completed_on" => "Date of the participant's most recent completion, or null.",
      "groups[].members" => "Number of users enrolled in the group.",
      "top_liked_verses" => "Up to 50 verses ranked by like count, descending.",
      "top_liked_verses[].reference" => "Book chapter:verse, e.g. '2 Corinthians 5:17'.",
      "top_commented_verses" => "Up to 50 verses ranked by number of comments, descending.",
      "top_commented_verses[].comments" => "Number of comments on that verse.",
      "participant.role" => "Enrollment role: 'member' or 'organizer'.",
      "reading_history" => "Every reading the participant completed in this challenge, ordered by completion date.",
      "reading_history[].completed_on" => "Date the participant marked that reading complete.",
      "groups[].joined_at" => "When the participant joined that group.",
      "likes" => "Every verse the participant liked in this challenge, ordered by time.",
      "likes[].reference" => "Liked verse, e.g. 'John 3:16'.",
      "comments" => "Every verse comment the participant wrote in this challenge, ordered by time.",
      "comments[].content" => "Text of the participant's comment.",
      "comments[].reference" => "Verse the comment is on.",
      "group.country" => "Full country name for the group's country_code, or null.",
      "group.stats.completion_percentage" => "Average percentage of due readings completed across the group's members (0–100).",
      "group.stats.on_schedule_percentage" => "Average percentage of readings members completed on or before their scheduled date (0–100).",
      "group.stats.longest_group_streak" => "Longest run of consecutive days every member completed the reading.",
      "group.members[].role" => "The member's challenge enrollment role: 'member' or 'organizer'.",
      "group.members[].joined_group_at" => "When the member joined this group.",
      "group.sprints[].won" => "True when this group is a recorded winner of that sprint.",
      "sprints[].status" => "One of: upcoming, active, past.",
      "sprints[].days" => "Number of days the sprint spans, inclusive of both endpoints.",
      "sprints[].winners_calculated" => "True once the sprint's winners have been computed and stored.",
      "sprints[].winners" => "Recorded winning group(s) — the groups tied for 1st place.",
      "sprint.standings" => "Every group with at least one member, ranked by completion then on-schedule percentage.",
      "sprint.standings[].rank" => "Competition rank (1, 2, 2, 4…); groups tied on both metrics share a rank.",
      "sprint.standings[].completion_percentage" => "The group's reading completion percentage over the sprint (0–100).",
      "sprint.standings[].on_schedule_percentage" => "The group's on-schedule percentage over the sprint (0–100)."
    }
  end

  # The live report with each list truncated to a single sample row. Because it
  # is generated from the real ChallengeReport, the shape stays accurate
  # automatically as the report evolves.
  def example_report_shape
    truncate_arrays(ChallengeReport.new(@challenge).as_json)
  end

  # A live participant graph (first enrollment) with arrays truncated to one
  # sample row, or nil when the challenge has no participants.
  def example_participant_shape
    enrollment = @challenge.user_challenge_enrollments.includes(:user).first
    return nil unless enrollment

    truncate_arrays(ParticipantReport.new(@challenge, enrollment).as_json)
  end

  # A live group graph (a group with members, else the first group) with arrays
  # truncated to one sample row, or nil when the challenge has no groups.
  def example_group_shape
    group = @challenge.groups.joins(:user_group_enrollments).distinct.first || @challenge.groups.first
    return nil unless group

    truncate_arrays(GroupReport.new(@challenge, group).as_json)
  end

  # The live sprints list with the sprints array truncated to one sample.
  def example_sprints_shape
    truncate_arrays(SprintsReport.new(@challenge).as_json)
  end

  # Live standings for the first sprint with arrays truncated to one sample row,
  # or nil when the challenge has no sprints.
  def example_sprint_standings_shape
    sprint = @challenge.sprints.ordered.first
    return nil unless sprint

    truncate_arrays(SprintStandings.new(sprint).as_json)
  end

  def truncate_arrays(hash)
    hash.transform_values { |value| value.is_a?(Array) ? value.first(1) : value }
  end

  def notes
    [
      "Arrays in every example_*_shape are truncated to one sample row; call the endpoints for the full data.",
      "Sprint standings are computed live at request time, so an in-progress sprint reflects current progress; only groups with at least one member are ranked.",
      "Breaking changes will be published under /api/v2; /api/v1 remains stable.",
      "An API key grants read-only access only to the challenge that owns it.",
      "Participant emails are intentionally not exposed."
    ]
  end
end
