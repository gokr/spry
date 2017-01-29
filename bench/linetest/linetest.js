var lineReader = require('readline').createInterface({
  input: require('fs').createReadStream('/home/gokr/nim/spry/bench/lotslines')
});

var lines = []

lineReader.on('line', function (line) {
  lines.push(line)
});

