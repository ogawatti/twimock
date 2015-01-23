require 'spec_helper'

describe Twimock::API do
  let(:hostname)    { "api.twitter.com" }
  let(:port)        { 443 }
  let(:middlewares) { [ Twimock::API::OAuthAccessToken, 
                        Twimock::API::OAuthRequestToken, 
                        Twimock::API::AccountVerifyCredentials ] }


  describe '::HOSTNAME' do
    subject { Twimock::API::HOSTNAME }
    it { is_expected.to eq hostname }
  end

  describe '::PORT' do
    subject { Twimock::API::PORT }
    it { is_expected.to eq port }
  end

  describe '::MIDDLEWARES' do
    subject { Twimock::API::MIDDLEWARES }
    it { is_expected.to eq middlewares }
  end

  describe '.on?' do
    context 'when api mock is on' do
      before { expect(ShamRack).to receive(:application_for).with(hostname, port) { Object.new } }
      subject { Twimock::API.on? }
      it { is_expected.to eq true }
    end

    context 'when api mock is off' do
      before { expect(ShamRack).to receive(:application_for).with(hostname, port) { nil } }
      subject { Twimock::API.on? }
      it { is_expected.to eq false }
    end
  end

  describe '.on' do
    context 'when api mock is on' do
      before do
        expect(Twimock::API).to receive(:on?) { false }
        expect(ShamRack).to receive(:at)
      end
      subject { Twimock::API.on }
      it { is_expected.to eq true }
    end

    context 'when api mock is off' do
      before do
        expect(Twimock::API).to receive(:on?) { true }
      end
      subject { Twimock::API.on }
      it { is_expected.to eq true }
    end
  end

  describe '.off' do
    before { expect(ShamRack).to receive(:unmount_all) }
    subject { Twimock::API.off }
    it { is_expected.to eq true }
  end

  describe '.app' do
    subject { Twimock::API.app }
    it { is_expected.to be_instance_of middlewares.last }

    it 'should have middlewares and application as instance variable "app"' do
      mid3 = Twimock::API.app
      mid2 = mid3.instance_variable_get(:@app)
      mid1 = mid2.instance_variable_get(:@app)
      app  = mid1.instance_variable_get(:@app)

      expect(app.class).to eq Twimock::API::Application
      expect(middlewares).to be_include mid1.class
      expect(middlewares).to be_include mid2.class
      expect(middlewares).to be_include mid3.class
    end
  end
end
