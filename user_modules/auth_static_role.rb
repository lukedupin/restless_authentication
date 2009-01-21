# Create static role authorization methods
module AuthStaticRole
	####################
	# Instance Methods #
	####################

	#################
	# Class Methods #
	#################
	module ClassMethods
    # Defines roles a set of roles in the class
    # This method can take arrays of symbols but it is much safer to pass
    # a hash with the numbers increasing {:unknown => 0, :admin => 1, :bob => 4}
    def create_role( roles )
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

    # Return the code of a given static role
    def role2code( role ); role_to_code(role); end
    def role_to_code( role )
      return nil if !defined? @@role_list
      return @@role_list[role.to_sym]
    end

    # Return the static role based on the code
    def code2role( code ); code_to_role(code); end
    def code_to_role( code )
      return nil if !defined? @@role_list_inv
      return @@role_list_inv[code]
    end
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
