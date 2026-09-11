import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'data/note_repository.dart';
import 'screens/folders_screen.dart';

const String _settingsBoxName = 'nitro_note_settings';
const String _themeKey = 'theme_mode';

/// Punto de entrada principal de la aplicación.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await NoteRepository.instance.initialize();

  // Abre el almacenamiento de configuraciones.
  final settingsBox = await Hive.openBox<String>(_settingsBoxName);

  // Recupera el tema guardado. En el primer inicio utiliza modo claro.
  final savedTheme = settingsBox.get(_themeKey, defaultValue: 'light');

  final initialThemeMode = savedTheme == 'dark'
      ? ThemeMode.dark
      : ThemeMode.light;

  runApp(NitroNoteApp(initialThemeMode: initialThemeMode));
}

/// Widget principal de NitroNote.
class NitroNoteApp extends StatefulWidget {
  final ThemeMode initialThemeMode;

  /// Constructor que permite definir el tema inicial.
  const NitroNoteApp({super.key, this.initialThemeMode = ThemeMode.light});

  @override
  State<NitroNoteApp> createState() => _NitroNoteAppState();
}

class _NitroNoteAppState extends State<NitroNoteApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();

    // Utiliza el tema recuperado antes de iniciar la aplicación.
    _themeMode = widget.initialThemeMode;
  }

  bool get _isDarkMode {
    return _themeMode == ThemeMode.dark;
  }

  /// Cambia el tema y guarda inmediatamente la preferencia.
  Future<void> _toggleTheme() async {
    final newThemeMode = _isDarkMode ? ThemeMode.light : ThemeMode.dark;

    setState(() {
      _themeMode = newThemeMode;
    });

    final settingsBox = Hive.box<String>(_settingsBoxName);

    await settingsBox.put(
      _themeKey,
      newThemeMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NitroNote',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: FoldersScreen(isDarkMode: _isDarkMode, onToggleTheme: _toggleTheme),
    );
  }
}
