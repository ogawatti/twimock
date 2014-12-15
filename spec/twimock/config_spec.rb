require 'spec_helper'
require 'tempfile'
require 'faker'

describe Twimock::Config do
  let(:db_name) { ".test" }
  let(:database) { Twimock::Database.new }
  before { stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name) }
  after { database.drop }

  ['default_database', 'database']. each do |db|
    describe "##{db}" do
      before do
        [:connect, :create_tables, :disconnect!].each do |method|
          allow_any_instance_of(Twimock::Database).to receive(method) { true }
        end
      end

      subject { Twimock::Config.send(db) }
      it { is_expected.to be_truthy }

      describe '.name' do
        subject { Twimock::Config.send(db).name }
        it { is_expected.not_to be_nil }
        it { is_expected.not_to be_empty }
      end
    end
  end

  describe '#reset_database' do
    subject { Twimock::Config.reset_database }
    it { is_expected.to be_nil }
  end

  describe '#load_users' do
    let(:user) { create_user }
    let(:app) { create_app([user]) }
    let(:path) { create_temporary_yaml_file(yaml_load_data) }

    context 'without argument' do
      subject { lambda { Twimock::Config.load_users } }
      it { is_expected.to raise_error ArgumentError }
    end

    context 'with yaml file path' do
      subject { lambda { Twimock::Config.load_users(path) } }

      context 'but file does not exist' do
        let(:path) { 'testdata.yml' }
        it { is_expected.to raise_error Errno::ENOENT }
      end

      shared_context 'app and user should not be created', assert: :incorrect_data_format do
        it 'app and user should not be created' do
          is_expected.to raise_error Twimock::Errors::IncorrectDataFormat
          expect(Twimock::Application.all).to be_empty
          expect(Twimock::User.all).to be_empty
        end
      end

      context 'but incorrect format' do
        context 'when load data is not array', assert: :incorrect_data_format do
          let(:yaml_load_data) { "" }
        end

        [:app_id, :api_key, :api_secret, :users].each do |key|
          context "when #{key} is not exist", assert: :incorrect_data_format do
            before { app.delete(key) }
            let(:yaml_load_data) { [app] }
          end
        end

        [:identifier, :display_name, :username, :password, :access_token, :access_token_secret].each do |key|
          context "when users #{key} is not exist", assert: :incorrect_data_format do
            before { app[:users].first.delete(key) }
            let(:yaml_load_data) { [app] }
          end
        end
      end

      context 'yaml is correct format' do
        let(:users) { [create_user, create_user({ identifier: 100000000000001 })] }
        let(:app2) { create_app(users, { app_id: 000000000000001 }) }
        let(:yaml_load_data) { [app, app2] }
        let(:app_count) { yaml_load_data.size }
        let(:user_count) { yaml_load_data.inject(0){ |count, data| count += data[:users].size } }

        it 'app and user should be created' do
          expect{ Twimock::Config.load_users(path) }.not_to raise_error
          expect(Twimock::Application.all.count).to eq app_count
          expect(Twimock::User.all.count).to eq user_count
        end
      end

      context 'same user should not be created' do
        let(:app) { create_app([user, user]) }
        let(:yaml_load_data) { [app] }

        it { expect{ Twimock::Config.load_users(path) }.to change{ Twimock::User.all.count }.by(1) }
      end
    end
  end
end

def create_user(params = {})
  id = Faker::Number.number(15)
  user = { identifier: id,
           display_name: "test user",
           username: "testuser",
           password: 'testpass',
           access_token: "test_token_#{id}",
           access_token_secret: "test_token_secret_#{id}" }
  user.merge! params
end

def create_app(users, params = {})
  id = Faker::Number.number(15)
  app = { app_id: id,
          api_key: "test_api_key_#{id}",
          api_secret: "test_api_secret_#{id}",
          users: users }
  app.merge! params
end

def create_temporary_yaml_file(data)
  ymlfile = 'testdata.yml'
  path = Tempfile.open(ymlfile) do |tempfile|
    tempfile.puts YAML.dump(data)
    tempfile.path
  end
end
