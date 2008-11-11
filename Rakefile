port = 3030

desc "Start the app server"
task :start => :stop do
	puts "Starting the blog"
	system "ruby main.rb -p #{port} > access.log 2>&1 &"
end

# code lifted from rush
def process_alive(pid)
	::Process.kill(0, pid)
	true
rescue Errno::ESRCH
	false
end

def kill_process(pid)
	::Process.kill('TERM', pid)

	5.times do
		return if !process_alive(pid)
		sleep 0.5
		::Process.kill('TERM', pid) rescue nil
	end

	::Process.kill('KILL', pid) rescue nil
rescue Errno::ESRCH
end

desc "Stop the app server"
task :stop do
	m = `lsof -i -P | grep "*:#{port}" | grep LISTEN | awk ' { print $2 } '`
	if m
		pid = m.to_i
		if pid != 0
		  puts "Killing old server #{pid}"
		  kill_process(pid)
		end
	end
end

task :environment do
	require 'sequel'
	DB = Sequel.connect('sqlite://blog.db')
	$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
	require 'post'
end

task :import => :environment do
	url = ENV['URL'] or raise "No url specified, use URL="

	require 'rest_client'
	posts = YAML.load RestClient.get(url)

	posts.each do |post|
		DB[:posts] << post
	end
end
