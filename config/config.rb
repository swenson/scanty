configure do
	Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://blog.db')

	require 'ostruct'
	Blog = OpenStruct.new(
    :title => 'a scanty blog',
		:subtitle => 'just a blog',
		:owner => 'John and Jane Doe',
		:url_base => 'http://localhost:4567/',
		:initial_admin_password => 'changeme',
		:admin_cookie_key => 'scanty_admin',
		:disqus_shortname => nil
	)
end

