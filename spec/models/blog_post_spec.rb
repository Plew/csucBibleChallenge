require 'rails_helper'

RSpec.describe BlogPost, type: :model do
  describe 'associations' do
    it { should belong_to(:challenge) }
    it { should belong_to(:user) }
    it { should have_many(:blog_comments).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:content) }
    it { should validate_inclusion_of(:visible).in_array([ true, false ]) }
  end

  describe 'scopes' do
    let(:challenge) { create(:challenge) }
    let!(:visible_post) { create(:blog_post, challenge: challenge, visible: true) }
    let!(:hidden_post) { create(:blog_post, challenge: challenge, visible: false) }
    let!(:old_post) { create(:blog_post, challenge: challenge, created_at: 2.days.ago) }
    let!(:new_post) { create(:blog_post, challenge: challenge, created_at: 1.day.ago) }

    describe '.visible' do
      it 'returns only visible posts' do
        expect(BlogPost.visible).to include(visible_post)
        expect(BlogPost.visible).not_to include(hidden_post)
      end
    end

    describe '.recent_first' do
      it 'returns posts in reverse chronological order' do
        expect(BlogPost.recent_first.first).to eq(new_post)
        expect(BlogPost.recent_first.last).to eq(old_post)
      end
    end
  end

  describe 'deletion' do
    let(:blog_post) { create(:blog_post, :with_comments) }

    it 'destroys associated comments when deleted' do
      expect { blog_post.destroy }.to change(BlogComment, :count).by(-3)
    end
  end
end
