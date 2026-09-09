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
        expect(assigns(:groups)).to match_array([ group, group2 ])
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

  describe 'GET #show' do
    let!(:reading1) { create(:reading, challenge: challenge, scheduled_date: 3.days.ago.to_date) }
    let!(:reading2) { create(:reading, challenge: challenge, scheduled_date: 1.day.ago.to_date) }
    let!(:member_enrollment) { create(:user_group_enrollment, user: user, group: group) }
    let!(:user_reading1) { create(:user_reading, user: user, reading: reading1, completed_on: reading1.scheduled_date) }
    let!(:user_reading2) { create(:user_reading, user: user, reading: reading2, completed_on: reading2.scheduled_date) }

    it 'calculates stats including all past readings when stats dates not set' do
      get :show, params: { id: group.id }
      expect(response).to have_http_status(:ok)
      stats = assigns(:group_stats)
      expect(stats[:total_scheduled] || stats[:total_possible]).to eq(2)
      expect(stats[:total_completed]).to eq(2)
    end

    it 'filters total_completed and total_possible when stats_start_date is set' do
      challenge.update!(start_date: 5.days.ago.to_date, stats_start_date: 2.days.ago.to_date)
      get :show, params: { id: group.id }
      expect(response).to have_http_status(:ok)
      stats = assigns(:group_stats)
      expect(stats[:total_possible]).to eq(1)
      expect(stats[:total_completed]).to eq(1)
      expect(stats[:total_on_time]).to eq(1)
    end
  end

  describe 'PATCH #update' do
    context 'when user is the group creator' do
      let(:creator_group) { create(:group, challenge: challenge, creator: user) }

      it 'updates closed_to_new_members to true' do
        patch :update, params: { id: creator_group.id, group: { closed_to_new_members: '1' } }
        creator_group.reload
        expect(creator_group.closed_to_new_members).to eq(true)
      end

      it 'updates closed_to_new_members to false' do
        creator_group.update!(closed_to_new_members: true)
        patch :update, params: { id: creator_group.id, group: { closed_to_new_members: '0' } }
        creator_group.reload
        expect(creator_group.closed_to_new_members).to eq(false)
      end

      it 'redirects to the group page' do
        patch :update, params: { id: creator_group.id, group: { closed_to_new_members: '1' } }
        expect(response).to redirect_to(group_path(creator_group))
      end
    end

    context 'when user is not the group creator' do
      it 'redirects with alert message' do
        patch :update, params: { id: group.id, group: { closed_to_new_members: '1' } }
        expect(response).to redirect_to(group_path(group))
        expect(flash[:alert]).to eq('Only the group creator can edit this group.')
      end

      it 'does not update the group' do
        original_status = group.closed_to_new_members
        patch :update, params: { id: group.id, group: { closed_to_new_members: '1' } }
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

  describe 'GET #confirm_remove_member' do
    let(:creator_group) { create(:group, challenge: challenge, creator: user) }
    let(:member) { create(:user) }
    let!(:member_enrollment) { create(:user_group_enrollment, user: member, group: creator_group) }

    context 'when user is the group creator' do
      it 'renders the confirm_remove_member template' do
        get :confirm_remove_member, params: { id: creator_group.id, member_id: member.id }
        expect(response).to render_template(:confirm_remove_member)
      end

      it 'assigns the member to @member' do
        get :confirm_remove_member, params: { id: creator_group.id, member_id: member.id }
        expect(assigns(:member)).to eq(member)
      end
    end

    context 'when user is not the group creator' do
      let(:other_group) { create(:group, challenge: challenge) }

      it 'redirects with alert message' do
        get :confirm_remove_member, params: { id: other_group.id, member_id: member.id }
        expect(response).to redirect_to(group_path(other_group))
      end
    end

    context 'when trying to remove self' do
      it 'redirects to edit page with alert' do
        get :confirm_remove_member, params: { id: creator_group.id, member_id: user.id }
        expect(response).to redirect_to(edit_group_path(creator_group))
        expect(flash[:alert]).to include('cannot remove yourself')
      end
    end
  end

  describe 'DELETE #remove_member' do
    let(:creator_group) { create(:group, challenge: challenge, creator: user) }
    let(:member) { create(:user) }
    let!(:member_enrollment) { create(:user_group_enrollment, user: member, group: creator_group) }

    context 'when user is the group creator' do
      it 'removes the member from the group' do
        expect {
          delete :remove_member, params: { id: creator_group.id, member_id: member.id }
        }.to change { creator_group.users.count }.by(-1)
      end

      it 'redirects to edit group page' do
        delete :remove_member, params: { id: creator_group.id, member_id: member.id }
        expect(response).to redirect_to(edit_group_path(creator_group))
      end

      it 'shows success notice' do
        delete :remove_member, params: { id: creator_group.id, member_id: member.id }
        expect(flash[:notice]).to eq(I18n.t('groups.member_removed'))
      end
    end

    context 'when user is not the group creator' do
      let(:other_group) { create(:group, challenge: challenge) }

      it 'does not remove the member' do
        expect {
          delete :remove_member, params: { id: other_group.id, member_id: member.id }
        }.not_to change { other_group.users.count }
      end

      it 'redirects with alert message' do
        delete :remove_member, params: { id: other_group.id, member_id: member.id }
        expect(response).to redirect_to(group_path(other_group))
      end
    end

    context 'when trying to remove self' do
      it 'does not remove the creator' do
        creator_enrollment = create(:user_group_enrollment, user: user, group: creator_group)
        expect {
          delete :remove_member, params: { id: creator_group.id, member_id: user.id }
        }.not_to change { creator_group.users.count }
      end

      it 'redirects to edit page with alert' do
        delete :remove_member, params: { id: creator_group.id, member_id: user.id }
        expect(response).to redirect_to(edit_group_path(creator_group))
        expect(flash[:alert]).to include('cannot remove yourself')
      end
    end
  end

  describe 'POST #leave' do
    let(:creator) { user }
    let(:creator_group) { create(:group, challenge: challenge, creator: creator) }
    let!(:creator_enrollment) { create(:user_group_enrollment, user: creator, group: creator_group, created_at: 10.days.ago) }
    let(:first_joiner) { create(:user) }
    let(:second_joiner) { create(:user) }
    let!(:first_joiner_enrollment) { create(:user_group_enrollment, user: first_joiner, group: creator_group, created_at: 5.days.ago) }
    let!(:second_joiner_enrollment) { create(:user_group_enrollment, user: second_joiner, group: creator_group, created_at: 2.days.ago) }

    context 'when group creator leaves and other members exist' do
      it 'transfers ownership to the member who joined first and removes creator from group' do
        expect {
          post :leave
        }.to change { creator_group.users.count }.by(-1)

        expect(creator_group.reload.creator).to eq(first_joiner)
        expect(creator_group.users).not_to include(creator)
        expect(response).to redirect_to(groups_path)
        expect(flash[:notice]).to include("transferred to #{first_joiner.username}")
      end
    end

    context 'when regular member leaves' do
      before do
        session[:user_id] = second_joiner.id
        create(:user_challenge_enrollment, user: second_joiner, challenge: challenge)
      end

      it 'removes the member from group without changing creator' do
        expect {
          post :leave
        }.to change { creator_group.users.count }.by(-1)

        expect(creator_group.reload.creator).to eq(creator)
        expect(creator_group.users).not_to include(second_joiner)
        expect(response).to redirect_to(groups_path)
      end
    end

    context 'when solo creator leaves' do
      let(:solo_group) { create(:group, challenge: challenge, creator: creator) }
      let!(:solo_enrollment) do
        creator_enrollment.destroy
        first_joiner_enrollment.destroy
        second_joiner_enrollment.destroy
        create(:user_group_enrollment, user: creator, group: solo_group)
      end

      it 'destroys the group' do
        expect {
          post :leave
        }.to change(Group, :count).by(-1)

        expect(response).to redirect_to(groups_path)
      end
    end
  end
end
