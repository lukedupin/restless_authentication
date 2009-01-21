# =Restless Authentication
#
# Author::    Luke Dupin (lukedupin@rebelonrails.com)
# Copyright:: RebelOnRails.com (2009)
# License::   GPL
# 
# ==The Goal
# Restless Authentication is just that, a plug in that does something when a
# user is authorized.  There are several goals of this plug in:
# * Ease of use
# * Shallow learning curve
# * Flexibility to suit any taste
# * More usable features
#
# ==Operational Parameters
# How does this plugin aim to meet our goals?  We attack the problem with the
# right attitude, don't just make it better, define what better is.  Once 
# better is defined, meet those parameters.  Here are our parameters:
# 1. No predefined database names.
# 1. Document the entire system.
# 1. New users up and running within 10 minutes of finding the plugin.
# 1. No assumpts about the website's flow or structure.
# 1. Authentication without loss of user's state information.
# 1. Seperate configuration from source code manipulation.
# 1. User roles are defined by program constants.
# 1. Seperate user authentication, roles, code access, and data access.
#
#	==Definitions
# What makes this plugin so different?  A clear vision of how and why:
#
# * User Authentication - User authentication defines the code access rules.
class RestlessAuthentication

  #################
  # Class Methods #
  #################

  # Returns the stack of the methods that are called  zero is the parent method
  def self.trace
    result = Array.new
    Kernel::caller.each do |stk|
      result.push( stk.gsub(/.*`([^']*)'.*/, '\1').to_sym) if stk.include?('`')
    end
    return result
  end
end
