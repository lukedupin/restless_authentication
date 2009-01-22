require "#{File.dirname(__FILE__)}/../lib/restless_authentication"

RAILS_ENV='test'
#require "#{File.dirname(__FILE__)}/../../../../config/boot"
#require 'active_record'

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
  namespace :setup do
    #Wrapper to call all the database setup
    desc "Used to configure a database to use restless_authentication"
    task :database => [:models, :migrations, :model_code, :environment]

    #Ensure the user has created models for the user tables
    desc "Create models for the user class and static roles"
    task :models => :environment do
      puts "#{'Model Creation Begin'.ljust(30,'-')}"

        #Create my instance variable to keep record of what I've done
      @models = Hash.new

        #Go through all the different models I need for this to work
      RestlessAuthentication.list_models(false, :both).each do |code,klass|
        #check if the model in the config exists
        if !class_exists?(klass)
          puts "Generating #{klass}"
          puts `ruby #{File.dirname(__FILE__)}/../../../../script/generate model #{code}`
          require "#{File.dirname(__FILE__)}/../../../../app/models/#{code}"
          @models[klass] = :new
        else
          @models[klass] = :extend
          puts "Found #{klass}"
        end
      end

      puts "#{'Model Creation Finished'.ljust(30,'-')}"
      puts
    end

    #Ensure the user has created models for the user tables
    desc "Create migrations for the fields we need"
    task :migrations => :environment do
      puts "#{'Migration Creation Begin'.ljust(30,'-')}"

        #Clean out the test database
      VERSION=0
      Rake::Task["db:migrate"].execute
      VERSION=nil
      Rake::Task["db:migrate"].execute

        #Create my models list if one doesn't exist already
      @models = Hash.new if @models.nil?

        #Now we are going to check each model and ensure they have all the
        #fields we need, if they don't then add it
      RestlessAuthentication.list_models(false, :both).each do |code,klass|
          #First we need to ensure that the model exists, cause it needs to
        if class_exists?(klass)
            #If the model already has all the fields we need, then do nothing
          

            #If we have made a choice about the migration, confirm with user
          if !@models.has_key? klass or @models[klass] == :extend
            list = Array.new
            ary = [:extend, :full]
            ary.size.times { |i| list[i] = "#{i} => #{ary[i]}" }
            print "{#{klass} Model} migration method: {#{list.join(',')}} [0]# "
            result = readline.chomp
            @models[klass] = ary[((result.empty?)? 0: result.to_i)]
          end
        else
          puts "**Error, couldn't find #{klass}"
        end
      end

        #Go through all my migrations and build out the fields we need
      @models.each do |klass, type|
      end

      puts "#{'Migration Creation Finished'.ljust(30,'-')}"
      puts
    end

    #Ensure the user has created models for the user tables
    desc "Add the requried model code into the user's models"
    task :model_code => :environment do
    end
  end
end

