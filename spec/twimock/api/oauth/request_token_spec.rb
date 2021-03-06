require 'spec_helper'
require 'rack/test'

describe Twimock::API::OAuth::RequestToken do
  include TestApplicationHelper
  include Rack::Test::Methods

  let(:method)   { 'POST' }
  let(:path)     { '/oauth/request_token' }
  let(:authorization_regexp) { Regexp.new('OAuth oauth_callback=\"(.*)\", oauth_consumer_key=\"(.*)\", oauth_nonce=\"(.*)\", oauth_signature=\"(.*)\", oauth_signature_method=\"(.*)\", oauth_timestamp=\"(.*)\", oauth_version=\"(.*)\".*') }
  let(:body)     { "" }
  let(:header)   { {} }
  let(:test_app) { TestApplicationHelper::TestRackApplication.new }
  let(:app)      { Twimock::API::OAuth::RequestToken.new(test_app) }

  describe '::METHOD' do
    subject { Twimock::API::OAuth::RequestToken::METHOD }
    it { is_expected.to eq method }
  end

  describe '::PATH' do
    subject { Twimock::API::OAuth::RequestToken::PATH }
    it { is_expected.to eq path }
  end

  describe '::AUTHORIZATION_REGEXP' do
    subject { Twimock::API::OAuth::RequestToken::AUTHORIZATION_REGEXP }
    it { is_expected.to eq authorization_regexp }
  end

  describe "POST '/oauth/request_token'" do
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
          @authorization = ["OAuth oauth_callback=\"http%3A%2F%2Fhiddeste.local.jp%3A3456%2Fusers%2Fauth%2Ftwitter%2Fcallback\", oauth_consumer_key=\"#{app.api_key}\", oauth_nonce=\"gop2czKq1IebHEvEIo2qE64Hwp5SRWxLgilYAKqrWE\", oauth_signature=\"FVn4chN1TbLPDDsLb%2FqG%2FU99biA%3D\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"1422273831\", oauth_version=\"1.0\""]
        end

        it 'should return 200 OK' do
          post path, body, header
          expect(last_response.status).to eq 200
          expect(last_response.header).not_to be_blank
          expect(last_response.header['Content-Length']).to eq last_response.body.bytesize.to_s
          expect(last_response.body).not_to be_blank

          index = last_response.body =~ /^oauth_token=(.*)&oauth_token_secret=(.*)&oauth_callback_confirmed=(.*)$/
          expect(index).to eq 0
          oauth_token = $1
          oauth_secret = $2
          oauth_callback_confirmed = $3

          token = Twimock::RequestToken.find_by_string(oauth_token)
          expect(token).not_to be_nil
          expect(token.secret).to eq oauth_secret
          expect(oauth_callback_confirmed).to eq true.to_s
        end
      end

      context 'that is incorrect format' do
        before do
          @authorization = ["OAuth consumer_key=\"test_consumer_key\""]
          post path, body, header
        end
        it_behaves_like "API 401 UnAuthorized"
      end

      context 'but consumer_key is invalid' do
        before do
          app = Twimock::Application.new
          @authorization = ["OAuth oauth_callback=\"http%3A%2F%2Fhiddeste.local.jp%3A3456%2Fusers%2Fauth%2Ftwitter%2Fcallback\", oauth_consumer_key=\"#{app.api_key}\", oauth_nonce=\"gop2czKq1IebHEvEIo2qE64Hwp5SRWxLgilYAKqrWE\", oauth_signature=\"FVn4chN1TbLPDDsLb%2FqG%2FU99biA%3D\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"1422273831\", oauth_version=\"1.0\""]
          post path, body, header
        end
        it_behaves_like "API 401 UnAuthorized"
      end

      context 'raise error that is not catched' do
        before do
          allow(Twimock::Application).to receive(:find_by_api_key){ raise }
          app = Twimock::Application.new
          app.save!
          @authorization = ["OAuth oauth_callback=\"http%3A%2F%2Fhiddeste.local.jp%3A3456%2Fusers%2Fauth%2Ftwitter%2Fcallback\", oauth_consumer_key=\"#{app.api_key}\", oauth_nonce=\"gop2czKq1IebHEvEIo2qE64Hwp5SRWxLgilYAKqrWE\", oauth_signature=\"FVn4chN1TbLPDDsLb%2FqG%2FU99biA%3D\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"1422273831\", oauth_version=\"1.0\""]
          post path, body, header
        end
        it_behaves_like 'API 500 InternalServerError'
      end

      context 'without authorization header'do
        before { post path, body, header }
        it_behaves_like "API 401 UnAuthorized"
      end
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
