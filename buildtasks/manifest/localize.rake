namespace :manifest do

  desc "localize will remove any entries that do not belong in the target language.  This includes any resources in other languages or resources in the default language that are also in the target language.  This looks at the CONFIG.preferred_language option, if specified.  A language will also be assigned to the entry"
  task :localize => :catalog do
    clang = MANIFEST.language || :en
    plang = CONFIG.preferred_language || clang
    
    MANIFEST.entries.each do |entry|

    end
    
  end
  task :build => :localize
  
end
