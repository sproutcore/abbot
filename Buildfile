import(*Dir.glob(File.join(File.dirname(__FILE__),'buildtasks', '**', '*.rake')))

# This task will build a particular entry.  You must pass into the parameters
# the final buildpath
task :build do
  target = PROJECT.target_for(OPTS.target_name)
  CONFIG.variations.each do |variation|
    target.manifest_for(variation).build!
  end
end
    
namespace :bundle do
  desc "main entrypoint for defining the build number"
  task :compute_build_number
end

namespace :manifest do
  desc "main entrypoint for the manifest build system."
  task :build
end

config :all, :url_prefix => 'static'


# project :sproutcore do
#   
#   target :bundle do
#     
#     def find_sproutcore_bundles_in(root_path, project, parent_name = '')
#       %w(apps clients).each do |dir_path|
#         dir_path = File.join root_path, dir_path
#         next unless File.directory? dir_path
#         Dir.glob(File.join(dir_path, '*')).each do |source_root|
#           next unless File.directory? source_root
#           target_name = [parent_name, File.basename(source_root)] * '/'
#           project.add_target target_name, 'sproutcore:app', 
#             :source_root => source_root
#           find_sproutcore_bundles_in source_root, project, target_name
#         end
#       end
# 
#       dir_path = File.join root_path, 'frameworks'
#       return unless File.directory? dir_path
#       Dir.glob(File.join(dir_path, '*')).each do |source_root|
#         next unless File.directory? source_root
#         target_name = [parent_name, File.basename(source_root)] * '/'
#         project.add_target target_name, 'sproutcore:framework', 
#           :source_root => source_root
#         find_sproutcore_bundles_in source_root, project, target_name
#       end
#     end
#       
#     # This task will be executed once per-project.  It should find all 
#     # SproutCore-style bundles.  Note the use of the helper method.
#     task :find do
#       find_sproutcore_bundles_in(PROJECT.project_root, PROJECT)
#     end
#     
#   end
#   
#   target :app => :bundle do
#     
#   end
#   
#   target :framework => :bundle do
#     
#   end
#   
# end    
# 
# 
# namespace :sproutcore do
#   
#   target :bundle do
#     task :prepare
#   end
#   
#   target :app => :bundle
#   target :framework => :bundle
# 
#   task :find_targets do
#     # search for SproutCore targets.  Assign target type
#   end
#   
#   namespace :build do
#     
#     build_task :javascript => 'build:javascript' do
#     end
#     
#   end
#   
# end
# task 'project:find_targets' => 'sproutcore:find_targets'
#   
# namespace :build do
#   
#   build_task :copy do
# 
#     action do
#       File.cp(src_path, dst_path)
#     end
#     
#     # define if the item is out of date.  If it is not out of date, the task
#     # and its dependents will not be executed.
#     condition do
#       dst_mtime = File.exist?(dst_path) ? File.mtime(dst_path).to_i : 0
#       out_of_date = false
#       src_paths.each do |path|
#         src_mtime = File.exist?(path) ? File.mtime(path).to_i : 0
#         break if out_of_date = src_mtime >= dst_mtime
#       end
#       out_of_date
#     end
#     
#   end
# 
# end

