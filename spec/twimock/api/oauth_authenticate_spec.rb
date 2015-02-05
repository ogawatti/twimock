require 'spec_helper'
require 'rack/test'

describe Twimock::API::OAuthAuthenticate do
  include TestApplicationHelper
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
          request_token = Twimock::RequestToken.new(application_id: application.id)
          request_token.save!
          @path = path + "?oauth_token=" + request_token.string
        end

        it 'should return 200' do
          get @path, body, header
          
          view = Twimock::API::OAuthAuthenticate.view
          content_length = view.bytesize.to_s

          expect(last_response.status).to eq 200
          expect(last_response.header).not_to be_blank
          expect(last_response.header['Content-Length']).to eq content_length
          expect(last_response.body).to eq view
        end
      end
    end
  end
end
