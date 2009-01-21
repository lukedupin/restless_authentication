require "#{File.dirname(__FILE__)}/../lib/restless_authentication"

# Jobs usally associtated with restless_authentication installations
namespace :restless do
  namespace :setup do
    #Wrapper to call all the database setup
    desc "Used to configure a database to use restless_authentication"
    task :database => [:models, :migrations, :model_code]

    #Ensure the user has created models for the user tables
    desc "Create models for the user class and static roles"
    task :models do
        #Create my instance variable to keep record of what I've done
      @models = Array.new

        #Go through all the different models I need for this to work
      tables = Array.new
      tables.push( RestlessAuthentication.database.user.model.to_s )
      tables.push( RestlessAuthentication.database.role.model.to_s )
      tables.sort!
      tables.push( "#{tables[0].pluralize}_#{tables[1]}" )
      tables.each do |table|
        #check if the model in the config exists
        model_name = table.split(/_/).collect{|x| x.capitalize}.join('')
        if !defined? eval(model_name)_
          puts "Generating #{model_name)}"
          `ruby #{File.dirname(__FILE__)}/../../../../script/generate model #{table}`
          @models.push( model_name )
        else
          puts "Found #{model_name}"
        end
      end
    end

    #Ensure the user has created models for the user tables
    desc "Create migrations for the fields we need"
    task :migrations do
      
      
    end

    #Ensure the user has created models for the user tables
    desc "Add the requried model code into the user's models"
    task :model_code do
      puts "Model Code"
    end
  end
end

