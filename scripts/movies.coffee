#
# Description:
#   Get the movie poster and synposis for a given query
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot movie <query> - Search for a movie and show a bunch of stuff about it
#   hubot imdb <query> - Just show imdb info about a movie
#   hubot rotten <query> - Just show Rotten Tomatoes info about a movie
#
# Author:
#   orderedlist
cheerio = require 'cheerio'

LD = (s, t, caseless) ->
  n = s.length
  m = t.length
  return m if n is 0
  return n if m is 0

  d       = []
  d[i]    = [] for i in [0..n]
  d[i][0] = i  for i in [0..n]
  d[0][j] = j  for j in [0..m]

  for c1, i in s
    for c2, j in t
      cost = if c1 is c2 then 0 else 1
      d[i+1][j+1] = Math.min d[i][j+1]+1, d[i+1][j]+1, d[i][j] + cost

  d[n][m]

module.exports = (robot) ->
  robot.respond /(imdb|movie|rotten) (.*?)(?: \((\d{4})\)\s*)?$/i, (msg) ->
    query = msg.match[2]
    queryType = msg.match[1]

    idSearch = query.match(/^tt\d+/)

    client = robot.http("http://imdbapi.org/")
    if idSearch
        client.query({ 
            id: query,
            type: 'json',
            episode: 0
        })
    else
        year = msg.match[3]
        if year
            yg = 1
        else 
            yg = 0
        client.query({
            limit: 10
            type: 'json'
            q: query,
            episode: 0,
            yg: yg,
            year: year
        });
    client.get() (err, res, body) ->
        console.log client.fullPath() 
        if idSearch 
            movie = JSON.parse(body)

        else 
            list = JSON.parse(body)
            lowestLevIndexes = []
            lowestLev = -1
        
            if list.length
                for listmovie,i in list 
                    lev = LD(query.toLowerCase(), listmovie.title.toLowerCase())
                    console.log "#{listmovie.title} (#{listmovie.year}) - #{lev} vs #{lowestLev}"
                    if lowestLev < 0 || lev < lowestLev
                        console.log "New lowest lev determined: #{lev} #{listmovie.title}"
                        lowestLev = lev
                        lowestLevIndex = i
                        lowestLevIndexes = [i]
                    else if lev == lowestLev
                        lowestLevIndexes.push(i)         
        
            if lowestLevIndexes.length > 1
                multipleTitles = []
                for index in lowestLevIndexes
                    multipleTitles.push("#{list[index].title} (#{list[index].year}) - #{list[index].imdb_id}")
            
            else if lowestLev > -1
                movie = list[lowestLevIndexes[0]]

        if multipleTitles && multipleTitles.length
            msg.send "Multiple matches found: " + multipleTitles.join(', ');
        else if movie && movie.imdb_id
            
            msg.send "#{movie.poster}#.png" if movie.poster and queryType != 'rotten'
            msgParts = ["#{movie.title} (#{movie.year})"]
            msgParts.push("Avg User Rating: #{movie.rating}") if movie.rating
            if movie.release_date
                releaseStr = movie.release_date.toString()
                release = new Date(parseInt(releaseStr.substr(0,4)), parseInt(releaseStr.substr(4,2)), parseInt(releaseStr.substr(6,2)));
                msgParts.push("Release: " + release.toDateString())
            msgParts.push("Cast: " + movie.actors.slice(0,3).join(", ") + (if movie.actors.length > 3 then '…' else '')) if movie.actors && movie.actors.length
            msgParts.push("#{movie.imdb_url}")
            msg.send "IMDb: " + msgParts.join("; ") if queryType != 'rotten'
            if queryType == 'imdb'
                return
            robot.http("http://api.rottentomatoes.com/api/public/v1.0/movie_alias.json")
                .query({
                    apikey: 'hasavevpy4wqynkzpxwrzk9n',
                    id: movie.imdb_id.replace(/^tt/, ''),
                    type: 'imdb'
                })
                .get() (err, res, body) ->
                    rottenMovie = JSON.parse(body)
                    console.log body.trim()
                    if rottenMovie && rottenMovie.id
                        msgParts = []

                        sendRotten = () ->
                            msg.send "RottenTomatoes: " + msgParts.join("; ") if msgParts.length
                            msg.send "#{rottenMovie.posters.original}" if (!movie.poster && rottenMovie.posters && rottenMovie.posters.original) or queryType == 'rotten'
                            
                        msgParts.push("#{rottenMovie.ratings.critics_score}% - #{rottenMovie.ratings.critics_rating}") if rottenMovie.ratings && rottenMovie.ratings.critics_score > -1
                        msgParts.push("Consensus: #{rottenMovie.critics_consensus}") if rottenMovie.critics_consensus
                        msgParts.push("#{rottenMovie.links.alternate}") if rottenMovie.links && rottenMovie.links.alternate

                        if rottenMovie.links?.alternate 
                            console.log 'Querying ' + rottenMovie.links.alternate
                            robot.http(rottenMovie.links.alternate).get() (err, res, body) ->
                                $ = cheerio.load(body)
                                criticStats = $('#all-critics-numbers .critic_stats');
                                if not criticStats or not criticStats.length
                                    return 
                                avgRating = criticStats.find('span:contains(/)').text() if criticStats.filter(':contains(Average Rating)').length
                                reviewCount = criticStats.find('span[itemprop=reviewCount]').text()
                                msgParts.splice(1,0,"Reviews Counted: #{reviewCount}") if reviewCount
                                msgParts.splice(1,0,"Average Rating: #{avgRating}") if avgRating
                                sendRotten()    
                        else
                            sendRotten()
                        
                    
        else
          msg.send "That's not a movie, yo."
