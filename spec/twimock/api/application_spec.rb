require 'spec_helper'

describe Twimock::API::Application do
  before do
    allow_any_instance_of(Excon::Connection).to receive(:request) do
      options = { status: status, headers: headers, body: body }
      response = Excon::Response.new(options)
    end
  end

  let(:status)  { 200 }
  let(:headers) { { "Content-Length" => 4, "Content-Type"=>"text/plain" } }
  let(:body)    { "test_body" }

  let(:env)     { { "rack.input"     => StringIO.new(body),
                    "REQUEST_METHOD" => "GET",
                    "SERVER_NAME"    => "api.twitter.com",
                    "SERVER_PORT"    => "443",
                    "QUERY_STRING"   => "",
                    "PATH_INFO"      => "/",
                    "HTTPS"          => "on" } }

  describe 'call' do
    subject { Twimock::API::Application.new.call(env) }
    it { is_expected.to eq [ status, headers, [ body ] ] }
  end
end
