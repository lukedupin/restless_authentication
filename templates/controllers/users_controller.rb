class UsersController < ApplicationController
  # GET /users
  # GET /users.xml
  def index
    @users = User.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find_by_id(params[:id])
    redirect_to(User.new) if @user.nil?
  end

  # POST /users
  # POST /users.xml
  def create
    @user = User.new
    @user.<%=RestlessAuthentication.database.user.usernames.username_sfield%> = params[:user][:<%=RestlessAuthentication.database.user.usernames.username_sfield%>]
    @user.<%=RestlessAuthentication.authentication.helpers.password_method%>(params[:user][:password], params[:user][:password_confirm])

      #Give the user whatever rights they deserve
    ary = Array.new
    params[:user].each do |k,v|
      ary.push(<%=RestlessAuthentication.database.role.model%>.code_to_role(v.to_i)) if k =~ /role_list/ and v.to_i != 0
    end
    @user.grant_roles(ary)

    respond_to do |format|
      if @user.save
        flash[:notice] = 'User was successfully created.'
        format.html { redirect_to(@user) }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
      #Ensure we get a valid user from this id
    @user = User.find_by_id(params[:id])
    if @user.nil?
      redirect_to(User.new) 
      return true
    end

      #Store the user's info
    @user.<%=RestlessAuthentication.database.user.usernames.username_sfield%> = params[:user][:<%=RestlessAuthentication.database.user.usernames.username_sfield%>]
    @user.<%=RestlessAuthentication.authentication.helpers.password_method%>(params[:user][:password], params[:user][:password_confirm])

    has = @user.roles.collect{|x| x.role}
    needs = Array.new
    params[:user].each do |k,v|
      needs.push( <%=RestlessAuthentication.database.role.model.to_s%>.code_to_role(v.to_i)) if k =~ /role_list/ and v.to_i != 0
    end

      #Add the new roles and remove the old ones
    @user.grant_roles( needs - has )
    @user.revoke_roles( has - needs )

    respond_to do |format|
      if @user.save
        flash[:notice] = 'User was successfully updated.'
        format.html { redirect_to(@user) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.find_by_id(params[:id])
    @user.destroy if @user

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end
end
