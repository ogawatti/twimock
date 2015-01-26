require 'spec_helper'
require 'rack/test'

describe Twimock::API::OAuthRequestToken do
  include TestApplicationHelper
  include Rack::Test::Methods

  let(:method) { 'POST' }
  let(:path)   { '/oauth/request_token' }
  let(:test_app) { TestApplicationHelper::TestRackApplication.new }
  let(:app)      { Twimock::API::OAuthRequestToken.new(test_app) }

  describe '::METHOD' do
    subject { Twimock::API::OAuthRequestToken::METHOD }
    it { is_expected.to eq method }
  end

  describe '::PATH' do
    subject { Twimock::API::OAuthRequestToken::PATH }
    it { is_expected.to eq path }
  end

  describe "POST '/oauth/request_token'" do
    let (:oauth_token) { "rtbhw3pwBG1l498HYrDIRe8QSX09Bal1" }
    let (:oauth_token_secret) { "EqKuyJU3XcS7mgwLUbUYnBZYcLSDavJq" }
    let (:oauth_callback_confirmed) { "true" }

    it 'should return 200 OK' do
      post '/oauth/request_token'

      expect(last_response.status).to eq 200

      expect(last_response.header).not_to be_blank
      expect(last_response.header['Content-Length']).to eq body.bytesize.to_s

      expect(last_response.body).not_to be_blank
      index = body =~ /^oauth_token=(.*)&oauth_token_secret=(.*)&oauth_callback_confirmed=(.*)$/
      expect(index).to eq 0
      expect($1).to eq oauth_token
      expect($2).to eq oauth_token_secret
      expect($3).to eq oauth_callback_confirmed
    end
  end

  describe "POST '/test'" do
    it 'should return 200 OK' do
      post '/test'

      expect(last_response.status).to eq 200
      expect(last_response.header).to be_blank
      expect(last_response.body).to be_blank
    end
  end

  describe "GET '/oauth/request_token'" do
    it 'should return 200 OK' do
      get '/oauth/request_token'

      expect(last_response.status).to eq 200
      expect(last_response.header).to be_blank
      expect(last_response.body).to be_blank
    end
  end
end
