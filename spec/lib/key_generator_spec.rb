# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KeyGenerator do
  describe '.generate' do
    it 'generates a key in the correct format' do
      key = KeyGenerator.generate
      expect(key).to match(/^[A-Z]{4}-\d{4}$/)
    end

    it 'generates unique keys' do
      keys = Set.new
      100.times do
        keys << KeyGenerator.generate
      end
      expect(keys.size).to eq(100)
    end

    it 'generates keys with random letters and numbers' do
      keys = 1000.times.map { KeyGenerator.generate }
      
      letters = keys.map { |k| k.split('-').first }.join
      numbers = keys.map { |k| k.split('-').last }.join
      
      ('A'..'Z').each do |letter|
        expect(letters).to include(letter)
      end
      
      ('0'..'9').each do |number|
        expect(numbers).to include(number)
      end
    end
  end
end