require 'sham_rack'

module Twimock
  module Api
    extend self

    HOST_NAME = "api.twitter.com"

    def on
      regist_to_shamrack(Net::HTTP.http_default_port)
      regist_to_shamrack(Net::HTTP.https_default_port)
    end

    def off
      ShamRack.unmount_all
    end

    def on?
      !ShamRack.application_for(HOST_NAME).nil?
    end

    private

    def regist_to_shamrack(port = Net::HTTP.http_default_port)
      ShamRack.at(HOST_NAME, port) do |env| 
        if validate_request(env) && validate_user
          generate_response
        else
          generate_response(404)
        end
      end
    end

    def validate_request(env)
      return false unless env && env['REQUEST_METHOD'] == 'GET' && env['PATH_INFO'] == '/'
      # TODO
      # RequestHeaderの検証
      true
    end

    def validate_user
      # TODO
      # ユーザ情報参照
      # 事前登録したユーザとのマッチング
      true
    end

    def generate_response(status = 200)
      # TODO
      body = case status
      when 200
        ['Hello, world!']
      when 404
        ['Not Found']
      end
      content_length = body.inject(0) { |sum, content| sum + content.bytesize }
      header = { 'Content-type' => 'text/plain',
                 'Content-Length' => content_length.to_s }
      [status, header, body]
    end
  end
end
