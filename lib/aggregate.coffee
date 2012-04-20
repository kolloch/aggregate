logger = require('./logging')('aggregate', debug: false)

# "this" is the aggregated function
forSingleId = ->
  return (id, callback) =>
    this [id], (err, result) ->
      if err
        callback err
      else
        callback null, result[id]

aggregate = (opts, func) ->
  unless func?
    func = opts
    opts = {}

  keys  = {} 
  calls = []

  performCall = logger.tracer 'performCall', ->
    keysAsArray = (k for k of keys)
    processResults = createProcessResultsForCalls calls
  
    keys  = {} 
    calls = []

    func keysAsArray, processResults

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
 
module.exports = aggregate