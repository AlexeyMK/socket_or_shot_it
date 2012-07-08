# Shared code
Contestants = new Meteor.Collection('contestants')
ServerState = new Meteor.Collection('serverstate')
# stores a bunch of state, only one row. basically a hack
# current_round: -1 => not started, 0..n => question #n, >n => over

game_started = ->
  ServerState.findOne({})?.current_round >= 0

if Meteor.is_server
  # if you haven't yet, start the game
  ServerState.findOne({}) or ServerState.insert
    current_round: -1

if Meteor.is_client
  Template.main.game_started = -> game_started()
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

  Template.admin_panel.game_started = -> game_started()
  Template.admin_panel.events =
    "click button#start_game": ->
      ServerState.update {},
        current_round: 0

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

