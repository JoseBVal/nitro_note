/// Representa una nota almacenada dentro de una carpeta.
class NoteModel {
  final String id;
  final String folderId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  // Imágenes convertidas a texto Base64.
  final List<String> imageData;

  const NoteModel({
    required this.id,
    required this.folderId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.imageData = const [],
  });

  /// Indica si la nota tiene al menos una imagen.
  bool get hasImages {
    return imageData.isNotEmpty;
  }

  /// Devuelve una pequeña vista previa del contenido.
  String get preview {
    final cleanContent = content.replaceAll('\n', ' ').trim();

    if (cleanContent.length <= 110) {
      return cleanContent;
    }

    return '${cleanContent.substring(0, 110)}...';
  }

  /// Crea una copia modificando solamente los campos enviados.
  NoteModel copyWith({
    String? folderId,
    String? title,
    String? content,
    DateTime? updatedAt,
    bool? isFavorite,
    List<String>? imageData,
  }) {
    return NoteModel(
      id: id,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      imageData: imageData ?? this.imageData,
    );
  }

  /// Convierte la nota en un mapa para guardarla localmente.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folderId': folderId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isFavorite': isFavorite,
      'imageData': imageData,
    };
  }

  /// Reconstruye una nota desde un mapa.
  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as String,
      folderId: map['folderId'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isFavorite: map['isFavorite'] as bool? ?? false,
      imageData: List<String>.from(map['imageData'] as List? ?? []),
    );
  }
}
