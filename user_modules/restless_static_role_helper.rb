# Create static role authorization methods
module RestlessStaticRoleHelper
  #################
  # Class Methods #
  #################
  module ClassMethods
    # Define the role table we use
    def define_role_class( klass, roles_field = :roles )
      @role_class = klass.to_s
      @roles_field = roles_field
    end

    # Return the role class
    def role_class; @role_class; end

    # Return the roles field
    def roles_field; @roles_field; end
  end


  ####################
  # Instance Methods #
  ####################
  # returns my role class
  def role_class
    @role_class ||= eval(self.class.role_class)
  end

  # returns my roles field
  def roles_field
    @roles_field ||= self.class.roles_field.to_sym
  end


  # Returns true if the current class contains the requested role(s)
  def has_role?( role, count = 1 ); has_roles?( role, count); end
  def has_roles?( roles_sym, count = 1 )
      #Convert role to an array if it isn't one
    roles_sym = [roles_sym.to_sym] if !roles_sym.is_a? Array

      #Convert all role symbols into the role code form
    roles = Array.new
    roles_sym.each {|r| roles.push( role_class.role_to_code(r)) }

      #Get all my local variables ready to be used
    hits = 0
    self.send(roles_field).each {|r| hits += 1 if roles.include?(r.code)}

      #If the number of hits is biggger than count, return true, else false
    return (hits >= count)
  end

  # Give a static role to a given user
  def grant_role( role ); grant_roles(role); end
  def grant_roles( roles )
    roles = [roles] if !roles.is_a? Array

      #Get a list of roles of new roles to add, removing ones I alread have
    r = self.send(roles_field).collect {|x| x.code }
    roles.delete_if {|x| r.include?(x)}

      #Add any roles that are still out there
    roles.compact.each do |role|
      self.send(roles_field) << role_class.create_role(role)
    end

    return self
  end

  # Revoke a list of rights a user has
  def revoke_role( role ); revoke_roles( role ); end
  def revoke_roles( roles )
    roles = [roles] if !roles.is_a? Array
    roles = roles.compact.collect{|x| role_class.role_to_code( x )}

      #Get a list of roles
    self.send(roles_field).each do |x|
      x.destroy if roles.include?( x.code )
    end

    return self
  end

  #################
  # Local Methods #
  #################
  private
  # Used to create class methods along with instance methods
  def self.included(base)
    base.extend(ClassMethods)
  end
end
