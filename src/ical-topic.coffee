# Description:
# Read an ical feed and prepend the current event to the channel topic
#
# Dependencies:
# - coffee-script
# - moment
# - cron
# - ical
# - fuzzy
# - underscore
#
# Configuration:
# HUBOT_ICAL_CHANNEL_MAP `\{\"ops\":\"HTTP_ICAL_LINK\",\"data\":\"HTTP_ICAL_LINK\"\}`
# HUBOT_ICAL_LABEL_CHANNEL_MAP `\{\"ops\":\"On\ duty\"\,\"engineering\":\"Oncall\"\}`
# HUBOT_ICAL_DUPLICATE_RESOLVER - When finding multiple events for `now` use the presence of this string to help choose winner
#    Note: Default value is `OVERRIDE: ` to handle calendars like VictorOps
# HUBOT_ICAL_CRON_JOB - How often to check for updates in cron time, default `0 */15 * * * 1-5` which is every 15 mins Monday-Friday
#
# Commands:
#  None
#
# Author:
#   ndaversa

_ = require 'underscore'
ical = require 'ical'
moment = require 'moment'
fuzzy = require 'fuzzy'
cronJob = require("cron").CronJob

module.exports = (robot) ->
  calendars = JSON.parse process.env.HUBOT_ICAL_CHANNEL_MAP
  labels = JSON.parse process.env.HUBOT_ICAL_LABEL_CHANNEL_MAP
  cronTime = process.env.HUBOT_ICAL_CRON_UPDATE_INTERVAL || "0 */15 * * * 1-5"
  duplicateResolution = process.env.HUBOT_ICAL_DUPLICATE_RESOLVER || "OVERRIDE: "
  topicRegex = "/(__LABEL__:(?:[^|]*)\\s*\\|\\s*)?(.*)/i"

  lookupUser = (name) ->
    [ __, cleanName ] = name.match /([^|:\(]*)/i
    users = robot.brain.users()
    users = _(users).keys().map (id) ->
      user = users[id]
      id: id
      username: user.name
      name: user.real_name || user.name

    results = fuzzy.filter cleanName.trim(), users, extract: (user) -> user.name
    if results?.length is 1
      return "@#{results[0].original.username}"
    else
      return name

  currentEvent = (room, cb) ->
    now = moment()
    calendar = calendars[room]
    ical.fromURL calendar, {}, (err, data) ->
      events = _(data).keys().map (id) ->
        event = data[id]
        start: moment event.start
        end: moment event.end
        summary: event.summary
        id: id
      .filter (event) -> now.isBetween event.start, event.end

      if events.length is 1
        event = events[0]
      else
        events = events.filter (event) -> event.summary.indexOf(duplicateResolution) > -1
        if events.length is 1
          event = events[0]

      event.summary = event.summary.replace duplicateResolution, '' if event?
      cb event

  updateTopicForRoom = (room) ->
    label = labels[room]
    channel = robot.adapter.client.getChannelGroupOrDMByName room
    currentTopic = channel.topic.value

    currentEvent room, (event) ->
      format = "__LABEL__: __SUMMARY__ | __TOPIC__"
      regex = eval topicRegex.replace "__LABEL__", label
      [ __, summary, leftover ] = currentTopic.match regex

      if event
        summary = lookupUser event.summary
      else
        format = "__TOPIC__"

      topic =
        format
        .replace("__LABEL__", label)
        .replace("__SUMMARY__", summary)
        .replace("__TOPIC__", leftover)

      if topic isnt currentTopic
        channel.setTopic topic

  updateTopics = () ->
    for room of calendars
      updateTopicForRoom room

  new cronJob(cronTime, updateTopics, null, true)
