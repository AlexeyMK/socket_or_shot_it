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

server = net.createServer((stream) ->
  client = new Client(stream)
  clients.push client

  write_stream = (message) =>
    stream.write(message + "\n")
  stream.setTimeout 0
  stream.setEncoding "utf8"

  stream.addListener('connect', ->
    if game_state is SETUP
      write_stream 'Welcome, enter your username:'
    else
      write_stream "Sorry, game's already full"
  )

  stream.addListener('data', (data) ->
    if client.name is null
      client.name = data.match /\S+/
      write_stream('===========')
      for c in clients when c isnt client
        c.write_stream(client.name + " has joined.")
      return

    matched = data.match /^\/(.*)/
    if matched and matched.length > 1
      command = matched[1]
      if command == 'users'
        for c in clients
          write_stream("- " + c.name + "")
      else if command == 'quit'
        stream.end()

      return

    for c in clients when c isnt client
      c.write_stream(client.name + ": " + data)
  )

  stream.addListener('end', ->
    clients.remove client

    for c in clients
      c.write_stream client.name+" has left."

    stream.end()
  )
)

server.listen 7000
