require 'yaml'
require 'ftools'

config = "#{File.dirname(__FILE__)}/config/restless_authentication.yml"

	#Define a readline statement that doesn't kill the stupid thing
def readline
	$stdin.readline
end

	#Rercurisively create the user's config file
def create_config( yaml, depth = Array.new )
	hash = Hash.new
	space = ''.rjust(depth.size*2, ' ')
	keys = yaml.keys
	keys.sort.each do |key|
		value = yaml[key]
		dep = depth.dup.push(key)
		case value.class.to_s.to_sym
		when :Hash
			puts "#{space}#{key}:"
			hash[key] = create_config(value, dep)
		when :Array
			list = Array.new
			ary = value[0].split(/,/)
			ary.size.times { |i| list[i] = "#{i} => #{ary[i]}" }
			print "#{space}#{key}: {#{list.join(',')}} [0]# "
			result = readline.chomp
			hash[key] = ary[((result.empty?)? 0: result.to_i)]
		when :TrueClass
			print "#{space}#{key}: [#{value.to_s}]# "
			result = readline.chomp.downcase
			result = (result.empty?)? value.to_s: result
			hash[key] = (result.eql?('1') or result.eql?('true'))
		else	#String class
			print "#{space}#{key}: [#{value.to_s}]# "
			result = readline.chomp
			hash[key] = (result.empty?)? value.to_s: result
		end
	end

	return hash
end

	#Output a has in yaml format
def dump_config( hash, depth = 0 )
	space = ''.rjust(depth*2, ' ')
	str = ''

		#Go through the hash dumping the hash to a yaml file
	keys = hash.keys
	keys.sort.each do |key|
		value = hash[key]
		if value.kind_of? Hash
			str += "#{space}#{key}:\n#{dump_config(value, depth + 1)}"
		else	
			str += "#{space}#{key}: #{value}\n"
		end
	end

	return str
end

# Install hook code here
puts File.open("#{File.dirname(__FILE__)}/README").read

	#Tell the user that we are going to ask questions now
puts ""
puts "##############"
puts "# User Input #"
puts "##############"
puts ""
puts "You are going to be asked questions about the configuration of restless."
puts "This configuration can be changed by editing config/restless_authentication.yml."
puts ""
puts "Are you ready?"
puts ""
readline

	#Loop while we are getting the user's input
while true

		#Create the configuraiton script
	puts ""
	puts ""
	yaml = YAML::load(File.open(config))
	@hash = Hash.new
	puts 'database:'
	@hash['database'] = create_config( yaml['database'], ['database'] )
	puts 'authentication:'
	@hash['authentication'] = create_config( yaml['authentication'], ['authentication'] )
	puts 'static_roles:'
	@hash['static_roles'] = create_config(yaml['static_roles'], ['static_roles'])

		#Output the user's config file
	puts ""
	puts dump_config( @hash )
	puts ""

		#Check if we are done
	result = ''
	while (result[0..0] !='n' && result[0..0] !='y')
		puts "Is this information Correct? [y/N]# "
		result = readline.chomp.downcase 
	end
	break if result == 'y' 
end

	#Write the config file out to the user's directory
puts "Writing #{File.dirname(__FILE__)}/../../../config/restless_authentication.yml"
file = File.open("#{File.dirname(__FILE__)}/../../../config/restless_authentication.yml", 'a' )
file.puts dump_config(@hash)
file.close

	#copy my modules
['auth_static_filter.rb', 'auth_static_role.rb', 'auth_sys.rb', 'auth_user.rb'].each do |f|
	puts "Copying #{f}"
	File.copy("#{File.dirname(__FILE__)}/user_modules/#{f}",
						"#{File.dirname(__FILE__)}/../../../lib/#{f}" )
end

  #Tell the user we are done
puts ""
puts "Restless Authentication installation complete"
