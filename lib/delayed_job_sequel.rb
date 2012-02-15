require 'sequel'
require 'delayed_job'
require 'delayed/backend/sequel'

Delayed::Worker.backend = :sequel
