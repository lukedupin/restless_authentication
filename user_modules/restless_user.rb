require 'digest/md5'
require 'digest/sha1'

# Helper functions to take the busy work away from encrypting and compairing
# passwords.  The contents of all these methods are inserted into the user's
# model to ensure they know what has been added.
module RestlessUser
	####################
	# Instance Methods #
	####################
	# Returns true if the given password matches the one in the database
	def authenticated?( password )
		crypt = RestlessAuthentication.authentication.helpers.encryption_method
		field = RestlessAuthentication.database.user.passwords[RestlessAuthentication.authentication.helpers.password_match]
		
		(self.send(field) == self.send(crypt, password))? self: nil
	end

  # Overide method to authomatically encrypt passwords
	def storePassword(password, pass2 = nil )
      #if the user gave us two passwords, ensure they match
    return false if !pass2.nil? and password != pass2

      #encrypt the password and store it
		pass = RestlessAuthentication.database.user.passwords
		crypt = RestlessAuthentication.authentication.encryption
		self.send("#{pass.plain_text_sfield}=", password) if pass.plain_text_sfield
		self.send("#{pass.encrypted_sfield}=", crypt.call(password)) if pass.encrypted_sfield
	end

	# Encrypt based on the encryption method defined: md5, sha1, or none
	def encrypt(password)
		RestlessAuthentication.authentication.encryption.call(password)
	end

  # Returns true if the current class contains the requested role(s)
  def has_roles?( roles, count ); has_role?( roles, count); end
  def has_role?( roles_sym, count = 1 )
      #Convert role to an array if it isn't one
    roles_sym = [roles_sym.to_sym] if !roles_sym.is_a? Array

      #Convert all role symbols into the role code form
    roles = Array.new
    model = RestlessAuthentication.database.role.model
    roles_sym.each {|r| roles.push(model.role_code(r)) }

      #Get all my local variables ready to be used
    hits = 0
    self.list_roles.each {|r| hits += 1 if roles.contains?(r)}

      #If the number of hits is biggger than count, return true, else false
    return (hits >= count)
  end

  # Return an array of all the static roles the user contains
  def list_roles
    field = RestlessAuthentication.database.role.role_code_ifield
    roles = RestlessAuthentication.database.user.role_relationship
  
      #Find all possible instances of the requested roles
    return self.send(roles).collect{|x| x.send(field)}
  end

  # Give a static role to a given user
  def grant_role( roles )
    roles = [roles] if !roles.is_a? Array

      #Get a list of roles
    r = self.send(RestlessAuthentication.user.role_relationship).collect {|x| 
      x.send(RestlessAuthentication.database.role.role_code_ifield)
    }
    r.delete_if {|x| roles.include?(x)}

      #Add any roles that are still out there
    roles.each do |role|
      self.send(RestlessAuthentication.user.role_relationship) << Role.create_role(role)
    end

      #Save user
    self.save
    return self
  end

  # Revoke a list of rights a user has
  def revoke_role( roles )
    roles = [roles] if !roles.is_a? Array

      #Get a list of roles
    self.send(RestlessAuthentication.user.role_relationship).each do |x| 
      x.destroy
    end

      #Save user
    self.save
    return self
  end


	#################
	# Class Methods #
	#################
	module ClassMethods
		# Authenticate a user based on username and password
		def authenticate( username, password )
			model = RestlessAuthentication.database.user.model	
			find_by = "find_by#{RestlessAuthentication.database.user.usernames.username}"
			auth = RestlessAuthentication.authentication.helpers.authenticated_method
			(user = model.send(find_by,username))? user.send(auth,password): nil
		end
	end

	private
	# Used to create class methods along with instance methods
	def self.included(base)
    base.extend(ClassMethods)
  end
end
