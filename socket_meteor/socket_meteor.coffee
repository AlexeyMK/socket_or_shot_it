if Meteor.is_client
  console.log "starting up!"
  Template.hello.bob = () ->
    return "Welcome to FirstApp.  OMG"

  Template.hello.events =
    "click input": -> console.log "You pressed the button!!"
