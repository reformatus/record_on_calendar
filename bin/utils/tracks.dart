import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import '../globals.dart';
import 'log.dart';

class AudioDevice {
  String id;
  String name;
  String? _fileName;
  String get fileName => (_fileName ?? name).getSanitizedForFilename();
  bool enabled = false;

  String toString() => "${(_fileName == null) ? "" : "$_fileName: "}$name";

  String toYamlSnippet() => """
$name:
  fileName: ${_fileName ?? '~'}
  record: $enabled
  id: '$id'
""";

  factory AudioDevice.fromJson(String name, Map json) {
    try {
      return AudioDevice(json['id'], name, json['fileName'], json['record']);
    } catch (e, s) {
      throw "Couldn't read properties of audio device $name!\nError: $e\nPlease check the tracks.yaml file\n$s";
    }
  }

  AudioDevice(this.id, this.name, [this._fileName, this.enabled = false]);

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is AudioDevice && other.id == id;
  }
}

List<AudioDevice> devicesToRecord = [];

String generateTracksYaml(Iterable<AudioDevice> devices) {
  return ("""
# DEVICES - TRACKS

# These are the audio devices the program detected in your computer.
# Please select which ones you want to record.
# If you remove an enabled device from the system, it does not get removed from here.
# New devices get added at the top.

# EXAMPLE:

# Example Microphone 1:   # Human readable name of the input (this shows up in your OS; don't change)
#   filename: John Guitar # You can specify a filename for this track. Leave on '~' to use the name of the device as track name.
#   record: true          # Set to true to record
#   id: 'xxxxxxxxxxxx'    # Used internally, don't change

""" +
      devices.map((e) => e.toYamlSnippet()).join('\n'));
}

void updateDevices() {
  logger.print("  Updating multitrack config and devices...");

  tracksFile.createSync();
  String tracksFileContent = tracksFile.readAsStringSync();

  Map data;
  List<AudioDevice> devicesInFile = [];
  if (tracksFileContent.length >= 1) {
    try {
      data = loadYaml(tracksFileContent);
    } catch (e, s) {
      throw "Couldn't load tracks.yaml! Delete file and re-run the program to generate a new one.\nError: $e\n$s";
    }

    try {
      data.forEach((key, value) {
        devicesInFile.add(AudioDevice.fromJson(key, value));
      });
    } catch (e, s) {
      throw "Error while parsing audio devices in tracks.json: $e\n$s";
    }
  }

  Iterable<AudioDevice> devicesPresent = getPresentDevices();
  Iterable<AudioDevice> devicesEnabled =
      devicesInFile.where((element) => element.enabled);
  List<AudioDevice> allDevices = devicesPresent
      .where((element) => !devicesInFile.contains(element))
      .followedBy(devicesInFile)
      .toList();
  ;

  devicesToRecord.clear();
  devicesToRecord.addAll(allDevices.where((element) =>
      devicesEnabled.contains(element) &&
      devicesInFile.contains(element) &&
      devicesPresent.contains(element)));

  List<AudioDevice> devicesEnabledNotPresent = allDevices
      .where(
        (element) =>
            devicesEnabled.contains(element) &&
            !devicesPresent.contains(element),
      )
      .toList();

  List<AudioDevice> devicesToConfigure = allDevices
      .where(
        (element) =>
            devicesPresent.contains(element) &&
            !devicesInFile.contains(element),
      )
      .toList();

  logger.print("""
    Devices that will be recorded: $devicesToRecord
    Devices marked for recording but not present: $devicesEnabledNotPresent
    New devices you should configure: $devicesToConfigure""");

  tracksFile.writeAsStringSync(generateTracksYaml(allDevices.where((element) =>
      !(!devicesEnabled.contains(element) &&
          devicesInFile.contains(element) &&
          !devicesPresent.contains(element)))));

  if (devicesToRecord.isEmpty) {
    logger
        .print('\nERROR! You have no devices enabled. Please edit tracks.yaml and run again.');
  }
}

List<AudioDevice> getPresentDevices() {
  String ffpmegOutput = Process.runSync(ffmpegExe.path,
          ['-list_devices', 'true', '-f', 'dshow', '-i', 'dummy'],
          stderrEncoding: Encoding.getByName('utf-8'))
      .stderr;

  List<String> allLines = ffpmegOutput
      .split('\n')
      .where(
        (element) => (element.startsWith('[dshow @')),
      )
      .map((e) => e.replaceAll(RegExp(r"\[dshow @.*\] "), ""))
      .toList();

  List<int> deviceLines = allLines
      .where((e) => RegExp(r"\(audio").hasMatch(e))
      .map((e) => allLines.indexOf(e))
      .toList();

  List<AudioDevice> _inputs = [];

  for (var i in deviceLines) {
    //There must be a simpler way of doing this xd
    try {
      _inputs.add(AudioDevice(
          RegExp(r'(?<=").*(?=")').firstMatch(allLines[i + 1])!.group(0)!,
          RegExp(r'(?<=").*(?=")').firstMatch(allLines[i])!.group(0)!));
    } catch (e, s) {
      logger
          .print("Error occured while getting an audio device from OS: $e\n$s");
    }
  }
  return _inputs;
}
