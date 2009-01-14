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
		field = ActsWhenAuthorized.config.database.user.passwords[ActsWhenAuthorized.authentication.helpers.password_match]
		
		(self.send(field) == self.send(crypt, password))? self: nil
	end

  # Overide method to authomatically encrypt passwords
	def storePassword(password)
		pass = ActsWhenAuthorized.config.database.user.passwords
		crypt = ActsWhenAuthorized.authentication.helpers.encryption_method
		self.send("#{pass.plain_text_field}=", password) if pass.plain_text_field
		self.send("#{pass.encrypted_field}=", self.send(crypt, password)) if pass.encrypted_field
	end

	# Encrypt based on the encryption method defined: md5, sha1, or none
	def encrypt(password)
		send(ActsWhenAuthorized.authentication.encryption, password)
	end


	#################
	# Class Methods #
	#################
	module ClassMethods
		# Authenticate a user based on username and password
		def authenticate( username, password )
			model = ActsWhenAuthorized.config.database.user.model	
			find_by = ActsWhenAuthorized.config.database.user.usernames.username_find
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
