logger = require('./logging')('aggregate', debug: false)

# "this" is the aggregated function
forSingleId = ->
  return (id, callback) =>
    this [id], (err, result) ->
      if err
        callback err
      else
        callback null, result[id]

# Merge the resultMaps of multiple callbacks
# and forward them to another callback when done
#
# Usage:
#   callback = (err, resultMap) ->
#        ...
#
#   collector = resultCollector(10, callback)
#   myFirstCall( param, collector.collect())
#   mySecondCall( param, collector.collect())
#
#   # After both callbacks have been called 
#   # callback null, mergedResultMaps is called
resultCollector = (callback) ->
  resultsLeft = 0
  collectedResults = {}
  errorReported = false

  collectResults = (err, result) ->
    if errorReported
      return

    if err?
      callback err
      errorReported = true
      return

    collectedResults[key] = result[key] for key of result
    resultsLeft--

    if resultsLeft == 0
      callback null, collectedResults

  return {
    collect: ->
      resultsLeft++
      collectResults
  }

getterByIds = (opts, func) ->
  unless func?
    func = opts
    opts = {}

  batchSize = opts.batchSize || 500

  if batchSize <= 0
    throw new Error('batchSize must be > 0')

  keys  = {} 
  calls = []

  # creates a callback which demultiplexes
  # the results to the given calls
  createProcessResultsForCalls = (calls) ->
    return logger.tracer 'processResults', (err,results) ->
      if err?
        for call in calls
          call.callback err 
      else
        for call in calls
          do (call) ->
            {callback,idArray} = call
            idResults = {}
            for id in idArray
              result = results[id]
              if result?
                idResults[id] = result

            callback null, idResults

  # Create the batched calls
  performCall = logger.tracer 'performCall', ->
    keysAsArray = (k for k of keys)
    processResults = createProcessResultsForCalls calls
  
    # reset
    keys  = {} 
    calls = []

    collector = resultCollector(processResults)

    while keysAsArray.length > 0
      batch = keysAsArray.slice(0, batchSize)
      func batch, collector.collect()
      keysAsArray = keysAsArray.slice(batchSize)

  ret = (idArray, callback) ->
    if idArray.length == 0
      logger.silly 'exiting because of empty array'
      callback null, {}
      return

    if calls.length == 0
      logger.silly 'scheduling next call'
      process.nextTick performCall

    calls.push {idArray, callback}

    keys[id] = 1 for id in idArray

  ret.forSingleId = forSingleId

  return ret

module.exports = {getterByIds}