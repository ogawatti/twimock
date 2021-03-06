require 'spec_helper'

describe Twimock::User do
  include TableHelper

  let(:db_name)        { ".test" }
  let(:table_name)     { :users }
  let(:column_names)   { [ :id,
                           :name,
                           :twitter_id,
                           :email,
                           :password,
                           :created_at ] }
  let(:children)       { [ Twimock::AccessToken, Twimock::RequestToken ] }
  let(:info_keys)      { [ :id, :name, :created_at ] }

  let(:id)                  { 1 }
  let(:name)                { "test user" }
  let(:twitter_id)          { "test_user" }
  let(:email)               { "test@example.com" }
  let(:password)            { "testpass" }
  let(:created_at)          { Time.now }
  let(:options)             { { id:                  id, 
                                name:                name,
                                twitter_id:          twitter_id,
                                email:               email,
                                password:            password,
                                created_at:          created_at } }
  let(:access_token_string_size) { 50 }
  let(:access_token_secret_size) { 45 }

  after { remove_dynamically_defined_all_method }

  describe '::TABLE_NAME' do
    subject { Twimock::User::TABLE_NAME }
    it { is_expected.to eq table_name }
  end

  describe '::COLUMN_NAMES' do
    subject { Twimock::User::COLUMN_NAMES }
    it { is_expected.to eq column_names }
  end

  describe '::CHILDREN' do
    subject { Twimock::User::CHILDREN }
    it { is_expected.to eq children }
  end

  describe '::INFO_KEYS' do
    subject { Twimock::User::INFO_KEYS }
    it { is_expected.to eq info_keys }
  end

  describe '#initialize' do
    context 'without option' do
      subject { Twimock::User.new }
      it { is_expected.to be_kind_of Twimock::User }

      describe '.id' do
        subject { Twimock::User.new.id }
        it { is_expected.to be > 0 }
        it { is_expected.to be < 10000000000 }
      end

      describe '.name' do
        subject { Twimock::User.new.name }
        it { is_expected.to be_kind_of String }

        describe '.size' do
          subject { Twimock::User.new.name.size }
          it { is_expected.to be > 0 }
        end
      end

      describe '.twitter_id' do
        before { @user = Twimock::User.new }
        subject { @user.twitter_id }
        it { is_expected.to be_kind_of String }

        describe '.size' do
          subject { @user.twitter_id.size }
          it { is_expected.to eq @user.name.size }
        end
      end

      describe '.email' do
        before { @user = Twimock::User.new }
        subject { @user.email }
        it { is_expected.to be_kind_of String }

        describe '.size' do
          subject { @user.email.size }
          it { is_expected.to be > 0 }
        end
      end

      describe '.password' do
        subject { Twimock::User.new.password }
        it { is_expected.to be_kind_of String }

        describe '.size' do
          subject { Twimock::User.new.password.size }
          it { is_expected.to be_between(8, 16) }
        end
      end

      describe '.created_at' do
        subject { Twimock::User.new.created_at }
        it { is_expected.to be_nil }
      end
    end

    context 'with id option but it is not integer' do
      before { @opts = { id: "test_id" } }
      subject { Twimock::User.new(@opts) }
      it { is_expected.to be_kind_of Twimock::User }

      describe '.id' do
        subject { Twimock::User.new(@opts).id }
        it { is_expected.to be > 0 }
        it { is_expected.to be < 10000000000 }
      end
    end

    context 'with identifier option' do
      before { @opts = { identifier: 1000000000 } }
      subject { Twimock::User.new(@opts) }
      it { is_expected.to be_kind_of Twimock::User }

      describe '.id' do
        subject { Twimock::User.new(@opts).id }
        it { is_expected.to eq @opts[:identifier] }
      end

      describe '.identifier' do
        subject { Twimock::User.new(@opts).identifier }
        it { is_expected.to eq @opts[:identifier] }
      end
    end

    context 'with all options' do
      subject { Twimock::User.new(options) }
      it { is_expected.to be_kind_of Twimock::User }

      context 'then attributes' do
        it 'should set specified value by option' do
          column_names.each do |column_name|
            value = Twimock::User.new(options).send(column_name)
            expect(value).to eq options[column_name]
          end
        end
      end
    end
  end

  describe '#info' do
    let(:user) { Twimock::User.new }
    let(:info) { user.info }
    let(:info_keys) { [:id, :id_str, :name, :created_at] }

    it 'should return user information' do
      expect(info).to be_kind_of Hashie::Mash
      Twimock::User::INFO_KEYS.each { |key| expect(info.send(key)).to eq user.send(key) }
      expect(info.id_str).to eq user.id.to_s
    end
  end

  describe '#generate_access_token' do
    before do
      stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name)
      @database = Twimock::Database.new
    end
    after { @database.drop }

    context 'without application_id' do
      context 'when user does not save yet' do
        before do 
          @user = Twimock::User.new
          @access_token = @user.generate_access_token
        end

        it 'should return not saved Twimock::AccessToken instance' do
          expect(@access_token).to be_instance_of Twimock::AccessToken
          expect(@access_token.persisted?).to eq false
          expect(@access_token.id).to be_nil
          expect(@access_token.user_id).to be_nil
          expect(@access_token.application_id).to be_nil
          expect(@access_token.string).not_to be_nil
          expect(@access_token.string.size).to eq access_token_string_size
          expect(@access_token.secret).not_to be_nil
          expect(@access_token.secret.size).to eq access_token_secret_size
        end
      end

      context 'when user has saved' do
        before do 
          @user = Twimock::User.new
          @user.save!
          @access_token = @user.generate_access_token
        end

        it 'should return saved Twimock::AccessToken instance' do
          expect(@access_token).to be_instance_of Twimock::AccessToken
          expect(@access_token.persisted?).to eq true
          expect(@access_token.id).not_to be_nil
          expect(@access_token.user_id).to eq @user.id
          expect(@access_token.application_id).to be_nil
          expect(@access_token.string).not_to be_nil
          expect(@access_token.string.size).to eq access_token_string_size
          expect(@access_token.secret).not_to be_nil
          expect(@access_token.secret.size).to eq access_token_secret_size
        end
      end
    end

    context 'with application_id' do
      context 'when specified application does not exist' do
        let(:user) { Twimock::User.new }
        let(:application_id) { 100000 }
        subject { lambda { user.generate_access_token(application_id) } }
        it { is_expected.to raise_error Twimock::Errors::ApplicationNotFound }
      end

      context 'when specified application exist' do
        before do
          @application = Twimock::Application.new
          @application.save!
        end

        context 'and user does not saved' do
          before do 
            @user = Twimock::User.new
            @access_token = @user.generate_access_token(@application.id)
          end

          it 'should return not saved Twimock::AccessToken instance' do
            expect(@access_token).to be_instance_of Twimock::AccessToken
            expect(@access_token.persisted?).to eq false
            expect(@access_token.id).to be_nil
            expect(@access_token.user_id).to be_nil
            expect(@access_token.application_id).to eq @application.id
            expect(@access_token.string).not_to be_nil
            expect(@access_token.string.size).to eq access_token_string_size
            expect(@access_token.secret).not_to be_nil
            expect(@access_token.secret.size).to eq access_token_secret_size
          end
        end

        context 'and user has saved' do
          before do 
            @user = Twimock::User.new
            @user.save!
            @access_token = @user.generate_access_token(@application.id)
          end

          it 'should return saved Twimock::AccessToken instance' do
            expect(@access_token).to be_instance_of Twimock::AccessToken
            expect(@access_token.persisted?).to eq true
            expect(@access_token.id).not_to be_nil
            expect(@access_token.user_id).to eq @user.id
            expect(@access_token.application_id).to eq @application.id
            expect(@access_token.string).not_to be_nil
            expect(@access_token.string.size).to eq access_token_string_size
            expect(@access_token.secret).not_to be_nil
            expect(@access_token.secret.size).to eq access_token_secret_size
          end
        end
      end
    end
  end
end
