# Record On Calendar

An overcomplicated, but pretty smart program to record audio automatically according to iCal calendar events.
Fully configurable.

_Using SoX and LAME (downloads runtimes automatically)._

Example config:

```
# █▀█ █▀▀ █▀▀ █▀█ █▄░█ █▀▀ ▄▀█ █░░
# █▀▄ ██▄ █▄▄ █▄█ █░▀█ █▄▄ █▀█ █▄▄

# Config file generated by Record on Calendar
version: 2.0.0 # Don't change this!

# Config file format is YAML. The RecOnCal will try to migrate it to new versions if updated.
# Made by Benedek Fodor in 2022

##########

# CALENDAR

# iCal link for calendar
link: = PLEASE PUT AN ICAL LINK HERE =
# Update frequency of calendar (minutes)
frequency: 30
# Start recording minutes earlier then calendar event start
earlier: 5
# Stop recording minutes later then calendar event end
later: 30
# Only record on events matching following regular expression (help: regexr.com)
# "." means record every event
regex: .

##########

# FILES

# Upload files to FTP - set field to "null" to disable
ftphost: null
username: null
password: null
# Keep this number of latest recordings, delete older automatically (0 means never delete)
keep: 0

##########

# EMAIL

# Send email notification after last recording on a day
# true - enable; false - disable
dailyEmail: false 
# Example for email recipients: [example@example.com, tim@apple.com]
dailyEmailRecipients: [""]
calendarEmail: false
calendarEmailRecipients: [""]

# Email client
smtpHost: null
smtpPort: null
smtpUser: null
smtpPassword: null

# Daily email content
dailyEmailSenderName: Record On Calendar
dailyEmailSubject: Today's recorded events
# Available replacements: [today list] [future list] [stat - success count] [stat - failed count] [time]
# Make sure to put 2 spaces before every line.
dailyEmailContent: |
  RecordOnCalendar has just finished recording the last event for today.

  Recorded events today:
  [today list]

  Next 10 events to record in the future:
  [future list]

  Successfully recorded [stat - success count] events so far. Failed [stat - failed count] times.

  Email sent at [time]


# Calendar email content
calendarEmailSenderName: Record On Calendar
calendarEmailSubject: Calendar updated
calendarEmailContent: |
  RecordOnCalendar has detected that future events have been changed in the calendar.

  Next 10 events to record are:
  [future list]

  Email sent at [time]
```
