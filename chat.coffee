net = require('net')

Array.prototype.remove = (element) ->
  for e, i in this when e is element
    return this.splice(i, 1)

class Client
  constructor: (stream) ->
    @stream = stream
    @name = null

clients = []
game_state = 0 # key: 0 => setup, # => (question N), -1 => done
SETUP = 0
solutions = [{answer: "4"}, {answer:"5"}]

broadcast = (message) ->
  c.stream.write(message + "\n") for c in clients

process_guess = (c, solution) ->
  if solutions[game_state].answer == solution.trim()
    broadcast "#{c.name} got question #{game_state} right!"
    #correct!
  else #so wrong
    broadcast "#{c.name} got question #{game_state} wrong!"

server = net.createServer((stream) ->
  client = new Client(stream)

  stream.setTimeout 0
  stream.setEncoding "utf8"

  stream.addListener('connect', ->
    if game_state is SETUP
      stream.write 'Welcome, enter your username:\n'
      clients.push client
    else
      stream.write "Sorry, game's already full\n"
      stream.end()
  )

  stream.addListener('data', (data) ->
    #get name
    if client.name is null
      client.name = data.match /\S+/
      broadcast("====================")
      broadcast(client.name + " has joined.")
    else
      process_guess client, data
  )

  stream.addListener('end', ->
    clients.remove client
    broadcast client.name+" has left."
    stream.end()
  )
)

server.listen 7000
