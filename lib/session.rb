require 'rdiscount'
require 'time'

class Session < Sequel::Model
  @@expires = 24 * 60 * 60  # cookies expire after a day

	set_schema do
		primary_key :id
		text :data
		timestamp :created_at
	end

	def Session.clean
	  Session.filter(:created_at < Time.now - @@expires).delete
	end
end

Session.create_table unless Session.table_exists?
