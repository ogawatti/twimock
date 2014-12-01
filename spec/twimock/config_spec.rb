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
    let(:user1) { { identifier: "100000000000001",
                    display_name: "test user one",
                    username: "testuserone",
                    password: "testpass",
                    access_token: "test_token_one",
                    access_token_secret: "test_token_secret_one" } }
    let(:user2) { { identifier: "100000000000002",
                    display_name: "test user two",
                    username: "testusertwo",
                    password: "testpass",
                    access_token: "test_token_two",
                    access_token_secret: "test_token_secret_two" } }
    let(:user3) { { identifier: 100000000000003,
                    display_name: "test user three",
                    username: "testuserthree",
                    password: "testpass",
                    access_token: "test_token_three",
                    access_token_secret: "test_token_secret_three" } }

    let(:app1_id) { "000000000000001" }
    let(:app1_api_key) { "test_api_key_one" }
    let(:app1_api_secret) { "test_api_secret_one" }
    let(:app1_users) { [user1, user2] }
    let(:app1) { { app_id: app1_id, api_key: app1_api_key, api_secret: app1_api_secret, users: app1_users } }

    let(:app2_id) { 000000000000002 }
    let(:app2_api_key) { "test_api_key_two" }
    let(:app2_api_secret) { "test_api_secret_two" }
    let(:app2_users) { [user3] }
    let(:app2) { { app_id: app2_id, api_key: app2_api_key, api_secret: app2_api_secret, users: app2_users } }

    let(:yaml_load_data) { [ app1, app2 ] }

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

        context 'when app id does not exist', assert: :incorrect_data_format do
          before do
            users_data = [ { api_secret: app1_api_secret, users: app1_users } ]
            @path = create_temporary_yaml_file(users_data)
          end
        end

        context 'when api key does not exist', assert: :incorrect_data_format do
          before do
            users_data = [ { app_id: app1_id, api_secret: app1_api_secret, users: app1_users } ]
            @path = create_temporary_yaml_file(users_data)
          end
        end

        context 'when api secret does not exist', assert: :incorrect_data_format do
          before do
            users_data = [ { app_id: app1_id, api_key: app1_api_key, users: app1_users } ]
            @path = create_temporary_yaml_file(users_data)
          end
        end

        context 'when users does not exist', assert: :incorrect_data_format do
          before do
            users_data = [ { app_id: app1_id, api_key: app1_api_key, api_secret: app1_api_secret } ]
            @path = create_temporary_yaml_file(users_data)
          end
        end

        context 'when users have only identifier', assert: :incorrect_data_format do
          before do
            users_data = [ { app_id: app1_id, api_key: app1_api_key, api_secret: app1_api_secret,
                             users: [ { identifier: "100000000000001" } ] } ]
            @path = create_temporary_yaml_file(users_data)
          end
        end
      end

      context 'yaml is correct format' do
        before { @path = create_temporary_yaml_file(yaml_load_data) }

        subject { lambda { Twimock::Config.load_users(@path) } }
        it { is_expected.not_to raise_error }

        it 'app and user should be created' do
          app_count  = yaml_load_data.size
          user_count = yaml_load_data.inject(0){|count, data| count += data[:users].size }
          Twimock::Config.load_users(@path)
          expect(Twimock::Application.all.count).to eq app_count
          expect(Twimock::User.all.count).to eq user_count
        end

        context 'when already exist specified users' do
          before do
            Twimock::Config.load_users(@path)
          end

          it 'should not raise error' do
            size = Twimock::User.all.size
            expect(size).to eq 3
            path = create_temporary_yaml_file(yaml_load_data)
            Twimock::Config.load_users(path)
            expect(size).to eq 3
          end
        end
      end
    end
  end
end
