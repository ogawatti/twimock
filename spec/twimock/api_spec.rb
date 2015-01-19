require 'spec_helper'

describe Twimock::Api do
  let(:host_name) { 'api.twitter.com' }
  let(:http_app) { ShamRack.application_for(host_name) }
  let(:https_app) { ShamRack.application_for(host_name, Net::HTTP.https_default_port) }

  describe '.on' do
    before { Twimock::Api.on }

    it 'should have ShamRack applicatiosn' do
      expect(http_app).not_to be_nil
      expect(https_app).not_to be_nil
    end

    context 'when path is registered' do
      it 'should return 200 OK' do
        [ Net::HTTP.default_port, Net::HTTP.https_default_port ].each do |port|
          res = Net::HTTP.new(host_name, port).get('/')
          expect(res.code).to eq '200'
          expect(res.body).to eq 'Hello, world!'
        end
      end
    end

    context 'when path is registered' do
      it 'should return 404 Not Found' do
        [ Net::HTTP.default_port, Net::HTTP.https_default_port ].each do |port|
          res = Net::HTTP.new(host_name, port).get('/hoge')
          expect(res.code).to eq '404'
          expect(res.body).to eq 'Not Found'
        end
      end
    end
  end

  describe '.off' do
    before { Twimock::Api.off }

    it 'should not have ShamRack application' do
      expect(http_app).to be_nil
      expect(https_app).to be_nil
    end
  end

  describe '.on?' do
    subject { Twimock::Api.on? }

    context 'when Twimock on' do
      before { Twimock::Api.on }
      it { is_expected.to be_truthy }
    end

    context 'when Twimock off' do
      before { Twimock::Api.off }
      it { is_expected.to be_falsey }
    end
  end
end
