require "spec_helper"
require "delayed/backend/sequel"

describe Delayed::Backend::Sequel::Job do
  after do
    Time.zone = nil
  end

  it_should_behave_like "a delayed_job backend"

  context "db_time_now" do
    it "should return time in current time zone if set" do
      Time.zone = "Eastern Time (US & Canada)"
      %w(EST EDT).should include(Delayed::Job.db_time_now.zone)
    end

    it "should return UTC time if that is the Sequel.database_timezone default" do
      Time.zone = nil
      Sequel.database_timezone = :utc
      Delayed::Backend::Sequel::Job.db_time_now.zone.should == "UTC"
    end

    it "should return local time if that is the AR default" do
      Time.zone = "Central Time (US & Canada)"
      Sequel.database_timezone = :local
      %w(CST CDT).should include(Delayed::Backend::Sequel::Job.db_time_now.zone)
    end
  end

  describe "before_fork" do
    it "should call disconnect on the connection" do
      Sequel::Model.db.should_receive(:disconnect)
      Delayed::Backend::Sequel::Job.before_fork
    end
  end

  describe "enqueue" do
    it "should allow enqueue hook to modify job at DB level" do
      later = described_class.db_time_now + 20.minutes
      job = Delayed::Backend::Sequel::Job.enqueue :payload_object => EnqueueJobMod.new
      Delayed::Backend::Sequel::Job[job.id].run_at.should be_within(1).of(later)
    end
  end
end
