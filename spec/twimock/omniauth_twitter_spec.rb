require 'spec_helper'

describe Twimock::OmniAuthTwitter do
  include OmniAuthTwitterHelper

  describe '.on' do
    before { OmniAuth.config.logger.level = 2 }
    after  { Twimock::OmniAuthTwitter.off }

    subject { Twimock::OmniAuthTwitter.on }
    it { is_expected.to eq true }

    context 'when OmniAuth Twitter mock is off' do
      before do
        Twimock::OmniAuthTwitter.off
        Twimock::OmniAuthTwitter.on
      end

      it '@@enable is true' do
        expect(Twimock::OmniAuthTwitter.class_variable_get(:@@enable)).to eq true
      end

      context 'then call ::OmniAuth::Strategies::Twitter#request_phase' do
        before do
          stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name)
          application = Twimock::Application.new
          application.save!
          @env = create_request_env(application.api_key, application.api_secret)
          OmniAuth.config.path_prefix = "/users/auth"
          Twimock::API.on

          rackapp = lambda {|env| [ 200, {}, [ "Test App" ] ] }
          @twitter = ::OmniAuth::Strategies::Twitter.new(rackapp)
          @twitter.options["consumer_key"]    = application.api_key
          @twitter.options["consumer_secret"] = application.api_secret
        end
        after do
          database.drop
          Twimock::Config.port = 80
        end

        let(:db_name)  { ".test" }
        let(:database) { Twimock::Database.new }

        shared_examples "Redirect to twimock" do
        it 'should return mock 302 response' do
          status, header, body = @twitter.call(@env)

          url = case Twimock::Config.port
          when 443 then "https://#{Twimock::Config.host}"
          when 80  then "http://#{Twimock::Config.host}"
          else "http://#{Twimock::Config.host}:#{Twimock::Config.port}"
          end
          url = File.join(url, @twitter.options.client_options.authorize_path)
          oauth_token = Twimock::RequestToken.last
          location = url + "?oauth_token=#{oauth_token.string}"

          expect(status).to eq 302
          expect(header["Location"]).to eq location
        end
        end

        it_behaves_like "Redirect to twimock"

        context 'and Twimock::Config.port set 80' do
          before { Twimock::Config.port = 80 }
          it_behaves_like "Redirect to twimock"
        end

        context 'and Twimock::Config.port set 443' do
          before { Twimock::Config.port = 443 }
          it_behaves_like "Redirect to twimock"
        end

        context 'and Twimock::Config.port set 3000' do
          before { Twimock::Config.port = 3000 }
          it_behaves_like "Redirect to twimock"
        end
      end
    end
  end

  describe '.off' do
    subject { Twimock::OmniAuthTwitter.off }
    it { is_expected.to eq true }

    context 'when OmniAuth Twitter mock is off' do
      before do
        Twimock::OmniAuthTwitter.on
        Twimock::OmniAuthTwitter.off
      end

      it '@@enable is false' do
        expect(Twimock::OmniAuthTwitter.class_variable_get(:@@enable)).to eq false
      end

      context 'then call ::OmniAuth::Strategies::Twitter#request_phase' do
        before do
          stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name)
          application = Twimock::Application.new
          application.save!
          @env = create_request_env(application.api_key, application.api_secret)
          OmniAuth.config.path_prefix = "/users/auth"
          Twimock::API.on

          rackapp = lambda {|env| [ 200, {}, [ "Test App" ] ] }
          @twitter = ::OmniAuth::Strategies::Twitter.new(rackapp)
          @twitter.options["consumer_key"]    = application.api_key
          @twitter.options["consumer_secret"] = application.api_secret
        end
        after  { database.drop }

        let(:db_name)  { ".test" }
        let(:database) { Twimock::Database.new }

        it 'should return mock 302 response' do
          status, header, body = @twitter.call(@env)

          oauth_token = Twimock::RequestToken.last
          url = File.join("https://api.twitter.com", @twitter.options.client_options.authorize_path)
          location = url + "?oauth_token=#{oauth_token.string}"

          expect(status).to eq 302
          expect(header["Location"]).to eq location
        end
      end
    end
  end
end
