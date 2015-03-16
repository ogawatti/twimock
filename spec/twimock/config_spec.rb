require 'spec_helper'
require 'tempfile'
require 'faker'

describe Twimock::Config do
  let(:db_name) { ".test" }
  let(:database) { Twimock::Database.new }

  let(:host) { "api.twimock.com" }
  let(:port) { 443 }
  let(:callback_url) { "http://localhost/auth/twiter/callback" }

  before { stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name) }
  after { database.drop }

  describe '.host' do
    after { Twimock::Config.host = host }

    subject { Twimock::Config.host }
    it { is_expected.to eq host }

    context 'when set this' do
      before { Twimock::Config.host = host }
      let(:host) { "test.twimock.com" }
      it { is_expected.to eq host }
    end
  end

  describe '.port' do
    after { Twimock::Config.port = port }

    subject { Twimock::Config.port }
    it { is_expected.to eq port }

    context 'when set this' do
      before { Twimock::Config.port = port }
      let(:port) { 80 }
      it { is_expected.to eq port }
    end
  end

  describe '.callback_url' do
    after { Twimock::Config.callback_url = callback_url }

    subject { Twimock::Config.callback_url }
    it { is_expected.to eq callback_url }

    context 'when set this' do
      before { Twimock::Config.callback_url = callback_url }
      let(:callback_url) { "http://localhost:3000/users/auth/twitter/callback" }
      it { is_expected.to eq callback_url }
    end
  end

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

      shared_examples 'IncorrectDataFormat' do
        it 'app and user should not be created' do
          is_expected.to raise_error Twimock::Errors::IncorrectDataFormat
          expect(Twimock::Application.all).to be_empty
          expect(Twimock::User.all).to be_empty
        end
      end

      context 'but incorrect format' do
        context 'when load data is not array' do
          let(:yaml_load_data) { "" }
          it_behaves_like 'IncorrectDataFormat'
        end

        [:id, :api_key, :api_secret, :users].each do |key|
          context "when #{key} is not exist" do
            before { app.delete(key) }
            it_behaves_like 'IncorrectDataFormat'
          end
        end

        [:id, :name, :password].each do |key|
          context "when users #{key} is not exist" do
            before do
              app[:users].first.delete(key)
              it_behaves_like 'IncorrectDataFormat'
            end
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
          expect(Twimock::AccessToken.all.count).to eq user_count

          # 要改善 : yamlの全部が登録されたことがチェックされていない
          [:api_key, :api_secret].each do |key|
            expect(Twimock::Application.find_by_id(app[:id]).send(key).to_s).to eq app[key].to_s
          end
          [:name, :password].each do |key|
            expect(Twimock::User.find_by_id(user[:id]).send(key).to_s).to eq user[key].to_s
          end
          access_tokens = Twimock::AccessToken.where(user_id: user[:id])
          expect(access_tokens.count).to eq 1
          access_token  = access_tokens.first
          expect(access_token.string).to eq user[:access_token]
          expect(access_token.secret).to eq user[:access_token_secret]
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
  users = []
  user_count.times do
    user = { id:                  Faker::Number.number(10),
             name:                create_user_name,
             password:            Faker::Internet.password,
             access_token:        Faker::Lorem.characters(50),
             access_token_secret: Faker::Lorem.characters(45) }
    users.push user
  end
  app = { id:         Faker::Number.number(10).to_i,
          api_key:    Faker::Lorem.characters(25),
          api_secret: Faker::Lorem.characters(50),
          users:      users }
end

def create_user_name
  n = Faker::Name.name
  (n.include?("'") || n.include?(".")) ? create_user_name : n
end

def create_temporary_yaml_file(data)
  ymlfile = 'testdata.yml'
  path = Tempfile.open(ymlfile) do |tempfile|
    tempfile.puts YAML.dump(data)
    tempfile.path
  end
end
