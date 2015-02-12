require 'spec_helper'
require 'rack/test'

describe Twimock::API::OAuthAuthenticate do
  include TestApplicationHelper
  include APISpecHelper
  include Rack::Test::Methods

  let(:method)   { 'GET' }
  let(:path)     { '/oauth/authenticate' }
  let(:body)     { "" }
  let(:header)   { {} }
  let(:test_app) { TestApplicationHelper::TestRackApplication.new }
  let(:app)      { Twimock::API::OAuthAuthenticate.new(test_app) }

  describe '::METHOD' do
    subject { Twimock::API::OAuthAuthenticate::METHOD }
    it { is_expected.to eq method }
  end

  describe '::PATH' do
    subject { Twimock::API::OAuthAuthenticate::PATH }
    it { is_expected.to eq path }
  end

  describe "GET '/oauth/authenticate'" do
    before { stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name) }
    after  { database.drop }

    let(:db_name)  { ".test" }
    let(:database) { Twimock::Database.new }

    context 'without oauth token', assert: :UnauthorizedRequestToken do
      before { get path, body, header }
    end

    context 'with invalid oauth token', assert: :UnauthorizedRequestToken do
      before do
        request_token = Twimock::RequestToken.new
        query_string = "request_token=#{request_token.string}"
        get path + "?" + query_string , body, header
      end
    end

    context 'with valid oauth token' do
      before do
        application = Twimock::Application.new
        application.save!
        @request_token = Twimock::RequestToken.new(application_id: application.id)
        @request_token.save!
        @path = path + "?oauth_token=#{@request_token.string}"
      end

      it 'should return 200 OK' do
        get @path, body, header
          
        view = Twimock::API::OAuthAuthenticate.view(@request_token.string)
        expect(last_response.status).to eq 200
        expect(last_response.header).not_to be_blank
        expect(last_response.header['Content-Length']).to eq last_response.body.bytesize.to_s
        expect(last_response.body).to eq view
        expect(last_response.body).to be_include(@request_token.string)
        expect(last_response.body).to be_include(Twimock::API::IntentSessions::PATH)
      end
    end

    context 'raise error that is not catched' do
      before { allow_any_instance_of(Rack::Request).to receive(:params) { lambda { raise } } }

      it 'should return 500' do
        get path, body, header

        expect(last_response.status).to eq 500
        expect(last_response.header).not_to be_blank
        expect(last_response.header['Content-Length']).to eq last_response.body.bytesize.to_s
        expect(last_response.body).to be_blank
      end
    end
  end

  describe "POST '/oauth/authenticate'" do
    it 'should return 200 OK' do
      post '/oauth/authenticate'

      expect(last_response.status).to eq 200
      expect(last_response.body).to be_blank
      expect(last_response.header).to be_blank
    end
  end

  describe "GET '/oauth/authentication'" do
    it 'should return 200 OK' do
      get '/oauth/authentication'

      expect(last_response.status).to eq 200
      expect(last_response.body).to be_blank
      expect(last_response.header).to be_blank
    end
  end
end
