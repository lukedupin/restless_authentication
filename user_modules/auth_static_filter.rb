require 'acts_when_authorized.rb'

# Create static authorization filters
module AuthStaticFilter
	####################
	# Instance Methods #
	####################
  # Returns false if the current user doesn't have permission use this method
  # This is done by figuring out what method we are in, then testing the
  # static access rights
  def has_access?( roles = nil, count = nil, user = current_user )
      #If the user is nil then we quit right now with false
    return false if !user.is_a? User

      #Store my filter policy
    policy = RestlessAuthentication.static_roles.filter_policy == :black_list

      #Populate my roles variable
    roles = [roles.to_sym] if !roles.nil? and !roles.is_a? Array

      #Now we check figure out what function is calling us
    if roles.nil?
        #Quit if we can't find any roles to check for
      return policy if !defined? @@filter_roles

        #Attempt to dirive the function that is calling us
      func = RestlessAuthentication.trace[1].to_s.to_sym

        #Store my roles role pool into the local role variables
      return policy if @@filter_roles[func].nil?

        #Check if this user meets any of the valid access requirements
      @@filter_roles[func].each do |count, roles|
        return true if user.has_role?(roles, count)
      end
    else
        #Authorize the user
      return user.has_role?(roles, count || 1)
    end

    return false
  end

      #If no roles are defined, throw an exception to tell them whats up
#    raise "No roles defined inside #{self.class}" if !defined? @@role_list

	#################
	# Class Methods #
	#################
	module ClassMethods
    # Define a list of static roles that are required to access a given action
    # These names must match the names inside the Roles model or they will 
    # be found inside a users account
    # action relates to the action these roles are required to run
    # if the user passes :all to the action param, then these roles are add 
    # to all functions.  If changable is passed, then the methods that change
    # the database are given the roles.  If viewable is passed, the methods that
    # show data are added to.  Any other value is aciton specific
    def add_required_roles( action, roles, count = 1 )
        #Create my action array
      act_ary = Array.new
      roles = [roles] if !roles.is_a? Array
      
        #Go through the list of all actions this applies to
      ((action.is_a? Array)? action: [action]).each do |act|
        case act
        when :all
          act_ary.concat([:index, :show, :new, :edit, :create, :update,:delete])
        when :changeable
          act_ary.concat([:create, :update, :delete])
        when :viewable
          act_ary.concat([:index, :show, :new, :edit])
        else
          act_ary.push( act )
        end
      end

        #Create my class objects to hold my list of static role auth
      if !defined? @@filter_roles
        @@filter_roles = Hash.new
#Make the counts dynamic        @@filter_count = Hash.new
      end

        #Add all these roles to all our actions we work with
      act_ary.each do |act|
        roles.each do |role|
          @@filter_roles[act] = Hash.new if @@filter_roles[act].nil? 
          @@filter_roles[act][count] = Array.new if @@filter_roles[act][count].nil?
          @@filter_roles[act][count].push(role) if !@@filter_roles[count].contains?(role)
        end
      end
    end

    # Before filter that requires a user to have static roles access to this
    # controller's specific action it is trying to work off of
    def restless_filter
        #Store my filter policy
      policy = RestlessAuthentication.static_roles.filter_policy == :black_list

        #Return that we failed if there is no way to know what action to use
      return policy if !params[:action] or !params[:controller]
      action = params[:action].to_sym
      controller = params[:controller].to_sym

        #Raise an error if my filter roles aren't even defined yet
      if !defined? @@filter_roles
        return true if policy #Exit out if we are black listed on errors
        raise "No roles defined for restless_filter inside #{controller}"
      end
        
        #Exit if this action isn't defined to have any roles
      return policy if @@filter_roles[action].nil?
      
        #Return false if there is no user and there are defined roles
      return false if !current_user

        #Go through all the requested roles checking if the user meets any
      @@filter_roles[action].each do |count, roles|
        return true if current_user.has_role?( roles, count )
      end
      
        #User isn't okay to do what they are trying to do
      return false
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
