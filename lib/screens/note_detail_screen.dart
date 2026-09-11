import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'dart:convert';

import '../core/theme/app_theme.dart';
import '../data/note_repository.dart';
import '../models/note_model.dart';
import 'note_editor_screen.dart';

/// Pantalla utilizada para leer una nota completa.
class NoteDetailScreen extends StatefulWidget {
  // Recibimos solamente el identificador para consultar la nota actualizada.
  final String noteId;

  const NoteDetailScreen({super.key, required this.noteId});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final NoteRepository _repository = NoteRepository.instance;

  /// Obtiene siempre la versión más reciente de la nota.
  NoteModel? get _note {
    return _repository.findNoteById(widget.noteId);
  }

  @override
  void initState() {
    super.initState();

    // Escuchamos cambios como edición o favorito.
    _repository.addListener(_refreshScreen);
  }

  /// Reconstruye la pantalla cuando cambia la nota.
  void _refreshScreen() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _repository.removeListener(_refreshScreen);
    super.dispose();
  }

  /// Convierte la fecha en un formato fácil de leer.
  String _formatDate(DateTime date) {
    final now = DateTime.now();

    final sameDay =
        date.year == now.year && date.month == now.month && date.day == now.day;

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    if (sameDay) {
      return 'Actualizada hoy, $hour:$minute';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return 'Actualizada el $day/$month/${date.year}';
  }

  /// Abre el editor con los datos actuales de la nota.
  Future<void> _editNote(NoteModel note) async {
    final result = await Navigator.push<NoteEditorResult>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return NoteEditorScreen(folderId: note.folderId, note: note);
        },
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == NoteEditorResult.saved) {
      _showMessage('Nota actualizada correctamente');
    } else if (result == NoteEditorResult.deleted) {
      // true indica a la lista anterior que la nota fue eliminada.
      Navigator.pop(context, true);
    }
  }

  /// Solicita confirmación antes de eliminar la nota.
  Future<void> _confirmDelete(NoteModel note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar nota'),
          content: Text('¿Deseas eliminar la nota "${note.title}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    _repository.deleteNote(note.id);

    if (!mounted) {
      return;
    }

    Navigator.pop(context, true);
  }

  /// Muestra un mensaje temporal en la parte inferior.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Comparte el título y contenido de la nota como texto.
  Future<void> _shareNote(NoteModel note) async {
    final sharedText =
        '''
    ${note.title}

    ${note.content}

    Compartido desde NitroNote
    ''';

    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          text: sharedText.trim(),
          title: note.title,
          subject: note.title,
        ),
      );

      if (!mounted) {
        return;
      }

      if (result.status == ShareResultStatus.unavailable) {
        _showMessage('La función compartir no está disponible');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('No se pudo compartir la nota');
    }
  }

  /// Abre una imagen en pantalla completa.
  void _openImagePreview(String imageData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return _ImagePreviewScreen(imageData: imageData);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final note = _note;

    // Esta protección evita errores si la nota fue eliminada.
    if (note == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nota')),
        body: const Center(child: Text('La nota ya no existe')),
      );
    }

    final folder = _repository.findFolderById(note.folderId);
    final folderColor = folder?.color ?? AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Nota',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Permite cambiar rápidamente el estado favorito.
          IconButton(
            tooltip: note.isFavorite
                ? 'Quitar de favoritas'
                : 'Agregar a favoritas',
            onPressed: () {
              _repository.toggleFavorite(note.id);
            },
            icon: Icon(
              note.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: note.isFavorite ? Colors.amber.shade700 : null,
            ),
          ),

          // Menú secundario para eliminar la nota.
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete(note);
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Eliminar',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
          const SizedBox(width: 6),
        ],
      ),

      // Permite desplazar la nota cuando su contenido es largo.
      body: SingleChildScrollView(
        // Cambia 20 para modificar los márgenes laterales.
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carpeta y fecha de actualización.
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: folderColor.withAlpha(28),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_outlined, size: 18, color: folderColor),
                      const SizedBox(width: 6),
                      Text(
                        folder?.name ?? 'Sin carpeta',
                        style: TextStyle(
                          color: folderColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '•',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _formatDate(note.updatedAt),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Cambia fontSize para modificar el tamaño del título.
            Text(
              note.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 22),

            // Tarjeta que muestra el contenido completo.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF34384B) : AppColors.border,
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
              child: SelectableText(
                note.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  // height controla la separación entre líneas.
                  height: 1.6,
                  fontSize: 17,
                ),
              ),
            ),

            // En el siguiente paso aparecerán aquí las imágenes.
            if (note.hasImages) ...[
              const SizedBox(height: 24),
              Text(
                'Imágenes adjuntas',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: note.imageData.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 190,
                ),
                itemBuilder: (context, index) {
                  final selectedImageData = note.imageData[index];

                  return GestureDetector(
                    onTap: () {
                      _openImagePreview(selectedImageData);
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            base64Decode(selectedImageData),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                child: const Center(
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              );
                            },
                          ),
                        ),

                        // Indica que la imagen puede abrirse.
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(170),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.open_in_full_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),

      // Botones permanentes en la parte inferior.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  // Cambia 54 para modificar la altura del botón.
                  minimumSize: const Size.fromHeight(54),
                ),
                onPressed: () {
                  _shareNote(note);
                },
                icon: const Icon(Icons.share_outlined),
                label: const Text('Compartir'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
                onPressed: () {
                  _editNote(note);
                },
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Editar nota'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Muestra una imagen completa y permite ampliarla.
class _ImagePreviewScreen extends StatelessWidget {
  final String imageData;

  const _ImagePreviewScreen({required this.imageData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Vista previa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return InteractiveViewer(
              minScale: 1,
              maxScale: 6,
              boundaryMargin: const EdgeInsets.all(80),
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Image.memory(
                  base64Decode(imageData),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white,
                            size: 60,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No se pudo mostrar la imagen',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
