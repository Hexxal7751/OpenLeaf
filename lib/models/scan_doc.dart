import 'package:path/path.dart' as p;

/// One scanned document: a folder with page images and a meta.json.
class ScanDoc {
  ScanDoc({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.dir,
    required this.pageFiles,
  });

  final String id;
  String name;
  final DateTime createdAt;
  final String dir;
  List<String> pageFiles;

  List<String> get pagePaths => pageFiles.map((f) => p.join(dir, f)).toList();
  int get pageCount => pageFiles.length;
  String? get coverPath => pageFiles.isEmpty ? null : p.join(dir, pageFiles.first);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'pages': pageFiles,
      };

  factory ScanDoc.fromJson(Map<String, dynamic> json, String dir) {
    return ScanDoc(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      dir: dir,
      pageFiles: (json['pages'] as List).cast<String>(),
    );
  }
}
