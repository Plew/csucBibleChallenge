require 'rails_helper'

RSpec.describe "Admin::Challenges", type: :request do
  let(:admin_user) { create(:user, admin: true) }
  let(:regular_user) { create(:user, admin: false) }
  let(:challenge) { create(:challenge) }

  describe "authorization" do
    context "when user is not logged in" do
      it "redirects to login for GET /admin/challenges" do
        get admin_challenges_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it "redirects to login for GET /admin/challenges/new" do
        get new_admin_challenge_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it "redirects to login for POST /admin/challenges" do
        post admin_challenges_path, params: { challenge: { name: 'Test' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is not an admin" do
      before { login_via_session(regular_user) }

      it "redirects to root for GET /admin/challenges" do
        get admin_challenges_path
        expect(response).to redirect_to(root_path)
      end

      it "redirects to root for GET /admin/challenges/new" do
        get new_admin_challenge_path
        expect(response).to redirect_to(root_path)
      end

      it "redirects to root for POST /admin/challenges" do
        post admin_challenges_path, params: { challenge: { name: 'Test' } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /admin/challenges" do
    before { login_via_session(admin_user) }

    let!(:visible_challenge) { create(:challenge, title: "Visible Challenge", hidden: false) }
    let!(:hidden_challenge) { create(:challenge, title: "Hidden Challenge", hidden: true) }

    it "returns http success" do
      get admin_challenges_path
      expect(response).to have_http_status(:success)
    end

    it "displays all challenges including hidden ones" do
      get admin_challenges_path
      expect(response.body).to include("Visible Challenge")
      expect(response.body).to include("Hidden Challenge")
    end
  end

  describe "GET /admin/challenges/:id" do
    before { login_via_session(admin_user) }

    it "returns http success" do
      get admin_challenge_path(challenge)
      expect(response).to have_http_status(:success)
    end

    it "displays challenge details" do
      get admin_challenge_path(challenge)
      expect(response.body).to include(challenge.title)
    end
  end

  describe "GET /admin/challenges/:id/edit" do
    before { login_via_session(admin_user) }

    it "returns http success" do
      get edit_admin_challenge_path(challenge)
      expect(response).to have_http_status(:success)
    end

    it "displays edit form" do
      get edit_admin_challenge_path(challenge)
      expect(response.body).to include("Edit Challenge")
      expect(response.body).to include(challenge.title)
    end
  end

  describe "PATCH /admin/challenges/:id" do
    before { login_via_session(admin_user) }

    context "with valid parameters" do
      let(:valid_attributes) do
        {
          title: "Updated Challenge Title",
          description: "Updated description",
          hidden: true
        }
      end

      it "updates the challenge" do
        patch admin_challenge_path(challenge), params: { challenge: valid_attributes }
        challenge.reload
        expect(challenge.title).to eq("Updated Challenge Title")
        expect(challenge.description).to eq("Updated description")
        expect(challenge.hidden).to be true
      end

      it "redirects to admin challenges index" do
        patch admin_challenge_path(challenge), params: { challenge: valid_attributes }
        expect(response).to redirect_to(admin_challenges_path)
      end

      it "displays success notice" do
        patch admin_challenge_path(challenge), params: { challenge: valid_attributes }
        follow_redirect!
        expect(response.body).to include("Challenge was successfully updated")
      end

      it "updates only the description field when other fields unchanged" do
        original_title = challenge.title
        original_timezone = challenge.timezone
        original_start_date = challenge.start_date

        patch admin_challenge_path(challenge), params: {
          challenge: {
            title: original_title,
            description: "Only description changed",
            timezone: original_timezone,
            start_date: original_start_date
          }
        }

        challenge.reload
        expect(challenge.description).to eq("Only description changed")
        expect(challenge.title).to eq(original_title)
        expect(challenge.timezone).to eq(original_timezone)
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        {
          title: "" # Assuming title is required
        }
      end

      it "does not update the challenge" do
        original_title = challenge.title
        patch admin_challenge_path(challenge), params: { challenge: invalid_attributes }
        challenge.reload
        expect(challenge.title).to eq(original_title)
      end

      it "renders edit template" do
        patch admin_challenge_path(challenge), params: { challenge: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /admin/challenges/new" do
    before { login_via_session(admin_user) }

    it "returns http success" do
      get new_admin_challenge_path
      expect(response).to have_http_status(:success)
    end

    it "displays the challenge creation form" do
      get new_admin_challenge_path
      expect(response.body).to include('Create New Reading Challenge')
      expect(response.body).to include('Challenge Title')
      expect(response.body).to include('Start Date')
      expect(response.body).to include('Select Bible Books')
    end
  end

  describe "POST /admin/challenges" do
    before { login_via_session(admin_user) }

    let(:valid_params) do
      {
        challenge: {
          name: 'Test Challenge',
          start_date: Date.current.to_s,
          timezone: 'UTC'
        },
        selected_books: [ '40', '41' ] # Matthew and Mark
      }
    end

    let(:invalid_params) do
      {
        challenge: {
          name: '',
          start_date: '',
          timezone: 'UTC'
        }
      }
    end

    context "with valid parameters" do
      it "creates a new challenge" do
        expect {
          post admin_challenges_path, params: valid_params
        }.to change(Challenge, :count).by(1)
      end

      it "creates readings for selected books" do
        expect {
          post admin_challenges_path, params: valid_params
        }.to change(Reading, :count).by(44) # Matthew (28) + Mark (16) = 44 chapters
      end

      it "redirects to root with success message" do
        post admin_challenges_path, params: valid_params
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq('Challenge created successfully!')
      end
    end

    context "with invalid parameters" do
      it "does not create a challenge" do
        expect {
          post admin_challenges_path, params: invalid_params
        }.not_to change(Challenge, :count)
      end

      it "returns unprocessable entity status" do
        post admin_challenges_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "redisplays the form" do
        post admin_challenges_path, params: invalid_params
        expect(response.body).to include('Create New Reading Challenge')
      end
    end
  end

  describe "challenge deletion" do
    let!(:challenge) { create(:challenge, creator: admin_user) }
    let!(:other_admin) { create(:user, admin: true) }

    describe "GET /admin/challenges/:id/delete_confirmation" do
      context "when user is the creator" do
        before { login_via_session(admin_user) }

        it "returns http success" do
          get delete_confirmation_admin_challenge_path(challenge)
          expect(response).to have_http_status(:success)
        end

        it "displays deletion confirmation page with warning" do
          get delete_confirmation_admin_challenge_path(challenge)
          expect(response.body).to include('Delete Challenge')
          expect(response.body).to include('This action cannot be undone')
          expect(response.body).to include('All user progress and data will be permanently lost')
          expect(response.body).to include('i want this')
        end
      end

      context "when user is not the creator" do
        before { login_via_session(other_admin) }

        it "redirects with error message" do
          get delete_confirmation_admin_challenge_path(challenge)
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq('You can only delete challenges you created.')
        end
      end

      context "when user is not logged in" do
        it "redirects to login" do
          get delete_confirmation_admin_challenge_path(challenge)
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    describe "DELETE /admin/challenges/:id" do
      let!(:other_user) { create(:user) }
      let!(:enrollment) { create(:user_challenge_enrollment, challenge: challenge, user: other_user) }
      let!(:reading) { create(:reading, challenge: challenge) }

      context "when user is the creator" do
        before { login_via_session(admin_user) }

        context "with correct confirmation text" do
          it "deletes the challenge and all related data" do
            expect {
              delete admin_challenge_path(challenge), params: { confirmation_text: 'i want this' }
            }.to change(Challenge, :count).by(-1)
              .and change(UserChallengeEnrollment, :count).by(-1)
              .and change(Reading, :count).by(-1)
          end

          it "redirects to root with success message" do
            delete admin_challenge_path(challenge), params: { confirmation_text: 'i want this' }
            expect(response).to redirect_to(root_path)
            expect(flash[:notice]).to eq('Challenge deleted successfully.')
          end
        end

        context "with incorrect confirmation text" do
          it "does not delete the challenge" do
            expect {
              delete admin_challenge_path(challenge), params: { confirmation_text: 'wrong text' }
            }.not_to change(Challenge, :count)
          end

          it "redirects back with error message" do
            delete admin_challenge_path(challenge), params: { confirmation_text: 'wrong text' }
            expect(response).to redirect_to(delete_confirmation_admin_challenge_path(challenge))
            expect(flash[:alert]).to eq('Confirmation text is incorrect. Please type "i want this" exactly.')
          end
        end
      end

      context "when user is not the creator" do
        before { login_via_session(other_admin) }

        it "does not delete the challenge" do
          expect {
            delete admin_challenge_path(challenge), params: { confirmation_text: 'i want this' }
          }.not_to change(Challenge, :count)
        end

        it "redirects with error message" do
          delete admin_challenge_path(challenge), params: { confirmation_text: 'i want this' }
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq('You can only delete challenges you created.')
        end
      end
    end
  end
end
