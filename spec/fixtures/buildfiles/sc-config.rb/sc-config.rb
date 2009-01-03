Kernel.const_reset :RESULTS, {}

task :default => :test_task1

task :test_task1 do
 RESULTS[:test_task1] = true
end
