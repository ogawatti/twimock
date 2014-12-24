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
    let(:app) { app_data }
    let(:yaml_load_data) { [app] }
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

        [:id, :api_key, :api_secret, :users].each do |key|
          context "when #{key} is not exist", assert: :incorrect_data_format do
            before { app.delete(key) }
          end
        end

        [:id, :name, :password, :access_token, :access_token_secret, :application_id].each do |key|
          context "when users #{key} is not exist", assert: :incorrect_data_format do
            before { app[:users].first.delete(key) }
          end
        end
      end

      context 'yaml is correct format' do
        let(:yaml_load_data) { [app_data, app_data(2)] }
        let(:app_count) { yaml_load_data.size }
        let(:user_count) { yaml_load_data.inject(0){ |count, data| count += data[:users].size } }
        let(:app) { yaml_load_data.first }
        let(:user) { yaml_load_data.first[:users].first }

        it 'app and user should be created' do
          expect{ Twimock::Config.load_users(path) }.not_to raise_error
          expect(Twimock::Application.all.count).to eq app_count
          expect(Twimock::User.all.count).to eq user_count
          [:api_key, :api_secret].each do |key|
            expect(Twimock::Application.find_by_id(app[:id]).send(key).to_s).to eq app[key].to_s
          end
          [:name, :password, :access_token, :access_token_secret, :application_id].each do |key|
            expect(Twimock::User.find_by_id(user[:id]).send(key).to_s).to eq user[key].to_s
          end
        end
      end


      context 'same user should not be created' do
        let(:new_path) { create_temporary_yaml_file(yaml_load_data) }
        before { Twimock::Config.load_users(path) }
        it { expect{ Twimock::Config.load_users(new_path) }.not_to change{ Twimock::User.all.count } }
      end
    end
  end
end

def app_data(user_count = 1)
  app_id = Faker::Number.number(15).to_i
  users = []
  user_count.times do
    user = { id: Faker::Number.number(15),
             name: 'test_user',
             password: 'test_pass',
             access_token: 'test_token',
             access_token_secret: "test_token_secret_#{Faker::Number.number(15)}",
             application_id: app_id }
    users.push user
  end
  app = { id: app_id,
          api_key: 'test_api_key',
          api_secret: "test_api_secret_#{app_id}",
          users: users }
end

def create_temporary_yaml_file(data)
  ymlfile = 'testdata.yml'
  path = Tempfile.open(ymlfile) do |tempfile|
    tempfile.puts YAML.dump(data)
    tempfile.path
  end
end
