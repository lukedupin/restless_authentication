  include RestlessStaticRole

	#################
	# Class Methods #
	#################
=begin
  # Return the code of a given static role
  def self.role2code( role ); role_to_code(role); end
  def self.role_to_code( role )

  # Return the static role based on the code
  def self.code2role( code ); code_to_role(code); end
  def self.code_to_role( code )

  # Return a human readable name for the given role
  def self.role2name( role ); role_to_name( role ); end
  def self.role_to_name( role )

  # Create a role in the database
  def self.create_role( role )

	####################
	# Instance Methods #
	####################
  # Returns the name of the role defined by this database entry
  def role

  # Return a user friendly version of this role
  def name
=end
