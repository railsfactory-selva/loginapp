def invoke cmds
  run cmds.join " && "
end

def run_rake task
  invoke [
    "cd #{current_path}",
    "#{rake_cmd} RAILS_ENV=#{deploy_env} #{task}"
  ]
end

namespace :vlad do
  desc "Deploy application"
  task :deploy => %w(
    vlad:setup
    vlad:update
    vlad:stop_app
    vlad:start_app
    vlad:cleanup
  )

  remote_task :start_app do
    invoke ['sudo /sbin/service unicorn restart']
  end

  remote_task :stop_app do
    invoke ['sudo /sbin/service unicorn stop']
  end

  ### After update hooks.
  task :update do
    %w(
      bundler:install
    ).each { |task| Rake::Task[task].invoke }
  end

  ### After setup hooks.
  task :setup do
    %w(
    ).each { |task| Rake::Task[task].invoke }
  end
end
