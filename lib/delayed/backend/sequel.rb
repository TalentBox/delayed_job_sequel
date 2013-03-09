require 'sequel'
module Delayed
  module Backend
    module Sequel
      # A job object that is persisted to the database.
      # Contains the work object as a YAML field.
      class Job < ::Sequel::Model(:delayed_jobs)
        include Delayed::Backend::Base
        plugin :timestamps

        def before_save
          super
          set_default_run_at
        end

        def_dataset_method :ready_to_run do |worker_name, max_run_time|
          db_time_now = model.db_time_now
          lock_upper_bound = db_time_now - max_run_time
          filter do
            ( (run_at <= db_time_now) &
              ({:locked_at => nil} | (locked_at < lock_upper_bound)) |
              {:locked_by => worker_name}
            ) & {:failed_at => nil}
          end
        end

        def_dataset_method :by_priority do
          order(:priority.asc, :run_at.asc)
        end

        def self.before_fork
          ::Sequel::Model.db.disconnect
        end

        # When a worker is exiting, make sure we don't have any locked jobs.
        def self.clear_locks!(worker_name)
          filter(:locked_by => worker_name).update(:locked_by => nil, :locked_at => nil)
        end

        def self.reserve(worker, max_run_time = Worker.max_run_time)
          set = ready_to_run(worker.name, max_run_time)
          set = set.filter("priority >= ?", Worker.min_priority) if Worker.min_priority
          set = set.filter("priority <= ?", Worker.max_priority) if Worker.max_priority
          set = set.filter(:queue => Worker.queues) if Worker.queues.any?

          job = set.by_priority.first

          now = self.db_time_now

          return unless job
          model.db.transaction do
            job.lock!
            job.locked_at = now
            job.locked_by = worker.name
            job.save(:raise_on_failure => true)
          end
          job
        end

        # Lock this job for this worker.
        # Returns true if we have the lock, false otherwise.
        def lock_exclusively!(max_run_time, worker)
          now = self.class.db_time_now
          affected_rows = if locked_by != worker
            # We don't own this job so we will update the locked_by name and the locked_at
            lock_upper_bound = now - max_run_time.to_i
            closure_pk = pk
            self.class.filter{
              {:id => closure_pk} &
              ({:locked_at => nil} | (locked_at < lock_upper_bound)) &
              (run_at <= now)
            }.update(:locked_at => now, :locked_by => worker)
          else
            # We already own this job, this may happen if the job queue crashes.
            # Simply resume and update the locked_at
            self.class.filter(:id => id, :locked_by => worker).update(:locked_at => now)
          end
          if affected_rows == 1
            self.locked_at = now
            self.locked_by = worker
            return true
          else
            return false
          end
        end

        # Get the current time (GMT or local depending on DB)
        # Note: This does not ping the DB to get the time, so all your clients
        # must have syncronized clocks.
        def self.db_time_now
          if Time.zone
            Time.zone.now
          elsif ::Sequel.database_timezone == :utc
            Time.now.utc
          else
            Time.now
          end
        end

        def self.delete_all
          delete
        end

        def reload(*args)
          reset
          super
        end

        def save!
          save :raise_on_failure => true
        end

        def update_attributes(attrs)
          update attrs
        end

        def self.create!(attrs)
          new(attrs).save :raise_on_failure => true
        end

        def self.silence_log(&block)
          if db.respond_to?(:logger) && db.logger.respond_to?(:silence)
            db.logger.silence &block
          else
            yield
          end
        end

        def self.count(attrs={})
          if attrs.respond_to?(:has_key?) && attrs.has_key?(:conditions)
            ds = self.where(attrs[:conditions])
            if attrs.has_key?(:group)
              column = attrs[:group]
              group_and_count(column.to_sym).map do |record|
                [column, record[:count]]
              end
            else
              ds.count
            end
          else
            super()
          end
        end

        # The default behaviour for sequel on #==/#eql? is to check if all
        # values are matching.
        # This differs from ActiveRecord which checks class and id only.
        # To pass the specs we're reverting to what AR does here.
        def eql?(obj)
          (obj.class == model) && (obj.pk == pk)
        end

      end
    end
  end
end
