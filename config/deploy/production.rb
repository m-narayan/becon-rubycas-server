server "cas.beaconlearning.in", :app, :web, :db, :primary => true
set :deploy_to, "/var/capistrano/beacon/rubycas-server"
set :scm_passphrase, "deployadmin123$"
set :branch, "production"

