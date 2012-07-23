# Shared code
Contestants = new Meteor.Collection('contestant')
Questions = new Meteor.Collection('question')
Answers = new Meteor.Collection('answer')
# {question, contestant} -> correct_or_incorrect, point_diff

ServerState = new Meteor.Collection('serverstate')
# stores a bunch of state, only one row. basically a hack
# current_round: -1 => not started, 0..n => question #n, >n => over

if Meteor.is_server
  Meteor.startup ->
    ServerState.insert
      current_round: -1
      points_for_correct: [10,5,3]  # this also indicates 3 correct total
      penalty_for_wrong: -2
      admin_id: ''

server_state = ->
  ServerState.findOne({})

next_round = ->
  ServerState.update {},
    $inc:
      current_round: 1
  $('#current_question').show()

get_contestants = ->
  active_players = Contestants.find
    name: $ne: ''
    _id: $ne: server_state()?.admin_id
  results = active_players.map (c) ->
    # Resolve duplicate names by using an ID prefix
    c.display_name = "#{ c.name } (#{c._id[..4]}) "
    c
  console.log "contestants: #{results}", results
  results

round_number = ->
  number = server_state()?.current_round
  if number? then number else -1

current_question = ->
  Questions.findOne(round: round_number())

game_started = ->
  console.log "game_started: #{round_number()}"
  round_number() >= 0

game_over = ->
  # can't find the current question, must be over
  game_started() and not current_question()

update_correct_answer = (contestant, round) ->
  # update points
  num_solutions = Answers.find(
    round: round,
    correct: true
  ).count()
  num_points_won = server_state().points_for_correct[num_solutions]

  # prevent multiple correct submissions
  return if Answers.findOne(
    round: round
    contestant_id: contestant._id
    correct: true
  )?
  Answers.insert
    contestant_id: contestant._id
    round: round
    point_value: num_points_won
    correct: true

  if num_solutions + 1 == server_state().points_for_correct.length
    next_round()

update_wrong_answer = (contestant, round) ->
  value = server_state().penalty_for_wrong
  console.log "inserting", value
  Answers.insert
    contestant_id: contestant._id
    round: round
    point_value: value
    correct: false

if Meteor.is_client
  Template.main.game_started = -> game_started()
  Template.main.game_over = -> game_over()
  Template.main.is_admin = -> get_contestant()._id == server_state()?.admin_id
  Template.main.player_in_game = -> get_contestant().name isnt ''

  Template.wait_for_start.contestant_name = -> get_contestant().display_name

  Template.register_new_user.events =
    "click button#register_button": ->
      name = $('input#username').val().trim()
      contestant_id = get_contestant()._id
      # if youre first youre the admin
      is_admin = Contestants.find(name: $ne: '').count() == 0
      Contestants.update contestant_id, name: name
      ServerState.update({}, $set: admin_id: contestant_id) if is_admin
      console.log "new user #{name}, id #{contestant_id} is admin? #{is_admin}"
      Session.set('contestant', Contestants.findOne(contestant_id,
        reactive: false))

  Template.scoreboard.contestants = ->
    scoreboard = {}
    console.log "updating contestants"
    get_contestants().forEach (c) ->
      if c.name isnt '' and c._id isnt server_state()?.admin_id
        scoreboard[c._id] =
          name: c.display_name
          score: 0

    # iterate over answers
    Answers.find().forEach (answer) ->
      console.log answer, answer.point_value
      scoreboard[answer.contestant_id].score += answer.point_value

    (v for k, v of scoreboard)

  Template.current_question.question_text = ->
    current_question().text

  Template.current_question.question_number = ->
    current_question().round + 1

  Template.current_question.events =
    "click button#answer_question": ->
      answer = $('input#answer').val().trim()
      console.log answer, current_question().solution
      # heh, coffeescript forces === so I have to coerce myself
      if String(answer) is String(current_question().solution)
        update_correct_answer(get_contestant(), current_question().round)
        $('#feedback').text "good job"
        $('#current_question').hide()
      else
        console.log "wrong answer"
        update_wrong_answer(get_contestant(), current_question().round)
        $('#feedback').text "not quite"


  Template.admin_panel.game_started = -> game_started()
  Template.admin_panel.game_over = -> game_over()

  Template.admin_panel.events =
    "click button#start_game": ->
      console.log "start game clicked"
      ServerState.update {},
        $inc:
          current_round: 1
    "click button#next_round": ->
      console.log "next round"
      next_round()

  get_contestant = ->
    contestant = Session.get('contestant')
    return "Unknown" if not contestant
    # Resolve duplicate names by using an ID prefix
    contestant.display_name = "#{ contestant.name } (#{contestant._id[..4]}) "
    return contestant

  Meteor.autosubscribe ->
    contestant_id =
      monster.get('local_contestant') or Contestants.insert({name: ''})
    monster.set('local_contestant', contestant_id)
    Session.set('contestant', Contestants.findOne(contestant_id))
