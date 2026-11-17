# OpenLeaf

A free, offline document scanner and PDF toolkit for Android. No accounts, no ads, no paywalls.

## Features (v0.1)
- Scan documents with edge detection, crop and filters
- Book scan: scan a two-page spread and get two separate pages
- Export any scan as a PDF and share it anywhere
- On-device OCR: extract and copy text from scans
- Rename, delete pages, local library
- Everything stays on your phone

## Roadmap
- Password-protected PDFs
- Redaction (blackout areas)
- Export to Word / Excel / PowerPoint
- Merge, split, compress PDFs
- Signatures, watermarks, ID photo maker

## Build
GitHub Actions builds the APK. Push to `main` for a downloadable build artifact,
or push a tag like `v0.1.0` to publish `OpenLeaf.apk` on the Releases page.

Local build (needs Flutter):

    flutter create --platforms=android --project-name openleaf --org com.openleaf .
    flutter pub get
    dart run flutter_launcher_icons
    flutter build apk --release
