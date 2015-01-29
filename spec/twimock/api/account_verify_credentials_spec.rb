require 'spec_helper'
require 'rack/test'

describe Twimock::API::AccountVerifyCredentials do
  include TestApplicationHelper
  include Rack::Test::Methods

  let(:method) { 'GET' }
  let(:path)   { '/1.1/account/verify_credentials.json' }
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

  describe "GET '/1.1/account/verify_credentials.json'" do
    let(:db_name) { ".test" }
    let(:database) { Twimock::Database.new }
    let(:body) { "" }
    let(:header) { { "authorization" => @authorization } }

    before do 
      stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name)
      app = Twimock::Application.new
      app.save!
      user = Twimock::User.new(application_id: app.id)
      user.save!
      @authorization = [ "OAuth oauth_consumer_key=\"#{app.api_key}\", oauth_nonce=\"Tc400qacfXAoixQ5Tk9yeFjdBBrDb7U3Sdgs7WA8cM\", oauth_signature=\"I7LRwjN%2FRvqp53kia2fGCg%2FrBHo%3D\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"1422273906\", oauth_token=\"#{user.access_token}\"" ]
    end
    after  { database.drop }

    it 'should return 200 OK' do
      get '/1.1/account/verify_credentials.json', body, header

      expect(last_response.status).to eq 200
      expect(last_response.header).not_to be_blank
      expect(last_response.header['Content-Length']).to eq last_response.body.bytesize.to_s
      expect(last_response.body).not_to be_blank
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
