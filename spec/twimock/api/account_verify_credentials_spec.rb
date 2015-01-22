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
    it 'should return 201 Created' do
      get '/1.1/account/verify_credentials.json'

      expect(last_response.status).to eq 200
      expect(last_response.body).to be_blank
      expect(last_response.header).to be_blank
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
