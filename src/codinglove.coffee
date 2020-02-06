# Description:
#   Display meme from "The coding love <http://thecodinglove.com>"
#   or "les joies du code <http://lesjoiesducode.tumblr.com>".
#
# Dependencies:
#   "cheerio": "0.7.0"
#   "he": "0.4.1"
#
# Configuration:
#   None
#
# Commands:
#   hubot [give me some] joy [asshole] - Return a random meme (coding love)
#   hubot last joy - Returns last meme (coding love)
#   hubot [spread some] love - Return a random meme (coding love)
#   hubot last love - Returns last meme (coding love)
#   hubot [donne moi de la] joie [bordel] - Returns a random meme (text and image)
#   hubot {dernière|derniere} joie - Returns last meme (text and image).
#
# Author:
#   Eunomie
#   Based 9gag.coffee by EnriqueVidal

cheerio = require('cheerio')
he = require('he')

module.exports = (robot)->
  robot.respond /(donne moi de la )?joie( bordel)?/i, (message)->
    send_random_meme message, 'http://lesjoiesducode.fr/random', (text)->
      message.send text
  robot.respond /derni[èe]re joie/i, (message)->
    send_meme message, 'http://lesjoiesducode.fr', (text)->
      message.send text
  robot.respond /((give me|spread) some )?(joy|love)( asshole)?/i, (message)->
    send_random_meme message, 'http://thecodinglove.com', (text)->
      message.send text
  robot.respond /last (joy|love)/i, (message)->
    send_meme message, 'http://thecodinglove.com', (text)->
      message.send text

# set the initial link values for the random gif logic
random_path = ""

send_random_meme = (message, location, response_handler)->
  # determine the url to use
  url = location
  if location.indexOf('thecodinglove.com') > -1
    url = if random_path then random_path else location

  message.http(url).get() (error, response, body)->
    return response_handler "Sorry, something went wrong" if error

    if response.statusCode == 302 || response.statusCode == 301
      location = response.headers['location']
      return send_random_meme(message, location, response_handler)
    
    if location.indexOf('thecodinglove.com') > -1
      random_path = get_random_link(body, "#randomPostBtn")
      pageUrl = random_path
    else 
      pageUrl = location

    send_meme(message, pageUrl, response_handler)

send_meme = (message, location, response_handler)->
  url = location

  message.http(url).get() (error, response, body)->
    return response_handler "Sorry, something went wrong" if error

    if response.statusCode == 302 || response.statusCode == 301
      location = response.headers['location']
      return send_meme(message, location, response_handler)

    img_src = get_meme_image(body, ".blog-post-content img", "src")
    
    if(!img_src)
      img_src = get_meme_image(body, ".blog-post-content video object", "data")

    if(img_src)
      txt = get_meme_txt(body, ".blog-post-title")
      response_handler "#{txt}"
      response_handler "#{img_src}"
      #response_handler "-----#{url}"
    else
      response_handler "Sorry, something went wrong at " + url + "."

get_meme_image = (body, selector, tag)->
  $ = cheerio.load(body)
  $(selector).first().attr(tag) 

get_meme_txt = (body, selector)->
  $ = cheerio.load(body)
  he.decode $(selector).first().text()

get_random_link = (body, selector)->
  $ = cheerio.load(body)
  $(selector).parent().attr('href')

