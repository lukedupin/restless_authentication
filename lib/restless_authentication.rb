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
  # Do a configuration reload
  def self.reload_config( stream_line = true )
    self.load_config( :nothing, stream_line )
  end

  # Returns the database section of my config file
  def self.database( stream_line = true )
    (defined? @@database)? @@database: self.load_config(:database, stream_line)
  end

  # Returns the authentication section of my config file
  def self.authentication( stream_line = true )
    (defined? @@authentication)? @@authentication: self.load_config(:auth, stream_line)
  end

  # Returns the static_roles section of my config file
  def self.static_roles( stream_line = true )
    (defined? @@static_roles)? @@static_roles: self.load_config(:static_roles, stream_line)
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

  # Returns a list of all the models we deal with
  def self.list_models_human( stream_line = true )
    self.list_models( stream_line, :human )
  end
  def self.list_models( stream_line = true, type = :code )
      #Go through all the different models I need for this to work
    tables = Array.new
    tables.push( RestlessAuthentication.database(stream_line).user.model.to_s )
    tables.push( RestlessAuthentication.database(stream_line).role.model.to_s )
    tables.collect!{|x| x.gsub(/([A-Z])/, '_\1').sub(/^_/,'').downcase}
    tables.sort!
    tables.push( "#{tables[0].pluralize}_#{tables[1]}" )

      #Convert all these to names to human names
    case type
    when :human
      tables.collect!{|t| t.split(/_/).collect{|x| x.capitalize}.join}
    when :both
      tables.collect!{|t| [t.dup,t.split(/_/).collect{|x| x.capitalize}.join]}
    end

    return tables
  end

  # Returns the stack of the methods that are called  zero is the parent method
  def self.trace
    result = Array.new
    Kernel::caller.each do |stk|
      result.push( stk.gsub(/.*`([^']*)'.*/, '\1').to_sym) if stk.include?('`')
    end
    return result
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
      @@database.user.model = eval("@@database.user.model")
      @@database.role.model = eval("@@database.role.model")
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
    return yaml if !yaml.is_a? Hash
  
      #Create a new class that can add accessors
    klass = Class.new
    klass.class_eval do
      def add_accessor(acs, value)
        eval("class << self; attr_reader :#{acs}; end")
        instance_variable_set("@#{acs}", value)
        self
      end
    end

      #Go through the yaml file recursing through all the config info
    daml = klass.new
    yaml.each {|key, value| daml.add_accessor(key, fill_daml(value))}
    return daml
  end
end
