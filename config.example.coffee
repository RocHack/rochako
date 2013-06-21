module.exports =
  couch:
    db: 'http://localhost:5984/ircmarkov'
  irc:
    server: 'irc.example.com'
    secure: true
    port: 6697
    channels: ['#test']
    nick: 'name'
    nickServPassword: ''
    userName: 'name'
    realName: 'Name'
    chattiness: 0.001
    polite: false
  debug: false
