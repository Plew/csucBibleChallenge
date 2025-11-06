# frozen_string_literal: true

class KeyGenerator
  def self.generate
    letters = ("A".."Z").to_a.sample(4).join
    numbers = (0..9).to_a.sample(4).join
    "#{letters}-#{numbers}"
  end
end
