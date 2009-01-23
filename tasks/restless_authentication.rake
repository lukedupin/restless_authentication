require "#{File.dirname(__FILE__)}/../lib/restless_authentication"

RAILS_ENV='test'
#require "#{File.dirname(__FILE__)}/../../../../config/boot"
#require 'active_record'

#Used to read in data safely, gets inside rails has issues
def readline; $stdin.readline; end
def hashTraverse( hash, d = Array.new, &p )
  hash.each do |k, v|
    (v.is_a? Hash)? hashTraverse(v, d.dup.push(k)): p.call(k, v, d)
  end
end

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
          @models[code] = :new
        else
          @models[code] = :extend
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
      Rake::Task["db:drop"].execute
      Rake::Task["db:migrate"].execute

        #Create my models list if one doesn't exist already
      @models = Hash.new if @models.nil?

        #Get my list of fields we need inside each user's models
      @model_fields = Hash.new
      RestlessAuthentication.list_models(false, :both).each do |code,klass|
        @model_fields[code] = Array.new
        hashTraverse(RestlessAuthentication['database'][code]) do |k, v, depth|
          @model_fields[code].push( [k.to_s, v] ) if k.to_s =~ /field/
        end
      end

        #Now we are going to check each model and ensure they have all the
        #fields we need, if they don't then add it
      RestlessAuthentication.list_models(false, :both).each do |code,klass|
          #First we need to ensure that the model exists, cause it needs to
        if class_exists?(klass)
            #If the model already has all the fields we need, then do nothing
          model_complete = true
          eval(klass).column_fields.each do |f|
            model_complete = false if !@model_fields[code].detect{|x| x[1] == f}
          end

            #If the model is complete then we don't want to touch it
          if model_complete
            puts "#{klass} is ready to go, not going to touch it"
            @models[code] = :skip

            #If we have made a choice about the migration, confirm with user
          elsif !@models.has_key? klass or @models[code] == :extend
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
      migrations = `ls #{File.dirname(__FILE__)}/../../../../db/migrate/*.rb`
      migrations.split!(/\n/)

        #Go through all my migrations and build out the fields we need
      @models.each do |code, type|
        case type
        when :inline, :new
          state = :search
          output = Array.new
          filename = migrations.detect{|x| x =~ /create_#{code.pluralize}\.rb/}
          File.open(filename).readlines do |line|
            case state
            when :search        #Search for the create table call
              if line =~ /^=begin/
                state = :comment_block
              elsif line.sub(/#.*/,'') =~ /create_table[\t ]+:#{code.pluralize}/
                state = :insert
              end
            when :comment_block #Skip over a comment block
              state = :search if line =~ /^=end/
            when :insert        #Insert my fields into this baby
              hash = { :string => [], :timestamp => [], :integer => [] }
              @models[code].each do |k, v|  #TODO create a variable that has on ly the missing variables
                hash[:string].push(":#{v}") if k =~ /_sfield/
                hash[:timestamp].push(":#{v}") if k =~ /_tfield/
                hash[:integer].push(":#{v}") if k =~ /_ifield/
              end
              table_var = 't'
              hash.each do |type, values|
                output.push( "#{table_var}.#{type.to_s}  #{values.join(', ')}")
              end
              state = :done
            else                #Likely in the done case
            end

              #Always keep the original contents
            output.push(line)
          end
        when :extend
        else
          puts "Skipping #{klass} of type #{type}"
        end
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

