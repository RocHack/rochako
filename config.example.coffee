module.exports =
  couch:
    db: 'http://localhost:5984/ircmarkov'
  irc:
    nick: 'name'
    nickServPassword: ''
    userName: 'name'
    realName: 'Name'
    chattiness: 0.001
    polite: false
    servers: [
      address: 'irc.example.com'
      port: 6697
      secure: true
      channels: ['#test']
    ,
      address: 'irc.otherexample.org'
      port: 6667
      channels: ['#othertest']
    ]
  tumblr:
    host: 'example.tumblr.com'
    key: null
  api:
    port: 8050
  debug: false
  skiplog: false
