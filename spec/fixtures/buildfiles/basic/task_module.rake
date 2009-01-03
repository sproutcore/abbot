# Test import -- define a demo task

task :imported_task do
  RESULTS[:imported_task] = true
end
task :default => :imported_task
