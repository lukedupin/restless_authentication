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

      puts `ruby #{File.dirname(__FILE__)}/../../../../script/generate scaffold #{RestlessAuthentication.database.user.model.to_s} #{fields.collect{|x| "#{x}:string"}.join(' ')} password1:string password2:string`

      puts "#{'Finished user scaffold'.ljust(40,'-')}"
      puts
    end

    ##
    ## Create a usable login system
    ##
    desc "Create a basic session management system"
    task :create_login_system do
      #Create a user scaffold
      puts "#{'Creating basic session management'.ljust(40,'-')}"

        #Create my session controller
      puts `ruby #{File.dirname(__FILE__)}/../../../../script/generate controller sessions`

        #Copy my session controller
      File.copy( "#{File.dirname(__FILE__)}/../app/controllers/sessions_controller.rb", "#{File.dirname(__FILE__)}/../../../../app/controllers/sessions_controller.rb")
      File.copy( "#{File.dirname(__FILE__)}/../app/views/sessions/new.html.erb", "#{File.dirname(__FILE__)}/../../../../app/views/sessions/new.html.erb")
      File.copy( "#{File.dirname(__FILE__)}/../app/views/layouts/session.html.erb", "#{File.dirname(__FILE__)}/../../../../app/views/layouts/session.html.erb")

      puts "#{'Finished basic session management'.ljust(40,'-')}"
      puts
    end

    ##
    ## Add the admin role into our system
    ##
    desc "Create the admin role inside the system"
    task :create_admin_role do
      #Create a user scaffold
      puts "#{'Creating admin role'.ljust(40,'-')}"

        #Create the role type of admin
      path = "#{File.dirname(__FILE__)}/../../../.."

        #Insert the admin role into our roles model
      filename = "#{path}/app/models/role.rb"
      match = "class Role"
      result = RestlessAuthentication.insert_code(filename, match){
        |sp, tv|
        output = Array.new

          #Insert my code
        output.push("#{sp}  #--Inserted by Restless Authentication")
        output.push("#{sp}define_roles { :admin => 1 }")
        output.push("#{sp}  #--End insert")
      }
  
        #Add the admin role requirement to editing users
      filename = "#{path}/app/controllers/user_controller.rb"
      match = "class UserController"
      result = RestlessAuthentication.insert_code(filename, match){
        |sp, tv|
        output = Array.new

          #Insert my code
        output.push("#{sp}  #--Inserted by Restless Authentication")
        output.push("#{sp}define_required_roles(:all, :admin)")
        output.push("#{sp}  #--End insert")
      }

      puts "#{'Finished admin role'.ljust(40,'-')}"
      puts
    end

    ##
    ## Add the admin role into our system
    ##
    desc "Create the admin role inside the system"
    task :create_admin do
      #Create a user scaffold
      puts "#{'Creating admin user'.ljust(40,'-')}"

        #Create a migration adding the default admin user
      path = "#{File.dirname(__FILE__)}/../../../.."
      puts `ruby #{path}/script/generate migration create_default_admin`

        #Find the migration
      file = nil
      `ls #{path}/db/migrate/`.split(/\n/).each do |mig|
        file = mig if mig =~ /create_default_admin/
      end

      if !file.nil?
          #Create my add admin user section
        match = "self\\.up"
        RestlessAuthentication.insert_code( filename, match ) { |sp, tv|
          output = Array.new

            #Insert my code
          output.push("#{sp}  #--Inserted by Restless Authentication")
          output.push("#{sp}user = User.new")
          output.push("#{sp}user.#{RestlessAuthentication.database.user.usernames.username_sfield} = 'admin'")
          output.push("#{sp}user.#{RestlessAuthentication.authentication.helpers.password_method}( 'restless', 'restless' )")
          output.push("#{sp}user.save")
          output.push("#{sp}  #--End insert")
        }

          #Create my remove admin section
        match = "self\\.down"
        RestlessAuthentication.insert_code( filename, match ) { |sp, tv|
          output = Array.new

            #Insert my code
          output.push("#{sp}  #--Inserted by Restless Authentication")
          output.push("#{sp}user = User.find_by_#{RestlessAuthentication.database.user.usernames.username_sfield}( 'admin' )"
          output.push("#{sp}user.destroy if !user.nil?")
          output.push("#{sp}  #--End insert")
        }
      end

      puts "#{'Finished admin user'.ljust(40,'-')}"
      puts
    end
  end
end
