#!/usr/bin/ruby

`find . -type f | grep -v git`.split(/\n/).each do |file|
  `rm #{file}`
  `ln -s /Development/rails_plugins/restless_authentication/user_modules/#{file} #{file}`
end
