net = require('net')

solutions =
  [{}, #dummy question for setup
   {
    "question":"Sum the first fifteen prime numbers",
    "answer":"328"
   },
   {
    "question":"Number of vowels (upper or lower case) in the following sequence:
    Note: vowels are: a, e, i, o, u and sometimes y. For the purpose of this question,
    consider y to be a vowel unless it is followed by a 'real vowel' (a,e,i,o,u)",
    "input":"
    Whereas recognition of the inherent dignity and of the equal and inalienable rights of all members of the human family is the foundation of freedom, justice and peace in the world,

    Whereas disregard and contempt for human rights have resulted in barbarous acts which have outraged the conscience of mankind, and the advent of a world in which human beings shall enjoy freedom of speech and belief and freedom from fear and want has been proclaimed as the highest aspiration of the common people,

    Whereas it is essential, if man is not to be compelled to have recourse, as a last resort, to rebellion against tyranny and oppression, that human rights should be protected by the rule of law,

    Whereas it is essential to promote the development of friendly relations between nations,

    Whereas the peoples of the United Nations have in the Charter reaffirmed their faith in fundamental human rights, in the dignity and worth of the human person and in the equal rights of men and women and have determined to promote social progress and better standards of life in larger freedom,

    Whereas Member States have pledged themselves to achieve, in co-operation with the United Nations, the promotion of universal respect for and observance of human rights and fundamental freedoms,

    Whereas a common understanding of these rights and freedoms is of the greatest importance for the full realization of this pledge,

    Now, Therefore THE GENERAL ASSEMBLY proclaims THIS UNIVERSAL DECLARATION OF HUMAN RIGHTS as a common standard of achievement for all peoples and all nations, to the end that every individual and every organ of society, keeping this Declaration constantly in mind, shall strive by teaching and education to promote respect for these rights and freedoms and by progressive measures, national and international, to secure their universal and effective recognition and observance, both among the peoples of Member States themselves and among the peoples of territories under their jurisdiction.
    "
    "answer":"649"
   },
   {
    "question":"How many different ways can you make change for 29 cents? (a quarter, or 25 pennies, or 2 dimes and 5 pennies, or...",
    "answer":"13"
   },
   {
    "question":"Given the formula f(x) = x^2 + b*x + c, 0<b<1000, 0<c<1000, what values for b and c produce the longest consecutive series of prime numbers for f(x) for values of x starting at zero and increasing? IE, f(x) = x^2 + 3 * x + 3, f(0) = 3, f(1) = 7, f(2) = 13, f(3) = 21.  sequence_length(3,3) = 3 (0, 1, 2 work, 3 fails).  Give the answer in the form of 1000 * b + c"
    "answer":"1041"
   },
   {
    "question": "What is the 12th positive number that is both a palindrome and a perfect square?"
    "answer":"69696",
   },
   {
    "question": "It's 6:15 AM (PST) on Saturday right now and the sun is coming up. The weather report promises 75 degrees fahrenheit, though in fairness celcius is a superior system. What day of the week, 1-7. (Monday=1... Sunday=7) is it 10,000 days from now, including leap years?",
    "answer": "3"
   },
   {
    "question": "The probability of rolling a prime in the sum of three six-digit die is X/216. What is X?",
    "answer": "73"
   },
  ]

Array.prototype.remove = (element) ->
  for e, i in this when e is element
    return this.splice(i, 1)

class Client
  constructor: (stream) ->
    @stream = stream
    @name = null

admin = null
clients = []
game_state = 0 # key: 0 => setup, # => (question N), -1 => done
buzzer_state = off # false by dfeault 
buzzed_in = []
SETUP = 0
RIGHT_CUTOFF = 1
DRINK_STR = "\7\7\7\7\7\7\7\7\7\7\7"

broadcast = (message) ->
  c.stream.write(message + "\n") for c in clients

command_drink = (client) ->
  #TODO: bell
  broadcast "#{client.name} has to drink!"
  client.stream.write DRINK_STR

all_drink = (message) ->
  broadcast message + DRINK_STR

broadcast_question = (number) ->
  broadcast "question ##{number}:"
  broadcast solutions[number].question
  if solutions[number].input?
    broadcast ""
    broadcast "======================================"
    broadcast "INPUT IS"
    broadcast "======================================"
    broadcast ""
    broadcast solutions[number].input
  broadcast "======================================"
  broadcast ""
  broadcast "gogogo"

process_guess = (c, solution) ->
  question = solutions[game_state]
  if game_state is SETUP
    return c.stream.write "Game hasn't started yet, chill\n"
  if buzzer_state is on
    buzzed_in.push c unless c in buzzed_in
    if buzzed_in.length + 2 == clients.length # all except last guy and admin
      #who has to drink 
      broadcast "So that's done..." 
      command_drink cl for cl in clients when (not (cl in buzzed_in) and not (cl is admin))
      buzzed_in = []
      buzzer_state = off
    return
  if question.answer == solution.trim()
    #correct!
    broadcast "#{c.name} got question #{game_state} right!"
    question.right = [] if not question.right
    question.right.push(c)
    if question.right.length >= RIGHT_CUTOFF # NEXT QUESTION
      broadcast("Question done! answer was #{question.answer}")
      #TODO: tell the right people to drink
      game_state +=1
      if game_state >= solutions.length
        all_drink "Game over! Thanks for playing. Also, drink."
        #TODO who won
      else
        broadcast_question game_state

  else #so wrong
    broadcast "#{c.name} got question #{game_state} wrong!"
    command_drink c

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
    data = data.trim()
    if client.name is null #get name
      client.name = data
      if client.name is 'the_dm' and admin is null
        admin = client
      else
        broadcast("====================")
        broadcast(client.name + " has joined.")
    else if client is admin and game_state is SETUP and data == "start" #game start
      game_state = 1 #start
      broadcast "Starting Game... here we go!"
      #start the first '
      broadcast_question game_state
    else # guess
      process_guess client, data
  )

  stream.addListener('end', ->
    clients.remove client
    broadcast client.name+" has left."
    stream.end()
  )
)

#Bell rings, respond last and you drink 
setInterval(( ->
  return if game_state is SETUP
  setTimeout(( ->
    buzzer_state = on
    buzzed_in = []
    broadcast "last one to respond to this (with any message) has to drink"
  ), parseInt(Math.random() * 110) * 1000) # sometime in the next 110 seconds)
), 120 * 1000) #should be 120
#Set timeout every 8 minutes
every_n_minutes = 8
setInterval(( ->
  if game_state > SETUP
    all_drink "Every 3 minutes, you drink. Wasn't kidding about that."
), every_n_minutes * 60 * 1000)

server.listen 7000
