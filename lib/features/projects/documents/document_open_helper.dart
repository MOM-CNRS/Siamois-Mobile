import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

/// Ouvre un fichier local (macOS : `open`, autres plateformes : OpenFilex).
class DocumentOpenHelper {
  const DocumentOpenHelper._();

  static String sanitizeFileName(String raw, {String? mimeType}) {
    var name = raw.trim();
    if (name.isEmpty) name = 'document';
    name = p.basename(name);
    name = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

    if (!name.contains('.') && mimeType != null) {
      final ext = _extensionForMime(mimeType);
      if (ext != null) name = '$name.$ext';
    }
    return name;
  }

  static String? _extensionForMime(String mime) {
    final m = mime.toLowerCase();
    if (m.contains('pdf')) return 'pdf';
    if (m.contains('jpeg') || m.contains('jpg')) return 'jpg';
    if (m.contains('png')) return 'png';
    if (m.contains('gif')) return 'gif';
    if (m.contains('zip')) return 'zip';
    if (m.contains('plain')) return 'txt';
    if (m.contains('json')) return 'json';
    if (m.contains('xml')) return 'xml';
    return null;
  }

  static String? fileNameFromContentDisposition(String? header) {
    if (header == null || header.isEmpty) return null;
    final filenameStar = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(header);
    if (filenameStar != null) {
      return Uri.decodeComponent(filenameStar.group(1)!.trim());
    }
    final filename = RegExp(
      r'filename="?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(header);
    return filename?.group(1)?.trim();
  }

  static bool looksLikeErrorPayload(List<int> bytes) {
    if (bytes.length < 4) return false;
    final head = String.fromCharCodes(bytes.take(64)).trimLeft().toLowerCase();
    return head.startsWith('<!doctype') ||
        head.startsWith('<html') ||
        head.startsWith('{');
  }

  static Future<String> openLocalFile({
    required String path,
    String? mimeType,
  }) async {
    if (!File(path).existsSync()) {
      throw Exception('Fichier introuvable : $path');
    }

    if (!kIsWeb && Platform.isMacOS) {
      final result = await Process.run('open', [path]);
      if (result.exitCode == 0) return '';
      final err = result.stderr.toString().trim();
      if (err.isNotEmpty) return err;
      return 'Impossible d’ouvrir le fichier (code ${result.exitCode}).';
    }

    final result = await OpenFilex.open(path, type: _openFileType(mimeType));
    if (result.type == ResultType.done) return '';
    return result.message.isNotEmpty
        ? result.message
        : 'Impossible d’ouvrir ce fichier.';
  }

  static String? _openFileType(String? mimeType) {
    final m = mimeType?.toLowerCase();
    if (m == null) return null;
    if (m.contains('pdf')) return 'application/pdf';
    return mimeType;
  }
}
