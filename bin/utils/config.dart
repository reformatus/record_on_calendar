import 'dart:io';

import 'package:yaml/yaml.dart';

import '../globals.dart';
import 'log.dart';
import 'package:path/path.dart';

String generateConfigText({
  String link = "= PLEASE PUT AN ICAL LINK HERE =",
  int frequency = 30,
  int earlier = 5,
  int later = 30,
  String regex = ".",
  String? ftphost,
  String? username,
  String? password,
  int keep = 0,
  bool dailyEmail = false,
  String dailyEmailRecipients = '[""]',
  bool calendarEmail = false,
  String calendarEmailRecipients = '[""]',
  String? smtpHost,
  int? smtpPort,
  String? smtpUser,
  String? smtpPassword,
  String dailyEmailSenderName = "Record On Calendar",
  String dailyEmailSubject = "Today's recorded events",
  String? dailyEmailContent,
  String calendarEmailSenderName = "Record On Calendar",
  String calendarEmailSubject = "Calendar updated",
  String? calendarEmailContent,
}) =>
    """
# █▀█ █▀▀ █▀▀ █▀█ █▄░█ █▀▀ ▄▀█ █░░
# █▀▄ ██▄ █▄▄ █▄█ █░▀█ █▄▄ █▀█ █▄▄

# Config file generated by Record on Calendar
version: $version # Don't change this!

# Config file format is YAML. The RecOnCal will try to migrate it to new versions if updated.
# Made by Benedek Fodor in 2022

##########

# CALENDAR

# iCal link for calendar
link: $link
# Update frequency of calendar (minutes)
frequency: $frequency
# Start recording minutes earlier then calendar event start
earlier: $earlier
# Stop recording minutes later then calendar event end
later: $later
# Only record on events matching following regular expression (help: regexr.com)
# "." means record every event
regex: $regex

##########

# FILES

# Upload files to FTP - set field to "null" to disable
ftphost: $ftphost
username: $username
password: $password
# Keep this number of latest recordings, delete older automatically (0 means never delete)
keep: $keep

##########

# EMAIL

# Send email notification after last recording on a day
# true - enable; false - disable
dailyEmail: $dailyEmail 
# Example for email recipients: [example@example.com, tim@apple.com]
dailyEmailRecipients: $dailyEmailRecipients
calendarEmail: $calendarEmail
calendarEmailRecipients: $calendarEmailRecipients

# Email client
smtpHost: $smtpHost
smtpPort: $smtpPort
smtpUser: $smtpUser
smtpPassword: $smtpPassword

# Daily email content
dailyEmailSenderName: $dailyEmailSenderName
dailyEmailSubject: $dailyEmailSubject
# Available replacements: [today list] [future list] [stat - success count] [stat - failed count] [time]
# Make sure to put 2 spaces before every line.
dailyEmailContent: ${dailyEmailContent ?? """|
  RecordOnCalendar has just finished recording the last event for today.

  Recorded events today:
  [today list]

  Next 10 events to record in the future:
  [future list]

  Successfully recorded [stat - success count] events so far. Failed [stat - failed count] times.

  Email sent at [time]
"""}

# Calendar email content
calendarEmailSenderName: $calendarEmailSenderName
calendarEmailSubject: $calendarEmailSubject
calendarEmailContent: ${calendarEmailContent ?? """|
  RecordOnCalendar has detected that future events have been changed in the calendar.

  Next 10 events to record are:
  [future list]

  Email sent at [time]
"""}
""";

loadConfig() {
  log.print('Loading config file');
  Map config;
  try {
    config = loadYaml(configFile.readAsStringSync());
  } catch (e, stack) {
    log.print(
        "Could not parse config file! If this error persists, please delete file and let the program regenerate it by restarting.\n$e\n$stack");
    stdin.readLineSync();
    exit(1);
  }

  //! Migrate
  if (config['version'] != version) {
    configFile.copySync(withoutExtension(configFile.path) +
        ".${DateTime.now().toFormattedString()}.yaml.old");

    configFile.writeAsStringSync(
      generateConfigText(
        link: config['link'],
        frequency: config['frequency'],
        earlier: config['earlier'],
        later: config['later'],
        regex: config['regex'],
        ftphost: config['ftphost'],
        username: config['username'],
        password: config['password'],
        keep: config['keep'],
        dailyEmail: config['dailyEmail'],
        dailyEmailRecipients: config['dailyEmailRecipients'].toString(),
        calendarEmail: config['calendarEmail'],
        calendarEmailRecipients: config['calendarEmailRecipients'].toString(),
        smtpHost: config['smtpHost'],
        smtpPort: config['smtpPort'],
        smtpUser: config['smtpUser'],
        smtpPassword: config['smtpPassword'],
        dailyEmailSenderName: config['dailyEmailSenderName'],
        dailyEmailSubject: config['dailyEmailSubject'],
        dailyEmailContent: "|\n  " +
            (config['dailyEmailContent'] as String).replaceAll("\n", "\n  "),
        calendarEmailSenderName: config['calendarEmailSenderName'],
        calendarEmailSubject: config['calendarEmailSubject'],
        calendarEmailContent: "|\n  " +
            (config['calendarEmailContent'] as String).replaceAll("\n", "\n  "),
      ),
    );
  }

  //! Load
  try {
    iCalUri = Uri.parse(config['link']!);
    iCalUpdateFrequencyMinutes = config['frequency'];
    startEarlierByMinutes = config['earlier'];
    endLaterByMinutes = config['later'];
    matchEventName = RegExp(config['regex']!);
    ftpHost = config['ftphost'];
    ftpUsername = config['username'];
    ftpPassword = config['password'];
    keepRecordings = config['keep'];
    dailyEmail = config['dailyEmail'] ?? false;
    dailyEmailRecipients =
        config['dailyEmailRecipients'].whereType<String>().toList();
    calendarEmail = config['calendarEmail'] ?? false;
    calendarEmailRecipients =
        config['calendarEmailRecipients'].whereType<String>().toList();
    smtpHost = config['smtpHost'];
    smtpPort = config['smtpPort'] ?? 0;
    smtpUser = config['smtpUser'] ?? "";
    smtpPassword = config['smtpPassword'] ?? "";
    dailyEmailSenderName = config['dailyEmailSenderName'] ?? "";
    dailyEmailSubject = config['dailyEmailSubject'] ?? "";
    dailyEmailContent = config['dailyEmailContent'] ?? "";
    calendarEmailSenderName = config['calendarEmailSenderName'];
    calendarEmailSubject = config['calendarEmailSubject'];
    calendarEmailContent = config['calendarEmailContent'];
  } catch (e, stack) {
    log.print(
        "Could not get config values! If this error persists, please delete file and let the program regenerate it by restarting.\n$e\n$stack");
    stdin.readLineSync();
    exit(1);
  }
}
