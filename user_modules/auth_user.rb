require 'digest/md5'
require 'digest/sha1'

# Helper functions to take the busy work away from encrypting and compairing
# passwords.  The contents of all these methods are inserted into the user's
# model to ensure they know what has been added.
module AuthHelper
	####################
	# Instance Methods #
	####################
	# Returns true if the given password matches the one in the database
	def authenticated?( password )
		crypt = ActsWhenAuthorized.authentication.helpers.encryption_method
		field = ActsWhenAuthorized.database.user.passwords[ActsWhenAuthorized.authentication.helpers.password_match]
		
		(self.send(field) == self.send(crypt, password))? self: nil
	end

  # Overide method to authomatically encrypt passwords
	def storePassword(password)
		pass = ActsWhenAuthorized.database.user.passwords
		crypt = ActsWhenAuthorized.authentication.helpers.encryption_method
		self.send("#{pass.plain_text_field}=", password) if pass.plain_text_field
		self.send("#{pass.encrypted_field}=", self.send(crypt, password)) if pass.encrypted_field
	end

	# Encrypt based on the encryption method defined: md5, sha1, or none
	def encrypt(password)
		send(ActsWhenAuthorized.authentication.encryption, password)
	end

  # Returns true if the current class contains the requested role(s)
  def has_roles?( roles, count ); has_role?( roles, count); end
  def has_role?( roles_sym, count = 1 )
      #Convert role to an array if it isn't one
    roles_sym = [roles_sym.to_sym] if !roles_sym.is_a? Array

      #Convert all role symbols into the role code form
    roles = Array.new
    model = ActsWhenAuthorized.database.role.model
    roles_sym.each {|r| roles.push(model.role_code(r)) }

      #Get all my local variables ready to be used
    hits = 0
    self.list_roles.each {|r| hits += 1 if roles.contains?(r)}

      #If the number of hits is biggger than count, return true, else false
    return (hits >= count)
  end

  # Return an array of all the static roles the user contains
  def list_roles
    field = ActsWhenAuthorized.database.role.role_code_field
    type = ActsWhenAuthorized.database.role.user_linkage.relationship_type
    linkage = ActsWhenAuthorized.database.role.user_linkage.relationship_field
  
      #Find all possible instances of the requested roles
    case type
    when :many_to_many
      return self.send(linkage)
    when :one_to_many
      return [self.send(linkage).send(field)]
    when :local
      return [self.send(field)]
    when :office_space
      raise "PC load letter"
    else
      raise "Unknown config/restless_authentication.yml: database.role.user_linkage.relationship_type: ( #{type} ).  Should be [many_to_many,one_to_many,local]"
    end
  end

	#################
	# Class Methods #
	#################
	module ClassMethods
		# Authenticate a user based on username and password
		def authenticate( username, password )
			model = ActsWhenAuthorized.database.user.model	
			find_by = ActsWhenAuthorized.database.user.usernames.username_find
			auth = ActsWhenAuthorized.authentication.helpers.authenticated_method
			(user = model.send(find_by,username))? user.send(auth,password): nil
		end
	end

	#################
	# Local Methods #
	#################
	private
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

	private
	# Used to create class methods along with instance methods
	def self.included(base)
    base.extend(ClassMethods)
  end
end
