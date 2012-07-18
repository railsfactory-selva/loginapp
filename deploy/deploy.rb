task :test_san1 do
  set :domain,     "#{app_user}@10.2.0.8"
  set :deploy_env, "test_san1"
  set :kms_port, "8080"
end

task :perf_san1 do
  set :domain,    ["#{app_user}@10.2.0.26","#{app_user}@10.2.0.136"]
  set :deploy_env, "perf_san1"
end

task :'dev-perf_san1' do
  set :domain,     ["#{app_user}@10.2.0.92","#{app_user}@10.2.0.127"]
  set :deploy_env, "dev-perf_san1"
end

task :prod_san1 do
  set :domain,     ["#{app_user}@10.2.0.47","#{app_user}@10.2.0.108"]
  set :deploy_env, "prod_san1"
end

task :uat_san1 do
  set :domain,     ["#{app_user}@10.2.0.56","#{app_user}@10.2.0.117"]
  set :deploy_env, "uat_san1"
end

task :dev_san1 do
  set :domain,     "#{app_user}@10.2.0.93"
  set :deploy_env, "dev_san1"
end

task :'blackflag-dev_san2' do
  set :domain,     "#{app_user}@10.6.11.24"
  set :deploy_env, "blackflag-dev_san2"
end

task :'blackflag-test_san2' do
  set :domain,     "#{app_user}@10.6.17.14"
  set :deploy_env, "blackflag-test_san2"
end

task :'blackflag-dev-test_san2' do
  set :domain,     "#{app_user}@10.6.12.31"
  set :deploy_env, "blackflag-dev-test_san2"
end

task :'blackflag-perf_san2' do
  set :domain,     "#{app_user}@10.6.20.20"
  set :deploy_env, "blackflag-perf_san2"
end

task :'blackflag-uat_san2' do
  set :domain,     "#{app_user}@10.6.21.18"
  set :deploy_env, "blackflag-uat_san2"
end

task :'blackflag-prod_ewr1' do
  set :domain,     "[#{app_user}@10.0.36.15,#{app_user}@10.0.36.20]"
  set :deploy_env, "blackflag-prod_ewr1"
end

task :'blackflag-uat_ewr1' do
  set :domain,     "#{app_user}@10.0.144.14"
  set :deploy_env, "blackflag-uat_ewr1"
end

task :'blackflag-dev_ewr1' do
  set :domain,     "#{app_user}@10.0.148.14"
  set :deploy_env, "blackflag-dev_ewr1"
end

task :'blackflag-dev-test_ewr1' do
  set :domain,     "[#{app_user}@10.0.156.14,#{app_user}@10.0.156.22]"
  set :deploy_env, "blackflag-dev-test_ewr1"
end


task :prod_dfw1 do
  set :domain,     ["#{app_user}@10.1.7.14","#{app_user}@10.1.7.7"]
  set :deploy_env, "prod_dfw1"
end

task :'apifoundry-dev' do
  set :domain,     "#{app_user}@10.4.45.12"
  set :deploy_env, "apifoundry-dev"
end

set :application, "login"
set :app_user   , "deploy"
set :deploy_to  , "/var/www/apps/#{application}"
set :repository , "git@github.com:att-innovate/apigee-login.git"
set :rake_cmd   , 'bundle exec rake'
set :ssh_flags  , %w{-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -A -q}
set :revision   , ENV['GIT_REVISION'] if ENV['GIT_REVISION'] 
