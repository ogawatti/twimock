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

  describe "GET '/oauth/authorize'" do
    before { get path, body, header }

    it 'should return 302 Redirected' do
      view = Twimock::API::OAuth::Authorize.view
      expect(last_response.status).to eq 302
      expect(last_response.header).not_to be_blank
      expect(last_response.header['Content-Length']).to eq last_response.body.bytesize.to_s
      expect(last_response.body).to eq view
    end
  end

  describe "GET '/test'" do
    before { get '/test' }
    it_behaves_like 'TestRackApplication 200 OK'
  end

  describe "POST '/oauth/authorize'" do
    before { post '/oauth/authorize' }
    it_behaves_like 'TestRackApplication 200 OK'
  end

  describe "GET '/oauth/authorization'" do
    before { get '/oauth/authorization' }
    it_behaves_like 'TestRackApplication 200 OK'
  end
end
