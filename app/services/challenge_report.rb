# Builds the comprehensive, read-only data document returned by the challenge
# API (Api::V1::ChallengeReportsController). Aggregates challenge metadata,
# summary stats, the reading schedule with completion counts, participants with
# their progress, groups, and the most-liked verses.
class ChallengeReport
  TOP_VERSES_LIMIT = 50

  def initialize(challenge)
    @challenge = challenge
  end

  def as_json(*)
    {
      challenge: challenge_hash,
      stats: stats_hash,
      readings: readings_list,
      participants: participants_list,
      groups: groups_list,
      top_liked_verses: top_liked_verses,
      top_commented_verses: top_commented_verses,
      generated_at: Time.current.iso8601
    }
  end

  private

  attr_reader :challenge

  def reading_ids
    @reading_ids ||= challenge.readings.pluck(:id)
  end

  def completions_by_reading
    @completions_by_reading ||= UserReading.where(reading_id: reading_ids).group(:reading_id).count
  end

  def completions_by_user
    @completions_by_user ||= UserReading.where(reading_id: reading_ids).group(:user_id).count
  end

  def last_completed_by_user
    @last_completed_by_user ||= UserReading.where(reading_id: reading_ids).group(:user_id).maximum(:completed_on)
  end

  def challenge_hash
    {
      id: challenge.id,
      name: challenge.name,
      description: challenge.description,
      start_date: challenge.start_date,
      end_date: challenge.end_date,
      timezone: challenge.timezone,
      status: status,
      hidden: challenge.hidden,
      locked: challenge.locked,
      created_at: challenge.created_at.iso8601,
      creator: { id: challenge.creator_id, username: challenge.creator&.username },
      join_url: challenge.join_url
    }
  end

  def status
    if challenge.in_progress?
      "in_progress"
    elsif challenge.past?
      "past"
    else
      "upcoming"
    end
  end

  def stats_hash
    participants = challenge.user_challenge_enrollments.count
    readings = reading_ids.size
    total_completions = completions_by_reading.values.sum
    denominator = participants * readings

    {
      participants: participants,
      groups: challenge.groups.count,
      readings: readings,
      total_completions: total_completions,
      completion_rate: denominator.zero? ? 0.0 : (total_completions.to_f / denominator).round(4),
      total_verse_likes: VerseLike.where(reading_id: reading_ids).count,
      total_verse_comments: VerseMessage.where(reading_id: reading_ids).count,
      blog_posts: challenge.blog_posts.count,
      sprints: challenge.sprints.count
    }
  end

  def readings_list
    challenge.readings.order(:scheduled_date, :id).map do |reading|
      {
        id: reading.id,
        scheduled_date: reading.scheduled_date,
        book_number: reading.book_number,
        book_name: BibleBooks.name_for(reading.book_number),
        chapter_number: reading.chapter_number,
        reference: BibleBooks.reference(reading.book_number, reading.chapter_number),
        completions: completions_by_reading[reading.id] || 0
      }
    end
  end

  def participants_list
    challenge.user_challenge_enrollments.includes(:user).map do |enrollment|
      user = enrollment.user
      {
        user_id: user.id,
        username: user.username,
        role: enrollment.role,
        joined_at: enrollment.created_at.iso8601,
        readings_completed: completions_by_user[user.id] || 0,
        last_completed_on: last_completed_by_user[user.id]
      }
    end
  end

  def groups_list
    group_ids = challenge.groups.pluck(:id)
    member_counts = UserGroupEnrollment.where(group_id: group_ids).group(:group_id).count

    challenge.groups.order(:name).map do |group|
      {
        id: group.id,
        name: group.name,
        members: member_counts[group.id] || 0,
        created_at: group.created_at.iso8601
      }
    end
  end

  def top_liked_verses
    top_verses(VerseLike.where(reading_id: reading_ids), :likes)
  end

  def top_commented_verses
    top_verses(VerseMessage.where(reading_id: reading_ids), :comments)
  end

  # Ranks the verses with the most rows in `relation` (grouped by reading +
  # verse), returning the top entries with the count under `count_key`.
  def top_verses(relation, count_key)
    relation.group(:reading_id, :verse_number)
            .count
            .sort_by { |(reading_id, verse_number), count| [ -count, reading_id, verse_number ] }
            .first(TOP_VERSES_LIMIT)
            .map do |(reading_id, verse_number), count|
              book, chapter = reading_location[reading_id]
              {
                reference: BibleBooks.reference(book, chapter, verse_number),
                book_number: book,
                chapter_number: chapter,
                verse_number: verse_number,
                count_key => count
              }
            end
  end

  def reading_location
    @reading_location ||= challenge.readings.pluck(:id, :book_number, :chapter_number)
                                   .each_with_object({}) { |(id, book, chapter), h| h[id] = [ book, chapter ] }
  end
end
