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

def getJSON(url)
	uri = URI.parse(url + "&v=" + VERSION)
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	request = Net::HTTP::Get.new(uri.request_uri)

	return http.request(request).body
end