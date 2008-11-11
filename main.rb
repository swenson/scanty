require 'rubygems'
require 'sinatra'
require 'sequel'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/config')
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'config'
require 'post'
require 'user'
require 'session'

helpers do
	def admin?
	  Session.clean
		Session.map(:data).include? request.cookies[Blog.admin_cookie_key]
	end

	def auth
		stop [ 401, 'Not authorized' ] unless admin?
	end
end

layout 'layout'

### Public

get '/' do
  if params[:p]
    post = Post.filter(:id => params[:p]).first
	  stop [ 404, "Page not found" ] unless post
		redirect post.url
	else
	  posts = Post.reverse_order(:created_at).limit(10)
	  erb :index, :locals => { :posts => posts }, :layout => false
	end
end

get '/past/:year/:month/:day/:slug/' do
	post = Post.filter(:slug => params[:slug]).first
	stop [ 404, "Page not found" ] unless post
	@title = post.title
	erb :post, :locals => { :post => post }
end

get '/past/:year/:month/:day/:slug' do
	redirect "/past/#{params[:year]}/#{params[:month]}/#{params[:day]}/#{params[:slug]}/", 301
end

get '/past' do
	posts = Post.reverse_order(:created_at)
	@title = "Archive"
	erb :archive, :locals => { :posts => posts }
end

get '/past/tags/:tag' do
	tag = params[:tag]
	posts = Post.filter(:tags.like("%#{tag}%")).reverse_order(:created_at).limit(30)
	@title = "Posts tagged #{tag}"
	erb :tagged, :locals => { :posts => posts, :tag => tag }
end

get '/feed' do
	@posts = Post.reverse_order(:created_at).limit(10)
	content_type 'application/atom+xml', :charset => 'utf-8'
	builder :feed
end

get '/rss' do
	redirect '/feed', 301
end

### Admin

get '/auth' do
	erb :auth
end

post '/auth' do
	if User.all.select { |s| 
	   SHA1.hexdigest(params[:password] + s.salt) ==
		 s.salted_hashed_password }.length > 0 then
	 	cookie = rand(2**128).to_s(16)
	 	set_cookie(Blog.admin_cookie_key, cookie) 
		session = Session.new :created_at => Time.now, :data => cookie
		session.save
	end
	redirect '/'
end

get '/users' do
  auth
	erb :users, :locals => { :users => User.all }
end

post '/users' do
  auth
	user = User.find(:name => params[:oldname])
	if user
	  user.name = params[:name]
		user.display_name = params[:display_name]
		user.password = params[:password] if params[:password] and params[:password].length > 0
		user.save
	end
	redirect '/users'
end

get '/users/:name' do
  auth
	user = User.find(:name => params[:name])
	user = User.new unless user
	erb :edit_user, :locals => { :user => user, :url => '/users' }
end

get '/users/new' do
  auth
	erb :edit_user, :locals => { :user => User.new, :url => '/users' }
end

get '/posts/new' do
	auth
	erb :edit, :locals => { :post => Post.new, :url => '/posts' }
end

post '/posts' do
	auth
	post = Post.new :title => params[:title], :tags => params[:tags], :body => params[:body], :created_at => Time.now, :slug => Post.make_slug(params[:title])
	post.save
	redirect post.url
end

get '/past/:year/:month/:day/:slug/edit' do
	auth
	post = Post.filter(:slug => params[:slug]).first
	stop [ 404, "Page not found" ] unless post
	erb :edit, :locals => { :post => post, :url => post.url }
end

post '/past/:year/:month/:day/:slug/' do
	auth
	post = Post.filter(:slug => params[:slug]).first
	stop [ 404, "Page not found" ] unless post
	post.title = params[:title]
	post.tags = params[:tags]
	post.body = params[:body]
	post.save
	redirect post.url
end

