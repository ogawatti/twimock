require 'spec_helper'

describe Twimock::AuthHash do
  it 'should inherit a OmniAuth::AuthHash class' do
    expect(Twimock::AuthHash.ancestors).to include OmniAuth::AuthHash
  end
end
