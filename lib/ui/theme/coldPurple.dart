import 'package:animetn/ui/theme/types.dart';
import 'package:flutter/material.dart';

/// Cold Purple Theme
class ColdPurple implements ThemeItem {
  @override
  int get id => 03;

  @override
  bool get dev => false;

  @override
  AnimetnTheme get lightVariant => AnimetnTheme(
        accentColor: Color(0xff9D8ABF),
        backgroundColor: Colors.white,
        backgroundSubColor: Color.fromARGB(255, 179, 179, 179),
        textMainColor: Colors.black,
        textSubColor: Color.fromARGB(255, 82, 82, 82),
        modalSheetBackgroundColor: Colors.white,
        onAccent: Colors.white,
      );

  @override
  String get name => "Cold Purple";

  @override
  AnimetnTheme get theme => AnimetnTheme(
        accentColor: Color(0xff9D8ABF),
        backgroundColor: Color.fromARGB(255, 24, 24, 24),
        backgroundSubColor: const Color.fromARGB(255, 36, 36, 36),
        textMainColor: Colors.white,
        textSubColor: Color.fromARGB(255, 180, 180, 180),
        modalSheetBackgroundColor: Color(0xff121212),
        onAccent: Colors.black,
      );
}
