import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:share_plus/share_plus.dart';

import '../models/scan_doc.dart';
import '../services/doc_store.dart';
import '../services/image_tools.dart';
import '../services/pdf_service.dart';
import '../theme.dart';

class DocScreen extends StatefulWidget {
  const DocScreen({super.key, required this.doc});

  final ScanDoc doc;

  @override
  State<DocScreen> createState() => _DocScreenState();
}

class _DocScreenState extends State<DocScreen> {
  late final ScanDoc doc = widget.doc;
  bool _busy = false;

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<void> Function() job) async {
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      _toast('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sharePdf() => _run(() async {
        final file = await PdfService.buildPdf(doc);
        await Share.shareXFiles([XFile(file.path)], subject: doc.name);
      });

  Future<void> _rename() async {
    final controller = TextEditingController(text: doc.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename document'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await DocStore.instance.rename(doc, name);
    if (mounted) setState(() {});
  }

  Future<void> _splitSpreads() async {
    final ok = await _confirm(
      'Split every page in half?',
      'Use this for book spreads. Each page becomes a left and a right page.',
      'Split',
    );
    if (ok != true) return;
    await _run(() async {
      final pages = <Uint8List>[];
      for (final path in doc.pagePaths) {
        pages.addAll(await ImageTools.splitSpread(await File(path).readAsBytes()));
      }
      await DocStore.instance.setPages(doc, pages);
    });
  }

  Future<void> _extractText() => _run(() async {
        final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final buffer = StringBuffer();
        try {
          for (final path in doc.pagePaths) {
            final result = await recognizer.processImage(InputImage.fromFilePath(path));
            if (result.text.trim().isNotEmpty) {
              buffer.writeln(result.text.trim());
              buffer.writeln();
            }
          }
        } finally {
          await recognizer.close();
        }
        if (!mounted) return;
        final text = buffer.toString().trim();
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: kPanel,
          builder: (ctx) => _TextSheet(text: text),
        );
      });

  Future<bool?> _confirm(String title, String body, String action) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
        ],
      ),
    );
  }

  Future<void> _deleteDoc() async {
    final ok = await _confirm('Delete this document?', 'This cannot be undone.', 'Delete');
    if (ok != true) return;
    await DocStore.instance.delete(doc);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deletePage(int index) async {
    final ok = await _confirm('Delete page ${index + 1}?', 'This cannot be undone.', 'Delete');
    if (ok != true) return;
    await DocStore.instance.deletePage(doc, index);
    if (!mounted) return;
    if (doc.pageCount == 0) {
      await DocStore.instance.delete(doc);
      if (mounted) Navigator.pop(context);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final paths = doc.pagePaths;
    return Scaffold(
      appBar: AppBar(
        title: Text(doc.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Share as PDF',
            onPressed: _busy ? null : _sharePdf,
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
          PopupMenuButton<String>(
            enabled: !_busy,
            onSelected: (value) {
              switch (value) {
                case 'rename':
                  _rename();
                case 'split':
                  _splitSpreads();
                case 'text':
                  _extractText();
                case 'delete':
                  _deleteDoc();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'text', child: Text('Extract text')),
              PopupMenuItem(value: 'split', child: Text('Split book spreads')),
              PopupMenuItem(value: 'delete', child: Text('Delete document')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: paths.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => _PageViewer(paths: paths, start: i)),
              ),
              onLongPress: () => _deletePage(i),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(paths[i]), fit: BoxFit.cover, cacheWidth: 500),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xCC0B0A24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${i + 1}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_busy)
            const ColoredBox(
              color: Color(0xAA0B0A24),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _PageViewer extends StatelessWidget {
  const _PageViewer({required this.paths, required this.start});

  final List<String> paths;
  final int start;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: PageView.builder(
        controller: PageController(initialPage: start),
        itemCount: paths.length,
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Center(child: Image.file(File(paths[i]))),
        ),
      ),
    );
  }
}

class _TextSheet extends StatelessWidget {
  const _TextSheet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Extracted text',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                if (text.isNotEmpty)
                  FilledButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: text));
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: SelectableText(
                  text.isEmpty ? 'No text found. Try a sharper, better-lit scan.' : text,
                  style: const TextStyle(height: 1.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
