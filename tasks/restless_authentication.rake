require "#{File.dirname(__FILE__)}/../lib/restless_authentication"

#Used to read in data safely, gets inside rails has issues
def readline; $stdin.readline; end
def hashTraverse( hash, d = Array.new, &p )
  hash.each do |k, v|
    (v.is_a? Hash)? hashTraverse(v, d.dup.push(k), &p): p.call(k, v, d)
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
    task :database do
      RAILS_ENV='test'
      Rake::Task["environment"].execute
      Rake::Task["restless:setup:models"].execute
      Rake::Task["restless:setup:migrations"].execute
      Rake::Task["restless:setup:model_code"].execute
    end

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
      @fields_req = Hash.new
      RestlessAuthentication.list_models(false, :both).each do |code,klass|
        @model_fields[code] = Array.new
        @fields_req[code] = { :string => [], :timestamp => [], :integer => [] }
        hashTraverse(RestlessAuthentication['database'][code]) { |k, v, depth|
          @model_fields[code].push( [k.to_s, v] ) if k.to_s =~ /field/ and v != 'nil'
        }
      end

        #Now we are going to check each model and ensure they have all the
        #fields we need, if they don't then add it
      RestlessAuthentication.list_models(false, :both).each do |code,klass|
          #First we need to ensure that the model exists, cause it needs to
        if class_exists?(klass)
            #If the model already has all the fields we need, then do nothing
          model_complete = true
          fields = eval(klass).column_names
          @model_fields[code].each do |k, v|
              #If the model doesn't have this field, then we need to add it
            if !fields.include?( v )
              model_complete = false 
              if    k =~ /_sfield/
                @fields_req[code][:string].push( ":#{v}" )
              elsif k =~ /_tfield/
                @fields_req[code][:timestamp].push( ":#{v}" )
              elsif k =~ /_ifield/
                @fields_req[code][:integer].push( ":#{v}" )
              end
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
          puts "Skipping #{klass} of type #{type}"
        end

          #If we were given a filename to update, then add our lines to it
        if !filename.nil?
          File.open(filename).readlines.each do |line|
            case state
            when :search        #Search for the create table call
              if line =~ /^=begin/
                state = :comment_block
              elsif line.sub(/#.*/,'') =~ /create_table[\t ]+:#{code.pluralize}/
                state = :insert
                @sp = line.sub(/create_table.*/, '  ').chomp
                @tv = line.sub(/.*\|[\t ]*([a-zA-Z0-9_]+).*/, '\1').chomp
              end
            when :comment_block #Skip over a comment block
              state = :search if line =~ /^=end/
            when :insert        #Insert my fields into this baby
              output.push("#{@sp}  #--Inserted by Restless Authentication")
              @fields_req[code].sort{|a,b| a[0].to_s<=>b[0].to_s}.each do |t, v|
                output.push( "#{@sp}#{@tv}.#{t} #{v.join(', ')}") if v.size > 0
              end
              output.push("#{@sp}  #--End insert")
              state = :done
            else                #Likely in the done case
            end

              #Always keep the original contents
            output.push(line)
          end

            #Write the migration back out, updated with the new fields
          file = File.open(filename, 'w')
          output.each {|line| file.puts line}
          file.close
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

