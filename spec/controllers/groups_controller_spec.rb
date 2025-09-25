require 'rails_helper'

RSpec.describe GroupsController, type: :controller do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge) }
  let(:group) { create(:group, challenge: challenge) }
  let(:closed_group) { create(:group, challenge: challenge, closed_to_new_members: true) }
  let(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }

  before do
    session[:user_id] = user.id
    enrollment # Create the enrollment so user is enrolled in challenge
  end

  describe 'GET #index' do
    context 'when user is not in a group' do
      it 'renders the index template' do
        get :index
        expect(response).to render_template(:index)
      end

      it 'assigns groups to @groups' do
        group # Ensure the let group is created
        group2 = create(:group, challenge: challenge)
        get :index
        expect(assigns(:groups)).to match_array([group, group2])
      end
    end

    context 'when user is already in a group' do
      let!(:user_group_enrollment) { create(:user_group_enrollment, user: user, group: group) }

      it 'redirects to the user group' do
        get :index
        expect(response).to redirect_to(group_path(group))
      end

      it 'does not render the index template' do
        get :index
        expect(response).not_to render_template(:index)
      end
    end
  end

  describe 'PATCH #toggle_closed' do
    context 'when user is the group creator' do
      let(:creator_group) { create(:group, challenge: challenge, creator: user) }

      it 'toggles closed_to_new_members to true' do
        patch :toggle_closed, params: { id: creator_group.id, closed_to_new_members: '1' }
        creator_group.reload
        expect(creator_group.closed_to_new_members).to eq(true)
      end

      it 'toggles closed_to_new_members to false' do
        creator_group.update!(closed_to_new_members: true)
        patch :toggle_closed, params: { id: creator_group.id, closed_to_new_members: '0' }
        creator_group.reload
        expect(creator_group.closed_to_new_members).to eq(false)
      end

      it 'redirects to the group page' do
        patch :toggle_closed, params: { id: creator_group.id, closed_to_new_members: '1' }
        expect(response).to redirect_to(group_path(creator_group))
      end
    end

    context 'when user is not the group creator' do
      it 'redirects with alert message' do
        patch :toggle_closed, params: { id: group.id, closed_to_new_members: '1' }
        expect(response).to redirect_to(group_path(group))
        expect(flash[:alert]).to eq('Only the group creator can perform this action.')
      end

      it 'does not update the group' do
        original_status = group.closed_to_new_members
        patch :toggle_closed, params: { id: group.id, closed_to_new_members: '1' }
        group.reload
        expect(group.closed_to_new_members).to eq(original_status)
      end
    end
  end

  describe 'POST #join' do
    let(:other_user) { create(:user) }
    let(:other_enrollment) { create(:user_challenge_enrollment, user: other_user, challenge: challenge) }

    before do
      session[:user_id] = other_user.id
      other_enrollment # Create enrollment for other user
    end

    context 'when group is open to new members' do
      it 'allows user to join' do
        expect {
          post :join, params: { id: group.id }
        }.to change { group.users.count }.by(1)
      end

      it 'redirects to groups path' do
        post :join, params: { id: group.id }
        expect(response).to redirect_to(groups_path)
      end
    end

    context 'when group is closed to new members' do
      it 'does not allow user to join' do
        expect {
          post :join, params: { id: closed_group.id }
        }.not_to change { closed_group.users.count }
      end

      it 'redirects with alert message' do
        post :join, params: { id: closed_group.id }
        expect(response).to redirect_to(groups_path)
        expect(flash[:alert]).to eq('This group is closed to new members.')
      end
    end
  end
end