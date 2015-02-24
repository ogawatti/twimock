require 'spec_helper'
require 'rack/test'

describe Twimock::API::IntentSessions do
  include TestApplicationHelper
  include APISpecHelper
  include Rack::Test::Methods

  let(:method)   { 'POST' }
  let(:path)     { '/intent/sessions' }
  let(:body)     { "" }
  let(:header)   { {} }
  let(:test_app) { TestApplicationHelper::TestRackApplication.new }
  let(:app)      { Twimock::API::IntentSessions.new(test_app) }

  def query_string_to_hash(query_string)
    ary  = URI::decode_www_form(query_string)
    hash = Hash[ary]
    Hashie::Mash.new(hash)
  end

  describe '::METHOD' do
    subject { Twimock::API::IntentSessions::METHOD }
    it { is_expected.to eq method }
  end

  describe '::PATH' do
    subject { Twimock::API::IntentSessions::PATH }
    it { is_expected.to eq path }
  end

  shared_context '302 Redirected OAuth Authenticate', assert: :InvalidInputData do
    it 'should return 302 Redirected /oauth/authenticate' do
      post path, @body, header

      expect(last_response.status).to eq 302
      expect(last_response.header).not_to be_blank
      expect(last_response.header['Content-Length']).to eq last_response.body.bytesize.to_s
      expect(last_response.header['Content-Type']).to eq "application/json; charset=utf-8"
      expect(last_response.header['Location']).not_to be_blank
      location = URI.parse(last_response.header['Location'])
      query = query_string_to_hash(location.query)
      expect(location.path).to eq "/oauth/authenticate"
      expect(query).to be_has_key "oauth_token"
      expect(query["oauth_token"]).to eq @body[:oauth_token]
      expect(last_response.body).not_to be_blank
      parsed_body = JSON.parse(last_response.body)
      expect(parsed_body["error"]["code"]).to match /^Invalid.*/
    end
  end

  shared_context '302 Redircted Callback URL', assert: :Authenticated do
    it 'should return 302 Redirected callback url' do
      post path, @body, header
      
      expect(last_response.status).to eq 302
      expect(last_response.header).not_to be_blank
      expect(last_response.header['Content-Length']).to eq last_response.body.bytesize.to_s
      query_string = "oauth_token=#{@request_token.string}&oauth_verifier=#{@request_token.verifier}"
      location = Twimock::Config.callback_url + "?" + query_string
      expect(last_response.header['Location']).to eq location
      expect(last_response.body).to be_blank
    end
  end

  describe "POST '/oauth/request_token'" do
    before { stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name) }
    after  { database.drop }

    let(:db_name)  { ".test" }
    let(:database) { Twimock::Database.new }

    context 'without oauth token', assert: :UnauthorizedRequestToken do
      before { post path, body, header }
    end

    context 'with invalid oauth token', assert: :UnauthorizedRequestToken do
      before do
        request_token = Twimock::RequestToken.new
        @body = { 'session[username_or_email]' => "testuser",
                  'session[password]' =>  "testpass",
                  oauth_token: request_token.string }
        post path, @body, header
      end
    end

    context 'with only valid oauth token', assert: :InvalidUsernameOrEmail do
      before do
        application   = Twimock::Application.new
        application.save!
        request_token = Twimock::RequestToken.new(application_id: application.id)
        request_token.save!
        @body = { oauth_token: request_token.string }
      end
    end

    context 'with only valid oauth token and invalid username', assert: :InvalidInputData do
      before do
        application   = Twimock::Application.new
        application.save!
        request_token = Twimock::RequestToken.new(application_id: application.id)
        request_token.save!
        user          = Twimock::User.new(application_id: application.id, name: "testuser")
        user.save!
        @body = { 'session[username_or_email]' => "invalidusername",
                  oauth_token: request_token.string }
      end
    end

    context 'with valid oauth token and username and invalid password', assert: :InvalidInputData do
      before do
        application   = Twimock::Application.new
        application.save!
        request_token = Twimock::RequestToken.new(application_id: application.id)
        request_token.save!
        user          = Twimock::User.new(application_id: application.id, password: "testpass")
        user.save!
        @body = { 'session[username_or_email]' => user.twitter_id,
                  'session[password]' => "invalidpassword",
                  oauth_token: request_token.string }
      end
    end

    context 'with valid oauth token and username and password', assert: :Authenticated do
      before do
        application   = Twimock::Application.new
        application.save!
        @request_token = Twimock::RequestToken.new(application_id: application.id)
        @request_token.save!
        user          = Twimock::User.new(application_id: application.id)
        user.save!
        @body = { 'session[username_or_email]' => user.twitter_id,
                  'session[password]' => user.password,
                  oauth_token: @request_token.string }
      end
    end

    context 'with valid oauth token and email and password', assert: :Authenticated do
      before do
        application   = Twimock::Application.new
        application.save!
        @request_token = Twimock::RequestToken.new(application_id: application.id)
        @request_token.save!
        user          = Twimock::User.new(application_id: application.id)
        user.save!
        @body = { 'session[username_or_email]' => user.email,
                  'session[password]' => user.password,
                  oauth_token: @request_token.string }
      end
    end

    context 'raise error that is not catched' do
      before do
        allow_any_instance_of(Twimock::API::IntentSessions).to receive(:query_string_to_hash) do
          lambda { raise }
        end
      end

      it 'should return 500' do
        post path, @body, header

        expect(last_response.status).to eq 500
        expect(last_response.header).not_to be_blank
        expect(last_response.header['Content-Length']).to eq last_response.body.bytesize.to_s
        expect(last_response.body).to be_blank
      end
    end
  end

  describe "GET '/intent/sessions'" do
    it 'should return 200 OK' do
      get '/intent/sessions'

      expect(last_response.status).to eq 200
      expect(last_response.body).to be_blank
      expect(last_response.header).to be_blank
    end
  end

  describe "POST '/oauth/sessions'" do
    it 'should return 200 OK' do
      post '/oauth/sessions'

      expect(last_response.status).to eq 200
      expect(last_response.body).to be_blank
      expect(last_response.header).to be_blank
    end
  end
end
