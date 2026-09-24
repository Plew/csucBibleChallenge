require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render plain: embedded? ? 'embedded' : 'not_embedded'
    end
  end

  describe '#embedded?' do
    it 'returns true and saves to session when params[:embed] is true' do
      get :index, params: { embed: 'true' }
      expect(response.body).to eq('embedded')
      expect(session[:embedded]).to be true
    end

    it 'returns false and sets session to false when params[:embed] is false' do
      session[:embedded] = true
      get :index, params: { embed: 'false' }
      expect(response.body).to eq('not_embedded')
      expect(session[:embedded]).to be false
    end

    it 'clears sticky session[:embedded] on top-level document navigations without embed param' do
      session[:embedded] = true
      request.headers['Sec-Fetch-Dest'] = 'document'
      get :index
      expect(response.body).to eq('not_embedded')
      expect(session[:embedded]).to be_nil
    end

    it 'preserves session[:embedded] when inside an iframe' do
      session[:embedded] = true
      request.headers['Sec-Fetch-Dest'] = 'iframe'
      get :index
      expect(response.body).to eq('embedded')
      expect(session[:embedded]).to be true
    end
  end
end
