import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/scan_doc.dart';

/// Stores documents as folders inside the app's private storage.
class DocStore {
  DocStore._();
  static final DocStore instance = DocStore._();

  Directory? _root;

  Future<Directory> _rootDir() async {
    final cached = _root;
    if (cached != null) return cached;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'openleaf_docs'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return _root = dir;
  }

  Future<List<ScanDoc>> list() async {
    final root = await _rootDir();
    final docs = <ScanDoc>[];
    await for (final entity in root.list()) {
      if (entity is! Directory) continue;
      final meta = File(p.join(entity.path, 'meta.json'));
      if (!await meta.exists()) continue;
      try {
        final json = jsonDecode(await meta.readAsString()) as Map<String, dynamic>;
        docs.add(ScanDoc.fromJson(json, entity.path));
      } catch (_) {
        // Skip unreadable documents.
      }
    }
    docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return docs;
  }

  Future<ScanDoc> create({
    required String name,
    required List<Uint8List> pages,
  }) async {
    final root = await _rootDir();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final dir = Directory(p.join(root.path, id));
    await dir.create(recursive: true);
    final doc = ScanDoc(
      id: id,
      name: name,
      createdAt: DateTime.now(),
      dir: dir.path,
      pageFiles: [],
    );
    await setPages(doc, pages);
    return doc;
  }

  /// Replaces all pages of [doc] with [pages] (used for create and split).
  Future<void> setPages(ScanDoc doc, List<Uint8List> pages) async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final newFiles = <String>[];
    for (var i = 0; i < pages.length; i++) {
      final name = 'p_${stamp}_$i.jpg';
      await File(p.join(doc.dir, name)).writeAsBytes(pages[i], flush: true);
      newFiles.add(name);
    }
    for (final old in doc.pageFiles) {
      final f = File(p.join(doc.dir, old));
      if (await f.exists()) await f.delete();
    }
    doc.pageFiles = newFiles;
    await save(doc);
  }

  Future<void> deletePage(ScanDoc doc, int index) async {
    final file = File(p.join(doc.dir, doc.pageFiles[index]));
    if (await file.exists()) await file.delete();
    doc.pageFiles = [...doc.pageFiles]..removeAt(index);
    await save(doc);
  }

  Future<void> rename(ScanDoc doc, String name) async {
    doc.name = name;
    await save(doc);
  }

  Future<void> save(ScanDoc doc) async {
    await File(p.join(doc.dir, 'meta.json'))
        .writeAsString(jsonEncode(doc.toJson()), flush: true);
  }

  Future<void> delete(ScanDoc doc) async {
    final dir = Directory(doc.dir);
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
