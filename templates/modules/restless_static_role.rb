  include RestlessStaticRole

	#################
	# Class Methods #
	#################
  # Return the code of a given static role
  def self.role2code( role ); role_to_code(role); end
  def self.role_to_code( role )
    return <%=RestlessAuthentication.database.role.model%>.role_list[role.to_sym]
  end

  # Return the static role based on the code
  def self.code2role( code ); code_to_role(code); end
  def self.code_to_role( code )
    return <%=RestlessAuthentication.database.role.model%>.role_list_inv[code]
  end

  # Create a role in the database
  def self.create_role( sym )
    role = Role.new
    role.<%=RestlessAuthentication.database.role.role_code_ifield%> = Role.role_to_code( sym )
    return role
  end

	####################
	# Instance Methods #
	####################
  # Returns the name of the role defined by this database entry
  def name
    <%=RestlessAuthentication.database.role.model.to_s%>.code_to_role( self.code )
  end
