require 'spec_helper'

describe Twimock::AccessToken do
  include TableHelper

  let(:db_name)        { ".test" }
  let(:table_name)     { :access_tokens }
  let(:column_names)   { [ :id, :string, :secret, :application_id, :user_id, :created_at ] }

  let(:id)             { 1 }
  let(:string)         { "test_token" }
  let(:secret)         { "test_token_secret" }
  let(:application_id) { 1 }
  let(:user_id)        { 1 }
  let(:created_at)     { Time.now }
  let(:options)        { { id:             id, 
                           string:         string,
                           secret:         secret,
                           application_id: application_id,
                           user_id:        user_id,
                           created_at:     created_at } }

  after { remove_dynamically_defined_all_method }

  describe '::TABLE_NAME' do
    subject { Twimock::AccessToken::TABLE_NAME }
    it { is_expected.to eq table_name }
  end

  describe '::COLUMN_NAMES' do
    subject { Twimock::AccessToken::COLUMN_NAMES }
    it { is_expected.to eq column_names }
  end

  describe '#initialize' do
    context 'without option' do
      subject { Twimock::AccessToken.new }
      it { is_expected.to be_kind_of Twimock::AccessToken }

      describe '.id' do
        subject { Twimock::AccessToken.new.id }
        it { is_expected.to be_nil }
      end

      describe '.string' do
        subject { Twimock::AccessToken.new.string }
        it { is_expected.to be_kind_of String }

        describe '.size' do
          subject { Twimock::AccessToken.new.string.size }
          it { is_expected.to eq 50 }
        end
      end

      describe '.secret' do
        subject { Twimock::AccessToken.new.secret }
        it { is_expected.to be_kind_of String }

        describe '.size' do
          subject { Twimock::AccessToken.new.secret.size }
          it { is_expected.to eq 45 }
        end
      end

      describe '.user_id' do
        subject { Twimock::AccessToken.new.user_id }
        it { is_expected.to be_nil }
      end

      describe '.application_id' do
        subject { Twimock::AccessToken.new.application_id }
        it { is_expected.to be_nil }
      end

      describe '.created_at' do
        subject { Twimock::AccessToken.new.created_at }
        it { is_expected.to be_nil }
      end
    end

    context 'with id option but it is not integer' do
      before { @opts = { id: "test_id" } }
      subject { Twimock::AccessToken.new(@opts) }
      it { is_expected.to be_kind_of Twimock::AccessToken }

      describe '.id' do
        subject { Twimock::AccessToken.new(@opts).id }
        it { is_expected.to be_nil }
      end
    end

    context 'with user_id option but it is not integer' do
      before { @opts = { user_id: "test_id" } }
      subject { Twimock::AccessToken.new(@opts) }
      it { is_expected.to be_kind_of Twimock::AccessToken }

      describe '.user_id' do
        subject { Twimock::AccessToken.new(@opts).user_id }
        it { is_expected.to be_nil }
      end
    end

    context 'with application_id option but it is not integer' do
      before { @opts = { application_id: "test_id" } }
      subject { Twimock::AccessToken.new(@opts) }
      it { is_expected.to be_kind_of Twimock::AccessToken }

      describe '.application_id' do
        subject { Twimock::AccessToken.new(@opts).application_id }
        it { is_expected.to be_nil }
      end
    end

    context 'with all options' do
      subject { Twimock::AccessToken.new(options) }
      it { is_expected.to be_kind_of Twimock::AccessToken }

      context 'then attributes' do
        it 'should set specified value by option' do
          column_names.each do |column_name|
            value = Twimock::AccessToken.new(options).send(column_name)
            expect(value).to eq options[column_name]
          end
        end
      end
    end
  end
end
