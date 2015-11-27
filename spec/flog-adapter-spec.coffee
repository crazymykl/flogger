fs = require 'fs'
path = require 'path'
flogAdapter = require '../lib/flog-adapter'

handlePromise = (p) ->
  res =
    success: null
    failure: null
  p
    .then (r) -> res.success = r
    .catch (e) -> res.failure = e
  res

describe "FlogAdapter", ->

  [output, fixturesPath] = []
  beforeEach ->
    fixturesPath = fixturesPath = path.join __dirname, 'fixtures'
    output = undefined

  it "parses valid ruby", ->

    waitsForPromise ->
      ruby = fs.readFileSync path.join(fixturesPath, 'test.rb'), 'utf8'
      flogAdapter.complexityOf ruby
        .then (x) -> output = x

    runs ->
      expect(output).toEqual
        total: 34.7
        perMethod: 11.6
        methods: [
          [15, 21.2]
          [9, 11.5]
          [5, 2]
        ]

  it "fails to parse invalid ruby", ->

    waitsForPromise ->
      barf = """
        def foo
          1x
        end
      """
      flogAdapter.complexityOf barf
        .catch (err) -> output = err

    runs ->
      expect(output instanceof Error).toBeTruthy()
