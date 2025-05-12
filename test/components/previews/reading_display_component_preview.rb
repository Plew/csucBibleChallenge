# frozen_string_literal: true

class ReadingDisplayComponentPreview < ViewComponent::Preview
  def default
    render ReadingDisplayComponent.new(
      title: "John 3:16-18",
      verses: [
        { verse_number: 16, verse_text: 'For God so loved the world, that he gave his only Son, that whoever believes in him should not perish but have eternal life.' },
        { verse_number: 17, verse_text: 'For God did not send his Son into the world to condemn the world, but in order that the world might be saved through him.' },
        { verse_number: 18, verse_text: 'Whoever believes in him is not condemned, but whoever does not believe is condemned already, because he has not believed in the name of the only Son of God.' }
      ]
    )
  end

  def empty_verses
    render ReadingDisplayComponent.new(
      title: 'Empty Reading',
      verses: []
    )
  end
end 