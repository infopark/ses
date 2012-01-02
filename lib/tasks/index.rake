require "resque/tasks"

namespace :index do
  desc "Re-index all objects"
  task :all => :environment do
    i = Infopark::SES::Indexer.new
    i.reindex_all
  end

  namespace :worker do
    desc "Start the worker"
    task :start => :environment do
      if worker_running?
        puts "Worker is already running"
      else
        sh "nohup bundle exec rake environment resque:work RAILS_ENV=production QUEUE=#{Infopark::SES::Indexer.queue} VERBOSE=1 PIDFILE=#{worker_pid_file} >> log/resque_worker_#{Infopark::SES::Indexer.queue}.log 2>&1 &"
      end
    end

    desc "Stop the worker"
    task :stop => :environment do
      if worker_running?
        sh "kill -QUIT #{worker_pid} && rm -f #{worker_pid_file}; true"
      else
        puts "Worker was not running"
      end
    end

    desc "Restart the worker"
    task :restart do
      Rake::Task["index:worker:stop"].invoke
      Rake::Task["index:worker:start"].invoke
    end

    desc "Reports the status of the worker"
    task :status => :environment do
      if worker_running?
        puts "Worker is running"
      else
        puts "Worker is not running"
      end
    end

    def worker_running?
      worker_pid && Process.getpgid(worker_pid)
    rescue Errno::ESRCH
      false
    end

    def worker_pid
      worker_pid_file.read.to_i
    rescue Errno::ENOENT
      nil
    end

    def worker_pid_file
      Rails.root + "tmp/pids/resque_worker_#{Infopark::SES::Indexer.queue}.pid"
    end
  end
end
