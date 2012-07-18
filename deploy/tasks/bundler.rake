namespace :bundler do
  remote_task :install, :roles => :app do
    invoke [
      "cd #{release_path}",
      "bundle install --without development test --path #{shared_path}/system/gems",
    ]
  end
end
