# Create static role authorization methods
module RestlessStaticRole
  #################
  # Class Methods #
  #################
  module ClassMethods
    # Defines roles a set of roles in the class
    # This method can take arrays of symbols but it is much safer to pass
    # a hash with the numbers increasing {:unknown => 0, :admin => 1, :bob => 4}
    def define_roles( roles )
        #If this is the first time we are calling this, make new class variables
      if !defined? @@role_list
        @@role_list = Hash.new
        @@role_idx = 0
      end
 
        #Add these roles into our list of roles
      case roles.class.to_s
      when 'Hash'
        roles.each do |role, idx|
          @@role_list[role.to_sym] = idx
          @@role_idx = idx.to_i if idx.to_i >= @@role_idx
        end
      when 'Array'
        roles.each {|role| @@role_list[role.to_sym] = (@@role_idx += 1)}
      else
        @@role_list[roles.to_sym] = (@@role_idx += 1)
      end
 
        #Create my invertered hash of roles
      @@role_list_inv = @@role_list.invert
    end

    # Used to relay the module class variables... might be a oxy moron there
    def role_list; (defined? @@role_list)? @@role_list: Hash.new; end
    def role_list_inv;(defined? @@role_list_inv)? @@role_list_inv: Hash.new;end
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
