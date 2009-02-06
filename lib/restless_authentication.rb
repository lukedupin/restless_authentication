require 'yaml'

# =Restless Authentication
#
# Author::    Luke Dupin (lukedupin@rebelonrails.com)
# Copyright:: RebelOnRails.com (2009)
# License::   GPL
# 
# ==The Goal
# Restless Authentication is plugin in built with flexibilty in mind.
# There are several goals of this plug in:
# * Ease of use
# * Shallow learning curve
# * Flexibility to suit any taste
# * More usable features
#
# ==Operational Parameters
# How does this plugin aim to meet our goals?  We attack the problem with the
# right attitude, don't just make it better, define what better is.  Once 
# better is defined, meet those parameters.  Here are our parameters:
# 1. No predefined database names.
# 1. Document the entire system.
# 1. New users up and running within 10 minutes of finding the plugin.
# 1. No assumpts about the website's flow or structure.
# 1. Authentication without loss of user's state information.
# 1. Seperate configuration from source code manipulation.
# 1. User roles are defined by program constants.
# 1. Seperate user authentication, roles, code access, and data access.
#
#	==Definitions
# What makes this plugin so different?  A clear vision of how and why:
#
# * User Authentication - User authentication defines the code access rules.
class RestlessAuthentication
  #############
  # Constants #
  #############
  CONFIG = "#{File.dirname(__FILE__)}/../../../../config/restless_authentication.yml"

  #################
  # Class Methods #
  #################
  # Create an md5 hex digest
  def self.md5( digest )
    Digest::MD5.hexdigest(digest)
  end

  # Create an sha1 hex digest
  def self.sha1( digest )
    Digest::SHA1.hexdigest(digest)
  end

  # This method is a pass through that returns the first param given
  def self.none( digest )
    digest
  end

  # Do a configuration reload
  def self.reload_config( stream_line = true )
    self.load_config( :nothing, stream_line )
  end

  # Returns the database section of my config file
  def self.database( stream_line = true )
    (defined? @@database and defined? @@stream_line and @@stream_line == stream_line)? @@database: self.load_config(:database, stream_line)
  end

  # Returns the authentication section of my config file
  def self.authentication( stream_line = true )
    (defined? @@authentication and defined? @@stream_line and @@stream_line == stream_line)? @@authentication: self.load_config(:auth, stream_line)
  end

  # Returns the static_roles section of my config file
  def self.static_roles( stream_line = true )
    (defined? @@static_roles and defined? @@stream_line and @@stream_line == stream_line)? @@static_roles: self.load_config(:static_roles, stream_line)
  end

  # Gives the user access to the yaml file
  def self.[]( param )
      #Load up just the yaml if it hasn't been loaded yet
    if !defined? @@yaml
      @@yaml = YAML::load( File.open(RestlessAuthentication::CONFIG) )
    end

      #Return whatever index the user is asking
    @@yaml[param]
  end

  # Return both possible names of a table based on the section
  def self.model_names( model_name, type, stream_line = true )
      #Go through all the different models I need for this to work
    db = RestlessAuthentication.database(stream_line)
    ary = nil
    if    model_name.to_sym == :user
      ary = [db.user.model.to_s,
             db.user.model.to_s.gsub(/([A-Z])/,'_\1').sub(/^_/,'').downcase]
    elsif model_name.to_sym == :role
      ary = [db.role.model.to_s,
             db.role.model.to_s.gsub(/([A-Z])/,'_\1').sub(/^_/,'').downcase]
    else
      return :unknown
    end

      #Convert all these to names to human names
    case type
    when :klass
      return ary[0]
    when :code
      return ary[1]
    else
      return ary
    end
  end

  # Returns a list of all the models we deal with
  def self.list_models_section( stream_line = true )
    self.list_models( stream_line, :section )
  end
  def self.list_models_klass( stream_line = true )
    self.list_models( stream_line, :klass )
  end
  def self.list_models_code( stream_line = true )
    self.list_models( stream_line, :code )
  end
  def self.list_models( stream_line = true, type = :all )
      #Go through all the different models I need for this to work
    db = RestlessAuthentication.database(stream_line)
    tables = Array.new
    tables.push([:user, db.user.model.to_s,
               db.user.model.to_s.gsub(/([A-Z])/,'_\1').sub(/^_/,'').downcase])
    tables.push([:role, db.role.model.to_s,
               db.role.model.to_s.gsub(/([A-Z])/,'_\1').sub(/^_/,'').downcase])

      #Convert all these to names to human names
    case type
    when :section
      tables.collect!{|t| t[0]}
    when :klass
      tables.collect!{|t| t[1]}
    when :code
      tables.collect!{|t| t[2]}
    end

    return tables
  end

  # Return all the required fields for each model we deal with
  def self.list_fields( order = :section, stream_line = true )
      #Get my list of fields we need inside each user's models
    models = Hash.new
    self.list_models(false).each do |section,klass,code|
      idx = section
      idx = code if order.to_sym == :code
      idx = klass if order.to_sym == :klass
      models[idx] = Array.new
      hash_traverse(RestlessAuthentication['database'][section.to_s]) {|k, v, d|
          #Check if this is a field, if so, push it onto the stack
        if k.to_s =~ /field/ and v != 'nil'
          if    k.to_s =~ /_sfield/
            models[idx].push( [:string, v.to_sym] )
          elsif k.to_s =~ /_tfield/
            models[idx].push( [:timestamp, v.to_sym] )
          elsif k.to_s =~ /_ifield/
            models[idx].push( [:integer, v.to_sym] )
          end
        end
      }
    end

    return models
  end

  # Returns the stack of the methods that are called  zero is the parent method
  def self.trace
    result = Array.new
    Kernel::caller.each do |stk|
      result.push( stk.gsub(/.*`([^']*)'.*/, '\1').to_sym) if stk.include?('`')
    end
    return result
  end

  # Insert code into a file
  # The proc is called when it is time to insert data
  # The proc should return an array which will be inserted into the file
  def self.insert_code( filename, search, first_line = [], comment = false, &e )
      #Quit if our params aren't valid
    return false if filename.nil? or e.nil? or !File.exists?( filename )

      #Create my local variables
    output = Array.new(first_line)
    state = :search
    sp = ''
    tv = ''

      #Read in all the data of this file
    File.open(filename).readlines.each do |line|
      case state
      when :search        #Search for the create table call
        if line =~ /^=begin/
          state = :comment_block
        elsif ((comment)? line: line.sub(/#.*/,'')) =~ /#{search}/
          state = :insert
          sp = line.sub(/#{search}.*/, '  ').chomp
          tv = line.sub(/.*\|[\t ]*([a-zA-Z0-9_]+).*/, '\1').chomp
        end
      when :comment_block #Skip over a comment block
        state = :search if line =~ /^=end/
      when :insert        #Insert my fields into this baby
        e.call( sp, tv ).each {|ul| output.push( ul )}
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

    return true
  end

  # This method recurses through a hash passing the data to a proc
  def self.hash_traverse( hash, d = Array.new, &p )
    hash.each do |k, v|
      (v.is_a? Hash)? self.hash_traverse(v, d.dup.push(k), &p): p.call(k, v, d)
    end
  end

  private
  # Loads the user's config file into class variables
  def self.load_config( config = :nothing, stream_line = true )
      #Load up the config file
    yaml = YAML::load( File.open(RestlessAuthentication::CONFIG) )

      #Populate my class variables
    @@database = self.fill_daml( yaml['database'] )
    @@authentication = self.fill_daml( yaml['authentication'] )
    @@static_roles = self.fill_daml( yaml['static_roles'] )
    @@yaml = yaml

      #Change my special instances to a better form
    @@stream_line = stream_line
    if stream_line
#      @@database.user.model = eval(@@database.user.model.to_s)
#      @@database.role.model = eval(@@database.role.model.to_s)
      @@authentication.encryption = RestlessAuthentication.method(@@authentication.encryption)
    end

      #Return a newly loaded config if requested
    case config
    when :database
      return @@database
    when :auth  #Short hand version, cause I hate typing
      return @@authentication
    when :authentication
      return @@authentication
    when :static_roles
      return @@static_roles
    end 

    return true
  end

  private
  # Build out my dynamic classes from a yaml file
  def self.fill_daml( yaml )
      #If this isn't a hash, don't do anything but return it
    if !yaml.is_a? Hash
      return nil if yaml.to_s == 'nil'
      return yaml.to_sym if yaml.is_a? String
      return yaml
    end
  
      #Create a new class that can add accessors
    klass = Class.new
    klass.class_eval do
      def add_accessor(acs, value)
        eval("class << self; attr_accessor :#{acs}; end")
        instance_variable_set("@#{acs}", value)
        self
      end

      def []( attr )
        self.send(attr)
      end
    end

      #Go through the yaml file recursing through all the config info
    daml = klass.new
    yaml.each {|key, value| daml.add_accessor(key, fill_daml(value))}
    return daml
  end
end
