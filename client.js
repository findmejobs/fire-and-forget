var dgram = require('dgram');
var client = dgram.createSocket("udp4");

var message = new Buffer(JSON.stringify({'objectType': 'user', 'someData':'data'}));

client.send(message, 0, message.length, 42314, "git.shiftrefresh.net", function(err, bytes) {
  console.log(err);
  console.log(bytes);
  client.close();
});
