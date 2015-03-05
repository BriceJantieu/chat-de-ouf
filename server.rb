require 'sinatra'
require 'mongo'
require 'rubygems'
require 'date'
require 'sinatra/streaming'
include Mongo

  set server: 'thin', connections: []
  configure do
  enable :sessions
	db = MongoClient.new("ds041861.mongolab.com", 41861).db("chat-de-ouf")
	db.authenticate("team", "team")
 	set :db, db
  set :list, []
end

def formatDate(aDate)
 
  date = DateTime.parse(aDate)
  return date.strftime("%D") + " a " + date.strftime("%R")
 
 end


post '/createaccount' do
  puts "user test"
	coll = settings.db.collection("users")
	doc = {"name" => params[:name], "password" => params[:password], "email" => params[:email]}
  puts doc
	if (coll != nil)
    puts "coll not nil"
		user = coll.insert(doc)
    puts user
    session[:name] = params[:name]
    session[:user_id] = user
    redirect to('/messages')
	end
end

post '/messages' do
  puts session[:user_id]
  if (session[:name] != nil && session[:user_id] != "")
     messages = settings.db.collection("messages")
     messageToInsert = {"content" => params[:message], "datetime" => DateTime.now.to_s, "author_id" => session[:user_id], "name"=> session[:name]}
     message = messages.insert(messageToInsert)
     affichage = "" 
     settings.connections.each { |out| out << "data: #{params[:message]}\n\n" }
     204
     redirect to('/messages')
  else
    redirect to('/')
  end
end

post '/logout' do
  puts "deco"
  session[:user_id] = nil
  session[:name] = nil
  redirect to('/')

 end

get '/stream', provides: 'text/event-stream' do
  puts "stream"
  stream :keep_open do |out|
    i = 0
    timer = EventMachine::PeriodicTimer.new(1) do
      timer.cancel if out.closed?
      i += 1
      out.puts i rescue ''
    end
  end
end



post '/' do
  coll = settings.db.collection("users")
  user = coll.find_one("name" => params[:name], "password" => params[:password])
  if (user != nil)
    puts user
    session[:name] = user["name"]
    session[:user_id] = user["_id"]
    redirect to('/messages')
  else
    redirect to('/')
  end
end


get '/' do
   if (session[:user_id] != nil && session[:user_id] != "")
      redirect to('/messages')
   else
      erb :index
   end

end

get '/createaccount' do
	erb :createaccount
end


get '/messages' do 
  dbmessages = settings.db.collection("messages")
  affichage = []
  dbmessages.find.each {|message| 
    message["datetime"] = formatDate(message["datetime"])
    affichage << message}
  erb :messages, :locals => {:messages => affichage}
end