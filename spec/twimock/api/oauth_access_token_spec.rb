require 'spec_helper'
require 'rack/test'

describe Twimock::API::OAuthAccessToken do
  include TestApplicationHelper
  include Rack::Test::Methods

  let(:method) { 'POST' }
  let(:path)   { '/oauth/access_token' }
  let(:authorization_regexp) { Regexp.new('OAuth oauth_body_hash=\"(.*)\", oauth_consumer_key=\"(.*)\", oauth_nonce=\"(.*)\", oauth_signature=\"(.*)\", oauth_signature_method=\"(.*)\", oauth_timestamp=\"(.*)\", oauth_token=\"(.*)\", oauth_verifier=\"(.*)\", oauth_version=\"(.*)\"') }
  let(:body)     { "" }
  let(:header)   { {} }
  let(:test_app) { TestApplicationHelper::TestRackApplication.new }
  let(:app)      { Twimock::API::OAuthAccessToken.new(test_app) }

  def create_authorization_header(consumer_key, token)
    params = {
      body_hash:        "2jmj7l5rSw0yVb%2FvlWAYkK%2FYBwk%3D",
      consumer_key:     consumer_key,
      nonce:            "IowIhqA1ckGHxbDL3pRVU3Td7BHfo2CWx7a6BArMveE",
      signature:        "FfuyevfGWuVC5ZBUta0J4TmFFfQ%3D",
      signature_method: "HMAC-SHA1",
      timestamp:        "1422273884",
      token:            token,
      verifier:         "Mk8kPU3Del5IrhQuxdYAVVJIAHeetQ4M",
      version:          "1.0" }
    string = params.inject([]){|a, (k,v)| a << "oauth_#{k}=\"#{v}\"" }.join(", ")
    [ "OAuth #{string}" ]
  end

  describe '::METHOD' do
    subject { Twimock::API::OAuthAccessToken::METHOD }
    it { is_expected.to eq method }
  end

  describe '::PATH' do
    subject { Twimock::API::OAuthAccessToken::PATH }
    it { is_expected.to eq path }
  end

  describe '::AUTHORIZATION_REGEXP' do
    subject { Twimock::API::OAuthAccessToken::AUTHORIZATION_REGEXP }
    it { is_expected.to eq authorization_regexp }
  end

  shared_context '401 Unauthorizaed OAuth Access Token', assert: :UnauthorizedOAuthAccessToken do
    it 'should return 401 Unauthorized' do
      post path, body, header

      expect(last_response.status).to eq 401
      expect(last_response.header).not_to be_blank
      expect(last_response.header['Content-Length']).to eq 0.to_s
      expect(last_response.body).to be_blank
    end
  end

  describe "POST '/oauth/access_token'" do
    context 'with authorization header' do
      before { stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name) }
      after  { database.drop }

      let(:db_name)  { ".test" }
      let(:database) { Twimock::Database.new }

      let(:header) { { "authorization" => @authorization } }

      context 'that is correct' do
        before do
          app = Twimock::Application.new
          app.save!
          user = Twimock::User.new(application_id: app.id)
          user.save!
          request_token = Twimock::RequestToken.new(application_id: app.id, user_id: user.id)
          request_token.save!

          @authorization = create_authorization_header(app.api_key, request_token.string)
        end

        it 'should return 200 Created' do
          post path, body, header

          expect(last_response.status).to eq 200
          expect(last_response.header).not_to be_blank
          expect(last_response.header['Content-Length']).to eq last_response.body.bytesize.to_s
          expect(last_response.body).not_to be_blank

          index = last_response.body =~ /^oauth_token=(.*)&oauth_token_secret=(.*)&user_id=(.*)&screen_name=(.*)$/
          expect(index).to eq 0
          oauth_token        = $1
          oauth_token_secret = $2
          user_id            = $3.to_i
          screen_name        = $4

          user = Twimock::User.find_by_access_token(oauth_token)
          expect(user).not_to be_nil
          expect(oauth_token_secret).to eq user.access_token_secret
          expect(user_id).to eq user.id
          expect(screen_name).to eq user.twitter_id
        end
      end

      context 'that is incorrect format', assert: :UnauthorizedOAuthAccessToken do
        before { @authorization = ["OAuth consumer_key=\"test_consumer_key\, oauth_token=\"test_token\""] }
      end

      context 'but consumer_key is invalid', assert: :UnauthorizedOAuthAccessToken do
        before do
          app = Twimock::Application.new
          request_token = Twimock::RequestToken.new(application_id: app.id)
          @authorization = create_authorization_header(app.api_key, request_token.string)
        end
      end

      context 'but oauth_token is invalid', assert: :UnauthorizedOAuthAccessToken do
        before do
          app = Twimock::Application.new
          app.save!
          request_token = Twimock::RequestToken.new(application_id: app.id)
          @authorization = create_authorization_header(app.api_key, request_token.string)
        end
      end

      context 'but oauth_token does not belong to user', assert: :UnauthorizedOAuthAccessToken do
        before do
          app = Twimock::Application.new
          app.save!
          request_token = Twimock::RequestToken.new(application_id: app.id)
          request_token.save!
          @authorization = create_authorization_header(app.api_key, request_token.string)
        end
      end

      context 'but oauth_token does not belong to application', assert: :UnauthorizedOAuthAccessToken do
        before do
          app = Twimock::Application.new
          app.save!
          user = Twimock::User.new(application_id: app.id)
          user.save!
          request_token = Twimock::RequestToken.new(application_id: app.id)
          request_token.save!
          @authorization = create_authorization_header(app.api_key, request_token.string)
        end
      end
    end

    context 'without authorization header', assert: :UnauthorizedOAuthAccessToken do
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
