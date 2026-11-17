import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/scan_doc.dart';

class PdfService {
  /// Builds a PDF with one full-bleed page per scanned image.
  static Future<File> buildPdf(ScanDoc doc) async {
    final pdf = pw.Document(title: doc.name, creator: 'OpenLeaf');

    for (final path in doc.pagePaths) {
      final bytes = await File(path).readAsBytes();
      final decoded = await decodeImageFromList(bytes);
      // Treat the image as 150 dpi: pixels -> PDF points (72 per inch).
      final w = decoded.width * 72 / 150;
      final h = decoded.height * 72 / 150;
      decoded.dispose();

      final image = pw.MemoryImage(bytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(w, h),
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Image(image, fit: pw.BoxFit.fill),
          ),
        ),
      );
    }

    final dir = await getTemporaryDirectory();
    final safeName = doc.name.replaceAll(RegExp(r'[^\w\- ]'), '_').trim();
    final file = File(p.join(dir.path, '${safeName.isEmpty ? 'scan' : safeName}.pdf'));
    await file.writeAsBytes(await pdf.save(), flush: true);
    return file;
  }
}
