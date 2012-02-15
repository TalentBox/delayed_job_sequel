# DelayedJob Sequel Backend

## Installation

Add the gem to your Gemfile:

    gem 'delayed_job_sequel'

Run `bundle install`.

If you're using Rails, run the generator to create the migration for the delayed_job table.

    rails g delayed_job:sequel
    rake db:migrate

## Build Status

[![Build Status](http://travis-ci.org/TalentBox/delayed_job_sequel.png)](https://travis-ci.org/TalentBox/delayed_job_sequel)

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
