# Commands:
#   hubot get me <number> travis builds - Gets you <number> of travis builds
#   hubot shinde imashita - Sadly, hubot (fure-kun) is dead.
#   hubot get me <travis/appveyor> <number> Gets builds.
# URLS:
#   POST /hubot/appveyor?room=<room>[&type=<type]
#     - for XMPP servers (such as HipChat) this is the XMPP room id which has the form id@server
module.exports = (robot) ->
  robot.respond /shinde imashita/i, (msg) ->
    msg.send "shinde inai yo!"

  robot.respond /get me travis (.*)/i, (msg) ->
     number = if not isNaN escape msg.match[1] then (parseInt escape msg.match[1] , 10) - 1 else 0
     msg.http("https://api.travis-ci.org/repos/SnowflakePowered/snowflake/builds")
          .header('Accept', 'application/json; version=2')
          .get() (err, res, body) ->
            response = JSON.parse body
            for build in [0..number]
               do ->
                resultMessage = "Build #{response.builds[build].number} '#{response.commits[build].message} (#{response.commits[build].sha})' in '#{response.commits[build].branch}'" 
                resultMessage = if response.builds[build].pull_request then resultMessage + " in PR #{response.builds[build].pull_request_number} (#{response.builds[build].pull_request_title})" else resultMessage  
                msg.send resultMessage
                
  robot.respond /get me appveyor (.*)/i, (msg) ->
     number = if not isNaN escape msg.match[1] then (parseInt escape msg.match[1] , 10) else 1
     msg.http("http://ci.appveyor.com/api/projects/RonnChyran/snowflake/history?recordsNumber=#{number}")
          .header('Accept', 'application/json')
          .header('Content-Type', 'application/json')
          .get() (err, res, body) ->
            response = JSON.parse body
            for build in response.builds[0..number]
              do ->
                resultMessage = "Build #{build.buildNumber} '#{build.message} (#{build.commitId})' in '#{build.branch}'" 
                resultMessage = if build.pullRequestId != undefined then resultMessage + " in PR #{build.pullRequestId} (#{build.pullRequestName})" else resultMessage
                msg.send resultMessage
                        
  robot.respond /rebuild me travis (.*)/i, (msg) ->
    if not isNaN escape msg.match[1]
      number = parseInt escape msg.match[1] , 10    
      msg.http("https://api.travis-ci.org/repos/SnowflakePowered/snowflake/builds?number=#{number}")
          .get() (err, res, body) ->
            response = JSON.parse body
            id = response[0].id
            data = JSON.stringify { "build_id" : id }
            msg.http("https://api.travis-ci.org/requests")
              .header('Authorization', "token #{process.env.HUBOT_TRAVIS_TOKEN}")
              .header('Content-Type', 'application/json')
              .header('Accept', 'application/vnd.travis-ci.2+json')
              .post(data) (err, res, body) ->
                response = JSON.parse body
                status = if response.flash[0].notice == undefined then response.flash[0].error else response.flash[0].notice 
                msg.send(status)
                
   robot.respond /rebuild me travis latest/i, (msg) -> 
      msg.http("https://api.travis-ci.org/repos/SnowflakePowered/snowflake/builds")
          .get() (err, res, body) ->
            response = JSON.parse body
            id = response[0].id
            data = JSON.stringify { "build_id" : id }
            msg.http("https://api.travis-ci.org/requests")
              .header('Authorization', "token #{process.env.HUBOT_TRAVIS_TOKEN}")
              .header('Content-Type', 'application/json')
              .header('Accept', 'application/vnd.travis-ci.2+json')
              .post(data) (err, res, body) ->
                response = JSON.parse body
                status = if response.flash[0].notice == undefined then response.flash[0].error else response.flash[0].notice 
                msg.send(status)
   
  robot.respond /rebuild me appveyor pr (.*)/i, (msg) ->
      if not isNaN escape msg.match[1]
        number = parseInt escape msg.match[1] , 10    
        data = JSON.stringify { accountName: 'RonnChyran', projectSlug: 'snowflake', pullRequestId: number }
        msg.http("http://ci.appveyor.com/api/builds")
                 .header('Authorization', "Bearer #{process.env.HUBOT_APPVEYOR_TOKEN}")
                 .header('Content-Type', 'application/json')
                 .post(data) (err, res, body) ->
                    msg.send "Build queued"
                    
  robot.respond /rebuild me appveyor latest/i, (msg) ->
        msg.http("http://ci.appveyor.com/api/projects/RonnChyran/snowflake/branch/master")
          .header('Accept', 'application/json')
          .header('Content-Type', 'application/json')
          .get() (err, res, body) ->
            response = JSON.parse body
            build = response.build
            data = JSON.stringify { accountName: response.project.accountName, projectSlug: response.project.slug, branch: response.project.repositoryBranch, commitId: build.commitId }
            msg.http("http://ci.appveyor.com/api/builds")
                 .header('Authorization', "Bearer #{process.env.HUBOT_APPVEYOR_TOKEN}")
                 .header('Content-Type', 'application/json')
                 .post(data) (err, res, body) ->
                    msg.send "Build queued"
                    
  robot.respond /get me ci docs/i, (msg) ->
        msg.http("http://ci.appveyor.com/api/projects/RonnChyran/snowflake/branch/master")
          .header('Accept', 'application/json')
          .header('Content-Type', 'application/json')
          .get() (err, res, body) ->
            response = JSON.parse body
            build = response.build
            jobid = build.jobs[0].jobId
            msg.send "http://ci.appveyor.com/api/buildjobs/#{jobid}/artifacts/" + "Generated doxygen documentation.zip"
 
 robot.respond /get me ci bins/i, (msg) ->
        msg.http("http://ci.appveyor.com/api/projects/RonnChyran/snowflake/branch/master")
          .header('Accept', 'application/json')
          .header('Content-Type', 'application/json')
          .get() (err, res, body) ->
            response = JSON.parse body
            build = response.build
            jobid = build.jobs[0].jobId
            msg.send "http://ci.appveyor.com/api/buildjobs/#{jobid}/artifacts/" + "Snowflake/bin/Snowflake Base Libraries.zip"
  
 robot.router.post "/hubot/appveyor", (req, res) ->
    query = querystring.parse url.parse(req.url).query

    user = {}
    user.room = query.room if query.room
    user.type = query.type if query.type

    try
      payload = JSON.parse req.body.payload
      event = payload.eventData
      robot.send user, "#{event.Status} build (#{event.buildUrl}) on #{event.repositoryName}:#{event.branch} by #{event.comitterName} with commit (#{event.commitId})"

    catch error
      console.log "appveyor hook error: #{error}. Payload: #{req.body.payload}"
     
    res.end JSON.stringify {
      send: true #some client have problems with and empty response, sending that response ion sync makes debugging easier
    }      