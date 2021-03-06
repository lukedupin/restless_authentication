require 'restless_auth_system'

# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  include RestlessAuthSystem

	skip_before_filter :restless_filter
	layout "sessions"

	# redirect them to the log in
	def index
		redirect_to('/sessions/new')
	end

	# redirect them to the log in
	def show
		redirect_to('/sessions/new')
	end

  # render new.rhtml
  def new
  end

  def create
    logout_keeping_session!
    user = User.authenticate( params[:login], params[:password] )
    if user
      # Protects against session fixation attacks, causes request forgery
      # protection if user resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session
      self.current_user = user
      #new_cookie_flag = (@_remember_me == "1")
      #handle_remember_cookie! new_cookie_flag
      flash[:notice] = "Logged in successfully"
      redirect_to('/users')
    else
      note_failed_signin
      @login       = params[:login]
      @remember_me = params[:remember_me]
      render :action => 'new'
    end
  end

  def destroy
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_to('/')
  end

protected
  # Track failed login attempts
  def note_failed_signin
    flash[:error] = "Couldn't log you in as '#{@_login}'"
    logger.warn "Failed login for '#{@_login}' from #{request.remote_ip} at #{Time.now.utc}"
  end
end
