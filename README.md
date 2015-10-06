# Hubot iCal Topic Bot
Read an ical feed and prepend the current event to the channel topic

###Dependencies
  * coffee-script
  * moment
  * cron
  * ical
  * fuzzy
  * underscore

###Configuration
 - `HUBOT_ICAL_CHANNEL_MAP` `\{\"ops\":\"HTTP_ICAL_LINK\",\"data\":\"HTTP_ICAL_LINK\"\}`
 - `HUBOT_ICAL_LABEL_CHANNEL_MAP` `\{\"ops\":\"On\ duty\"\,\"engineering\":\"Oncall\"\}`
 - `HUBOT_ICAL_DUPLICATE_RESOLVER` - When finding multiple events for `now` use the presence of this string to help choose winner
   Note: Default value is `OVERRIDE: ` to handle calendars like VictorOps
 - `HUBOT_ICAL_CRON_JOB` - How often to check for updates in cron time, default `0 */15 * * * 1-5` which is every 15 mins Monday-Friday

###Commands
None
