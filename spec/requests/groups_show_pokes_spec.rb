require "rails_helper"

# Verifies the poke buttons render on the group show page when conditions are
# met, that they wire up to the right endpoint, and that posting to that
# endpoint creates a poke and replaces the button with the "poked" indicator.
RSpec.describe "Group show page poke buttons", type: :request do
  let(:test_date) { Date.new(2026, 9, 1) }
  let(:challenge) do
    create(:challenge,
      start_date: Date.new(2026, 8, 25),
      end_date: Date.new(2026, 9, 25),
      timezone: "UTC"
    )
  end
  let(:group) { create(:group, challenge: challenge) }
  let(:current_user) { create(:user, username: "poker_user") }
  let(:other_member) { create(:user, username: "pokee_user") }
  let!(:reading) { create(:reading, challenge: challenge, scheduled_date: test_date) }

  before do
    create(:user_challenge_enrollment, user: current_user, challenge: challenge)
    create(:user_challenge_enrollment, user: other_member, challenge: challenge)
    create(:user_group_enrollment, user: current_user, group: group)
    create(:user_group_enrollment, user: other_member, group: group)
    login_via_session(current_user)
  end

  describe "GET /groups/:id" do
    context "when conditions for poking are met (after 9pm, pokee has push, hasn't read)" do
      before do
        create(:push_subscription, user: other_member)
        travel_to Time.zone.parse("2026-09-01 21:30:00 UTC")
      end

      after { travel_back }

      it "renders the poke button form pointing at the pokes endpoint" do
        get group_path(group)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(%(id="poke_button_#{other_member.id}"))
        expect(response.body).to match(
          %r{<form[^>]+action="/groups/#{group.id}/pokes\?[^"]*pokee_id=#{other_member.id}}
        )
        expect(response.body).to include(%(title="#{I18n.t('pokes.poke')}"))
      end

      it "does not render a poke button for the current user themselves" do
        get group_path(group)

        expect(response.body).not_to include(%(id="poke_button_#{current_user.id}"))
      end

      it "renders the poked indicator instead when the current user has already poked them today" do
        create(:poke,
          poker: current_user,
          pokee: other_member,
          challenge: challenge,
          poked_on: test_date
        )

        get group_path(group)

        expect(response.body).to include(%(id="poke_button_#{other_member.id}"))
        expect(response.body).to include(%(title="#{I18n.t('pokes.poked')}"))
        expect(response.body).not_to match(
          %r{<form[^>]+action="/groups/#{group.id}/pokes}
        )
      end
    end

    context "when before 9pm" do
      before do
        create(:push_subscription, user: other_member)
        travel_to Time.zone.parse("2026-09-01 08:00:00 UTC")
      end

      after { travel_back }

      it "does not render the poke button" do
        get group_path(group)

        expect(response.body).not_to match(
          %r{<form[^>]+action="/groups/#{group.id}/pokes}
        )
        expect(response.body).not_to include(%(id="poke_button_#{other_member.id}"))
      end
    end

    context "when the pokee has no push subscription" do
      before do
        travel_to Time.zone.parse("2026-09-01 21:30:00 UTC")
      end

      after { travel_back }

      it "does not render the poke button" do
        get group_path(group)

        expect(response.body).not_to match(
          %r{<form[^>]+action="/groups/#{group.id}/pokes}
        )
      end
    end

    context "when the pokee has already read today" do
      before do
        create(:push_subscription, user: other_member)
        create(:user_reading, user: other_member, reading: reading, completed_on: test_date)
        travel_to Time.zone.parse("2026-09-01 21:30:00 UTC")
      end

      after { travel_back }

      it "does not render the poke button" do
        get group_path(group)

        expect(response.body).not_to match(
          %r{<form[^>]+action="/groups/#{group.id}/pokes}
        )
      end
    end

    context "when the current user is viewing a group they are not in" do
      let(:other_group) { create(:group, challenge: challenge) }
      let(:third_user) { create(:user) }
      let(:fourth_user) { create(:user) }

      before do
        create(:user_challenge_enrollment, user: third_user, challenge: challenge)
        create(:user_challenge_enrollment, user: fourth_user, challenge: challenge)
        create(:user_group_enrollment, user: third_user, group: other_group)
        create(:user_group_enrollment, user: fourth_user, group: other_group)
        create(:push_subscription, user: third_user)
        create(:push_subscription, user: fourth_user)
        travel_to Time.zone.parse("2026-09-01 21:30:00 UTC")
      end

      after { travel_back }

      it "does not render any poke buttons" do
        get group_path(other_group)

        expect(response.body).not_to match(
          %r{<form[^>]+action="/groups/#{other_group.id}/pokes}
        )
      end
    end

    context "with simulate_9pm=true bypass during the day" do
      before do
        create(:push_subscription, user: other_member)
        travel_to Time.zone.parse("2026-09-01 10:00:00 UTC")
      end

      after { travel_back }

      it "renders the poke button when simulate_9pm=true is passed" do
        get group_path(group, simulate_9pm: "true")

        expect(response.body).to match(
          %r{<form[^>]+action="/groups/#{group.id}/pokes\?[^"]*pokee_id=#{other_member.id}}
        )
      end
    end
  end

  describe "click flow: GET button -> POST -> reload shows poked indicator" do
    before do
      create(:push_subscription, user: other_member)
      travel_to Time.zone.parse("2026-09-01 21:30:00 UTC")
    end

    after { travel_back }

    it "renders the button, posts to the form action, and reloads with the poked indicator" do
      get group_path(group)
      expect(response.body).to include(%(id="poke_button_#{other_member.id}"))
      expect(response.body).to match(
        %r{<form[^>]+action="/groups/#{group.id}/pokes\?[^"]*pokee_id=#{other_member.id}}
      )

      expect {
        post group_pokes_path(group), params: { pokee_id: other_member.id }
      }.to change(Poke, :count).by(1)
      expect(response).to redirect_to(group_path(group))

      get group_path(group)
      expect(response.body).to include(%(title="#{I18n.t('pokes.poked')}"))
      expect(response.body).not_to match(
        %r{<form[^>]+action="/groups/#{group.id}/pokes}
      )
    end
  end
end
