import 'dart:io';
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class PdfService {
  // Load existing PDF and add logo watermark
  static Future<Uint8List> addLogoToPdf({
    required String language,
    String? logoUrl,
  }) async {
    // Load the existing PNG file to use as base for PDF
    final pngFileName = language == 'es' ? 'Folleto ES.png' : 'Leaflet EN.png';
    final pngBytes = await rootBundle.load('assets/$pngFileName');

    // Decode the original image
    final originalImage = img.decodeImage(pngBytes.buffer.asUint8List());
    if (originalImage == null) {
      throw Exception('Failed to decode original image');
    }

    // Load logo if available
    pw.MemoryImage? logoImage;
    if (logoUrl != null) {
      try {
        final response = await http.get(Uri.parse(logoUrl));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        print('Failed to load logo: $e');
      }
    }

    // Create a new PDF with the image as background
    final pdf = pw.Document();

    // Convert image to PDF format
    final pdfImage = pw.MemoryImage(pngBytes.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Stack(
          children: [
            // Original image as background
            pw.Positioned.fill(
              child: pw.Image(
                pdfImage,
                fit: pw.BoxFit.contain,
              ),
            ),
            // Logo overlay at bottom
            if (logoImage != null)
              pw.Positioned(
                bottom: 20,
                right: 50,
                child: pw.Container(
                  width: 150,
                  height: 150,
                  child: pw.Center(
                    child: pw.Image(
                      logoImage,
                      width: 150,
                      height: 150,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // Load existing PNG and add logo watermark
  static Future<Uint8List> addLogoToPng({
    required String language,
    String? logoUrl,
  }) async {
    // Load the existing PNG file
    final pngFileName = language == 'es' ? 'Folleto ES.png' : 'Leaflet EN.png';
    final pngBytes = await rootBundle.load('assets/$pngFileName');

    // Decode the original image
    final originalImage = img.decodeImage(pngBytes.buffer.asUint8List());
    if (originalImage == null) {
      throw Exception('Failed to decode original image');
    }

    // Load logo if available
    img.Image? logoImage;
    if (logoUrl != null) {
      try {
        final response = await http.get(Uri.parse(logoUrl));
        if (response.statusCode == 200) {
          logoImage = img.decodeImage(response.bodyBytes);
        }
      } catch (e) {
        print('Failed to load logo: $e');
      }
    }

    // Create a copy of the original image
    final resultImage = img.Image.from(originalImage);

    // Add logo overlay if available
    if (logoImage != null) {
      // Calculate logo size (25% of image width)
      final logoWidth = (resultImage.width * 0.25).round();
      final logoHeight = (logoWidth * 0.5).round(); // Maintain aspect ratio

      // Resize logo to appropriate size
      final resizedLogo = img.copyResize(
        logoImage,
        width: logoWidth,
        height: logoHeight,
        interpolation: img.Interpolation.linear,
      );

      // Calculate position (right bottom, moved up a bit)
      final int x = resultImage.width - logoWidth - 50; // 50px from right edge
      final int y =
          resultImage.height - logoHeight - 150; // 150px from bottom (moved up)

      // Draw logo
      img.compositeImage(resultImage, resizedLogo, dstX: x, dstY: y);
    }

    // Encode as PNG
    return Uint8List.fromList(img.encodePng(resultImage));
  }

  // Download PDF to device
  static Future<String> downloadPdf({
    required String language,
    String? logoUrl,
    String? adminName,
  }) async {
    final pdfBytes = await addLogoToPdf(
      language: language,
      logoUrl: logoUrl,
    );

    if (kIsWeb) {
      // For web, trigger download using browser
      final baseFileName = language == 'es' ? 'Folleto_ES' : 'Leaflet_EN';
      final fileName = adminName != null && adminName.isNotEmpty
          ? '${adminName}_$baseFileName.pdf'
          : '$baseFileName.pdf';

      // Create blob URL and trigger download
      final blob = html.Blob([pdfBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);

      return 'Downloaded: $fileName';
    } else {
      try {
        // Try to get application documents directory
        final directory = await getApplicationDocumentsDirectory();
        final baseFileName = language == 'es' ? 'Folleto_ES' : 'Leaflet_EN';
        final fileName = adminName != null && adminName.isNotEmpty
            ? '${adminName}_$baseFileName.pdf'
            : '$baseFileName.pdf';
        final file = File('${directory.path}/$fileName');

        await file.writeAsBytes(pdfBytes);
        return file.path;
      } catch (e) {
        print('Failed to get application documents directory: $e');

        try {
          // Fallback to current directory
          final baseFileName = language == 'es' ? 'Folleto_ES' : 'Leaflet_EN';
          final fileName = adminName != null && adminName.isNotEmpty
              ? '${adminName}_$baseFileName.pdf'
              : '$baseFileName.pdf';
          final file = File(fileName);

          await file.writeAsBytes(pdfBytes);
          return file.path;
        } catch (e2) {
          print('Failed to save to current directory: $e2');
          throw Exception('Failed to save PDF file: $e2');
        }
      }
    }
  }

  // Download PNG to device
  static Future<String> downloadPng({
    required String language,
    String? logoUrl,
    String? adminName,
  }) async {
    final pngBytes = await addLogoToPng(
      language: language,
      logoUrl: logoUrl,
    );

    if (kIsWeb) {
      // For web, trigger download using browser
      final baseFileName = language == 'es' ? 'Folleto_ES' : 'Leaflet_EN';
      final fileName = adminName != null && adminName.isNotEmpty
          ? '${adminName}_$baseFileName.png'
          : '$baseFileName.png';

      // Create blob URL and trigger download
      final blob = html.Blob([pngBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);

      return 'Downloaded: $fileName';
    } else {
      try {
        // Try to get application documents directory
        final directory = await getApplicationDocumentsDirectory();
        final baseFileName = language == 'es' ? 'Folleto_ES' : 'Leaflet_EN';
        final fileName = adminName != null && adminName.isNotEmpty
            ? '${adminName}_$baseFileName.png'
            : '$baseFileName.png';
        final file = File('${directory.path}/$fileName');

        await file.writeAsBytes(pngBytes);
        return file.path;
      } catch (e) {
        print('Failed to get application documents directory: $e');

        try {
          // Fallback to current directory
          final baseFileName = language == 'es' ? 'Folleto_ES' : 'Leaflet_EN';
          final fileName = adminName != null && adminName.isNotEmpty
              ? '${adminName}_$baseFileName.png'
              : '$baseFileName.png';
          final file = File(fileName);

          await file.writeAsBytes(pngBytes);
          return file.path;
        } catch (e2) {
          print('Failed to save to current directory: $e2');
          throw Exception('Failed to save PNG file: $e2');
        }
      }
    }
  }

  static Future<Uint8List> generateMemorialPdf({
    required String capsuleName,
    required String qrData,
    String? logoUrl,
  }) async {
    // Load background and logo images
    final bgBytes = await rootBundle.load('assets/velatorio.png');
    final bgImage = pw.MemoryImage(bgBytes.buffer.asUint8List());

    pw.MemoryImage? logoImage;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(logoUrl));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {}
    }
    // Fallback to asset if remote not available
    logoImage ??= pw.MemoryImage(
        (await rootBundle.load('assets/logo.png')).buffer.asUint8List());

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Stack(
            children: [
              // Background image
              pw.Positioned.fill(
                child: pw.Image(bgImage, fit: pw.BoxFit.cover),
              ),
              // Foreground content
              pw.Positioned.fill(
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      // Header
                      pw.Column(children: [
                        pw.SizedBox(height: 40),
                        pw.Text(
                          capsuleName,
                          style: pw.TextStyle(
                            fontSize: 40,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ]),
                      // Message left, QR code right centered
                      pw.Center(
                        child: pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Cherish a memory',
                                  style: pw.TextStyle(
                                    fontSize: 30,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.black,
                                  ),
                                ),
                                pw.SizedBox(height: 10),
                                pw.Container(
                                  width: 250,
                                  child: pw.Text(
                                    'Scan this QR code and leave your message in the memorial. Your contribution will be part of a digital tribute that the family will cherish forever.',
                                    style: pw.TextStyle(
                                      fontSize: 18,
                                      color: PdfColors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(width: 40),
                            pw.BarcodeWidget(
                              barcode: pw.Barcode.qrCode(),
                              data: qrData,
                              width: 200,
                              height: 200,
                            ),
                          ],
                        ),
                      ),
                      // Footer logo
                      pw.Column(children: [
                        pw.Image(logoImage!,
                            width: 120, height: 120, fit: pw.BoxFit.contain),
                        pw.SizedBox(height: 20),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<String> downloadMemorialPdf({
    required String capsuleName,
    required String qrData,
    String? logoUrl,
  }) async {
    final pdfBytes = await generateMemorialPdf(
      capsuleName: capsuleName,
      qrData: qrData,
      logoUrl: logoUrl,
    );

    final sanitizedName = capsuleName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final fileName =
        'Memorial_${sanitizedName.isNotEmpty ? sanitizedName : 'capsule'}.pdf';

    if (kIsWeb) {
      // Trigger browser download
      final blob = html.Blob([pdfBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      return 'Downloaded: $fileName';
    } else {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pdfBytes);
        return file.path;
      } catch (e) {
        // Fallback to current directory
        final file = File(fileName);
        await file.writeAsBytes(pdfBytes);
        return file.path;
      }
    }
  }
}
