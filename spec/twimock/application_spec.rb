require 'spec_helper'

describe Twimock::Application do
  include TableHelper

  let(:db_name)      { ".test" }

  let(:table_name)   { :applications }
  let(:column_names) { [ :id, :api_key, :api_secret, :created_at ] }
  let(:children)     { [ Twimock::User ] }

  let(:id)           { 1 }
  let(:api_key)      { "test_api_key" }
  let(:api_secret)   { "test_api_secret" }
  let(:created_at)   { Time.now }
  let(:options)      { { id: id, api_key: api_key, api_secret: api_secret, created_at: created_at } }

  after { remove_dynamically_defined_all_method }

  describe '::TABLE_NAME' do
    subject { Twimock::Application::TABLE_NAME }
    it { is_expected.to eq table_name }
  end

  describe '::COLUMN_NAMES' do
    subject { Twimock::Application::COLUMN_NAMES }
    it { is_expected.to eq column_names }
  end

  describe '::CHILDREN' do
    subject { Twimock::Application::CHILDREN }
    it { is_expected.to eq children }
  end

  describe '#initialize' do
    context 'without option' do
      subject { Twimock::Application.new }
      it { is_expected.to be_kind_of Twimock::Application }

      describe '.id' do
        subject { Twimock::Application.new.id }
        it { is_expected.to be > 0 }
        it { is_expected.to be < 10000000000 }
      end

      describe '.api_key' do
        subject { Twimock::Application.new.api_key }
        it { is_expected.to be_kind_of String }

        describe '.size' do
          subject { Twimock::Application.new.api_key.size }
          it { is_expected.to eq 25 }
        end
      end

      describe '.api_secret' do
        subject { Twimock::Application.new.api_secret }
        it { is_expected.to be_kind_of String }

        describe '.size' do
          subject { Twimock::Application.new.api_secret.size }
          it { is_expected.to eq 50 }
        end
      end

      describe '.created_at' do
        subject { Twimock::Application.new.created_at }
        it { is_expected.to be_nil }
      end
    end

    context 'with id option but it is not integer' do
      before { @opts = { id: "test_id" } }
      subject { Twimock::Application.new(@opts) }
      it { is_expected.to be_kind_of Twimock::Application }

      describe '.id' do
        subject { Twimock::Application.new(@opts).id }
        it { is_expected.to be > 0 }
      end
    end

    context 'with all options' do
      subject { Twimock::Application.new(options) }
      it { is_expected.to be_kind_of Twimock::Application }

      context 'then attributes' do
        it 'should set specified values by option' do
          column_names.each do |column_name|
            value = Twimock::Application.new(options).send(column_name)
            expect(value).to eq options[column_name]
          end
        end
      end
    end
  end

  describe 'destroy' do
    before do
      stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name)
      @database = Twimock::Database.new
    end
    after { @database.drop }

    context 'when has user' do
      before do
        @application = Twimock::Application.create!
        Twimock::User.create!(application_id: @application.id)
      end

      it 'should delete permissions' do
        @application.destroy
        users = Twimock::User.find_all_by_application_id(@application.id)
        expect(users).to be_empty
      end
    end
  end
end
