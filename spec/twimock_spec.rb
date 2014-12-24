require 'spec_helper'

describe Twimock do
  let(:version) { '0.0.1' }
  let(:db_name) { '.test' }
  let(:provider) { 'twitter' }

  let(:host) { 'exapmle.com' }
  let(:port) { 80 }
  let(:path) { '/' }

  it 'should have a version number' do
    expect(Twimock::VERSION).to eq version
  end

  it { expect(Twimock.class_variable_get(:@@enable)).to eq false }

  describe '.on?' do
    context 'by default' do
      subject { Twimock.on? }
      it { is_expected.to be false }
    end

    context 'after on' do
      before { Twimock.on }
      subject { Twimock.on? }
      it { is_expected.to be true }
      after { Twimock.off }
    end

    context 'after off' do
      before do
        Twimock.on
        Twimock.off
      end
      subject { Twimock.on? }
      it { is_expected.to be false }
    end
  end

  describe '.on' do
    after { Twimock.off }

    subject { Twimock.on }
    it { is_expected.to be true }

    context 'after on' do
      before { Twimock.on }
      it { expect(Twimock.class_variable_get(:@@enable)).to eq true }
    end

    context 'Net::HTTP' do
      before { Twimock.on }

      describe '.ancestors' do
        it { expect(Net::HTTP.ancestors).to be_include(Twimock::Net::HTTP) }
      end

      describe '.methods' do
        it { expect(Net::HTTP.instance_methods).to be_include(:get) }
        it { expect(Net::HTTP.instance_methods).to be_include(:__get) }
      end

      describe '#get' do
        before { expect_any_instance_of(Twimock::Net::HTTP).to receive(:get).once }
        subject { lambda { Net::HTTP.new(host, port).get(path) } }
        it { is_expected.not_to raise_error }
      end
    end
  end

  describe '.off' do
    before { Twimock.on }
    after  { Twimock.off }

    subject { Twimock.off }
    it { is_expected.to be true }

    context 'after off' do
      before do
        Twimock.on
        Twimock.off
      end
      it { expect(Twimock.class_variable_get(:@@enable)).to eq false }
    end

    context 'Net::HTTP' do
      describe '.ancestors' do
        it { expect(Net::HTTP.ancestors).to be_include(Twimock::Net::HTTP) }
      end

      describe '.methods' do
        before { Twimock.off }
        it { expect(Net::HTTP.instance_methods).to be_include(:get) }
        it { expect(Net::HTTP.instance_methods).not_to be_include(:__get) }
      end

      describe '#get' do
        before { expect_any_instance_of(::Net::HTTP).to receive(:get).once }
        subject { lambda { Net::HTTP.new(host, port).get(path) } }
        it { is_expected.not_to raise_error }
      end
    end
  end

  describe '.auth_hash' do
    context 'withou argument' do
      subject { Twimock.auth_hash }
      it { is_expected.to be_kind_of Twimock::AuthHash }
      it { is_expected.to be_empty }
    end 
    
    context 'with incorrect argument' do
      it 'should return empty hash' do
        [nil, false, true, 1, ""].each do |argument|
          value = Twimock.auth_hash(argument)
          expect(value).to be_kind_of Twimock::AuthHash
          expect(value).to be_empty
        end 
      end 
    end 
    
    context 'with incorrect access_token' do
      before do
        stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name)
        @database = Twimock::Database.new
        @user = Twimock::User.new
        @access_token = @user.access_token
      end 
      
      context 'that is incorrect' do
        it 'should return empty AuthHash' do
          auth_hash = Twimock.auth_hash(@access_token)
          expect(auth_hash).to be_kind_of Twimock::AuthHash
          expect(auth_hash).to be_empty
        end 
      end 
    end 

    context 'with access_token' do
      before do
        stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name)
        @database = Twimock::Database.new
        application = Twimock::Application.create!
        @user = Twimock::User.create!(application_id: application.id)
        @access_token = @user.access_token
      end
      after { @database.drop }
      
      context 'that is correct' do
        it 'should return AuthHash with some keys and value' do
          auth_hash = Twimock.auth_hash(@access_token)
          expect(auth_hash).to be_kind_of Twimock::AuthHash
          expect(auth_hash).not_to be_empty
          expect(auth_hash.provider).to eq provider
          expect(auth_hash.uid).to eq @user.id
          [ auth_hash.info, auth_hash.credentials,
            auth_hash.extra, auth_hash.extra.raw_info ].each do |value|
            expect(value).to be_kind_of Hash
          end
          expect(auth_hash.info.name).to eq @user.name
          expect(auth_hash.credentials.token).to eq @user.access_token
          expect(auth_hash.credentials.expires_at).to be > Time.now
          expect(auth_hash.extra.raw_info.id).to eq @user.id
          expect(auth_hash.extra.raw_info.name).to eq @user.name
        end
      end
    end
  end
end
