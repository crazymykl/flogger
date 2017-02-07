{BufferedProcess} = require 'atom'

parse = (flogData) ->
  lines = flogData.split "\n"

  total = +lines.shift().match /\d+\.\d+(?=:)/
  perMethod = +lines.shift().match /\d+\.\d+(?=:)/

  methods = []
  lines.shift()

  while value = lines.shift()
    [_, complexity, line_num] = value.match /^\s+(\d+\.\d+):.*:(\d+)(?:-\d+)?$/
    methods.push [+line_num, +complexity]

  {total, perMethod, methods}

complexityOf = (code) ->
  new Promise (resolve, reject) ->
    output = ''

    process = new BufferedProcess
      command: atom.config.get 'flogger.flogCommand'
      args: ['-aqm']
      stdout: (out) -> output += out
      stderr: (err) ->
        console.error("Flogger encountered an error while executing command:")
        console.error(err)
      exit: (code) ->
        if code
          reject new Error "flog barfed with #{code}"
        else
          resolve parse output
    .process

    if process.stdin.writable
      process.stdin.write code
      process.stdin.end()

module.exports = {complexityOf}
