require "active_support/time"
require "twimock/version"
require "twimock/database"
require "twimock/config"
require "twimock/application"
require "twimock/user"
require "twimock/auth_hash"
require "twimock/errors"
require "sham_rack"

module Twimock
  extend self

  def auth_hash(access_token=nil)
    if access_token.kind_of?(String) && access_token.size > 0
      user = Twimock::User.find_by_access_token(access_token)
      if user
        Twimock::AuthHash.new({
          provider:    "twitter",
          uid:         user.id,
          info:        { name: user.name },
          credentials: { token: access_token, expires_at: Time.now + 60.days },
          extra:       { raw_info: { id: user.id, name: user.name } }
        })
      else
        Twimock::AuthHash.new
      end 
    else
      Twimock::AuthHash.new
    end 
  end

  module Api
    extend self

    API_HOST_NAME = "api.twitter.com"

    def on
      regist_to_shamrack
      regist_to_shamrack(Net::HTTP.https_default_port)
    end

    def off
      ShamRack.unmount_all
    end

    def on?
      !ShamRack.application_for(API_HOST_NAME).nil?
    end

    private

    def regist_to_shamrack(port = Net::HTTP.default_port)
      ShamRack.at(API_HOST_NAME, port) do |env| 
        if validate_request(env) && validate_user
          generate_request 
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

    def generate_request
      # TODO
      # Request生成
      status = '200 OK'
      header = { 'Content-type' => 'text/plain' }
      body = ['Hello, world!']
      [status, header, body]
    end
  end
end
