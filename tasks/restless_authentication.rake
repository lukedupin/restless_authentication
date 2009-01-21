require "#{File.dirname(__FILE__)}/../lib/restless_authentication"

#Used to read in data safely, gets inside rails has issues
def readline; $stdin.readline; end

# Jobs usally associtated with restless_authentication installations
namespace :restless do
  namespace :setup do
    #Wrapper to call all the database setup
    desc "Used to configure a database to use restless_authentication"
    task :database => [:models, :migrations, :model_code]

    #Ensure the user has created models for the user tables
    desc "Create models for the user class and static roles"
    task :models do
      puts "#{'Model Creation Begin'.ljust(30,'-')}"
        #Create my instance variable to keep record of what I've done
      @models = Hash.new

        #Go through all the different models I need for this to work
      RestlessAuthentication.list_models(false, :both).each do |code,klass|
        #check if the model in the config exists
        if !defined? eval(klass)
          puts "Generating #{klass}"
          `ruby #{File.dirname(__FILE__)}/../../../../script/generate model #{code}`
          @models[klass] = :full
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
    task :migrations do
      puts "#{'Migration Creation Begin'.ljust(30,'-')}"

        #Create my models list if one doesn't exist already
      @models = Hash.new if @models.nil?

        #Now we are going to check each model and ensure they have all the
        #fields we need, if they don't then add it
      RestlessAuthentication.list_models(false, :both).each do |code,klass|
          #First we need to ensure that the model exists, cause it needs to
        if defined? eval(klass)
          if !@models.has_key? klass or @models[klass] != :full
            list = Array.new
            ary = [:full, :extend]
            ary.size.times { |i| list[i] = "#{i} => #{ary[i]}" }
            print "#{klass} migration update method: {#{list.join(',')}} [0]# "
            result = readline.chomp
            @models[klass] = ary[((result.empty?)? 0: result.to_i)]
          end
        else
          puts "**Error, couldn't find #{klass}"
        end
      end

      puts "#{'Migration Creation Finished'.ljust(30,'-')}"
      puts
    end

    #Ensure the user has created models for the user tables
    desc "Add the requried model code into the user's models"
    task :model_code do
    end
  end
end

