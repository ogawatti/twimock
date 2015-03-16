require 'spec_helper'

describe Twimock do
  let(:version) { '0.0.1' }
  let(:db_name) { '.test' }
  let(:provider) { 'twitter' }

  it 'should have a version number' do
    expect(Twimock::VERSION).to eq version
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
        @access_token = @user.generate_access_token
      end 
      
      context 'that is incorrect' do
        it 'should return empty AuthHash' do
          auth_hash = Twimock.auth_hash(@access_token.string)
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
        @user = Twimock::User.create!
        @access_token = @user.generate_access_token
      end
      after { @database.drop }
      
      context 'that is correct' do
        it 'should return AuthHash with some keys and value' do
          auth_hash = Twimock.auth_hash(@access_token.string)
          expect(auth_hash).to be_kind_of Twimock::AuthHash
          expect(auth_hash).not_to be_empty
          expect(auth_hash.provider).to eq provider
          expect(auth_hash.uid).to eq @user.id
          [ auth_hash.info, auth_hash.credentials,
            auth_hash.extra, auth_hash.extra.raw_info ].each do |value|
            expect(value).to be_kind_of Hash
          end
          expect(auth_hash.info.name).to eq @user.name
          expect(auth_hash.credentials.token).to eq @access_token.string
          expect(auth_hash.credentials.expires_at).to be > Time.now
          expect(auth_hash.extra.raw_info.id).to eq @user.id
          expect(auth_hash.extra.raw_info.name).to eq @user.name
        end
      end
    end
  end
end
