import 'package:http/http.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:rrule/rrule.dart';

//import 'email.dart';
import 'event.dart';
import '../globals.dart';
import 'log.dart';

/*
void main() async {
  //TODO comment me
  iCalUri = Uri.parse(
      "https://calendar.google.com/calendar/ical/a2i0nar8fvsu0a0n5preu9ifqk%40group.calendar.google.com/private-c686b4722edfbe1f093bfdc110b7e3a4/basic.ics");
  await updateICal();
  print("done");
}
*/
Event? getNext() {
  try {
    return events
        .lastWhere((event) => event.startWithOffset().isAfter(DateTime.now()));
  } catch (e) {
    return null;
  }
}

List<Event> getCurrents() {
  return events
      .where((event) =>
          event.startWithOffset().isBefore(DateTime.now()) &&
          event.endWithOffset().isAfter(DateTime.now()))
      .toList();
}

Future updateICal() async {
  //log.print("\n\n\n\n${DateTime.now().getFormattedString()} | Updating Calendar");
  logger.log("\n${DateTime.now().toFormattedString()} | Updating Calendar");

  int nextEventsHash = events.reversed
      .where((element) => element.start.isAfter(DateTime.now()))
      .join()
      .hashCode;

  try {
    var req = await get(iCalUri).timeout(Duration(seconds: 30));
    String iCalString = req.body;

    List<Event> _events = [];

    ICalendar iCalendar = ICalendar.fromString(iCalString);

    for (Map vEvent
        in iCalendar.data.where((data) => data["type"] == "VEVENT")) {
      List<Event> _eventsFromEntry = [];

      RecurrenceRule? rrule = (vEvent['rrule'] != null)
          ? RecurrenceRule.fromString('RRULE:${vEvent['rrule']}')
          : null;

      String uid = vEvent["uid"];
      DateTime start =
          DateTime.parse((vEvent["dtstart"] as IcsDateTime).dt).toLocal();
      DateTime end =
          DateTime.parse((vEvent["dtend"] as IcsDateTime).dt).toLocal();
      String summary = vEvent["summary"];
      String description = vEvent["description"] ?? "";

      if (eventSelectedForRecordMatcher.hasMatch(summary + description)) {
        if (rrule == null) {
          _eventsFromEntry.add(Event(uid, start, end, summary, description));
        } else {
          Duration duration = end.difference(start);

          //? Make events based on RRULE
          for (DateTime generatedStart in rrule
              .getAllInstances(
                start: start.toUtc(),
                before: DateTime.now().add(Duration(days: 90)).toUtc(),
              )
              .map((e) => e.toLocal())
              .toList()) {
            DateTime generatedEnd = generatedStart.add(duration);
            _eventsFromEntry.add(
                Event(uid, generatedStart, generatedEnd, summary, description));
          }
        }
      }

      _events.addAll(_eventsFromEntry);
    }

    //Sort alphabetically then by start time
    _events.sort((a, b) => a.title.compareTo(b.title));
    _events.sort((a, b) => a.start.compareTo(b.start));

    //Only keep one event of events starting at the same time, keep first one alphabetically
    _events.removeWhere((element) =>
        (_events.where((e) => e.start.isAtSameMomentAs(element.start)).length >
            1) &&
        (_events
                .where((e) => e.start.isAtSameMomentAs(element.start))
                .toList()
                .indexOf(element) !=
            0));

    events = _events;

    logger.log("Got ${events.length} events marked for recording.");
  } catch (e, stack) {
    logger.log(
        "Exception occured while updating calendar: $e\nContinuing with already downloaded events.\n$stack");
  }

  int updatedNextEventsHash = events.reversed
      .where((element) => element.start.isAfter(DateTime.now()))
      .join()
      .hashCode;

  if (nextEventsHash != updatedNextEventsHash) {
    sendCalendarEmail();
  }
}
