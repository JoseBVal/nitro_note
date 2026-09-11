import 'package:flutter/material.dart';

import '../data/note_repository.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
import 'note_editor_screen.dart';
import 'note_detail_screen.dart';

/// Muestra las notas pertenecientes a la carpeta seleccionada.
class NotesScreen extends StatefulWidget {
  // Solo recibimos el identificador de la carpeta.
  final String folderId;

  const NotesScreen({super.key, required this.folderId});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NoteRepository _repository = NoteRepository.instance;
  final TextEditingController _searchController = TextEditingController();
  // Nodo de enfoque para el campo de búsqueda, útil para manejar el teclado.
  final FocusNode _searchFocusNode = FocusNode();

  String _searchText = '';
  bool _showOnlyFavorites = false;

  /// Obtiene la carpeta actual desde el repositorio.
  FolderModel? get _folder {
    return _repository.findFolderById(widget.folderId);
  }

  /// Obtiene las notas y aplica los filtros seleccionados.
  List<NoteModel> get _filteredNotes {
    final notes = _repository.notesForFolder(widget.folderId);
    final query = _searchText.trim().toLowerCase();

    return notes.where((note) {
      final matchesText =
          query.isEmpty ||
          note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query);

      final matchesFavorite = !_showOnlyFavorites || note.isFavorite;

      return matchesText && matchesFavorite;
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    // Escuchamos los cambios del repositorio.
    _repository.addListener(_refreshScreen);
    // Desenfoca el campo de búsqueda después de que se construya la pantalla, evitando que el teclado aparezca automáticamente.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
  }

  /// Actualiza la interfaz cuando cambia alguna nota.
  void _refreshScreen() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _repository.removeListener(_refreshScreen);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Convierte una fecha en un texto sencillo.
  String _formatDate(DateTime date) {
    final now = DateTime.now();

    final sameDay =
        date.year == now.year && date.month == now.month && date.day == now.day;

    if (sameDay) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return 'Hoy, $hour:$minute';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  /// Muestra un mensaje temporal.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final folder = _folder;

    // Protección por si la carpeta fue eliminada.
    if (folder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carpeta')),
        body: const Center(child: Text('La carpeta ya no existe')),
      );
    }

    final notes = _filteredNotes;
    final totalNotes = _repository.noteCountForFolder(folder.id);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: folder.color.withAlpha(28),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(folder.icon, color: folder.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$totalNotes '
                    '${totalNotes == 1 ? 'nota guardada' : 'notas guardadas'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        /*actions: [
          IconButton(
            tooltip: 'Opciones',
            onPressed: () {
              _showMessage('Puedes editar la carpeta desde el inicio');
            },
            icon: const Icon(Icons.more_vert_rounded),
          ),
          const SizedBox(width: 6),
        ],*/
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buscador de notas.
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: false,
              textInputAction: TextInputAction.search,

              onTapOutside: (event) {
                _searchFocusNode.unfocus();
              },

              onSubmitted: (value) {
                _searchFocusNode.unfocus();
              },
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar notas en ${folder.name}...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchText.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _searchText = '';
                          });
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Activa o desactiva el filtro de favoritas.
            FilterChip(
              selected: _showOnlyFavorites,
              avatar: Icon(
                _showOnlyFavorites
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: _showOnlyFavorites ? Colors.amber.shade700 : null,
              ),
              label: const Text('Favoritas'),
              onSelected: (selected) {
                setState(() {
                  _showOnlyFavorites = selected;
                });
              },
            ),
            const SizedBox(height: 16),

            Expanded(
              child: notes.isEmpty
                  ? _EmptyNotes(
                      searchActive:
                          _searchText.trim().isNotEmpty || _showOnlyFavorites,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: notes.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(height: 14);
                      },
                      itemBuilder: (context, index) {
                        final note = notes[index];

                        return _NoteCard(
                          note: note,
                          folderColor: folder.color,
                          formattedDate: _formatDate(note.updatedAt),
                          onFavoritePressed: () {
                            _repository.toggleFavorite(note.id);
                          },
                          onTap: () {
                            _openNoteDetail(note);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _createNote();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva nota'),
      ),
    );
  }

  /// Abre el editor vacío para crear una nota.
  Future<void> _createNote() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await Navigator.push<NoteEditorResult>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return NoteEditorScreen(folderId: widget.folderId);
        },
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == NoteEditorResult.saved) {
      _showMessage('Nota guardada correctamente');
    }
  }

  /// Abre la pantalla de visualización de una nota.
  Future<void> _openNoteDetail(NoteModel note) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final wasDeleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return NoteDetailScreen(noteId: note.id);
        },
      ),
    );

    if (!mounted) {
      return;
    }

    if (wasDeleted == true) {
      _showMessage('Nota eliminada');
    }
  }
}

/// Tarjeta que muestra el resumen de una nota.
class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final Color folderColor;
  final String formattedDate;
  final VoidCallback onFavoritePressed;
  final VoidCallback onTap;

  const _NoteCard({
    required this.note,
    required this.folderColor,
    required this.formattedDate,
    required this.onFavoritePressed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF34384B) : const Color(0xFFE2E5EE),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título y botón de favorito.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: note.isFavorite
                        ? 'Quitar de favoritas'
                        : 'Agregar a favoritas',
                    onPressed: onFavoritePressed,
                    icon: Icon(
                      note.isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: note.isFavorite
                          ? Colors.amber.shade700
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              // Vista previa generada por NoteModel.
              Text(
                note.preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Fecha e indicador de imágenes.
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (note.hasImages) ...[
                    Icon(Icons.image_outlined, size: 18, color: folderColor),
                    const SizedBox(width: 4),
                    Text(
                      '${note.imageData.length} '
                      '${note.imageData.length == 1 ? 'imagen' : 'imágenes'}',
                      style: TextStyle(
                        color: folderColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mensaje mostrado cuando no existen resultados.
class _EmptyNotes extends StatelessWidget {
  final bool searchActive;

  const _EmptyNotes({required this.searchActive});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searchActive ? Icons.search_off_rounded : Icons.note_add_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              searchActive
                  ? 'No se encontraron notas'
                  : 'Esta carpeta todavía no tiene notas',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
