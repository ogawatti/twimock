[![Gem Version](https://badge.fury.io/rb/twimock.svg)](http://badge.fury.io/rb/twimock)
[![Build Status](https://travis-ci.org/ogawatti/twimock.svg?branch=master)](https://travis-ci.org/ogawatti/twimock)
[![Coverage Status](https://coveralls.io/repos/ogawatti/twimock/badge.png?branch=master)](https://coveralls.io/r/ogawatti/twimock?branch=master)
[<img src="https://gemnasium.com/ogawatti/twimock.png" />](https://gemnasium.com/ogawatti/twimock)
[![Code Climate](https://codeclimate.com/github/ogawatti/twimock.png)](https://codeclimate.com/github/ogawatti/twimock)

# Twimock

This gem is used to mock the communication part of the twitter api.

## Installation

Add this line to your application's Gemfile:

    gem 'twimock'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install twimock

## Usage

TODO: Write usage instructions here

### For Rails App Settings (config/initializers/twimock.rb)

    # Create Twimock Application & User
    application = Twimock::Application.create!
    user        = Twimock::User.create!

    # Associate App and User
    user.generate_access_token(app.id)

    # Twimock Setting
    Twimock::Config.host         = 'example.com'
    Twimock::Config.port         = 3000
    Twimock::Config.callback_url = '/users/auth/twitter/callback'

    # Enable Twimock
    Twimock::API.on
    Twimock::OmniAuthTwitter.on

    # Add Rack Middleware for twimock
    [ Twimock::API::OAuth::Authenticate, Twimock::API::Intent::Sessions ].each do |middleware|
      Rails.application.config.middleware.use middleware
    end

### Create Apps and Users at onece by yaml file

    require 'twimock'

    filename = File.expand_path('../test_users.yml', __FILE__)
    Twimock::Config.load_users(filename)

    Twimock::Application.find_by_id(1).api_key  #=> avb0vlu767yhu37hti5qq9hcc
    Twimock::User.find_by_id(1).name            #=> testuser01

yaml file see below.

    ---
    - :id: 1
      :api_key: avb0vlu767yhu37hti5qq9hcc
      :api_secret: e85vl7fc4susiyjjp0pncz0hf2xtf3vm29gj7hhp2ktv28wunl
      :users:
      - :id: 1
        :name: testuser01
        :password: r3xkhy64w
        :access_token: 6697725737-9ntcnith1wq7zgphnisxu6bqybl019bms05t8l9
        :access_token_secret: 22ogzdkn5kqtlihr3u5vwplrlh8noie61pr6ndeangrpt
        :application_id: 1
      - :id: 2
        :name: testuser02
        :password: 5ush05lp0
        :access_token: 6891305263-xpvu78zd1p76s3cp6jwrudgb0g0sffxe9hp7mdj
        :access_token_secret: or1xkqs96tim8n7vhc77yxo2i6ed9a6bmhru0zozjao80
        :application_id: 1
    - :id: 2
      :api_key: w6cb9sj17fyf5g1rr4fl5ignp
      :api_secret: 2vrdpujwvl3421qatn8qah9ishpia9khq7mprnkfx49mldo0k6
      :users:
      - :id: 3
        :name: testuser03
        :password: ylgi4lth
        :access_token: 6932630251-1sshumnflh0abshkgaf2scxa6l02cr8tyi2kt00
        :access_token_secret: txncllipm1wl0g21wvtc750lqz2dleu6e0lqg62vt7eam
        :application_id: 2

### User Model

    require 'twimock'

    # Create
    user = Twimock::User.new
    user.name = "twimock_test_user"
    user.save!

    user = Twimock::User.new(name: "hoge", password: "fuga")
    user.name      #=> "hoge"
    user.save!

    user = Twimock::User.create!(name: "hogehoge", password: "fugafuga")
    user.name      #=> "hogehoge"
    user.password  #=> "fugafuga"

    # Find
    Twimock::User.find_by_id(1)
    Twimock::User.find_by_name("testuser01")
    Twimock::User.where(name: "testuser02")
    Twimock::User.all
    Twimock::User.first
    Twimock::User.last

    # Delete
    user = User.last
    user.destroy

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
