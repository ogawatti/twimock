require 'spec_helper'
require 'rack/test'

describe Twimock::API::AccountVerifyCredentials do
  include TestApplicationHelper
  include Rack::Test::Methods

  let(:method) { 'GET' }
  let(:path)   { '/1.1/account/verify_credentials.json' }
  let(:authorization_regexp) { Regexp.new('OAuth oauth_consumer_key=\"(.*)\", oauth_nonce=\"(.*)\", oauth_signature=\"(.*)\", oauth_signature_method=\"(.*)\", oauth_timestamp=\"(.*)\", oauth_token=\"(.*)\", oauth_version=\"(.*)\".*') }
  let(:body) { "" }
  let(:header) { {} }
  let(:test_app) { TestApplicationHelper::TestRackApplication.new }
  let(:app)      { Twimock::API::AccountVerifyCredentials.new(test_app) }

  describe '::METHOD' do
    subject { Twimock::API::AccountVerifyCredentials::METHOD }
    it { is_expected.to eq method }
  end

  describe '::PATH' do
    subject { Twimock::API::AccountVerifyCredentials::PATH }
    it { is_expected.to eq path }
  end

  describe '::AUTHORIZATION_REGEXP' do
    subject { Twimock::API::AccountVerifyCredentials::AUTHORIZATION_REGEXP }
    it { is_expected.to eq authorization_regexp }
  end

  shared_context '401 Unauthorizaed Account Verify Credentials', assert: :UnauthorizedAccountVerifyCredentials do
    it 'should return 401 Unauthorized' do
      get path, body, header

      expect(last_response.status).to eq 401
      expect(last_response.header).not_to be_blank
      expect(last_response.header['Content-Length']).to eq 0.to_s
      expect(last_response.body).to be_blank
    end
  end

  describe "GET '/1.1/account/verify_credentials.json'" do
    context 'with authorization header' do
      let(:db_name) { ".test" }
      let(:database) { Twimock::Database.new }
      let(:header) { { "authorization" => @authorization } }

      before { stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name) }
      after  { database.drop }

      context 'that is correct' do
        before do 
          stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name)
          app = Twimock::Application.new
          app.save!
          @user = Twimock::User.new(application_id: app.id)
          @user.save!
          @authorization = [ "OAuth oauth_consumer_key=\"#{app.api_key}\", oauth_nonce=\"Tc400qacfXAoixQ5Tk9yeFjdBBrDb7U3Sdgs7WA8cM\", oauth_signature=\"I7LRwjN%2FRvqp53kia2fGCg%2FrBHo%3D\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"1422273906\", oauth_token=\"#{@user.access_token}\", oauth_version=\"1.0\"" ]
        end

        it 'should return 200 OK' do
          get '/1.1/account/verify_credentials.json', body, header

          expect(last_response.status).to eq 200
          expect(last_response.header).not_to be_blank
          expect(last_response.header['Content-Length']).to eq last_response.body.bytesize.to_s
          expect(last_response.body).not_to be_blank

          # bodyの検証
          parsed_body = JSON.parse(last_response.body)
          expect(parsed_body['id']).to eq @user.id
          expect(parsed_body['id_str']).to eq @user.id.to_s
          expect(parsed_body['name']).to eq @user.name
          expect(parsed_body['created_at']).to eq @user.created_at.to_s
        end
      end

      context 'that is incorrect format', assert: :UnauthorizedAccountVerifyCredentials do
        before { @authorization = ["OAuth consumer_key=\"test_consumer_key\""] }
      end

      context 'but consumer_key is invalid', assert: :UnauthorizedAccountVerifyCredentials do
        before do
          app = Twimock::Application.new
          @authorization = [ "OAuth oauth_consumer_key=\"#{app.api_key}\", oauth_nonce=\"Tc400qacfXAoixQ5Tk9yeFjdBBrDb7U3Sdgs7WA8cM\", oauth_signature=\"I7LRwjN%2FRvqp53kia2fGCg%2FrBHo%3D\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"1422273906\", oauth_token=\"288818073-pHvCoXJtYnUeHaIpjNptFW53YAAgtpyDhkmcHPqy\", oauth_version=\"1.0\"" ]
        end
      end
    end

    context 'without authorization header', assert: :UnauthorizedAccountVerifyCredentials do
    end
  end

  describe "GET '/test'" do
    it 'should return 200 OK' do
      get '/test'

      expect(last_response.status).to eq 200
      expect(last_response.body).to be_blank
      expect(last_response.header).to be_blank
    end
  end

  describe "POST '/1.1/account/verify_credentials.json'" do
    it 'should return 200 OK' do
      post '/1.1/account/verify_credentials.json'

      expect(last_response.status).to eq 200
      expect(last_response.body).to be_blank
      expect(last_response.header).to be_blank
    end
  end
end
