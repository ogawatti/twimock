require 'sqlite3'
require 'twimock/database/table'

module Twimock
  class Database
    ADAPTER = "sqlite3"
    DB_DIRECTORY = File.expand_path("../../../db", __FILE__)
    DEFAULT_DB_NAME = "twimock"
    TABLE_NAMES = [:applications, :users, :request_tokens]

    attr_reader :name
    attr_reader :connection

    def initialize(name=nil)
      @name = DEFAULT_DB_NAME
      connect
      create_tables
    end

    def connect
      @connection = SQLite3::Database.new filepath
      @state = :connected
      @connection
    end

    def disconnect!
      @connection.close
      @state = :disconnected
      nil
    end
      
    def connected?
      @state == :connected
    end

    def drop
      disconnect!
      File.delete(filepath) if File.exist?(filepath)
      nil
    end

    def clear
      drop_tables
      create_tables
    end

    def create_tables
      TABLE_NAMES.each do |table_name|
        self.send "create_#{table_name}_table" unless table_exists?(table_name)
      end
      true
    end

    def drop_table(table_name)
      return false unless File.exist?(filepath) && table_exists?(table_name)
      @connection.execute "drop table #{table_name};"
      true
    end

    def drop_tables
      return false unless File.exist?(filepath)
      TABLE_NAMES.each{|table_name| drop_table(table_name) }
      true
    end

    def filepath
      name ||= @name
      File.join(DB_DIRECTORY, "#{@name}.#{ADAPTER}")
    end

    def table_exists?(table_name)
      tables = @connection.execute "select * from sqlite_master"
      tables.each do |table|
        return true if table[1].to_s == table_name.to_s
      end
      false
    end

    private

    def create_applications_table
      @connection.execute <<-SQL
        CREATE TABLE applications (
          id          INTEGER   PRIMARY KEY AUTOINCREMENT,
          api_key     TEXT      NOT NULL,
          api_secret  TEXT      NOT NULL,
          created_at  DATETIME  NOT NULL,
          UNIQUE(api_secret)
        );
      SQL
    end 

    def create_users_table
      @connection.execute <<-SQL
        CREATE TABLE users (
          id                   INTEGER   PRIMARY KEY AUTOINCREMENT,
          name                 TEXT      NOT NULL,
          twitter_id           TEXT      NOT NULL,
          email                TEXT      NOT NULL,
          password             TEXT      NOT NULL,
          access_token         TEXT      NOT NULL,
          access_token_secret  TEXT      NOT NULL,
          application_id       INTEGER   NOT NULL,
          created_at           DATETIME  NOT NULL,
          UNIQUE(twitter_id, email, access_token, access_token_secret));
      SQL
    end

    def create_request_tokens_table
      @connection.execute <<-SQL
        CREATE TABLE request_tokens (
          id              INTEGER   PRIMARY KEY AUTOINCREMENT,
          string          TEXT      NOT NULL,
          secret          TEXT      NOT NULL,
          verifier        TEXT      NOT NULL,
          application_id  INTEGER   NOT NULL,
          user_id         INTEGER,
          created_at      DATETIME  NOT NULL,
          UNIQUE(string, secret, verifier));
      SQL
    end
  end
end
