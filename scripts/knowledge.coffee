# Description:
#   Allows Hubot to learn
#
# Commands:
#   !!<term>!! <defitition> - Store a new definition
#   ?? <term> - Retreive a definition
#
Util = require 'util'
dateformat = require 'dateformat'

module.exports = (robot) ->

  knowledge = new Knowledge robot

  canModify = (def, user) ->
    robot.Auth.hasRole(user.name,'bot master') or def.userId == user.id

  robot.hear /^!!\s*(.*?)\s*!!\s*(.*)/i, (msg) ->
    term = msg.match[1].trim() ? false
    def = msg.match[2].trim() ? false

    if not def
      msg.send "You need to specify a defintion for '#{term}'"
      return
    
    previous = knowledge.get(term)
    exists = typeof previous != "undefined"
    if exists and not canModify previous, msg.message.user
      msg.send "'#{term}' already has a definiton. See: ?? #{term}"
      return

    knowledge.set(term, def, msg.message.user)
    msg.send "Definition " + (if exists then "overwritten" else "saved") + " for '#{term}'" + (if exists then ". Was previously: " + previous.definition else '')

  robot.hear /^--\s*(.+)/i, (msg) ->
    term = msg.match[1]
    def = knowledge.get(term)
    
    if typeof def == "undefined"
      msg.send "'#{term}' has no definition yet."
      return

    if not canModify def, msg.message.user
      msg.reply "Only the original author or an admin can remove a term."
      return

    knowledge.remove(term)
    msg.send "Definition removed for '#{term}'"

  robot.hear /^\?#$/i, (msg) ->
    msg.send "I know #{knowledge.length()} terms"
    return
    
  robot.hear /^\?\?(\?)?\s*(.+)/i, (msg) ->
    term = msg.match[2]
    info = msg.match[1] == '?'
    
    def = knowledge.get(term)
    if typeof def == "undefined"
      msg.send "'#{term}' has no definition yet."
      return

    if info
        user = robot.brain.userForId def.userId
        robot.logger.info Util.inspect(def)
        msg.send "Term '#{def.term}' was added by #{user.name} on " + dateformat def.created, 'ddd mmm d yyyy "at" h:MM:ss TT Z'
        return
    msg.send "[#{def.term}] #{def.definition.trim()}"

class Knowledge
  constructor: (@robot) ->
    @brain = @robot.brain
    @storage = {}
    @brain.on 'loaded', =>
      @brain.data.knowledge ?= {}
      @storage = @brain.data.knowledge
      @robot.logger.info "Knowledge loaded. #{this.length()} terms defined."

  @normalizeTerm: (term) ->
    term.trim().toLowerCase()

  set: (term, def, user) ->
    term = term.trim()
    key = Knowledge.normalizeTerm term
    def = def.trim()
    @storage[key] = { term: term, definition: def, created: new Date(), userId: user.id }
    @brain.save()
    @robot.logger.info "Defintion stored for '#{term}': #{def}"
    
  remove: (term) ->
    term = Knowledge.normalizeTerm term
    delete @storage[term]
    @brain.save()
    @robot.logger.info "Removed definition for '#{term}'"

  get: (term) ->
    term = Knowledge.normalizeTerm term
    @storage[term.toLowerCase()]
    
  length: ->
    Object.getOwnPropertyNames(@storage).length
