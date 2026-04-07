require "rails_helper"

RSpec.describe PushSubscription, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    subject { create(:push_subscription) }

    it { should validate_presence_of(:endpoint) }
    it { should validate_uniqueness_of(:endpoint) }
    it { should validate_presence_of(:p256dh_key) }
    it { should validate_presence_of(:auth_key) }
  end
end
