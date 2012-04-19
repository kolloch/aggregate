winston = require('winston')

DEBUG = true

module.exports = (category, opts = {debug: DEBUG}) ->
  if opts?.debug && !winston.loggers[category]?
    winston.loggers.add category,
      console:
        level: 'silly'
        colorize: 'true'
  else
    winston.loggers.add category,
      console:
        level: 'warn'
        colorize: 'true'

  logger = winston.loggers.get(category)

  logger.tracer = (name, func) ->
    unless DEBUG
      return func

    return (args...) =>
      logger.silly "> #{name} " + args
      finished = false
      ret = null
      try 
        ret = func.apply(this, arguments)
        finished = true
      catch error
        logger.silly "EXCEPTION " + error
        throw error
      finally
        if finished
          logger.silly "< #{name}"
          ret
        else
          logger.silly "< #{name} throws error!"

  logger