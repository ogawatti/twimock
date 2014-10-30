require 'spec_helper'

describe Twimock::User do
  include TableHelper

  let(:db_name)        { ".test" }
  let(:table_name)     { :users }
  let(:column_names)   { [ :id,
                           :name,
                           :password,
                           :access_token,
                           :access_token_secret,
                           :application_id,
                           :created_at ] }

  let(:id)                  { 1 }
  let(:name)                { "test user" }
  let(:password)            { "testpass" }
  let(:access_token)        { "test_token" }
  let(:access_token_secret) { "test_token_secret" }
  let(:application_id)      { 1 }
  let(:created_at)          { Time.now }
  let(:options)             { { id:                  id, 
                                name:                name,
                                password:            password,
                                access_token:        access_token,
                                access_token_secret: access_token_secret,
                                application_id:      application_id,
                                created_at:          created_at } }

  after { remove_dynamically_defined_all_method }

  describe '::TABLE_NAME' do
    subject { Twimock::User::TABLE_NAME }
    it { is_expected.to eq table_name }
  end

  describe '::COLUMN_NAMES' do
    subject { Twimock::User::COLUMN_NAMES }
    it { is_expected.to eq column_names }
  end

  describe '#initialize' do
    context 'without option' do
      subject { Twimock::User.new }
      it { is_expected.to be_kind_of Twimock::User }

      describe '.id' do
        subject { Twimock::User.new.id }
        it { is_expected.to be > 0 }
        it { is_expected.to be < 100010000000000 }
      end

      describe '.name' do
        subject { Twimock::User.new.name }
        it { is_expected.to be_kind_of String }

        describe '.size' do
          subject { Twimock::User.new.name.size }
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

      describe '.access_token' do
        subject { Twimock::User.new.access_token }
        it { is_expected.to be_kind_of String }

        describe '.size' do
          subject { Twimock::User.new.access_token.size }
          it { is_expected.to eq 255 }
        end
      end

      describe '.application_id' do
        subject { Twimock::User.new.application_id }
        it { is_expected.to be_nil }
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
        it { is_expected.to be < 100010000000000 }
      end
    end

    # TODO : DOING
    context 'with identifier option' do
      before { @opts = { identifier: 100010000000000 } }
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

    context 'with application_id option but it is not integer' do
      before { @opts = { application_id: "test_id" } }
      subject { Twimock::User.new(@opts) }
      it { is_expected.to be_kind_of Twimock::User }

      describe '.application_id' do
        subject { Twimock::User.new(@opts).application_id }
        it { is_expected.to be_nil }
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
end
