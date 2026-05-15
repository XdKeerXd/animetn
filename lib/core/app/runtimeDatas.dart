import 'package:animetn/core/data/types.dart';
import 'package:animetn/core/database/anilist/types.dart';
import 'package:animetn/ui/theme/types.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

//saved anilist data
UserModal? storedUserData;

//saved settings
SettingsModal? currentUserSettings;

//user prefs
UserPreferencesModal? userPreferences;

//saved theme
late AnimetnTheme appTheme;

late String animeOnsenToken;
