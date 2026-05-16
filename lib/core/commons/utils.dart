import 'dart:io';

import 'package:animetn/core/commons/enums.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String> fetch(String uri) async {
  final res = await get(Uri.parse(uri));
  return res.body;
}

Future<String?> getMediaMimeType(String uri, Map<String, String>? headers) async {
  final heads = await head(Uri.parse(uri), headers: headers);
  final type = heads.headers['content-type'];
  return type;
}

String getCurrentSeason() {
  final month = DateTime.now().month;
  switch (month) {
    case 1:
    case 2:
    case 3:
      return 'WINTER';
    case 4:
    case 5:
    case 6:
      return 'SPRING';
    case 7:
    case 8:
    case 9:
      return 'SUMMER';
    case 10:
    case 11:
    case 12:
      return 'FALL';
    default:
      return 'Unknown';
  }
}

Map<String, String>? MonthnumberToMonthName(
  int? monthNumber,
) {
  if (monthNumber == null) return {'short': '', 'full': ''};
  if (monthNumber > 12 || monthNumber < 1) return null;
  const monthName = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return {
    'full': monthName[monthNumber - 1],
    'short': monthName[monthNumber - 1].substring(0, 3),
  };
}

MediaStatus? assignItemEnum(String? valueInString) {
  if (valueInString == null) return null;
  switch (valueInString) {
    case "CURRENT":
      return MediaStatus.CURRENT;
    case "PLANNING":
      return MediaStatus.PLANNING;
    case "DROPPED":
      return MediaStatus.DROPPED;
    case "COMPLETED":
      return MediaStatus.COMPLETED;
    default:
      throw new Exception("ERR_BAD_STRING");
  }
}

import 'package:flutter/foundation.dart';

Future<bool> isTv() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
  AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
  return androidInfo.systemFeatures.contains('android.software.leanback');
}

Future<Directory> getDocumentsDirectory() async {
  if (kIsWeb) throw UnsupportedError("Cannot access file system on Web");
  final Directory dir = await getApplicationDocumentsDirectory();
  if (defaultTargetPlatform == TargetPlatform.android) {
    bool status = await Permission.manageExternalStorage.isGranted;
    if (!status) {
      final req = await Permission.manageExternalStorage.request();
      if (req.isDenied || req.isPermanentlyDenied) {
        return dir;
      }
    }
    return Directory('/storage/emulated/0/Documents/Animetn');
  }
  return Directory(dir.path + '/Animetn');
}
