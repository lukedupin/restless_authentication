# Create static role authorization methods
module RestlessDynamicRole
  #################
  # Class Methods #
  #################
  module ClassMethods
    # Defines a dynamic role relationship
    def has_roles( field, hash )
      params = Hash.new

        #Figure out what the user passed to me
      params['field'] = ":#{field.to_s}"
      raise "has_roles requires roles access; Example: has_roles  :groups, :roles => :role_groups" if !hash.has_key?(:roles)
      params['role_field'] = ":#{hash[:roles].to_s}"
      params['class_name'] = (hash.has_key?(:class_name))? hash[:class_name]: hash[:roles].to_s.split(/_/).collect{|x| x.capitalize}.join[0..-2]

        #Create all the pieces defining this relationship
      fdef = "def #{field}_by_role( roles, count = 1 );"
      fbody = params.collect {|k, v| ":#{k} => #{v}"}.join(', ')

        #Create this method
      self.class_eval "#{fdef} find_by_roles( #{fbody}, :roles => roles, :count => count ); end;"
    end
  end


  ####################
  # Instance Methods #
  ####################
  # Return all entries the user has access to
  def find_by_roles( hash )
    field = hash[:field]
    role_field = hash[:role_field]
    count = hash[:count]
    klass = hash[:class_name]

      #Get and convert the user's roles to codes
    roles = (hash[:roles].is_a? Array)? hash[:roles]: [hash[:roles]]
    codes = roles.collect{|x| klass.role_to_code(x)}

      #Delete any fields that the user doesn't have the required access to
    self.send(field).delete_if {|f|
      hit = 0
      f.send(role_field).each {|r| hit += 1 if codes.include?(r.code)}
      hit >= count
    }
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
