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
      it { is_expected.to be_nil }
    end

    context 'when already set database' do
      before do
        stub_const("Twimock::Database::DEFAULT_DATABASE_NAME", db_name)
        @database = Twimock::Database.new
      end

      subject { Twimock::Config.reset_database }
      it { is_expected.to be_nil }

      after { @database.drop }
    end
  end

  describe '#load_users' do
    def create_user(name, opts = {})
      user = { identifier: "100000000000001",
               display_name: "test #{name}",
               username: "test#{name}",
               password: 'testpass',
               access_token: "test_token_#{name}",
               access_token_secret: "test_token_secret_#{name}" }
      user.merge! opts
    end

    def create_app(name, users, opts = {})
      app = { app_id: "000000000000001",
              api_key: "test_api_key_#{name}",
              api_secret: "test_api_secret_#{name}",
              users: users }
      app.merge! opts
    end

    let(:app1_user1) { create_user("app1_user1") }
    let(:app1_user2) { create_user("app1_user2", { identifier: "100000000000002" }) }
    let(:app1) { create_app("app1", [app1_user1, app1_user2]) }
    let(:app2_user1) { create_user("app2_user1", { identifier: 100000000000003 }) }
    let(:app2) { create_app("app2", [app2_user1], { app_id: 000000000000002 }) }

    context 'without argument' do
      subject { lambda { Twimock::Config.load_users } }
      it { is_expected.to raise_error ArgumentError }
    end

    context 'with yaml file path' do
      before do
        stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name)
        @database = Twimock::Database.new
      end
      after { @database.drop }

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
        let(:path) { create_temporary_yaml_file(users_data) }

        subject { lambda { Twimock::Config.load_users(path) } }
        it 'app and user should not be created' do
          is_expected.to raise_error Twimock::Errors::IncorrectDataFormat
          expect(Twimock::Application.all).to be_empty
          expect(Twimock::User.all).to be_empty
        end
      end

      context 'but incorrect format' do
        context 'when load data is not array', assert: :incorrect_data_format do
          let(:users_data) { "" }
        end

        [:app_id, :api_key, :api_secret, :users].each do |key|
          context "when #{key} is not exist", assert: :incorrect_data_format do
            before { app2.delete(key) }
            let(:users_data) { [app2] }
          end
        end

        [:identifier, :display_name, :username, :password, :access_token, :access_token_secret].each do |key|
          context "when users #{key} is not exist", assert: :incorrect_data_format do
            before { app2[:users].first.delete(key) }
            let(:users_data) { [app2] }
          end
        end
      end

      context 'yaml is correct format' do
        let(:yaml_load_data) { [app1, app2] }
        let(:path) { create_temporary_yaml_file(yaml_load_data) }
        let(:app_count) { yaml_load_data.size }
        let(:user_count) { yaml_load_data.inject(0){ |count, data| count += data[:users].size } }

        subject { lambda { Twimock::Config.load_users(path) } }
        it { is_expected.not_to raise_error }

        it 'app and user should be created' do
          Twimock::Config.load_users(path)
          expect(Twimock::Application.all.count).to eq app_count
          expect(Twimock::User.all.count).to eq user_count
        end

        context 'when already exist specified users' do
          before { Twimock::Config.load_users(path) }
          it 'should not raise error' do
            new_path = create_temporary_yaml_file(yaml_load_data)
            expect{ Twimock::Config.load_users(new_path) }.to change{ user_count }.by(0)
          end
        end
      end
    end
  end
end
