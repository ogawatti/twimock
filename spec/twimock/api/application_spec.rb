require 'spec_helper'

describe Twimock::API::OAuthRequestToken do
  let
  let(:method) { 'POST' }
  let(:path)   { '/oauth/request_token' }
  let(:test_app) { TestApplicationHelper::TestRackApplication.new }
  let(:app)      { Twimock::API::OAuthRequestToken.new(test_app) }

  describe '::METHOD' do
    subject { Twimock::API::OAuthRequestToken::METHOD }
    it { is_expected.to eq method }
  end
end
