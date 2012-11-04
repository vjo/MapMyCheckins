require 'sinatra'
require 'net/https'
require 'json'

$LOAD_PATH << './config'
require 'AppConfig'

# Config param
CLIENT_ID = AppConfig::CLIENT_ID
CLIENT_SECRET = AppConfig::CLIENT_SECRET
REDIRECT_URI = AppConfig::REDIRECT_URI
VERSION = AppConfig::VERSION

enable :sessions

get '/' do
	@url = "/authenticate"
	erb :index
end

get '/authenticate' do

	if session[:token]
		redirect "/app"

	elsif params[:code]
		json = getJSON("https://foursquare.com/oauth2/access_token?client_id=" + CLIENT_ID + "&client_secret=" + CLIENT_SECRET + "&grant_type=authorization_code&redirect_uri=" + REDIRECT_URI + "&code=" + params[:code])
		session[:token] = JSON.parse(json)['access_token']

# XXX : do i need id ?		
#		json = getJSON("https://api.foursquare.com/v2/users/self?oauth_token=" + token)
		#puts json
#		id = JSON.parse(json)['response']['user']['id']

# Store id and token in file
#		File.open('usersToken.txt', 'w') do |f|  
#    		f.puts id + " : " + token + "\n"
#		end 
		
		# XXX : must i store ids and tokens ? 
		# as said in https://developer.foursquare.com/overview/auth 
		# "4. Save this access token for this user in your database."

		# or use session to store token ?

	redirect "/app"

	else 
		# Authorize app
		redirect "https://fr.foursquare.com/oauth2/authenticate?client_id=" + CLIENT_ID + "&response_type=code&redirect_uri=" + REDIRECT_URI
	end


end

get '/app' do	
	if session[:token]
		@venues = getJSON("https://api.foursquare.com//v2/users/self/venuehistory?oauth_token=" + session[:token])
		erb :app
	else
		"Error: something strange happened here"
	end
end

get '/test' do	
	if session[:token]
		checkin = getJSON("https://api.foursquare.com//v2/users/self/checkins?oauth_token=" + session[:token] + "&limit=1")
		nbCheckins = JSON.parse(checkin)['response']['checkins']['count'] # here i have the total number of checkins
		
		limit = 250
		checkins = []

		for i in 0..(nbCheckins / limit)
			result = getJSON("https://api.foursquare.com//v2/users/self/checkins?oauth_token=" + session[:token] + "&offset=#{i*250}&limit=#{limit}")
   		puts "Get checkins from #{i*250} to #{(i+1)*250}"

   		JSON.parse(result)['response']['checkins']['items'].each do |checkin|
   			checkins.push checkin
   		end
		end
		
		#puts "Checkins : #{checkins.length}"


		checkinDates = []
		checkins.each do |checkin|
			checkin['venue']['id'] == "4beba7896295c9b684fe8708" ? (checkinDates.push checkin['createdAt']) : nil
		end

		checkinDates.each do |date|
			puts "4beba7896295c9b684fe8708 : " + Time.at(date).to_s
		end
		#puts @checkins
		#erb :test

		# now use d3js to make nice graph
		# http://square.github.com/crossfilter/

	else
		"Error: something strange happened here"
	end
end

def getJSON(url)
	uri = URI.parse(url + "&v=" + VERSION)
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	request = Net::HTTP::Get.new(uri.request_uri)

	return http.request(request).body
end
