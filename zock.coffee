FakeXMLHttpRequest =
  require './components/fake-xml-http-request/fake_xml_http_request'

Router = require 'routes'
URL = require 'url'

class Zock
  routers =
    get: Router()

  base: (@baseUrl) ->
    return this

  get: (@route) ->
    @currentRouter = routers.get
    return this

  reply: (status, body) ->
    url = @baseUrl + @route

    @currentRouter.addRoute url, ->
      return {
        statusCode: status
        body: JSON.stringify(body)
      }

    return this

  logger: (logger) ->
    @logger = logger
    return this

  XMLHttpRequest: =>
    log = @logger or -> null
    request = new FakeXMLHttpRequest()
    response = null

    oldOpen = request.open
    oldSend = request.send

    url = null
    method = null

    send = ->
      if not response
        throw new Error("No route for #{method} #{url}")

      res = response.fn()
      status = res.statusCode || 200
      headers = res.headers || {'Content-Type': 'application/json'}
      body = res.body

      respond = -> request.respond(status, headers, body)

      setTimeout respond, 0

    open = (_method, _url) ->
      url = _url
      method = _method

      parsed = URL.parse url
      delete parsed.query
      delete parsed.hash
      delete parsed.search
      delete parsed.path

      log "#{method} #{URL.format(parsed)}"

      response = routers[method.toLowerCase()].match URL.format(parsed)

    request.open = ->
      open.apply null, arguments
      oldOpen.apply request, arguments

    request.send = ->
      send()
      oldSend.apply request, arguments

    return request

module.exports = Zock
