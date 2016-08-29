# SHUSA /config/puma.rb
# Tmkdam

# Change to match your CPU core count
# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked webserver processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
#
workers Integer(ENV['WEB_CONCURRENCY'] || 2)

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum, this matches the default thread size of Active Record.
#
min_threads_count = Integer(ENV['RAILS_MIN_THREADS'] || 1)
max_threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads min_threads_count, max_threads_count

# Use following in production
if ENV['RAILS_ENV'] = "production"
	# Run in background
	daemonize true

	app_name = "sample_mina"
	app_dir = "/var/www/#{app_name}"
	shared_dir = "#{app_dir}/shared"

	# Specifies the `environment` that Puma will run in.
	# Default to production
	#
	rails_env = ENV['RAILS_ENV'] || "production"
	environment rails_env

	# Test for enviorment before enabling
	preload_app!

	# Set up socket location
	bind "unix:///var/www/#{app_name}/shared/tmp/sockets/puma.sock"

	# Logging
	stdout_redirect "#{shared_dir}/log/puma.stdout.log", "#{shared_dir}/log/puma.stderr.log", true

	# Set master PID and state locations
	pidfile "/var/www/#{app_name}/shared/tmp/pids/puma.pid"
	stdout_redirect "/var/www/#{app_name}/shared/tmp/log/stdout", "/var/www/#{app_name}/shared/tmp/log/stderr"

	state_path "#{shared_dir}/pids/puma.state"
	activate_control_app

	# The code in the `on_worker_boot` will be called if you are using
	# clustered mode by specifying a number of `workers`. After each worker
	# process is booted this block will be run, if you are using `preload_app!`
	# option you will want to use this block to reconnect to any threads
	# or connections that may have been created at application boot, Ruby
	# cannot share connections between processes.
	# 
	on_worker_boot do
	  require "active_record"
	  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
	  ActiveRecord::Base.establish_connection(YAML.load_file("#{shared_dir}/config/database.yml")[rails_env])
	end
end
