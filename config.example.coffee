module.exports =
  couch:
    secure: true
    auth: 'username:password'
    host: 'localhost'
    port: '6984'
    rejectUnauthorized: false
    database: 'ircmarkov'
  irc:
    server: 'irc.example.com'
    secure: true
    port: 6697
    channels: ['#test']
    nick: 'name'
    nickServPassword: ''
    userName: 'name'
    realName: 'Name'
