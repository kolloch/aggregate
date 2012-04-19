aggregate = require '../index.js'
expect    = require 'expect.js'

logger = (func=null) ->
  log = []

  logCalls = (args...) ->
    log.push args

    if func?
      func.apply(null, args)

  logCalls.log = log
  logCalls.wrapped = func

  logCalls

doubleTick = (cb) ->
  process.nextTick -> process.nextTick cb

describe "aggregate", ->
  wrapped = callback = aggregated = null

  simulated = (ids, callback) ->
    process.nextTick ->
      results = {}
      results[id] = 'result_' + id for id in ids
      callback null, results

  beforeEach (done) ->
    wrapped    = logger(simulated)
    callback   = logger()
    aggregated = aggregate(wrapped)
    done()

  it "prevents emtpy calls", (done) ->
    aggregated([], callback)

    doubleTick ->
      expect(wrapped.log).to.be.empty()
      expect(callback.log).to.eql([[null, {}]])

      done()

  it "works with one call only", (done) ->
    aggregated(['1'], callback)

    doubleTick ->
      expect(wrapped.log.length).to.eql(1)
      expect(wrapped.log[0][0]).to.eql(['1'])

      expect(callback.log).to.eql([[null, {'1': 'result_1'}]])

      done()

  it "helper for single", (done) ->
    aggregatedForSingle = aggregated.forSingleId()

    aggregatedForSingle('1', callback)

    doubleTick ->
      expect(wrapped.log.length).to.eql(1)
      expect(wrapped.log[0][0]).to.eql(['1'])

      expect(callback.log).to.eql([[null, 'result_1']])

      done()


  it "aggregation", (done) ->
    callback2 = logger()

    aggregated(['1'], callback)
    aggregated(['1', '2', '3'], callback2)

    doubleTick ->
      expect(wrapped.log.length).to.eql(1)
      expect(wrapped.log[0][0]).to.eql(['1', '2', '3'])   

      expect(callback.log).to.eql([[null, {'1': 'result_1'}]])
      expect(callback2.log).to.eql([[null, {'1': 'result_1', '2':'result_2', '3':'result_3'}]])

      done()
