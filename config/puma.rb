# Change to match your CPU core count
workers 2

# Min and Max threads per worker
threads 1, 6
daemonize true

app_dir = "/var/www/sample_mina"
shared_dir = "#{app_dir}/shared"

# Default to production
rails_env = ENV['RAILS_ENV'] || "production"
environment rails_env

# Set up socket location
bind "unix:///var/www/sample_mina/shared/tmp/sockets/puma.sock"

# Logging
stdout_redirect "#{shared_dir}/log/puma.stdout.log", "#{shared_dir}/log/puma.stderr.log", true

# Set master PID and state locations
pidfile "/var/www/sample_mina/shared/tmp/pids/puma.pid"
stdout_redirect "/var/www/sample_mina/shared/tmp/log/stdout", "/var/www/sample_mina/shared/tmp/log/stderr"

state_path "#{shared_dir}/pids/puma.state"
activate_control_app

on_worker_boot do
  require "active_record"
  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
  ActiveRecord::Base.establish_connection(YAML.load_file("#{shared_dir}/config/database.yml")[rails_env])
end