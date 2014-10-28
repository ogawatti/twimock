require 'spec_helper'

describe Twimock do
  let(:version) { "0.0.1" }

  it 'should have a version number' do
    expect(Twimock::VERSION).to eq version
  end
end
