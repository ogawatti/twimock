require 'spec_helper'

describe Twimock::API::OAuth::Cancelled do
  let(:view_directory) { File.expand_path("../../../../../view", __FILE__) }
  let(:view_file_name) { "oauth_cancelled.html.erb" }

  describe '::VIEW_DIRECTORY' do
    subject { Twimock::API::OAuth::Cancelled::VIEW_DIRECTORY }
    it { is_expected.to eq view_directory }
  end

  describe '::VIEW_FILE_NAME' do
    subject { Twimock::API::OAuth::Cancelled::VIEW_FILE_NAME }
    it { is_expected.to eq view_file_name }
  end

  describe '.view' do
    context 'without oauth_token' do
      subject { lambda { Twimock::API::OAuth::Cancelled.view } }
      it { is_expected.to raise_error ArgumentError }
    end

    context 'with oauth token' do
      before { @oauth_token = Twimock::RequestToken.new.string }
      subject { Twimock::API::OAuth::Cancelled.view(@oauth_token) }
      it { is_expected.to be_include "<!DOCTYPE html>" }
      it { is_expected.to be_include 'body class="oauth cancelled' }
      it { is_expected.to be_include @oauth_token }
    end
  end
end
