# frozen_string_literal: true

class ReadingPageComponentPreview < ViewComponent::Preview
  def default
    render ReadingPageComponent.new(
      days: sample_days,
      selected_date: Date.current,
      reading_title: "John 4",
      verses: sample_verses,
      is_completed: false,
      mobile: true,
      challenge_name: "Munich Fall Reading Challenge"
    )
  end

  def completed_reading
    render ReadingPageComponent.new(
      days: sample_days,
      selected_date: Date.current,
      reading_title: "Matthew 5",
      verses: sample_verses,
      is_completed: true,
      mobile: true,
      challenge_name: "Munich Fall Reading Challenge"
    )
  end

  def no_reading_scheduled
    render ReadingPageComponent.new(
      days: sample_days,
      selected_date: Date.current - 1.day,
      show_no_reading: true,
      mobile: true,
      challenge_name: "Munich Fall Reading Challenge"
    )
  end

  def selected_past_date
    past_date = Date.current - 3.days
    render ReadingPageComponent.new(
      days: sample_days_for_date(past_date),
      selected_date: past_date,
      reading_title: "Luke 2",
      verses: sample_verses,
      is_completed: true,
      mobile: true,
      challenge_name: "Munich Fall Reading Challenge"
    )
  end

  def cross_month_dates
    # Simulate dates spanning across months
    cross_month_days = generate_cross_month_days
    render ReadingPageComponent.new(
      days: cross_month_days,
      selected_date: Date.new(2025, 9, 1), # Sept 1st
      reading_title: "Psalms 23",
      verses: short_verses,
      is_completed: false,
      mobile: true,
      challenge_name: "Munich Fall Reading Challenge"
    )
  end

  def long_chapter
    render ReadingPageComponent.new(
      days: sample_days,
      selected_date: Date.current,
      reading_title: "Matthew 23",
      verses: long_chapter_verses,
      is_completed: false,
      mobile: true,
      challenge_name: "Munich Fall Reading Challenge"
    )
  end

  private

  def sample_days
    today = Date.current
    7.times.map do |i|
      date = today - (6 - i).days
      {
        date: date,
        day_of_week: date.strftime('%a'),
        day_of_month: date.day.to_s,
        month_day: date.strftime('%b %-d'),
        completed: [1, 3, 5].include?(i), # Some days completed
        group_completion: [0, 25, 50, 75, 100, 33, 66][i],
        has_reading: true
      }
    end
  end

  def sample_days_for_date(target_date)
    7.times.map do |i|
      date = target_date - 3.days + i.days
      {
        date: date,
        day_of_week: date.strftime('%a'),
        day_of_month: date.day.to_s,
        month_day: date.strftime('%b %-d'),
        completed: date <= Date.current - 1.day, # Past days completed
        group_completion: rand(0..100),
        has_reading: true
      }
    end
  end

  def generate_cross_month_days
    # Generate dates from Aug 29 to Sep 4 (cross month)
    start_date = Date.new(2025, 8, 29)
    7.times.map do |i|
      date = start_date + i.days
      {
        date: date,
        day_of_week: date.strftime('%a'),
        day_of_month: date.day.to_s,
        month_day: date.strftime('%b %-d'),
        completed: i < 3, # First few days completed
        group_completion: [25, 50, 75, 100, 20, 40, 60][i],
        has_reading: true
      }
    end
  end

  def sample_verses
    [
      { verse_number: 1, verse_text: 'When therefore the LORD knew how the Pharisees had heard that Jesus made and baptized more disciples than John,' },
      { verse_number: 2, verse_text: '(Though Jesus himself baptized not, but his disciples,)' },
      { verse_number: 3, verse_text: 'He left Judaea, and departed again into Galilee.' },
      { verse_number: 4, verse_text: 'And he must needs go through Samaria.' },
      { verse_number: 5, verse_text: 'Then cometh he to a city of Samaria, which is called Sychar, near to the parcel of ground that Jacob gave to his son Joseph.' }
    ]
  end

  def short_verses
    [
      { verse_number: 1, verse_text: 'The LORD is my shepherd; I shall not want.' },
      { verse_number: 2, verse_text: 'He maketh me to lie down in green pastures: he leadeth me beside the still waters.' },
      { verse_number: 3, verse_text: 'He restoreth my soul: he leadeth me in the paths of righteousness for his name\'s sake.' }
    ]
  end

  def long_chapter_verses
    [
      { verse_number: 1, verse_text: 'Then spake Jesus to the multitude, and to his disciples,' },
      { verse_number: 2, verse_text: 'Saying The scribes and the Pharisees sit in Moses\' seat:' },
      { verse_number: 3, verse_text: 'All therefore whatsoever they bid you observe, that observe and do; but do not ye after their works: for they say, and do not.' },
      { verse_number: 4, verse_text: 'For they bind heavy burdens and grievous to be borne, and lay them on men\'s shoulders; but they themselves will not move them with one of their fingers.' },
      { verse_number: 5, verse_text: 'But all their works they do for to be seen of men: they make broad their phylacteries, and enlarge the borders of their garments,' },
      { verse_number: 6, verse_text: 'And love the uppermost rooms at feasts, and the chief seats in the synagogues,' },
      { verse_number: 7, verse_text: 'And greetings in the markets, and to be called of men, Rabbi, Rabbi.' },
      { verse_number: 8, verse_text: 'But be not ye called Rabbi: for one is your Master, even Christ; and all ye are brethren.' },
      { verse_number: 9, verse_text: 'And call no man your father upon the earth: for one is your Father, which is in heaven.' },
      { verse_number: 10, verse_text: 'Neither be ye called masters: for one is your Master, even Christ.' },
      { verse_number: 11, verse_text: 'But he that is greatest among you shall be your servant.' },
      { verse_number: 12, verse_text: 'And whosoever shall exalt himself shall be abased; and he that shall humble himself shall be exalted.' }
    ]
  end
end