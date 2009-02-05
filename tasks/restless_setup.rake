require "#{File.dirname(__FILE__)}/../lib/restless_authentication"
require 'erb'

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

# ERB a template
def erbt(t); erb( "#{File.dirname(__FILE__)}/../templates/#{t}" ); end
def erb(t)
  ERB.new( File.open(t).read, 0, '<>' ).result
end


# Jobs usally associtated with restless_authentication installations
namespace :restless do
  ##
  ## Define the default task
  ##
  desc 'Default: run all tasks'
  task :setup => ["setup:all"]

  namespace :setup do
    ##
    ## Wrapper to call all the database setup
    ##
    desc "Used to configure a database to use restless_authentication"
    task :all do
      RAILS_ENV='test'
      Rake::Task["environment"].execute
      Rake::Task["restless:setup:modules"].execute
      Rake::Task["restless:setup:models"].execute
      Rake::Task["restless:setup:migrations"].execute
      Rake::Task["restless:setup:model_code"].execute
      Rake::Task["restless:setup:controller_code"].execute
      puts 
      puts '**Run rake restless:system'
    end

    ##
    ## Copy the user's modules into the lib directory
    ##
    desc "Copy the user modules into the user's lib directory"
    task :modules do
      #Start building out models
      puts "#{'Module Copy Begin'.ljust(40,'-')}"

        #Create my instance variable to keep record of what I've done
      @models = Hash.new
      path = "#{File.dirname(__FILE__)}/../user_modules"

        #copy my modules
      `ls #{path}`.split(/\n/).each do |f|
        puts "Copying #{f}"
        file = File.open("#{File.dirname(__FILE__)}/../../../../lib/#{f}", 'w')
        file.puts erb("#{path}/#{f}")
        file.close
      end

      puts "#{'Module Copy Finished'.ljust(40,'-')}"
      puts
    end


    ##
    ## Ensure the user has created models for the user tables
    ##
    desc "Create models for the user class and static roles"
    task :models do
      #Start building out models
      puts "#{'Model Creation Begin'.ljust(40,'-')}"

      RAILS_ENV='test'
      Rake::Task["environment"].execute
      Rake::Task["db:drop"].execute
      Rake::Task["db:migrate"].execute

        #Create my instance variable to keep record of what I've done
      @models = Hash.new

        #Go through all the different models I need for this to work
      RestlessAuthentication.list_models(false).each do |section,klass,code|
        #check if the model in the config exists
        if !class_exists?(klass)
          puts "Generating #{klass}"
          puts `ruby #{File.dirname(__FILE__)}/../../../../script/generate model #{code}`
          require "#{File.dirname(__FILE__)}/../../../../app/models/#{code}"
          @models[code] = :new
        else
          @models[code] = :extend
          puts "Found #{klass}"
        end
      end

      puts "#{'Model Creation Finished'.ljust(40,'-')}"
      puts
    end

    ##
    ## Ensure the user has created models for the user tables
    ##
    desc "Create migrations for the fields we need"
    task :migrations do
      puts "#{'Migration Creation Begin'.ljust(40,'-')}"

      RAILS_ENV='test'
      Rake::Task["environment"].execute
      Rake::Task["db:drop"].execute
      Rake::Task["db:migrate"].execute

        #Create my models list if one doesn't exist already
      @models = Hash.new if @models.nil?

        #Get my list of fields we need inside each user's models
      model_fields = RestlessAuthentication.list_fields( :code, false )
      fields_req = Hash.new

        #Now we are going to check each model and ensure they have all the
        #fields we need, if they don't then add it
      RestlessAuthentication.list_models(false).each do |section,klass,code|
          #First we need to ensure that the model exists, cause it needs to
        if class_exists?(klass)
            #If the model already has all the fields we need, then do nothing
          model_complete = true
          fields = eval(klass).column_names
          fields_req[code] = { :string => [], :timestamp => [], :integer => [] }

            #Loop through all the fields we need for this class
          model_fields[code].each do |k, v|
              #If the model doesn't have this field, then we need to add it
            if !fields.include?( v.to_s )
              model_complete = false 
              fields_req[code][k].push( ":#{v}" )
            end
          end

            #If the model is complete then we don't want to touch it
          if model_complete
            puts "#{klass} is ready to go, not going to touch it"
            @models[code] = :skip

            #If we have made a choice about the migration, confirm with user
          elsif !@models.has_key? code or @models[code] == :extend
            list = Array.new
            ary = [:extend, :inline]
            ary.size.times { |i| list[i] = "#{i} => #{ary[i]}" }
            print "{#{klass} Model} migration method: {#{list.join(',')}} [0]# "
            result = readline.chomp
            @models[code] = ary[((result.empty?)? 0: result.to_i)]
          end
        else
          puts "**Error, couldn't find #{klass}"
        end
      end

        #Get a list of all the files in the migration directory
      path = "#{File.dirname(__FILE__)}/../../../.."
      migrations = `ls #{path}/db/migrate/*.rb`.split(/\n/)

        #Go through all my migrations and build out the fields we need
      @models.each do |code, type|
        filename = nil
        state = :search
        output = Array.new

          #Got through all the possible switch cases
        case type
        when :inline, :new
          filename = migrations.detect{|x| x =~ /create_#{code.pluralize}\.rb/}
          puts "Updating #{filename}"
        when :extend
          puts "Generating migration"
          mig = `ruby #{path}/script/generate migration restless_update_#{code}`
          filename = mig.sub(/.*create.*\//, '').chomp
          puts mig
          puts "Adding data to #{filename}"
        else
          puts "Skipping #{code} of type #{type}"
        end

          #If we were given a filename to update, then add our lines to it
        if !filename.nil?
          match = "create_table[\\t ]+:#{code.pluralize}"
          RestlessAuthentication.insert_code( filename, match ) { |sp, tv|
            output = Array.new
            
              #Insert my code
            output.push("#{sp}  #--Inserted by Restless Authentication")
            fields_req[code].sort{|a,b| a[0].to_s<=>b[0].to_s}.each do |t, v|
              output.push( "#{sp}#{tv}.#{t} #{v.join(', ')}") if v.size > 0
            end
            output.push( "#{sp}#{tv}.timestamps")
            output.push("#{sp}  #--End insert")
          }
        end
      end

      puts "#{'Migration Creation Finished'.ljust(40,'-')}"
      puts
    end

    ##
    ## Ensure the user has created models for the user tables
    ##
    desc "Add the requried model code into the user's models"
    task :model_code do
        #Print out what we're doing
      puts "#{'Model Code Insertion Begin'.ljust(40,'-')}"

      RAILS_ENV='test'
      Rake::Task["environment"].execute
      Rake::Task["db:drop"].execute
      Rake::Task["db:migrate"].execute

        #Go through all the models I use and insert my code into them
      path = "#{File.dirname(__FILE__)}/../../../../app/models"
      db = RestlessAuthentication.database(false)
      RestlessAuthentication.list_models(false).each do |section,klass,code|
          #ensure that we already have a class
        if !class_exists?(klass)
          puts "** Error, no class #{klass}, skipping"
        else
            #Create my first line insert data
          output = Array.new
          output.push("  #--Inserted by Restless Authentication")

          case section
          when :user
            output.push("require 'digest/md5'")
            output.push("require 'digest/sha1'")
          when :role
            output.push("require 'restless_static_role'")
          else 
          end
          output.push("  #--End insert")
          output.push( '' )

            #Create my local variables of who we are editing
          filename = "#{path}/#{code}.rb"
          match = "class #{klass.to_s}"
          result = RestlessAuthentication.insert_code(filename, match, output){
            |sp, tv|
            output = Array.new
            
              #Insert my code
            output.push("#{sp}  #--Inserted by Restless Authentication")
            case section
            when :user
              output.push("#{sp}has_many :#{db.user.role_relationship}, :class_name => '#{db.role.model.to_s}', :foreign_key => '#{db.role.user_id_ifield}', :dependent => :destroy")
              output.push('')
              output.push(erbt("modules/restless_user.rb"))
            when :role
              output.push("#{sp}belongs_to :#{db.role.user_relationship}, :class_name => '#{db.user.model.to_s}', :foreign_key => '#{db.role.user_id_ifield}'")
              output.push('')
              output.push(erbt("modules/restless_static_role.rb"))
            else
            end
            output.push("#{sp}  #--End insert")
          }

            #tell the user what happened
          if result
            puts "Successfully wrote data to #{filename}"
          else
            puts "** Failed write to #{filename}"
          end
        end
      end
      
      puts "#{'Model Code Insertion Finished'.ljust(40,'-')}"
      puts
    end

    ##
    ## Add in the static filters into the user's controller
    ##
    desc "Add requried controller code to the application controller"
    task :controller_code do
        #Print out what we're doing
      puts "#{'Controller Code Insertion Begin'.ljust(40,'-')}"

      RAILS_ENV='test'
      Rake::Task["environment"].execute
      Rake::Task["db:drop"].execute
      Rake::Task["db:migrate"].execute

        #Go through all the models I use and insert my code into them
      path = "#{File.dirname(__FILE__)}/../../../../app/controllers"
      db = RestlessAuthentication.database(false)

        #Create my first line insert data
      output = Array.new
      output.push("  #--Inserted by Restless Authentication")
      output.push("require 'restless_static_filter'")
      output.push("require 'restless_auth_system'")
      output.push("  #--End insert")
      output.push( '' )

        #Create my local variables of who we are editing
      filename = "#{path}/application.rb"
      match = "class ApplicationController"
      result = RestlessAuthentication.insert_code(filename, match, output){
        |sp, tv|
        output = Array.new
        
          #Insert my code
        output.push("#{sp}  #--Inserted by Restless Authentication")
        output.push("#{sp}include RestlessStaticFilter")
        output.push("#{sp}include RestlessAuthSystem")
        output.push('')
        output.push("#{sp}before_filter :restless_filter")
        output.push("#{sp}  #--End insert")
      }

         #tell the user what happened
      if result
        puts "Successfully wrote data to #{filename}"
      else
        puts "** Failed write to #{filename}"
      end

      puts "#{'Controller Code Insertion Finished'.ljust(40,'-')}"
      puts
    end
  end
end

