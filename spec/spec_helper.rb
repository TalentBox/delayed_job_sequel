$:.unshift(File.dirname(__FILE__) + "/../lib")
ENV["RAILS_ENV"] = "test"

require "rubygems"
require "bundler/setup"
require "rspec"
require "logger"
require "sequel"

def jruby?
  (defined?(RUBY_ENGINE) && RUBY_ENGINE=="jruby") || defined?(JRUBY_VERSION)
end

rspec_exclusions = {}
rspec_exclusions[:skip_jdbc] = !jruby?
rspec_exclusions[:postgres] = ENV['TEST_ADAPTER'] != 'postgresql'
rspec_exclusions[:mysql] = !%w(mysql mysql2).include?(ENV['TEST_ADAPTER'])
rspec_exclusions[:sqlite] = ENV['TEST_ADAPTER'] != 'sqlite3'

RSpec.configure do |config|
  config.filter_run_excluding rspec_exclusions
end

db_host = ENV.fetch("TEST_DATABASE_HOST", "127.0.0.1")
db_name = ENV.fetch("TEST_DATABASE", "delayed_jobs_test")

DB = case ENV["TEST_ADAPTER"]
when /mysql/
  db_port = ENV.fetch("TEST_DATABASE_PORT", 3306)
  opts = {test: true, encoding: ENV.fetch("TEST_ENCODING", "utf8")}
  begin
    if jruby?
      Sequel.connect "jdbc:mysql://#{db_host}:#{db_port}/#{db_name}", opts
    else
      opts.merge!({database: db_name, host: db_host, port: db_port})
      opts[:user] = ENV["TEST_USERNAME"] if ENV.key?("TEST_USERNAME")
      opts[:password] = ENV["TEST_PASSWORD"] if ENV.key?("TEST_PASSWORD")
      Sequel.connect({adapter: "mysql2"}.merge(opts))
    end
  rescue Sequel::DatabaseConnectionError
    if ENV.key? "CI"
      raise
    else
      system "mysql -e 'CREATE DATABASE IF NOT EXISTS `#{db_name}` DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_unicode_ci'"
      retry
    end
  end
when /postgres/
  db_port = ENV.fetch("TEST_DATABASE_PORT", 5432)
  opts = {test: true, encoding: ENV.fetch("TEST_ENCODING", nil)}
  begin
    if jruby?
      Sequel.connect "jdbc:postgresql://#{db_host}:#{db_port}/#{db_name}", opts
    else
      opts.merge!({database: db_name, host: db_host, port: db_port})
      opts[:user] = ENV["TEST_USERNAME"] if ENV.key?("TEST_USERNAME")
      opts[:password] = ENV["TEST_PASSWORD"] if ENV.key?("TEST_PASSWORD")
      Sequel.connect({adapter: "postgres"}.merge(opts))
    end
  rescue Sequel::DatabaseConnectionError
    if ENV.key? "CI"
      raise
    else
      system "createdb --encoding=UTF8 #{db_name}"
      retry
    end
  end
else
  if jruby?
    Sequel.connect "jdbc:sqlite::memory:", test: true
  else
    Sequel.sqlite
  end
end

DB.drop_table :delayed_jobs rescue Sequel::DatabaseError
DB.drop_table :another_delayed_jobs rescue Sequel::DatabaseError
DB.drop_table :stories rescue Sequel::DatabaseError

DB.create_table :delayed_jobs do
  primary_key :id
  Integer :priority, default: 0
  Integer :attempts, default: 0
  String  :handler, text: true
  String  :last_error, text: true
  Time    :run_at
  Time    :locked_at
  Time    :failed_at
  String  :locked_by
  String  :queue
  Time    :created_at
  Time    :updated_at
  index   [:priority, :run_at]
end
DB.create_table :stories do
  primary_key :story_id
  String      :text
  TrueClass   :scoped, default: true
end

require "delayed_job_sequel"
require "delayed/backend/shared_spec"

Delayed::Worker.logger = Logger.new(ENV["DEBUG"] ? $stdout : "/tmp/dj.log")
DB.logger = Delayed::Worker.logger

Delayed::Worker.backend = :sequel

# Purely useful for test cases...
class Story < Sequel::Model
  def tell; text; end
  def whatever(n, _); tell*n; end
  def update_attributes(*args)
    update *args
  end
  handle_asynchronously :whatever
  alias_method :persisted?, :exists?
  def save!
    save(raise_on_failure: true)
  end
end
