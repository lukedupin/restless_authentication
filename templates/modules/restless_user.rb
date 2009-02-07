	#################
	# Class Methods #
	#################
  # Authenticate a user based on username and password
	def self.authenticate( username, password )
<%model = RestlessAuthentication.database.user.model%>
<%find_by = "find_by_#{RestlessAuthentication.database.user.usernames.username_sfield}"%>
<%auth = RestlessAuthentication.authentication.helpers.authenticated_method%>
		user = <%=model%>.<%=find_by%>(username)
    (!user.nil?)? user.<%=auth%>(password): nil
	end


	####################
	# Instance Methods #
	####################
	# Returns true if the given password matches the one in the database
	def authenticated?( password )
<%crypt = RestlessAuthentication.authentication.helpers.encryption_method.to_sym%>
<%field = RestlessAuthentication.database.user.passwords[RestlessAuthentication.authentication.password_match].to_sym%>
		(self.<%=field%> == self.<%=crypt%>(password))? self: nil
	end

  # Overide method to authomatically encrypt passwords
	def storePassword(password, pass2 = nil )
      #if the user gave us two passwords, ensure they match
    return false if !pass2.nil? and password != pass2

      #encrypt the password and store it
<%pass = RestlessAuthentication.database.user.passwords%>
<%crypt = RestlessAuthentication.authentication.helpers.encryption_method%>
		<%="#{(pass.plain_text_sfield)? 'self.': '#self.plain_text_pass'}#{pass.plain_text_sfield} = password"%>
		<%="#{(pass.encrypted_sfield)? 'self.': '#self.encrypted_pass'}#{pass.encrypted_sfield} = #{crypt}(password)"%>
	end

	# Encrypt based on the encryption method defined: md5, sha1, or none
	def encrypt(password)
		RestlessAuthentication.authentication.encryption.call(password)
	end

  # Returns true if the current class contains the requested role(s)
  def has_role?( role, count = 1 ); has_roles?( role, count); end
  def has_roles?( roles_sym, count = 1 )
      #Convert role to an array if it isn't one
    roles_sym = [roles_sym.to_sym] if !roles_sym.is_a? Array

      #Convert all role symbols into the role code form
    roles = Array.new
<%model = RestlessAuthentication.database.role.model%>
    roles_sym.each {|r| roles.push(<%=model%>.role_to_code(r)) }

      #Get all my local variables ready to be used
    hits = 0
    self.roles.each {|r| hits += 1 if roles.include?(r.code)}

      #If the number of hits is biggger than count, return true, else false
    return (hits >= count)
  end

  # Give a static role to a given user
  def grant_role( role ); grant_roles(role); end
  def grant_roles( roles )
    roles = [roles] if !roles.is_a? Array

      #Get a list of roles of new roles to add, removing ones I alread have
    r = self.<%=RestlessAuthentication.database.user.role_relationship%>.collect {|x| x.<%=RestlessAuthentication.database.role.role_code_ifield%> }
    roles.delete_if {|x| r.include?(x)}

      #Add any roles that are still out there
    roles.compact.each do |role|
      self.<%=RestlessAuthentication.database.user.role_relationship%> << <%=RestlessAuthentication.database.role.model%>.create_role(role)
    end

    return self
  end

  # Revoke a list of rights a user has
  def revoke_role( role ); revoke_roles( role ); end
  def revoke_roles( roles )
    roles = [roles] if !roles.is_a? Array
    roles = roles.compact.collect{|x| <%=RestlessAuthentication.database.role.model%>.role_to_code( x )}

      #Get a list of roles
    self.<%=RestlessAuthentication.database.user.role_relationship%>.each do |x| 
      x.destroy if roles.include?( x.code )
    end

    return self
  end
