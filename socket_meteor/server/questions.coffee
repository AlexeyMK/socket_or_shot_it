Meteor.startup ->
  # TODO - move questions over successfully
  Questions.insert
    round: 0
    text: "What's two times two?"
    solution: 4
  Questions.insert
    round: 1
    text: "How are you Today?"
    solution: 'good'
  Questions.insert
    round: 2
    text: "What round is this?"
    solution: '3'
