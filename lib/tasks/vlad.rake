begin
  require "vlad"
  Vlad.load :web => nil, :app => nil, :scm => :git, :config => "deploy/deploy.rb"
rescue LoadError
  puts $!
end

deploy_home = File.join File.dirname(__FILE__), "..", "..", "deploy"
Dir[File.join deploy_home, "tasks", "*.rake"].each { |rake| load rake }
