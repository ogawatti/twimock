require 'spec_helper'
require 'rack/test'

describe Twimock::API::OAuth::Authenticate do
  include TestApplicationHelper
  include APISpecHelper
  include Rack::Test::Methods

  let(:method)   { 'GET' }
  let(:path)     { '/oauth/authenticate' }
  let(:body)     { "" }
  let(:header)   { {} }
  let(:test_app) { TestApplicationHelper::TestRackApplication.new }
  let(:app)      { Twimock::API::OAuth::Authenticate.new(test_app) }

  describe '::METHOD' do
    subject { Twimock::API::OAuth::Authenticate::METHOD }
    it { is_expected.to eq method }
  end

  describe '::PATH' do
    subject { Twimock::API::OAuth::Authenticate::PATH }
    it { is_expected.to eq path }
  end

  describe "GET '/oauth/authenticate'" do
    before { stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name) }
    after  { database.drop }

    let(:db_name)  { ".test" }
    let(:database) { Twimock::Database.new }

    context 'without oauth token' do
      before { get path, body, header }
      it_behaves_like 'API 401 UnAuthorized'
    end

    context 'with invalid oauth token' do
      before do
        request_token = Twimock::RequestToken.new
        query_string = "request_token=#{request_token.string}"
        get path + "?" + query_string , body, header
      end
      it_behaves_like 'API 401 UnAuthorized'
    end

    context 'with valid oauth token' do
      before do
        application = Twimock::Application.new
        application.save!
        @request_token = Twimock::RequestToken.new(application_id: application.id)
        @request_token.save!
        @path = path + "?oauth_token=#{@request_token.string}"
        get @path, body, header
      end

      it 'should return 200 OK' do
        view = Twimock::API::OAuth::Authenticate.view(@request_token.string)
        expect(last_response.status).to eq 200
        expect(last_response.header).not_to be_blank
        expect(last_response.header['Content-Length']).to eq last_response.body.bytesize.to_s
        expect(last_response.body).to eq view
        expect(last_response.body).to be_include(@request_token.string)
        expect(last_response.body).to be_include(Twimock::API::Intent::Sessions::PATH)
      end
    end

    context 'raise error that is not catched' do
      before do
        allow(Twimock::API::OAuth::Authenticate).to receive(:view){ raise }
        application = Twimock::Application.new
        application.save!
        @request_token = Twimock::RequestToken.new(application_id: application.id)
        @request_token.save!
        @path = path + "?oauth_token=#{@request_token.string}"
        get @path, body, header
      end
      it_behaves_like 'API 500 InternalServerError'
    end
  end

  describe "GET '/test'" do
    before { get '/test' }
    it_behaves_like 'TestRackApplication 200 OK'
  end

  describe "POST '/oauth/authenticate'" do
    before { post '/oauth/authenticate' }
    it_behaves_like 'TestRackApplication 200 OK'
  end

  describe "GET '/oauth/authentication'" do
    before { get '/oauth/authentication' }
    it_behaves_like 'TestRackApplication 200 OK'
  end
end
