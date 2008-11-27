require 'rdiscount'
require 'sha1'

class User < Sequel::Model
	set_schema do
		primary_key :id
		text :display_name
		text :name
		text :salt
		text :salted_hashed_password
		timestamp :created_at
	end

	def password=(pass)
	  self.salted_hashed_password = SHA1.hexdigest(pass + self.salt)
	end
end

unless User.table_exists?
  User.create_table
	admin_salt = rand(2**128).to_s(16)
	admin = User.new :name => 'admin',
	                 :salt => admin_salt
	admin.password = Blog.initial_admin_password
	admin.save
end
