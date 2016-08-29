# config/development.rb

# Specify all the servers to deploy to , example set :domains, %w[host1 host2 host3] for load balancers
set :domain, 'localhost'
set :deploy_to, '/var/www/sample_mina'
set :app_path, lambda { "#{deploy_to}/#{current_path}" }
set :repository, 'git@github.com:tmkdam/sample_mina.git'
set :branch, 'development'
set :forward_agent, true
set :port, '2222'  
set :user, 'deployer'
set :rails_env, 'development'