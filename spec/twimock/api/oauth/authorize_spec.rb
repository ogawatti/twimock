require 'spec_helper'
require 'rack/test'

describe Twimock::API::OAuth::Authorize do
  include TestApplicationHelper
  include APISpecHelper
  include Rack::Test::Methods

  let(:method)   { 'GET' }
  let(:path)     { '/oauth/authorize' }
  let(:body)     { "" }
  let(:header)   { {} }
  let(:test_app) { TestApplicationHelper::TestRackApplication.new }
  let(:app)      { Twimock::API::OAuth::Authorize.new(test_app) }

  describe '::METHOD' do
    subject { Twimock::API::OAuth::Authorize::METHOD }
    it { is_expected.to eq method }
  end

  describe '::PATH' do
    subject { Twimock::API::OAuth::Authorize::PATH }
    it { is_expected.to eq path }
  end

  describe "POST '/oauth/authorize'" do
    before { stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name) }
    after  { database.drop }

    let(:db_name)  { ".test" }
    let(:database) { Twimock::Database.new }

    context 'with invalid oauth token' do
      before do
        @request_token = Twimock::RequestToken.new
        get path + "?oauth_token=#{@request_token.string}", body, header
      end
      it_behaves_like 'API 401 UnAuthorized'
    end

    context 'with only valid oauth token' do
      before do
        application   = Twimock::Application.new
        application.save!
        @request_token = Twimock::RequestToken.new(application_id: application.id)
        @request_token.save!
        get path + "?oauth_token=#{@request_token.string}", body, header
      end

      it 'should return 200 OK' do
        expect(last_response.status).to eq 200
        expect(last_response.header['Content-Length']).to eq last_response.body.bytesize.to_s
        expect(last_response.body).to be_blank
      end
    end

    context 'with valid oauth token and cancel' do
      before do
        application   = Twimock::Application.new
        application.save!
        @request_token = Twimock::RequestToken.new(application_id: application.id)
        @request_token.save!
        get path + "?oauth_token=#{@request_token.string}&cancel=true", body, header
      end

      it 'should return 200 OK with Cancelled view' do
        view = Twimock::API::OAuth::Cancelled.view(@request_token.string)
        expect(last_response.status).to eq 200
        expect(last_response.header['Content-Length']).to eq last_response.body.bytesize.to_s
        expect(last_response.body).to eq view
      end
    end

    context 'when raise unexpected error anywhere' do
      before do
        allow_any_instance_of(Rack::Request).to receive(:params) { raise }
        application   = Twimock::Application.new
        application.save!
        @request_token = Twimock::RequestToken.new(application_id: application.id)
        @request_token.save!
        get path + "?oauth_token=#{@request_token.string}", body, header
      end
      it_behaves_like 'API 500 InternalServerError'
    end
  end

  describe "get '/test'" do
    before { get '/test' }
    it_behaves_like 'TestRackApplication 200 OK'
  end

  describe "POST '/oauth/authorize'" do
    before { post '/oauth/authorize' }
    it_behaves_like 'TestRackApplication 200 OK'
  end

  describe "POST '/oauth/authorization'" do
    before { get '/oauth/authorization' }
    it_behaves_like 'TestRackApplication 200 OK'
  end
end
