require 'spec_helper'
require 'rack/test'

describe Twimock::API::OAuthAccessToken do
  include TestApplicationHelper
  include Rack::Test::Methods

  let(:method) { 'POST' }
  let(:path)   { '/oauth/access_token' }
  let(:test_app) { TestApplicationHelper::TestRackApplication.new }
  let(:app)      { Twimock::API::OAuthAccessToken.new(test_app) }

  describe '::METHOD' do
    subject { Twimock::API::OAuthAccessToken::METHOD }
    it { is_expected.to eq method }
  end

  describe '::PATH' do
    subject { Twimock::API::OAuthAccessToken::PATH }
    it { is_expected.to eq path }
  end

  describe "POST '/oauth/access_token'" do
    it 'should return 201 Created' do
      post '/oauth/access_token'

      expect(last_response.status).to eq 201
      expect(last_response.body).to be_blank
      expect(last_response.header).to be_blank
    end
  end

  describe "POST '/test'" do
    it 'should return 200 OK' do
      post '/test'

      expect(last_response.status).to eq 200
      expect(last_response.body).to be_blank
      expect(last_response.header).to be_blank
    end
  end

  describe "GET '/oauth/access_token'" do
    it 'should return 200 OK' do
      get '/oauth/access_token'

      expect(last_response.status).to eq 200
      expect(last_response.body).to be_blank
      expect(last_response.header).to be_blank
    end
  end
end
