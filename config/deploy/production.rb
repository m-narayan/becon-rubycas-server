server "cas.beaconlaerning.com", :app, :web, :db, :primary => true
set :deploy_to, "/var/capistrano/beacon/rubycas-server"