require 'spec_helper'

describe Twimock do
  let(:version) { '0.0.1' }
  let(:db_name) { '.test' }
  let(:provider) { 'twitter' }

  it 'should have a version number' do
    expect(Twimock::VERSION).to eq version
  end

  describe '.auth_hash' do
    context 'without argument' do
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

  describe Twimock::Api do
    let(:api_host_name) { 'api.twitter.com' }
    let(:http_app) { ShamRack.application_for(api_host_name) }
    let(:https_app) { ShamRack.application_for(api_host_name, Net::HTTP.https_default_port) }

    describe '.on' do
      before { Twimock::Api.on }

      it 'should have ShamRack applicatiosn' do
        expect(http_app).not_to be_nil
        expect(https_app).not_to be_nil
      end

      it 'should return 200 OK' do
        [ Net::HTTP.default_port, Net::HTTP.https_default_port ].each do |port|
          res = Net::HTTP.new(api_host_name, port).get('/')
          expect(res.code).to eq '200'
          expect(res.body).to eq 'Hello, world!'
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
end
