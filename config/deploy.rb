require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
# require 'mina/rbenv'  # for rbenv support. (http://rbenv.org)
require 'mina/rvm'    # for rvm support. (http://rvm.io)
require 'mina/puma'

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :user, 'deployer'
set :domain, 'localhost'
set :deploy_to, '/var/www/sample_mina'
set :app_path, lambda { "#{deploy_to}/#{current_path}" }
set :repository, 'git@github.com:tmkdam/sample_mina.git'
set :branch, 'master'
set :forward_agent, true
set :port, '2222'  
# For system-wide RVM install.
#   set :rvm_path, '/usr/local/rvm/bin/rvm'

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['config/database.yml', 'config/secrets.yml', 'log']

# Optional settings:
#   set :user, 'foobar'    # Username in the server to SSH to.
#   set :port, '30000'     # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  invoke :'rvm:use[ruby-2.2.2@default]'
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/log"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/config"]

  # write script to copy file from initial deploy rather than touch
  queue! %[touch "#{deploy_to}/#{shared_path}/config/database.yml"]
  queue! %[touch "#{deploy_to}/#{shared_path}/config/secrets.yml"]
  queue  %[echo "-----> Be sure to edit '#{deploy_to}/#{shared_path}/config/database.yml' and 'secrets.yml'."]

  queue! %(mkdir -p "#{deploy_to}/#{shared_path}/tmp/sockets")
  queue! %(chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/tmp/sockets")
  
  queue! %(mkdir -p "#{deploy_to}/#{shared_path}/tmp/pids")
  queue! %(chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/tmp/pids")

  if repository
    repo_host = repository.split(%r{@|://}).last.split(%r{:|\/}).first
    repo_port = /:([0-9]+)/.match(repository) && /:([0-9]+)/.match(repository)[1] || '22'

    queue %[
      if ! ssh-keygen -H  -F #{repo_host} &>/dev/null; then
        ssh-keyscan -t rsa -p #{repo_port} -H #{repo_host} >> ~/.ssh/known_hosts
      fi
    ]
  end
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    to :launch do
      invoke :'puma:restart'
    end
  end
end

desc 'Rollbacks the latest release with restart'
task rollback: :environment do
  comment "Rolling back to previous release"

  in_path "#{fetch(:releases_path)}" do
    # TODO: add check if there are more than 1 release
    command "rollback_release=`ls -1A | sort -n | tail -n 2 | head -n 1`"
    comment 'Rollbacking to release: $rollback_release'
    command "ln -nfs #{fetch(:releases_path)}/$rollback_release #{fetch(:current_path)}"
    command "current_release=`ls -1A | sort -n | tail -n 1`"
    comment 'Deleting current release: $current_release'
    command "rm -rf #{fetch(:releases_path)}/$current_release"
  end
  invoke :'puma:restart'
end

# namespace :puma do
#   desc "Start the application"
#   task :start do
#     queue 'echo "-----> Start Puma"'
#     queue "cd #{app_path} && RAILS_ENV=#{stage} && bin/puma.sh start" #, :pty => false
#   end

#   desc "Stop the application"
#   task :stop do
#     queue 'echo "-----> Stop Puma"'
#     queue "cd #{app_path} && RAILS_ENV=#{stage} && bin/puma.sh stop"
#   end

#   desc "Restart the application"
#   task :restart do
#     queue 'echo "-----> Restart Puma"'
#     queue "cd #{app_path} && RAILS_ENV=#{stage} && bin/puma.sh restart"
#   end
# end

# For help in making your deploy script, see the Mina documentation:
#
#  - http://nadarei.co/mina
#  - http://nadarei.co/mina/tasks
#  - http://nadarei.co/mina/settings
#  - http://nadarei.co/mina/helpers
