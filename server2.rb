require 'sinatra'
set server: 'thin', connections: []

get '/' do
  puts "test : "
  halt erb(:login) unless params[:user]
  erb :chat, locals: { user: params[:user].gsub(/\W/, '') }
end

get '/stream', provides: 'text/event-stream' do
  stream :keep_open do |out|
    EventMachine::PeriodicTimer.new(20) { out << "data: \n\n" } # added
    settings.connections << out
    puts settings.connections.count # added
    out.callback { puts 'closed'; settings.connections.delete(out) } # modified
  end
end

post '/' do
  puts "message : "
  puts params[:msg]
  settings.connections.each { |out| out << "data: #{params[:msg]}\n\n" }
  204 # response without entity body
end

__END__

@@ layout
<html>
  <head> 
    <title>Super Simple Chat with Sinatra</title> 
    <meta charset="utf-8" />
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js"></script> 
  </head> 
  <body><%= yield %></body>
</html>

@@ login
<form action='/'>
  <label for='user'>User Name:</label>
  <input name='user' value='' />
  <input type='submit' value="GO!" />
</form>

@@ chat
<pre id='chat'></pre>

<script>
  // reading
  var es = new EventSource('/stream');
  es.onmessage = function(e) { if (e.data != '') $('#chat').append(e.data + "\n") }; // modified
  // writing
  
  
</script>

<form method="post" action="/">
  <input type="text"  name='msg' placeholder='type message here...' />
  <input type='submit' value="GO!"  />
</form>