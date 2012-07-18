##
# This recipe relies on the vlad-unikorn gem.
# https://github.com/retr0h/vlad-unikorn
#
# OS X 'brew install proctools'

require "etc"

namespace :unicorn do
  task :start => :stop do
    config = File.join current_path, "config", "unicorn.rb"

    sh "unicorn_rails -D -c #{config} -E #{ENV['RAILS_ENV']}"
  end

  task :stop do |task|
    sh "pkill -u #{Etc.getlogin} -f '[u]nicorn_rails master.*8080'" rescue nil
  end
end
