import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/note_repository.dart';
import '../models/note_model.dart';

/// Resultado que devuelve el editor al cerrarse.
enum NoteEditorResult { saved, deleted }

/// Pantalla utilizada tanto para crear como para editar notas.
///
/// Si [note] es null, crea una nota nueva.
/// Si [note] contiene una nota, modifica esa nota.
class NoteEditorScreen extends StatefulWidget {
  final String folderId;
  final NoteModel? note;

  const NoteEditorScreen({super.key, required this.folderId, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final NoteRepository _repository = NoteRepository.instance;

  // Permite validar todos los campos del formulario.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Permite seleccionar imágenes desde la galería o la cámara.
  final ImagePicker _imagePicker = ImagePicker();
  final List<String> _imageData = [];

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  bool _isFavorite = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _audioPath;
  int? _audioDurationMs;
  bool _isRecording = false;
  DateTime? _recordingStarted;

  /// Indica si estamos editando una nota existente.
  bool get _isEditing {
    return widget.note != null;
  }

  @override
  void initState() {
    super.initState();

    // Si estamos editando, los campos reciben los valores existentes.
    _titleController = TextEditingController(text: widget.note?.title ?? '');

    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );

    _isFavorite = widget.note?.isFavorite ?? false;
    _imageData.addAll(widget.note?.imageData ?? const []);
    _audioPath = widget.note?.audioPath;
    _audioDurationMs = widget.note?.audioDurationMs;
  }

  @override
  void dispose() {
    // Liberamos los controladores cuando se cierra la pantalla.
    _titleController.dispose();
    _contentController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        if (path != null && mounted) {
          setState(() {
            _audioPath = path;
            _audioDurationMs = DateTime.now().difference(_recordingStarted!).inMilliseconds;
            _isRecording = false;
          });
        }
        return;
      }
      if (!await _audioRecorder.hasPermission()) {
        _showMessage('Se necesita permiso para usar el micrófono');
        return;
      }
      final directory = await getApplicationDocumentsDirectory();
      final audioDirectory = Directory('${directory.path}/audio_notes');
      await audioDirectory.create(recursive: true);
      final path = '${audioDirectory.path}/${DateTime.now().microsecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      if (mounted) setState(() { _recordingStarted = DateTime.now(); _isRecording = true; });
    } catch (_) {
      if (mounted) _showMessage('No se pudo grabar el audio');
    }
  }

  Future<void> _removeAudio() async {
    await _audioPlayer.stop();
    final path = _audioPath;
    if (path != null) await File(path).delete().catchError((_) => File(path));
    if (mounted) setState(() { _audioPath = null; _audioDurationMs = null; });
  }

  /// Muestra las opciones disponibles para agregar una imagen.
  Future<void> _showImageSourceOptions() async {
    if (_imageData.length >= 2) {
      _showMessage('Solo puedes agregar un máximo de 2 imágenes');
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Agregar imagen',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // Abre la galería del dispositivo.
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.photo_library_outlined),
                  ),
                  title: const Text('Elegir de la galería'),
                  subtitle: const Text('Seleccionar una imagen existente'),
                  onTap: () {
                    Navigator.pop(sheetContext, ImageSource.gallery);
                  },
                ),

                // Abre la cámara del dispositivo.
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.camera_alt_outlined),
                  ),
                  title: const Text('Tomar una fotografía'),
                  subtitle: const Text('Usar la cámara del dispositivo'),
                  onTap: () {
                    Navigator.pop(sheetContext, ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null || !mounted) {
      return;
    }

    await _pickImage(source);
  }

  /// Obtiene una imagen desde la fuente seleccionada.
  Future<void> _pickImage(ImageSource source) async {
    if (_imageData.length >= 2) {
      _showMessage('Solo puedes agregar un máximo de 2 imágenes');
      return;
    }

    try {
      final selectedImage = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
        requestFullMetadata: false,
      );

      // El usuario cerró la galería o cámara sin seleccionar nada.
      if (selectedImage == null) {
        return;
      }

      final bytes = await selectedImage.readAsBytes();

      if (bytes.isEmpty || !mounted) {
        return;
      }

      setState(() {
        _imageData.add(base64Encode(bytes));
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        source == ImageSource.camera
            ? 'No se pudo abrir la cámara'
            : 'No se pudo seleccionar la imagen',
      );
    }
  }

  /// Elimina una imagen del formulario.
  void _removeImage(int index) {
    setState(() {
      _imageData.removeAt(index);
    });
  }

  /// Valida el formulario y guarda la nota.
  void _saveNote() {
    // validate() ejecuta los validator de los TextFormField.
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (_isEditing) {
      final updatedNote = widget.note!.copyWith(
        title: title,
        content: content,
        isFavorite: _isFavorite,
        imageData: List<String>.from(_imageData),
        audioPath: _audioPath,
        audioDurationMs: _audioDurationMs,
        clearAudio: _audioPath == null,
      );

      _repository.updateNote(updatedNote);
    } else {
      _repository.createNote(
        folderId: widget.folderId,
        title: title,
        content: content,
        isFavorite: _isFavorite,
        imageData: List<String>.from(_imageData),
        audioPath: _audioPath,
        audioDurationMs: _audioDurationMs,
      );
    }

    // Regresamos a la lista indicando que se guardó correctamente.
    Navigator.pop(context, NoteEditorResult.saved);
  }

  /// Solicita confirmación antes de eliminar la nota.
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar nota'),
          content: const Text('¿Deseas eliminar esta nota permanentemente?'),
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

    _repository.deleteNote(widget.note!.id);

    if (!mounted) {
      return;
    }

    Navigator.pop(context, NoteEditorResult.deleted);
  }

  /// Muestra un mensaje temporal.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final folder = _repository.findFolderById(widget.folderId);

    return Scaffold(
      appBar: AppBar(
        // Cambia este valor para modificar la altura superior.
        toolbarHeight: 72,
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          _isEditing ? 'Editar nota' : 'Nueva nota',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _saveNote,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Guardar'),
            ),
          ),
        ],
      ),

      // SingleChildScrollView evita desbordamientos cuando aparece el teclado.
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            // Cambia 20 para modificar el margen general.
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Muestra la carpeta donde se guardará la nota.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Carpeta: ${folder?.name ?? 'Sin carpeta'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Campo del título.
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Título de la nota',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Escribe un título';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Interruptor para marcar la nota como favorita.
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SwitchListTile(
                      value: _isFavorite,
                      secondary: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.nitro,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      title: const Text(
                        'Marcar como favorita',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'La nota aparecerá en el filtro de favoritas',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _isFavorite = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo principal para escribir el contenido.
                TextFormField(
                  controller: _contentController,
                  textCapitalization: TextCapitalization.sentences,

                  // minLines define la altura inicial del campo.
                  minLines: 10,

                  // null permite que crezca mientras se escribe.
                  maxLines: null,

                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: 'Contenido',
                    hintText: 'Escribe tu nota aquí...',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Escribe el contenido de la nota';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 22),

                Text('Nota de audio', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(children: [
                  FilledButton.icon(onPressed: _toggleRecording, icon: Icon(_isRecording ? Icons.stop : Icons.mic), label: Text(_isRecording ? 'Detener grabación' : 'Grabar audio')),
                  if (_audioPath != null) ...[
                    IconButton(tooltip: 'Reproducir audio', onPressed: () async { await _audioPlayer.play(DeviceFileSource(_audioPath!)); }, icon: const Icon(Icons.play_arrow)),
                    IconButton(tooltip: 'Eliminar audio', onPressed: _removeAudio, icon: const Icon(Icons.delete_outline)),
                    Text('${((_audioDurationMs ?? 0) / 1000).round()} s'),
                  ],
                ]),
                const SizedBox(height: 22),

                // Sección para administrar las imágenes.
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Imágenes adjuntas',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _imageData.length >= 2
                          ? null
                          : _showImageSourceOptions,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Agregar imagen'),
                    ),
                  ],
                ),
                Text(
                  '${_imageData.length}/2 imágenes seleccionadas',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),

                if (_imageData.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 42,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Todavía no agregaste imágenes',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _imageData.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 150,
                        ),
                    itemBuilder: (context, index) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              base64Decode(_imageData[index]),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.broken_image_outlined),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Material(
                              color: Colors.black.withAlpha(160),
                              shape: const CircleBorder(),
                              child: IconButton(
                                tooltip: 'Quitar imagen',
                                onPressed: () {
                                  _removeImage(index);
                                },
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                // La opción eliminar solo aparece al editar.
                if (_isEditing) ...[
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .errorContainer,
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onErrorContainer,
                        minimumSize: const Size.fromHeight(54),
                      ),
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Eliminar nota'),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                Center(
                  child: Text(
                    _isEditing
                        ? 'La fecha se actualizará al guardar'
                        : 'La fecha se creará automáticamente',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
