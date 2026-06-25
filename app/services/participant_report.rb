# Builds the full per-participant graph within a single challenge: the
# participant's profile, complete reading history, group memberships, and every
# verse like and comment they made. Scoped to the given challenge's readings and
# groups only (the API key grants access to one challenge).
class ParticipantReport
  def initialize(challenge, enrollment)
    @challenge = challenge
    @enrollment = enrollment
    @user = enrollment.user
  end

  def as_json(*)
    {
      participant: participant_hash,
      challenge: { id: @challenge.id, name: @challenge.name },
      stats: stats_hash,
      reading_history: reading_history,
      groups: groups,
      likes: likes,
      comments: comments,
      generated_at: Time.current.iso8601
    }
  end

  private

  def reading_ids
    @reading_ids ||= @challenge.readings.pluck(:id)
  end

  def readings_by_id
    @readings_by_id ||= Reading.where(id: reading_ids).index_by(&:id)
  end

  def participant_hash
    {
      user_id: @user.id,
      username: @user.username,
      role: @enrollment.role,
      joined_at: @enrollment.created_at.iso8601
    }
  end

  def stats_hash
    completed = reading_history.size
    total = reading_ids.size
    {
      readings_completed: completed,
      readings_total: total,
      completion_rate: total.zero? ? 0.0 : (completed.to_f / total).round(4),
      likes: likes.size,
      comments: comments.size,
      groups: groups.size
    }
  end

  def reading_history
    @reading_history ||=
      UserReading.where(user_id: @user.id, reading_id: reading_ids)
                 .order(:completed_on)
                 .map do |ur|
                   reading = readings_by_id[ur.reading_id]
                   {
                     reading_id: ur.reading_id,
                     reference: BibleBooks.reference(reading.book_number, reading.chapter_number),
                     book_number: reading.book_number,
                     chapter_number: reading.chapter_number,
                     scheduled_date: reading.scheduled_date,
                     completed_on: ur.completed_on
                   }
                 end
  end

  def groups
    @groups ||=
      UserGroupEnrollment.joins(:group)
                         .where(user_id: @user.id, groups: { challenge_id: @challenge.id })
                         .order("groups.name")
                         .map do |uge|
                           { id: uge.group_id, name: uge.group.name, joined_at: uge.created_at.iso8601 }
                         end
  end

  def likes
    @likes ||=
      VerseLike.where(user_id: @user.id, reading_id: reading_ids)
               .order(:created_at)
               .map { |like| verse_event(like) }
  end

  def comments
    @comments ||=
      VerseMessage.where(user_id: @user.id, reading_id: reading_ids)
                  .order(:created_at)
                  .map { |message| verse_event(message).merge(content: message.content) }
  end

  # Common shape for a verse-scoped event (like or comment).
  def verse_event(record)
    reading = readings_by_id[record.reading_id]
    {
      reading_id: record.reading_id,
      reference: BibleBooks.reference(reading.book_number, reading.chapter_number, record.verse_number),
      book_number: reading.book_number,
      chapter_number: reading.chapter_number,
      verse_number: record.verse_number,
      created_at: record.created_at.iso8601
    }
  end
end
