import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/folder_model.dart';
import '../models/note_model.dart';

/// Administra temporalmente todas las carpetas y notas de NitroNote.
///
/// Se utiliza una única instancia para que todas las pantallas trabajen
/// con los mismos datos. Más adelante agregaremos almacenamiento local.
class NoteRepository extends ChangeNotifier {
  /// Constructor privado.
  ///
  /// Impide que diferentes pantallas creen repositorios separados.
  NoteRepository._();

  /// Instancia única compartida por toda la aplicación.
  static final NoteRepository instance = NoteRepository._();

  // Listas internas. El guion bajo indica que son privadas.
  final List<FolderModel> _folders = [];
  final List<NoteModel> _notes = [];

  // Nombre del almacenamiento local.
  static const String _boxName = 'nitro_note_storage';

  // Claves utilizadas para guardar los datos.
  static const String _foldersKey = 'folders';
  static const String _notesKey = 'notes';

  Box<String>? _storageBox;
  bool _initialized = false;

  /// Entrega una copia de las carpetas para proteger la lista original.
  List<FolderModel> get folders {
    return List.unmodifiable(_folders);
  }

  /// Entrega una copia de todas las notas.
  List<NoteModel> get notes {
    return List.unmodifiable(_notes);
  }

  /// Inicializa el almacenamiento y recupera los datos guardados.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _storageBox = await Hive.openBox<String>(_boxName);

    final foldersJson = _storageBox!.get(_foldersKey);
    final notesJson = _storageBox!.get(_notesKey);

    // Si todavía no existe información, corresponde al primer inicio.
    if (foldersJson == null && notesJson == null) {
      //_loadDemoData(); se quito el demo data para que no se cargue al iniciar la app por primera vez
      await _saveData();
      _initialized = true;
      return;
    }

    try {
      if (foldersJson != null) {
        final decodedFolders = jsonDecode(foldersJson) as List<dynamic>;

        _folders
          ..clear()
          ..addAll(
            decodedFolders.map((item) {
              return FolderModel.fromMap(
                Map<String, dynamic>.from(item as Map),
              );
            }),
          );
      }

      if (notesJson != null) {
        final decodedNotes = jsonDecode(notesJson) as List<dynamic>;

        _notes
          ..clear()
          ..addAll(
            decodedNotes.map((item) {
              return NoteModel.fromMap(Map<String, dynamic>.from(item as Map));
            }),
          );
      }
    } catch (error) {
      // Si los datos están dañados, la aplicación puede iniciar nuevamente.
      debugPrint('No se pudieron recuperar los datos: $error');

      _folders.clear();
      _notes.clear();
      //_loadDemoData(); se quito el demo data para que no se cargue al iniciar la app por primera vez

      await _saveData();
    }

    _initialized = true;
  }

  /// Guarda todas las carpetas y notas.
  Future<void> _saveData() async {
    final box = _storageBox;

    if (box == null) {
      return;
    }

    final foldersJson = jsonEncode(
      _folders.map((folder) => folder.toMap()).toList(),
    );

    final notesJson = jsonEncode(_notes.map((note) => note.toMap()).toList());

    await box.putAll({_foldersKey: foldersJson, _notesKey: notesJson});
  }

  /// Actualiza las pantallas y solicita el guardado automático.
  void _saveAndNotify() {
    notifyListeners();
    unawaited(_saveData());
  }

  /// Carga información de ejemplo para mostrar inicialmente la aplicación.
  /*void _loadDemoData() {
    final now = DateTime.now();

    _folders.addAll([
      FolderModel(
        id: 'folder_python',
        name: 'Python',
        iconCodePoint: Icons.code_rounded.codePoint,
        colorValue: const Color(0xFF42A5F5).toARGB32(),
      ),
      FolderModel(
        id: 'folder_database',
        name: 'Bases de datos',
        iconCodePoint: Icons.storage_rounded.codePoint,
        colorValue: const Color(0xFF9C6ADE).toARGB32(),
      ),
      FolderModel(
        id: 'folder_classes',
        name: 'Clases',
        iconCodePoint: Icons.school_rounded.codePoint,
        colorValue: const Color(0xFFFF8A3D).toARGB32(),
      ),
      FolderModel(
        id: 'folder_solutions',
        name: 'Soluciones',
        iconCodePoint: Icons.build_rounded.codePoint,
        colorValue: const Color(0xFF26BFA6).toARGB32(),
      ),
    ]);

    _notes.addAll([
      NoteModel(
        id: 'note_powershell',
        folderId: 'folder_python',
        title: 'Error al ejecutar scripts en PowerShell',
        content:
            'PowerShell puede bloquear scripts automáticamente debido '
            'a su política de ejecución. Para solucionarlo, se debe revisar '
            'la política actual y modificarla únicamente para el usuario '
            'actual.\n\n'
            'Set-ExecutionPolicy RemoteSigned -Scope CurrentUser',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
        isFavorite: true,
      ),
      NoteModel(
        id: 'note_venv',
        folderId: 'folder_python',
        title: 'Crear entornos virtuales',
        content:
            'Comandos necesarios para crear y activar un entorno con venv '
            'de forma local dentro de un proyecto de Python.',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      NoteModel(
        id: 'note_pip',
        folderId: 'folder_python',
        title: 'Instalar paquetes con pip',
        content:
            'Comandos frecuentes para instalar, actualizar y eliminar '
            'paquetes utilizando pip desde la terminal.',
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
    ]);
  }
*/
  /// Genera un identificador utilizando la fecha y hora actual.
  String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  /// Busca una carpeta mediante su identificador.
  FolderModel? findFolderById(String folderId) {
    for (final folder in _folders) {
      if (folder.id == folderId) {
        return folder;
      }
    }
    return null;
  }

  /// Busca una nota utilizando su identificador.
  NoteModel? findNoteById(String noteId) {
    for (final note in _notes) {
      if (note.id == noteId) {
        return note;
      }
    }

    return null;
  }

  /// Devuelve las notas pertenecientes a una carpeta.
  ///
  /// Las notas más recientemente modificadas aparecen primero.
  List<NoteModel> notesForFolder(String folderId) {
    final result = _notes.where((note) {
      return note.folderId == folderId;
    }).toList();

    result.sort((first, second) {
      return second.updatedAt.compareTo(first.updatedAt);
    });

    return result;
  }

  /// Cuenta cuántas notas contiene una carpeta.
  int noteCountForFolder(String folderId) {
    return _notes.where((note) {
      return note.folderId == folderId;
    }).length;
  }

  /// Crea y agrega una nueva carpeta.
  FolderModel createFolder({
    required String name,
    required IconData icon,
    required Color color,
  }) {
    final folder = FolderModel(
      id: _generateId(),
      name: name,
      iconCodePoint: icon.codePoint,
      colorValue: color.toARGB32(),
    );

    _folders.add(folder);

    // Avisa a los widgets interesados que los datos cambiaron.
    _saveAndNotify();

    return folder;
  }

  /// Reemplaza una carpeta existente por su versión actualizada.
  void updateFolder(FolderModel updatedFolder) {
    final index = _folders.indexWhere((folder) {
      return folder.id == updatedFolder.id;
    });

    if (index == -1) {
      return;
    }

    _folders[index] = updatedFolder;
    _saveAndNotify();
  }

  /// Elimina una carpeta y todas las notas que le pertenecen.
  void deleteFolder(String folderId) {
    _folders.removeWhere((folder) {
      return folder.id == folderId;
    });

    _notes.removeWhere((note) {
      return note.folderId == folderId;
    });

    _saveAndNotify();
  }

  /// Crea una nota nueva dentro de una carpeta.
  NoteModel createNote({
    required String folderId,
    required String title,
    required String content,
    bool isFavorite = false,
    List<String> imageData = const [],
  }) {
    final now = DateTime.now();

    final note = NoteModel(
      id: _generateId(),
      folderId: folderId,
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      isFavorite: isFavorite,
      imageData: imageData,
    );

    _notes.add(note);
    _saveAndNotify();

    return note;
  }

  /// Actualiza una nota y registra automáticamente la fecha del cambio.
  void updateNote(NoteModel updatedNote) {
    final index = _notes.indexWhere((note) {
      return note.id == updatedNote.id;
    });

    if (index == -1) {
      return;
    }

    _notes[index] = updatedNote.copyWith(updatedAt: DateTime.now());

    _saveAndNotify();
  }

  /// Cambia el estado favorito de una nota.
  void toggleFavorite(String noteId) {
    final index = _notes.indexWhere((note) {
      return note.id == noteId;
    });

    if (index == -1) {
      return;
    }

    final currentNote = _notes[index];

    _notes[index] = currentNote.copyWith(
      isFavorite: !currentNote.isFavorite,
      updatedAt: DateTime.now(),
    );

    _saveAndNotify();
  }

  /// Elimina una nota mediante su identificador.
  void deleteNote(String noteId) {
    _notes.removeWhere((note) {
      return note.id == noteId;
    });

    _saveAndNotify();
  }
}
