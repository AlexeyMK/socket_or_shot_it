# Shared code
Contestants = new Meteor.Collection('contestant')
ServerState = new Meteor.Collection('serverstate')
Questions = new Meteor.Collection('question')

if Meteor.is_server
  Meteor.startup ->
    Questions.insert
      round: 0
      text: "What's two times two?"
    Questions.insert
      round: 1
      text: "How are you Today?"

    ServerState.insert
      current_round: -1

# stores a bunch of state, only one row. basically a hack
# current_round: -1 => not started, 0..n => question #n, >n => over
#
round_number = ->
  number = ServerState.findOne({})?.current_round
  if number? then number else -1

current_question = ->
  Questions.findOne(round: round_number())

game_started = ->
  console.log "game_started: #{round_number()}"
  round_number() >= 0

game_over = ->
  # can't find the current question, must be over
  game_started() and not current_question()

if Meteor.is_client
  Template.main.game_started = -> game_started()
  Template.main.game_over = -> game_over()
  Template.main.is_admin = -> true # FOR NOW
  Template.main.player_in_game = -> get_contestant().name isnt ''

  Template.wait_for_start.contestant_name = -> get_contestant().display_name

  Template.register_new_user.events =
    "click button#register_button": ->
      name = $('input#username').val().trim()
      contestant_id = get_contestant()._id
      Contestants.update contestant_id,
        name: name
      Session.set('contestant', Contestants.findOne(contestant_id,
        reactive: false))

  Template.contestant_list.contestants = ->
    Contestants.find
      name: $ne: ''

  Template.current_question.question_text = ->
    current_question().text

  Template.current_question.question_number = ->
    current_question().round

  Template.admin_panel.game_started = -> game_started()
  Template.admin_panel.game_over = -> game_over()

  Template.admin_panel.events =
    "click button#start_game": ->
      console.log "start game clicked"
      ServerState.update {},
        current_round: 0
    "click button#next_round": ->
      console.log "next round"
      ServerState.update {},
        $inc:
          current_round: 1

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
