desc 'Release the website and new gem version'
task :deploy => [:check_version, :website, :release] do
  puts "Remember to create SVN tag:"
  puts "svn copy svn+ssh://#{rubyforge_username}@rubyforge.org/var/svn/#{PATH}/trunk " +
    "svn+ssh://#{rubyforge_username}@rubyforge.org/var/svn/#{PATH}/tags/REL-#{VERS} "
  puts "Suggested comment:"
  puts "Tagging release #{CHANGES}"
end

desc 'Runs tasks website_generate and install_gem as a local deployment of the gem'
task :local_deploy => [:website_generate, :install_gem]

task :check_version do
  unless ENV['VERSION']
    puts 'Must pass a VERSION=x.y.z release version'
    exit
  end
  unless ENV['VERSION'] == VERS
    puts "Please update your version.rb to match the release version, currently #{VERS}"
    exit
  end
end

desc 'Install the package as a gem, without generating documentation(ri/rdoc)'
task :install_gem_no_doc => [:clean, :package] do
  sh "#{'sudo ' unless Hoe::WINDOZE }gem install pkg/*.gem --no-rdoc --no-ri"
end

IGNORE_DIRS = [] unless defined?(IGNORE_DIRS)

namespace :manifest do
  desc 'Recreate Manifest.txt to include ALL files from specified locations'
  task :refresh do
    Dir.chdir(APP_ROOT)
    files = Dir.glob(File.join('**','*'))
    puts "IGNORE_DIRS = #{IGNORE_DIRS.join(',')}"
    files.reject! do |x|
      path_parts = x.split('/')

      (path_parts.last[0..0] == '.') || File.directory?(x) || IGNORE_DIRS.include?(path_parts.first)
    end

    f = File.open(File.join(APP_ROOT, 'Manifest.txt'), 'w')
    f.write(files.join("\n"))
    f.close
  end
end
