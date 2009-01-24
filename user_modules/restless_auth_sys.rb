# =User Authentication System
#
# The authorization system provides user hooks to the acts_when_authorized
# plugin.  This portion deals specifically with user session management.
module RestlessAuthSystem
	#######################
	# User Specific Needs #
	#######################
	protected
	# Log a user in using a unique id from their session
	def login_from_session
		(auth.auth_session)? 
							db.user.model.send("find_by_#{db.user.uid.user_uid_field}", 
																	session[auth.session.uid_field]): nil
	end

	# Log a user in from posted variables inside the param method
	def login_from_post
		(auth.auth_post and params and params[auth.post_login.post_form_field])?
			User.authenticate( params[auth.post_login.post_form_field][auth.post_login.post_username_field], params[auth.post_login.post_form_field][auth.post_login.post_password_field] ): nil
	end

	def login_from_cookie
	end

	# Store the user's unique id to our session so it can be loaded next time
	# If no user is found or this ability is turned off, then nil the session var
	def store_login_to_session
		session[auth.session_login.uid_field] =(auth.auth_session and current_user)?
						current_user.send("#{db.user.uid.user_uid_field}"): nil
	end

	# Used to populate user information into instance variables
	# This is only used in special cases and thus, is empty
	def store_login_to_post
	end

	# Store the user's cookie login information to our database
	def store_login_to_cookie
	end


	################
	# System Hooks #
	################
	protected
	# Returns true if the user is logged in.
	# If the user isn't logged in the system will attempt to a login
	def logged_in?
		!!current_user
	end

	# Return the user currently logged in
	# If the user isn't logged in then attempt to do so
	def current_user
		@current_user ||= (login_from_session || login_from_post || login_from_cookie) if @current_user != false
	end

	# Tell the system what the new current user is
	# If false is passed, then the user account is made inactive for this run
	def current_user=(new_user)
			#If the user gave us anything other than a user model, nil and split
		if !new_user.is_a? db.user.model
			@current_user = false 
		else
			@current_user = new_user
			store_login_to_session
			store_login_to_cookie
		end

			#Return my user object back
		return @current_user
	end

	# Create hooks into action view that gives the user access to the current_user
	def self.included(base)
		base.send :helper_method, :current_user, :logged_in? if base.respond_to? :helper_method
	end

	##################
	# Module Methods #
	##################
	private
	#Return the database section on the configuration
	def db
		return RestlessAuthentication.database
	end

	#Return the authentication section of the configuration
	def auth
		return RestlessAuthentication.authentication
	end
end
