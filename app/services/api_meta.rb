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
      api: "CSM Bible Challenge — Challenge Data API",
      version: "v1",
      description: "Read-only API for challenge organizers to retrieve everything about their challenge. " \
                   "Authenticate every request with the per-challenge API key.",
      auth: auth_block,
      challenge: { id: @challenge.id, name: @challenge.name },
      endpoints: endpoints,
      field_glossary: field_glossary,
      example_report_shape: example_report_shape,
      example_participant_shape: example_participant_shape,
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
      "comments[].reference" => "Verse the comment is on."
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

  def truncate_arrays(hash)
    hash.transform_values { |value| value.is_a?(Array) ? value.first(1) : value }
  end

  def notes
    [
      "Arrays in example_report_shape and example_participant_shape are truncated to one sample row; call the endpoints for the full data.",
      "Breaking changes will be published under /api/v2; /api/v1 remains stable.",
      "An API key grants read-only access only to the challenge that owns it.",
      "Participant emails are intentionally not exposed."
    ]
  end
end
