$:.unshift(File.dirname(__FILE__) + "/../lib")

require "rubygems"
require "bundler/setup"
require "rspec"
require "logger"
require "sqlite3"
require "sequel"

config = YAML.load(File.read("spec/database.yml"))
DB = Sequel.connect config["sqlite"]

Sequel.extension :migration
Class.new(Sequel::Migration) do
  def up
    create_table :delayed_jobs do
      primary_key :id
      Integer :priority, :default => 0
      Integer :attempts, :default => 0
      String  :handler, :text => true
      String  :last_error, :text => true
      Time    :run_at
      Time    :locked_at
      Time    :failed_at
      String  :locked_by
      String  :queue
      Time    :created_at
      Time    :updated_at
      index   [:priority, :run_at]
    end

    create_table :stories do
      primary_key :story_id
      String      :text
      TrueClass   :scoped, :default => true
    end
  end
end.apply(DB, :up)

require "delayed_job_sequel"
require "delayed/backend/shared_spec"

Delayed::Worker.logger = Logger.new("/tmp/dj.log")
ENV["RAILS_ENV"] = "test"
DB.logger = Delayed::Worker.logger

# Purely useful for test cases...
class Story < Sequel::Model
  def tell; text; end
  def whatever(n, _); tell*n; end
  def update_attributes(*args)
    update *args
  end
  handle_asynchronously :whatever
end

# Add this directory so the ActiveSupport autoloading works
# ActiveSupport::Dependencies.autoload_paths << File.dirname(__FILE__)
