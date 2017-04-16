require 'spec_helper'

describe Twimock::Net::HTTP do
  let(:path) { '/' }

  before do
    @http = Object.new
    @http.extend(Twimock::Net::HTTP)
  end

  describe '#get' do
    context 'without argument' do
      it { expect( lambda { @http.get } ).to raise_error ArgumentError }
    end

    context 'with request path' do
      it { expect(@http.get(:path)).to be_instance_of Twimock::Net::HTTPOK }

      describe '#http_version' do
        it { expect(@http.get(:path).http_version).to be_nil }
      end

      describe '#code' do
        it { expect(@http.get(:path).code).to eq "200" }
      end

      describe '#message' do
        it { expect(@http.get(:path).message).to eq "OK" }
      end

      describe '#body' do
        it { expect(@http.get(:path).body).to be_nil }
      end
    end
  end
end
