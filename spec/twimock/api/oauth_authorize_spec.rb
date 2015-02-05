require 'spec_helper'
require 'rack/test'

describe Twimock::API::OAuthAuthorize do
  include TestApplicationHelper
  include Rack::Test::Methods

  let(:method)   { 'GET' }
  let(:path)     { '/oauth/authorize' }
  let(:body)     { "" }
  let(:header)   { {} }
  let(:test_app) { TestApplicationHelper::TestRackApplication.new }
  let(:app)      { Twimock::API::OAuthAuthorize.new(test_app) }

  describe '::METHOD' do
    subject { Twimock::API::OAuthAuthorize::METHOD }
    it { is_expected.to eq method }
  end

  describe '::PATH' do
    subject { Twimock::API::OAuthAuthorize::PATH }
    it { is_expected.to eq path }
  end

  describe "GET '/oauth/request_token'" do
    context 'without oauth token' do
      it 'should return 401' do
        get path, body, header

        expect(last_response.status).to eq 401
        expect(last_response.header).not_to be_blank
        expect(last_response.header['Content-Length']).to eq 0.to_s
        expect(last_response.body).to be_blank
      end
    end

    context 'with oauth token' do
      before { stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name) }
      after  { database.drop }

      let(:db_name)  { ".test" }
      let(:database) { Twimock::Database.new }

      context 'but it is invalid' do
        before do
          request_token = Twimock::RequestToken.new
          @path = path + "?oauth_token=" + request_token.string
        end

        it 'should return 401' do
          get @path, body, header
          
          expect(last_response.status).to eq 401
          expect(last_response.header).not_to be_blank
          expect(last_response.header['Content-Length']).to eq 0.to_s
          expect(last_response.body).to be_blank
        end
      end

      context 'that is valid' do
        before do
          application = Twimock::Application.new
          application.save!
          user = Twimock::User.new(application_id: application.id)
          user.save!
          @request_token = Twimock::RequestToken.new(application_id: application.id)
          @request_token.save!
          uri = Addressable::URI.new
          uri.query_values = { "session[username_or_email]" => user.twitter_id,
                               "remember_me"                => "1",
                               "oauth_token"                => @request_token.string }
          @path = path + "?" + uri.query
        end

        it 'should return 302' do
          get @path, body, header
          
          expect(last_response.status).to eq 302
          expect(last_response.header).not_to be_blank
          expect(last_response.header['Content-Length']).to eq "0"
          query_string = ""
          uri = Addressable::URI.new
          uri.query_values = { "oauth_token"    => @request_token.string,
                               "oauth_verifier" => @request_token.verifier }
          location = Twimock::Config.callback_url + "?" + uri.query
          expect(last_response.header['Location']).to eq location
          expect(last_response.body).to eq ""
        end
      end
    end
  end
end
