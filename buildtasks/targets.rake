namespace :targets do

  def targets_for(root_path, root_name, project)
    target_types = { :apps => :app, :clients => :app, :frameworks => :framework }
    target_types.each do |dir_name, target_type|
      dir_path = File.join(root_path, dir_name.to_s)
      if File.directory?(dir_path)
        Dir.glob(File.join(dir_path, '*')).each do |path|
          next unless File.directory?(path)
          target_name = [root_name, File.basename(path)].compact.join('/')
          project.add_target(target_name, :source_root => path, :type => target_type)
          targets_for(path, target_name, project)
        end
      end
    end
  end
  
  task :find do
    targets_for(PROJECT.root_path, nil, PROJECT)
  end
  
end
