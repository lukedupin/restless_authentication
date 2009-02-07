# Create static role authorization methods
module RestlessStaticRole
  #################
  # Class Methods #
  #################
  module ClassMethods
    # Defines roles a set of roles in the class
    # This method can take arrays of symbols but it is much safer to pass
    # a hash with the numbers increasing {:unknown => 0, :admin => 1, :bob => 4}
    def define_roles( roles, lock = true )
        #If our roles are locked, then quit out right now
      return true if defined? @@role_lock and @@role_lock

        #If this is the first time we are calling this, make new class variables
      if !defined? @@role_list
        @@role_list = { :none => 0 }
        @@role_idx = 0
      end
 
        #Add these roles into our list of roles
      case roles.class.to_s
      when 'Hash'
        roles.each do |role, idx|
          raise "Attempting to re-add static role #{role}" if @@role_list.has_key?( role.to_sym ) and @@role_list[role.to_sym] != idx.to_i
          raise "Invalid role code #{idx} for role #{role}.  Role codes must be >= 1" if idx <= 0
          @@role_list[role.to_sym] = idx.to_i
          @@role_idx = idx.to_i if idx.to_i >= @@role_idx
        end
      when 'Array'
        roles.each do |role| 
          raise "Attempting to re-add static role #{role}" if @@role_list.has_key?( role.to_sym ) and @@role_list[role.to_sym] != @@role_idx + 1
          @@role_list[role.to_sym] = (@@role_idx += 1)
        end
      else
          raise "Attempting to re-add static role #{role}" if @@role_list.has_key?( roles.to_sym ) and @@role_list[role.to_sym] != @@role_idx + 1
        @@role_list[roles.to_sym] = (@@role_idx += 1)
      end
 
        #Create my invertered hash of roles
      @@role_list_inv = @@role_list.invert

        #Ensure each role has a unique code id
      if @@role_list.size != @@role_list_inv.size
        tmp = Hash.new
        conflict = Hash.new
        @@role_list.each do |k,v|
          if tmp.has_key?(v)
            conflict[v] = [tmp[v]] if !conflict.has_key?(v)
            conflict[v].push(k)
          end
          tmp[v] = k
        end
        
        raise "Static role unique code overlap: #{conflict.collect{|k,v| "IDX(#{k}) -> [ #{v.join(', ')} ]"}.join('; ')}"
      end

        #If we got here and the lock is requested, then set the lock
      @@lock = lock
    end

    # Used to relay the module class variables... might be a oxy moron there
    def role_list; (defined? @@role_list)? @@role_list: Hash.new; end
    def role_list_inv;(defined? @@role_list_inv)? @@role_list_inv: Hash.new;end

    # Return the code of a given static role
    def role2code( role ); role_to_code(role); end
    def role_to_code( role )
      return <%=RestlessAuthentication.database.role.model%>.role_list[role.to_sym]
    end

    # Return the static role based on the code
    def code2role( code ); code_to_role(code); end
    def code_to_role( code )
      return <%=RestlessAuthentication.database.role.model%>.role_list_inv[code]
    end

    # Return a human readable name for the given role
    def role2name( role ); role_to_name( role ); end
    def role_to_name( role )
      role.to_s.capitalize.gsub(/_/, ' ')
    end

    # Create a role in the database
    def create_role( sym )
      role = <%=RestlessAuthentication.database.role.model%>.new
      role.<%=RestlessAuthentication.database.role.role_code_ifield%> = <%=RestlessAuthentication.database.role.model%>.role_to_code( sym )
      return role
    end
  end


  ####################
  # Instance Methods #
  ####################
  # Returns the name of the role defined by this database entry
  def role
    <%=RestlessAuthentication.database.role.model.to_s%>.code_to_role( self.code )
  end

  # Return a user friendly version of this role
  def name
    <%=RestlessAuthentication.database.role.model.to_s%>.role_to_name(self.role)
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
