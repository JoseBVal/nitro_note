import 'package:flutter/material.dart';

/// Representa una carpeta creada dentro de NitroNote.
class FolderModel {
  // Identificador único utilizado para diferenciar cada carpeta.
  final String id;

  // Nombre visible de la carpeta.
  final String name;

  // Código numérico del icono de Material Icons.
  final int iconCodePoint;

  // Color guardado como número entero.
  final int colorValue;

  const FolderModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
  });

  /// Convierte el código guardado en un icono que Flutter puede mostrar.
  IconData get icon {
    if (iconCodePoint == Icons.code_rounded.codePoint) {
      return Icons.code_rounded;
    }

    if (iconCodePoint == Icons.storage_rounded.codePoint) {
      return Icons.storage_rounded;
    }

    if (iconCodePoint == Icons.school_rounded.codePoint) {
      return Icons.school_rounded;
    }

    if (iconCodePoint == Icons.build_rounded.codePoint) {
      return Icons.build_rounded;
    }

    if (iconCodePoint == Icons.terminal_rounded.codePoint) {
      return Icons.terminal_rounded;
    }

    return Icons.folder_rounded;
  }

  /// Convierte el número almacenado nuevamente en un objeto Color.
  Color get color {
    return Color(colorValue);
  }

  /// Crea una copia de la carpeta cambiando únicamente los datos indicados.
  ///
  /// Esta técnica evita modificar directamente el objeto original.
  FolderModel copyWith({String? name, int? iconCodePoint, int? colorValue}) {
    return FolderModel(
      id: id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  /// Convierte la carpeta en un mapa para guardarla localmente.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
    };
  }

  /// Reconstruye una carpeta utilizando los datos almacenados.
  factory FolderModel.fromMap(Map<String, dynamic> map) {
    return FolderModel(
      id: map['id'] as String,
      name: map['name'] as String,
      iconCodePoint: (map['iconCodePoint'] as num).toInt(),
      colorValue: (map['colorValue'] as num).toInt(),
    );
  }
}
