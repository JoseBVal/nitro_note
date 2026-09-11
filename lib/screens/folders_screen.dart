import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/note_repository.dart';
import '../models/folder_model.dart';
import 'notes_screen.dart';

/// Pantalla principal que muestra las carpetas de NitroNote.
class FoldersScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const FoldersScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  // Repositorio compartido que contiene las carpetas y notas.
  final NoteRepository _repository = NoteRepository.instance;

  // Controlador del campo de búsqueda.
  final TextEditingController _searchController = TextEditingController();

  // Nodo de enfoque para el campo de búsqueda, útil para manejar el teclado.
  final FocusNode _searchFocusNode = FocusNode();

  String _searchText = '';

  /// Devuelve solamente las carpetas que coinciden con la búsqueda.
  List<FolderModel> get _filteredFolders {
    final query = _searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return _repository.folders;
    }

    return _repository.folders.where((folder) {
      return folder.name.toLowerCase().contains(query);
    }).toList();
  }

  /// Comienza a escuchar los cambios realizados en el repositorio.
  @override
  void initState() {
    super.initState();
    _repository.addListener(_refreshScreen);

    // Desenfoca el campo de búsqueda después de que se construya la pantalla, evitando que el teclado aparezca automáticamente.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
  }

  /// Reconstruye la pantalla cuando cambian las carpetas o notas.
  void _refreshScreen() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Libera los controladores y deja de escuchar el repositorio.
  @override
  void dispose() {
    _repository.removeListener(_refreshScreen);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Abre la pantalla que contiene las notas de una carpeta.
  void _openFolder(FolderModel folder) {
    // Desenfoca el campo de búsqueda para que el teclado se cierre al abrir la pantalla de notas.
    FocusManager.instance.primaryFocus?.unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return NotesScreen(folderId: folder.id);
        },
      ),
    );
  }

  /// Abre el formulario inferior para crear o editar una carpeta.
  Future<void> _openFolderForm({FolderModel? folder}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final nameController = TextEditingController(text: folder?.name ?? '');

    IconData selectedIcon = folder?.icon ?? Icons.folder_rounded;
    Color selectedColor = folder?.color ?? AppColors.primary;
    String? errorText;

    final result = await showModalBottomSheet<_FolderDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            const colors = [
              AppColors.primary,
              Color(0xFF42A5F5),
              Color(0xFF9C6ADE),
              Color(0xFFFF8A3D),
              Color(0xFF26BFA6),
              Color(0xFF84CC16),
            ];

            const icons = [
              Icons.folder_rounded,
              Icons.code_rounded,
              Icons.storage_rounded,
              Icons.school_rounded,
              Icons.build_rounded,
              Icons.terminal_rounded,
            ];

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  MediaQuery.viewInsetsOf(context).bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder == null ? 'Nueva carpeta' : 'Editar carpeta',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // Campo para escribir el nombre.
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Nombre de la carpeta',
                          hintText: 'Ejemplo: Redes',
                          errorText: errorText,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Elegir icono',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),

                      // Selector de iconos.
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: icons.map((icon) {
                          final isSelected = selectedIcon == icon;

                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setModalState(() {
                                selectedIcon = icon;
                              });
                            },
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected ? Colors.white : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Color de carpeta',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),

                      // Selector de colores.
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: colors.map((color) {
                          final isSelected = selectedColor == color;

                          return InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () {
                              setModalState(() {
                                selectedColor = color;
                              });
                            },
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        width: 3,
                                      )
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 26),

                      // Botones del formulario.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                            },
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () {
                              final name = nameController.text.trim();

                              if (name.isEmpty) {
                                setModalState(() {
                                  errorText = 'Escribe un nombre';
                                });
                                return;
                              }

                              Navigator.pop(
                                sheetContext,
                                _FolderDraft(
                                  name: name,
                                  icon: selectedIcon,
                                  color: selectedColor,
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_rounded),
                            label: Text(folder == null ? 'Crear' : 'Guardar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    if (folder == null) {
      // El repositorio crea el identificador automáticamente.
      _repository.createFolder(
        name: result.name,
        icon: result.icon,
        color: result.color,
      );

      _showMessage('Carpeta creada correctamente');
    } else {
      // copyWith conserva los datos que no necesitamos cambiar.
      final updatedFolder = folder.copyWith(
        name: result.name,
        iconCodePoint: result.icon.codePoint,
        colorValue: result.color.toARGB32(),
      );

      _repository.updateFolder(updatedFolder);
      _showMessage('Carpeta actualizada correctamente');
    }
  }

  /// Solicita confirmación antes de eliminar una carpeta.
  Future<void> _confirmDelete(FolderModel folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar carpeta'),
          content: Text(
            '¿Deseas eliminar la carpeta "${folder.name}"?\n\n'
            'También se eliminarán sus notas.',
          ),
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

    _repository.deleteFolder(folder.id);
    _showMessage('Carpeta eliminada');
  }

  /// Muestra un mensaje temporal en la parte inferior.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final folders = _filteredFolders;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Row(
          children: [
            // Logotipo oficial de NitroNote.
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/icon/nitronote_icon.png',
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 42,
                    height: 42,
                    color: AppColors.primary,
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.nitro,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'NitroNote',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Cambia entre el modo claro y oscuro.
          IconButton(
            tooltip: widget.isDarkMode ? 'Modo claro' : 'Modo oscuro',
            onPressed: widget.onToggleTheme,
            icon: Icon(
              widget.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mis carpetas',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Organiza tus apuntes y soluciones',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Buscador general de carpetas.
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: false,
              textInputAction: TextInputAction.search,

              onTapOutside: (event) {
                _searchFocusNode.unfocus();
              },
              // Quita el foco al presionar Buscar en el teclado, evitando que el teclado se quede abierto.
              onSubmitted: (value) {
                _searchFocusNode.unfocus();
              },
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar en NitroNote...',
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
            const SizedBox(height: 24),

            Expanded(
              child: folders.isEmpty
                  ? const Center(child: Text('No se encontraron carpetas'))
                  : GridView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: folders.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 160,
                          ),
                      itemBuilder: (context, index) {
                        final folder = folders[index];

                        return _FolderCard(
                          folder: folder,
                          noteCount: _repository.noteCountForFolder(folder.id),
                          onTap: () => _openFolder(folder),
                          onEdit: () {
                            _openFolderForm(folder: folder);
                          },
                          onDelete: () {
                            _confirmDelete(folder);
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
          _openFolderForm();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva carpeta'),
      ),
    );
  }
}

/// Tarjeta reutilizable que representa una carpeta.
class _FolderCard extends StatelessWidget {
  final FolderModel folder;
  final int noteCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FolderCard({
    required this.folder,
    required this.noteCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: folder.color.withAlpha(28),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(folder.icon, color: folder.color),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    tooltip: 'Opciones',
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 10),
                              Text('Editar'),
                            ],
                          ),
                        ),
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
                ],
              ),
              const Spacer(),
              Text(
                folder.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                '$noteCount ${noteCount == 1 ? 'nota' : 'notas'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Datos que devuelve el formulario de carpeta.
class _FolderDraft {
  final String name;
  final IconData icon;
  final Color color;

  const _FolderDraft({
    required this.name,
    required this.icon,
    required this.color,
  });
}
