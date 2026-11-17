import 'dart:io';
import 'dart:typed_data';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';

import '../models/scan_doc.dart';
import '../services/doc_store.dart';
import '../services/image_tools.dart';
import '../theme.dart';
import 'doc_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ScanDoc> _docs = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final docs = await DocStore.instance.list();
    if (!mounted) return;
    setState(() {
      _docs = docs;
      _loading = false;
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _scan({required bool book}) async {
    List<String>? pictures;
    try {
      pictures = await CunningDocumentScanner.getPictures();
    } catch (e) {
      _toast('Scanner could not start: $e');
      return;
    }
    if (pictures == null || pictures.isEmpty) return;

    setState(() => _busy = true);
    try {
      final pages = <Uint8List>[];
      for (final path in pictures) {
        final bytes = await File(path).readAsBytes();
        if (book) {
          pages.addAll(await ImageTools.splitSpread(bytes));
        } else {
          pages.add(bytes);
        }
      }
      final stamp = DateTime.now().toString().substring(0, 16);
      final doc = await DocStore.instance.create(
        name: book ? 'Book $stamp' : 'Scan $stamp',
        pages: pages,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DocScreen(doc: doc)),
      );
    } catch (e) {
      _toast('Could not save the scan: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load();
    }
  }

  Future<void> _open(ScanDoc doc) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DocScreen(doc: doc)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OpenLeaf')),
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_docs.isEmpty)
            _EmptyState()
          else
            ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
              itemCount: _docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _DocTile(doc: _docs[i], onTap: () => _open(_docs[i])),
            ),
          if (_busy)
            const ColoredBox(
              color: Color(0xAA0B0A24),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'book',
            onPressed: _busy ? null : () => _scan(book: true),
            backgroundColor: kPanelHigh,
            foregroundColor: kAmber,
            icon: const Icon(Icons.menu_book_rounded),
            label: const Text('Book scan'),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'scan',
            onPressed: _busy ? null : () => _scan(book: false),
            icon: const Icon(Icons.document_scanner_rounded),
            label: const Text('Scan'),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', width: 150),
            const SizedBox(height: 20),
            const Text(
              'Nothing scanned yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap Scan for a document, or Book scan to turn a two-page spread into two pages.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFB9B5E6), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({required this.doc, required this.onTap});

  final ScanDoc doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cover = doc.coverPath;
    return Material(
      color: kPanel,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 64,
                  height: 80,
                  child: cover == null
                      ? const ColoredBox(color: kPanelHigh)
                      : Image.file(File(cover), fit: BoxFit.cover, cacheWidth: 200),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${doc.pageCount} ${doc.pageCount == 1 ? 'page' : 'pages'}',
                      style: const TextStyle(color: Color(0xFFB9B5E6)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFB9B5E6)),
            ],
          ),
        ),
      ),
    );
  }
}
