require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#country_flag_emoji' do
    it 'returns the regional-indicator emoji flag for an ISO alpha-2 code' do
      expect(helper.country_flag_emoji("US")).to eq("\u{1F1FA}\u{1F1F8}")
      expect(helper.country_flag_emoji("DE")).to eq("\u{1F1E9}\u{1F1EA}")
    end

    it 'upcases lowercase codes' do
      expect(helper.country_flag_emoji("de")).to eq("\u{1F1E9}\u{1F1EA}")
    end

    it 'returns nil for blank input' do
      expect(helper.country_flag_emoji(nil)).to be_nil
      expect(helper.country_flag_emoji("")).to be_nil
    end
  end

  describe '#group_name_with_flag' do
    it 'prepends the flag emoji and a space when country_code is set' do
      group = FactoryBot.build(:group, name: "Team Berlin", country_code: "DE")
      expect(helper.group_name_with_flag(group)).to eq("\u{1F1E9}\u{1F1EA} Team Berlin")
    end

    it 'returns just the name when country_code is blank' do
      group = FactoryBot.build(:group, name: "Team Berlin", country_code: nil)
      expect(helper.group_name_with_flag(group)).to eq("Team Berlin")
    end
  end
end
