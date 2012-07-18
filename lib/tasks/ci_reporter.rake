begin
  require 'ci/reporter/rake/rspec'
  task :spec => ["ci:setup:rspec"]
rescue LoadError
  puts $!
end
