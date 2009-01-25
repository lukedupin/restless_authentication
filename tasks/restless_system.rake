require "#{File.dirname(__FILE__)}/../lib/restless_authentication"

#Used to read in data safely, gets inside rails has issues
def readline; $stdin.readline; end

#Returns true if the a class exists by the given name
def class_exists?( name )
  begin
    eval(name)
    return true
  rescue
    return false
  end
end


# Jobs usally associtated with restless_authentication installations
namespace :restless do
  ##
  ## Define the default task
  ##
  desc 'Default: Run all the system generation tasks'
  task :system => ["system:all"]

  namespace :system do
    ##
    ## Wrapper to call all the system setup tasks
    ##
    desc "Used to configure a basic system with user login and user management"
    task :all do
      RAILS_ENV='test'
      Rake::Task["environment"].execute
      Rake::Task["restless:system:user"].execute
#      Rake::Task["restless:system:session"].execute
      Rake::Task["restless:system:default_user"].execute
    end

    ##
    ## Ensure the user has created models for the user tables
    ##
    desc "Create a user scaffold"
    task :user do
      #Create a user scaffold
      puts "#{'Creating user scaffold'.ljust(40,'-')}"

      RAILS_ENV='test'
      Rake::Task["environment"].execute
      Rake::Task["db:drop"].execute
      Rake::Task["db:migrate"].execute

        #Get a list of all the fields we are going to add for the user
      usr = RestlessAuthentication.database.user
      skip = [usr.passwords.plain_text_sfield, 
              usr.passwords.encrypted_sfield, usr.cookies.token_sfield]

        #Spit out a list of fields we are going to use
      fields = Array.new
      RestlessAuthentication.database.user.model.columns.each do |field|
        if field.type == :string and !skip.include?( field.name.to_sym )
          fields.push( field.name ) 
        end
      end

      puts 'ruby #{File.dirname(__FILE__)}/../../../../script/generate scaffold #{RestlessAuthentication.database.user.model.to_s} #{fields.collect{|x| "#{x}:string"}.join(' ')} password1:string password2:string'

      puts "#{'Finished user scaffold'.ljust(40,'-')}"
      puts
    end
  end

    ##
    ## Ensure Create a default admin user and admin rights in the system
    ##
    desc "Create a user scaffold"
    task :default_user do
      #Create a user scaffold
      puts "#{'Creating admin user'.ljust(40,'-')}"

      puts "#{'Finished admin user'.ljust(40,'-')}"
      puts
    end
  end
end
