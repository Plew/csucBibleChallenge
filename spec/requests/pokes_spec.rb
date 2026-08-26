require "rails_helper"

RSpec.describe "Pokes", type: :request do
  let(:test_date) { Date.new(2026, 9, 1) }
  let(:challenge) do
    create(:challenge,
      start_date: Date.new(2026, 8, 25),
      end_date: Date.new(2026, 9, 25),
      timezone: "UTC"
    )
  end
  let(:group) { create(:group, challenge: challenge) }
  let(:poker) { create(:user) }
  let(:pokee) { create(:user) }
  let!(:reading) { create(:reading, challenge: challenge, scheduled_date: test_date) }

  before do
    create(:user_challenge_enrollment, user: poker, challenge: challenge)
    create(:user_challenge_enrollment, user: pokee, challenge: challenge)
    create(:user_group_enrollment, user: poker, group: group)
    create(:user_group_enrollment, user: pokee, group: group)
    create(:push_subscription, user: pokee)
    login_via_session(poker)
  end

  describe "POST /groups/:group_id/pokes" do
    context "when after 9 PM" do
      before do
        travel_to Time.zone.parse("2026-09-01 21:30:00 UTC")
      end

      after { travel_back }

      it "creates a poke and enqueues a notification job" do
        expect {
          post "/groups/#{group.id}/pokes", params: { pokee_id: pokee.id }
        }.to change(Poke, :count).by(1)

        expect(response).to redirect_to(group_path(group))
      end

      it "does not allow poking the same person twice in one day" do
        create(:poke, poker: poker, pokee: pokee, challenge: challenge, poked_on: test_date)

        expect {
          post "/groups/#{group.id}/pokes", params: { pokee_id: pokee.id }
        }.not_to change(Poke, :count)
      end

      it "does not allow poking a user who has already read today" do
        create(:user_reading, user: pokee, reading: reading, completed_on: test_date)

        expect {
          post "/groups/#{group.id}/pokes", params: { pokee_id: pokee.id }
        }.not_to change(Poke, :count)

        expect(response).to redirect_to(group_path(group))
      end

      it "does not allow poking a user without push subscriptions" do
        pokee.push_subscriptions.destroy_all

        expect {
          post "/groups/#{group.id}/pokes", params: { pokee_id: pokee.id }
        }.not_to change(Poke, :count)

        expect(response).to redirect_to(group_path(group))
      end
    end

    context "when before 9 PM" do
      before do
        travel_to Time.zone.parse("2026-09-01 20:59:00 UTC")
      end

      after { travel_back }

      it "does not allow poking" do
        expect {
          post "/groups/#{group.id}/pokes", params: { pokee_id: pokee.id }
        }.not_to change(Poke, :count)

        expect(response).to redirect_to(group_path(group))
        expect(flash[:alert]).to eq(I18n.t("pokes.too_early"))
      end
    end

    context "when not logged in" do
      before { login_via_session(nil) }

      it "redirects to login" do
        post "/groups/#{group.id}/pokes", params: { pokee_id: pokee.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
