require 'spec_helper'
require 'rack/test'

describe Twimock::API::Account::VerifyCredentials do
  include TestApplicationHelper
  include Rack::Test::Methods

  let(:method) { 'GET' }
  let(:path)   { '/1.1/account/verify_credentials.json' }
  let(:authorization_regexp) { Regexp.new('OAuth oauth_consumer_key=\"(.*)\", oauth_nonce=\"(.*)\", oauth_signature=\"(.*)\", oauth_signature_method=\"(.*)\", oauth_timestamp=\"(.*)\", oauth_token=\"(.*)\", oauth_version=\"(.*)\".*') }
  
  let(:oauth_consumer_key)     { Twimock::Application.new.api_key }
  let(:oauth_nonce)            { "Tc400qacfXAoixQ5Tk9yeFjdBBrDb7U3Sdgs7WA8cM" }
  let(:oauth_signature)        { "I7LRwjN%2FRvqp53kia2fGCg%2FrBHo%3D" }
  let(:oauth_signature_method) { "HMAC-SHA1" }
  let(:oauth_timestamp)        { "1422273906" }
  let(:oauth_token)            { Twimock::AccessToken.string }
  let(:oauth_version)          { "1.0" }
  let(:authorization_header)   { [ "OAuth oauth_consumer_key=\"#{oauth_consumer_key}\", oauth_nonce=\"#{oauth_nonce}\", oauth_signature=\"#{oauth_signature}\", oauth_signature_method=\"#{oauth_signature_method}\", oauth_timestamp=\"#{oauth_timestamp}\", oauth_token=\"#{oauth_token}\", oauth_version=\"#{oauth_version}\"" ] }

  let(:body) { "" }
  let(:header) { {} }
  let(:test_app) { TestApplicationHelper::TestRackApplication.new }
  let(:app)      { Twimock::API::Account::VerifyCredentials.new(test_app) }

  describe '::METHOD' do
    subject { Twimock::API::Account::VerifyCredentials::METHOD }
    it { is_expected.to eq method }
  end

  describe '::PATH' do
    subject { Twimock::API::Account::VerifyCredentials::PATH }
    it { is_expected.to eq path }
  end

  describe '::AUTHORIZATION_REGEXP' do
    subject { Twimock::API::Account::VerifyCredentials::AUTHORIZATION_REGEXP }
    it { is_expected.to eq authorization_regexp }
  end

  describe "GET '/1.1/account/verify_credentials.json'" do
    context 'with authorization header' do
      let(:db_name) { ".test" }
      let(:database) { Twimock::Database.new }

      before { stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name) }
      after  { database.drop }

      context 'that is correct' do
        let(:header) { { "authorization" => authorization_header } }
        let(:oauth_consumer_key) { @application.api_key }
        let(:oauth_token)        { @access_token.string }

        before do 
          @application = Twimock::Application.new
          @application.save!
          @user = Twimock::User.new(application_id: @application.id)
          @user.save!
          @access_token = @user.generate_access_token(@application.id)
        end

        it 'should return 200 OK' do
          get path, body, header

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

      context 'that is incorrect format' do
        let(:consumer_key) { "test_consumer_key" }
        before { get path, body, header }
        it_behaves_like 'API 401 UnAuthorized'
      end

      context 'but consumer_key is invalid' do
        before { get path, body, header }
        it_behaves_like 'API 401 UnAuthorized'
      end
    end

    context 'without authorization header', assert: :UnauthorizedAccountVerifyCredentials do
      let(:authorization_header) { nil }
      before { get path, body, header }
      it_behaves_like 'API 401 UnAuthorized'
    end

    context 'raise error that is not catched' do
      let(:header) { { "authorization" => authorization_header } }
      let(:oauth_consumer_key) { @application.api_key }
      let(:oauth_token)        { @access_token.string }

      before do 
        @application = Twimock::Application.new
        @application.save!
        @user = Twimock::User.new(application_id: @application.id)
        @user.save!
        @access_token = @user.generate_access_token(@application.id)
        allow(Twimock::User).to receive(:find_by_id) { raise }
        get path, body, header
      end

      it_behaves_like 'API 500 InternalServerError'
    end
  end

  describe "GET '/test'" do
    before { get '/test' }
    it_behaves_like 'TestRackApplication 200 OK'
  end

  describe "POST '/1.1/account/verify_credentials.json'" do
    before { post '/1.1/account/verify_credentials.json' }
    it_behaves_like 'TestRackApplication 200 OK'
  end
end
