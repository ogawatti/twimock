require 'spec_helper'
require 'tempfile'

describe Twimock::Config do
  let(:db_name) { ".test" }
  let(:ymlfile) { "testdata.yml" }

  before { stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name) }

  describe '#default_database' do
    before do
      allow_any_instance_of(Twimock::Database).to receive(:connect) { true }
      allow_any_instance_of(Twimock::Database).to receive(:create_tables) { true }
      allow_any_instance_of(Twimock::Database).to receive(:disconnect!) { true }
    end

    subject { Twimock::Config.default_database }
    it { is_expected.to be_truthy }

    describe '.name' do
      subject { Twimock::Config.default_database.name }
      it { is_expected.not_to be_nil }
      it { is_expected.not_to be_empty }
    end
  end

  describe '#database' do
    before do
      allow_any_instance_of(Twimock::Database).to receive(:connect) { true }
      allow_any_instance_of(Twimock::Database).to receive(:create_tables) { true }
      allow_any_instance_of(Twimock::Database).to receive(:disconnect!) { true }
    end

    subject { Twimock::Config.database }
    it { is_expected.to be_truthy }

    describe '.name' do
      subject { Twimock::Config.database.name }
      it { is_expected.not_to be_nil }
      it { is_expected.not_to be_empty }
    end
  end

  describe '#reset_database' do
    context 'when does not set database' do
      subject { Twimock::Config.reset_database }
      it { is_expected.to eq nil }
    end

    context 'when already set database' do
      before do
        stub_const("Twimock::Database::DEFAULT_DATABASE_NAME", db_name)
        @database = Twimock::Database.new
      end

      subject { Twimock::Config.reset_database }
      it { is_expected.to eq nil }

      after { @database.drop }
    end
  end

  describe '#load_users' do
    context 'without argument' do
      subject { lambda { Twimock::Config.load_users } }
      it { is_expected.to raise_error ArgumentError }
    end

    context 'with yaml file path' do
      before do
        stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name)
        @database = Twimock::Database.new
      end
      after  { @database.drop }

      context 'but file does not exist' do
        subject { lambda { Twimock::Config.load_users("testdata.yml") } }
        it { is_expected.to raise_error Errno::ENOENT }
      end

      def create_temporary_yaml_file(data)
        path = Tempfile.open(ymlfile) do |tempfile|
          tempfile.puts YAML.dump(data)
          tempfile.path
        end
      end

      shared_context 'app and user should not be created', assert: :incorrect_data_format do
        subject { lambda { Twimock::Config.load_users(@path) } }
        it { is_expected.to raise_error Twimock::Errors::IncorrectDataFormat }

        it 'app and user should not be created' do
          begin
            Twimock::Config.load_users(@path)
          rescue => error
            expect(Twimock::Application.all).to be_empty
            expect(Twimock::User.all).to be_empty
          end
        end
      end

      context 'but incorrect format' do
        context 'when load data is not array', assert: :incorrect_data_format do
          before do
            users_data = ""
            @path = create_temporary_yaml_file(users_data)
          end
        end
      end
    end
  end
end
