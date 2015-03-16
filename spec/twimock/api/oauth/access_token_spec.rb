require 'spec_helper'
require 'rack/test'

describe Twimock::API::OAuth::AccessToken do
  include TestApplicationHelper
  include Rack::Test::Methods

  let(:method) { 'POST' }
  let(:path)   { '/oauth/access_token' }
  let(:authorization_regexp) { Regexp.new('OAuth oauth_body_hash=\"(.*)\", oauth_consumer_key=\"(.*)\", oauth_nonce=\"(.*)\", oauth_signature=\"(.*)\", oauth_signature_method=\"(.*)\", oauth_timestamp=\"(.*)\", oauth_token=\"(.*)\", oauth_verifier=\"(.*)\", oauth_version=\"(.*)\"') }
  let(:body)     { "" }
  let(:header)   { {} }
  let(:test_app) { TestApplicationHelper::TestRackApplication.new }
  let(:app)      { Twimock::API::OAuth::AccessToken.new(test_app) }

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
    subject { Twimock::API::OAuth::AccessToken::METHOD }
    it { is_expected.to eq method }
  end

  describe '::PATH' do
    subject { Twimock::API::OAuth::AccessToken::PATH }
    it { is_expected.to eq path }
  end

  describe '::AUTHORIZATION_REGEXP' do
    subject { Twimock::API::OAuth::AccessToken::AUTHORIZATION_REGEXP }
    it { is_expected.to eq authorization_regexp }
  end

  shared_examples "Get Access Token" do
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
      
      access_token = Twimock::AccessToken.find_by_string(oauth_token)
      expect(access_token).not_to be_nil
      expect(access_token.secret).to eq oauth_token_secret
      expect(access_token.user_id).to eq user_id
      user = Twimock::User.find_by_id(user_id)
      expect(user).not_to be_nil
      expect(user.twitter_id).to eq screen_name
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
        it_behaves_like "Get Access Token"

        context 'authorization header is string' do
          before do
            app = Twimock::Application.new
            app.save!
            user = Twimock::User.new(application_id: app.id)
            user.save!
            request_token = Twimock::RequestToken.new(application_id: app.id, user_id: user.id)
            request_token.save!
            @authorization = create_authorization_header(app.api_key, request_token.string).first
          end
          it_behaves_like "Get Access Token"
        end

        context 'raise error that is not catched' do
          before do
            allow(Twimock::RequestToken).to receive(:find_by_string){ raise }
            post path, body, header
          end
          it_behaves_like 'API 500 InternalServerError'
        end
      end

      context 'that is incorrect format' do
        before do
          @authorization = ["OAuth consumer_key=\"test_consumer_key\, oauth_token=\"test_token\""]
          post path, body, header
        end
        it_behaves_like "API 401 UnAuthorized"
      end

      context 'but consumer_key is invalid' do
        before do
          app = Twimock::Application.new
          request_token = Twimock::RequestToken.new(application_id: app.id)
          @authorization = create_authorization_header(app.api_key, request_token.string)
          post path, body, header
        end
        it_behaves_like "API 401 UnAuthorized"
      end

      context 'but oauth_token is invalid' do
        before do
          app = Twimock::Application.new
          app.save!
          request_token = Twimock::RequestToken.new(application_id: app.id)
          @authorization = create_authorization_header(app.api_key, request_token.string)
          post path, body, header
        end
        it_behaves_like "API 401 UnAuthorized"
      end

      context 'but oauth_token does not belong to user' do
        before do
          app = Twimock::Application.new
          app.save!
          request_token = Twimock::RequestToken.new(application_id: app.id)
          request_token.save!
          @authorization = create_authorization_header(app.api_key, request_token.string)
          post path, body, header
        end
        it_behaves_like "API 401 UnAuthorized"
      end

      context 'but oauth_token does not belong to application' do
        before do
          app = Twimock::Application.new
          app.save!
          user = Twimock::User.new(application_id: app.id)
          user.save!
          request_token = Twimock::RequestToken.new(application_id: app.id)
          request_token.save!
          @authorization = create_authorization_header(app.api_key, request_token.string)
          post path, body, header
        end
        it_behaves_like "API 401 UnAuthorized"
      end

      context 'without authorization header' do
        before { post path, body, header }
        it_behaves_like "API 401 UnAuthorized"
      end
    end
  end

  describe "GET '/test'" do
    before { post '/test' }
    it_behaves_like 'TestRackApplication 200 OK'
  end

  describe "GET '/oauth/access_token'" do
    before { get '/oauth/access_token' }
    it_behaves_like 'TestRackApplication 200 OK'
  end
end
