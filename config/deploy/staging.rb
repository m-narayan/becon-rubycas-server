server "beacon.arrivu.corecloud.com", :app, :web, :db, :primary => true
set :deploy_to, "/var/capistrano/beacon/rubycas-server_staging"
set :rails_env, "staging" 