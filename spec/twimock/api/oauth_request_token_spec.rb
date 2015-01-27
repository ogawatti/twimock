require 'spec_helper'
require 'rack/test'

describe Twimock::API::OAuthRequestToken do
  include TestApplicationHelper
  include Rack::Test::Methods

  let(:method) { 'POST' }
  let(:path)   { '/oauth/request_token' }
  let(:test_app) { TestApplicationHelper::TestRackApplication.new }
  let(:app)      { Twimock::API::OAuthRequestToken.new(test_app) }

  describe '::METHOD' do
    subject { Twimock::API::OAuthRequestToken::METHOD }
    it { is_expected.to eq method }
  end

  describe '::PATH' do
    subject { Twimock::API::OAuthRequestToken::PATH }
    it { is_expected.to eq path }
  end

  describe "POST '/oauth/request_token'" do
    before do
      stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name)

      @app = Twimock::Application.new
      @app.save!
    end
    after { database.drop }

    let(:db_name) { ".test" }
    let(:database) { Twimock::Database.new }

    let (:body) { "" }
    let (:header)  { { "authorization" => authorization } }
    let (:authorization) { ["OAuth oauth_callback=\"http%3A%2F%2Fhiddeste.local.jp%3A3456%2Fusers%2Fauth%2Ftwitter%2Fcallback\", oauth_consumer_key=\"#{@app.api_key}\", oauth_nonce=\"gop2czKq1IebHEvEIo2qE64Hwp5SRWxLgilYAKqrWE\", oauth_signature=\"FVn4chN1TbLPDDsLb%2FqG%2FU99biA%3D\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"1422273831\", oauth_version=\"1.0\""] }

    it 'should return 200 OK' do
      post path, body, header

      status = last_response.status
      header = last_response.header
      body   = last_response.body

      expect(status).to eq 200

      expect(header).not_to be_blank
      expect(header['Content-Length']).to eq body.bytesize.to_s

      expect(body).not_to be_blank
      index = body =~ /^oauth_token=(.*)&oauth_token_secret=(.*)&oauth_callback_confirmed=(.*)$/
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
