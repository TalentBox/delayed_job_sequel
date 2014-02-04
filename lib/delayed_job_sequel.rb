require 'sequel'
require 'delayed_job'
require 'delayed/backend/sequel'
require 'delayed/serialization/sequel'

Delayed::Worker.backend = :sequel
