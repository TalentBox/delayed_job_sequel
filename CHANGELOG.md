4.2.0 (2016-06-10)
==================

* Update `delayed-job` dependency to `~> 4.1.0` (James Goodhouse)

4.1.0 (2015-02-12)
==================

* Allow overriding the Job table name

**BREAKING CHANGE**

In order to support the Job's table name override, requiring `delayed_job_sequel`
no longer set the backend. You will have to do it manually (for example in an
initializer):

```ruby
::Delayed::Worker.backend = :sequel
```

4.0.1 (2013-02-04)
==================

* Compatibility with Ruby 2.0, 2.1 and JRuby

4.0.0 (2013-10-29)
==================

* Fix a locking race condition in job reservation (Jonathan Tron, Mark Rushakoff) [#2](https://github.com/TalentBox/delayed_job_sequel/pull/2)
* Update Sequel dependency to allow versions from `3.38` to `4.x`
* Update DelayedJob dependency to allow `~> 4.0.0`
