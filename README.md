# DelayedJob Sequel Backend

## Installation

Add the gem to your Gemfile:

    gem 'talentbox-delayed_job_sequel'

Run `bundle install`.

Create the table (using the sequel migration syntax):

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

## Build Status

[![Build Status](https://secure.travis-ci.org/TalentBox/delayed_job_sequel.png?branch=master)](http://travis-ci.org/TalentBox/delayed_job_sequel)

## How to contribute

If you find what looks like a bug:

* Search the [mailing list](http://groups.google.com/group/delayed_job) to see if anyone else had the same issue.
* Check the [GitHub issue tracker](http://github.com/TalentBox/delayed_job_sequel/issues/) to see if anyone else has reported issue.
* If you don't see anything, create an issue with information on how to reproduce it.

If you want to contribute an enhancement or a fix:

* Fork the project on github.
* Make your changes with tests.
* Commit the changes without making changes to the Rakefile or any other files that aren't related to your enhancement or fix
* Send a pull request.
