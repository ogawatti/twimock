require 'spec_helper'
require 'rack/test'

describe Twimock::API::Intent::Sessions do
  include TestApplicationHelper
  include APISpecHelper
  include Rack::Test::Methods

  let(:method)   { 'POST' }
  let(:path)     { '/intent/sessions' }
  let(:body)     { "" }
  let(:header)   { {} }
  let(:test_app) { TestApplicationHelper::TestRackApplication.new }
  let(:app)      { Twimock::API::Intent::Sessions.new(test_app) }

  def query_string_to_hash(query_string)
    ary  = URI::decode_www_form(query_string)
    hash = Hash[ary]
    Hashie::Mash.new(hash)
  end

  describe '::METHOD' do
    subject { Twimock::API::Intent::Sessions::METHOD }
    it { is_expected.to eq method }
  end

  describe '::PATH' do
    subject { Twimock::API::Intent::Sessions::PATH }
    it { is_expected.to eq path }
  end

  shared_examples 'API 302 InvalidInputData' do
    it 'should return 302 Redirected /oauth/authenticate' do
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

  shared_examples 'API 302 Redircted Callback URL' do
    it 'should return 302 Redirected callback url' do
      post path, @body, header
      
      expect(last_response.status).to eq 302
      expect(last_response.header).not_to be_blank
      expect(last_response.header['Content-Length']).to eq last_response.body.bytesize.to_s
      query_string = "oauth_token=#{@request_token.string}&oauth_verifier=#{@request_token.verifier}"
      location = Twimock::Config.callback_url + "?" + query_string
      expect(last_response.header['Location']).to eq location
      expect(last_response.body).to be_blank
      user_id = Twimock::RequestToken.find_by_string(@body[:oauth_token]).user_id
      expect(user_id).to eq @user.id
    end
  end

  describe "POST '/oauth/request_token'" do
    before { stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name) }
    after  { database.drop }

    let(:db_name)  { ".test" }
    let(:database) { Twimock::Database.new }

    context 'without oauth token' do
      before { post path, body, header }
      it_behaves_like 'API 401 UnAuthorized'
    end

    context 'with invalid oauth token' do
      before do
        request_token = Twimock::RequestToken.new
        @body = { 'session[username_or_email]' => "testuser",
                  'session[password]' =>  "testpass",
                  oauth_token: request_token.string }
        post path, @body, header
      end
      it_behaves_like 'API 401 UnAuthorized'
    end

    context 'with only valid oauth token' do
      before do
        application   = Twimock::Application.new
        application.save!
        request_token = Twimock::RequestToken.new(application_id: application.id)
        request_token.save!
        @body = { oauth_token: request_token.string }
        post path, @body, header
      end
      it_behaves_like 'API 302 InvalidInputData'
    end

    context 'with only valid oauth token and invalid username' do
      before do
        application   = Twimock::Application.new
        application.save!
        request_token = Twimock::RequestToken.new(application_id: application.id)
        request_token.save!
        user          = Twimock::User.new(application_id: application.id, name: "testuser")
        user.save!
        @body = { 'session[username_or_email]' => "invalidusername",
                  oauth_token: request_token.string }
        post path, @body, header
      end
      it_behaves_like 'API 302 InvalidInputData'
    end

    context 'with valid oauth token and username and invalid password' do
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
        post path, @body, header
      end
      it_behaves_like 'API 302 InvalidInputData'
    end

    context 'with valid oauth token and username and password' do
      before do
        application   = Twimock::Application.new
        application.save!
        @request_token = Twimock::RequestToken.new(application_id: application.id)
        @request_token.save!
        @user          = Twimock::User.new(application_id: application.id)
        @user.save!
        @body = { 'session[username_or_email]' => @user.twitter_id,
                  'session[password]' => @user.password,
                  oauth_token: @request_token.string }
        post path, @body, header
      end
      it_behaves_like 'API 302 Redircted Callback URL'
    end

    context 'with valid oauth token and email and password' do
      before do
        application   = Twimock::Application.new
        application.save!
        @request_token = Twimock::RequestToken.new(application_id: application.id)
        @request_token.save!
        @user          = Twimock::User.new(application_id: application.id)
        @user.save!
        @body = { 'session[username_or_email]' => @user.email,
                  'session[password]' => @user.password,
                  oauth_token: @request_token.string }
        post path, @body, header
      end
      it_behaves_like 'API 302 Redircted Callback URL'
    end

    context 'raise error that is not catched' do
      before do
        allow_any_instance_of(Twimock::API::Intent::Sessions).to receive(:query_string_to_hash) do
          lambda { raise }
        end
        post path, @body, header
      end
      it_behaves_like 'API 500 InternalServerError'
    end
  end

  describe "GET '/intent/sessions'" do
    before { get '/intent/sessions' }
    it_behaves_like 'TestRackApplication 200 OK'
  end

  describe "POST '/oauth/sessions'" do
    before { post '/oauth/sessions' }
    it_behaves_like 'TestRackApplication 200 OK'
  end
end
