import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'settings_service.dart';

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
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Stack(
          children: [
            // Original image as background
            pw.Positioned.fill(
              child: pw.Image(
                pdfImage,
                fit: pw.BoxFit.contain,
              ),
            ),
            // Logo overlay on top right
            if (logoImage != null)
              pw.Positioned(
                top: 20,
                right: 20,
                child: pw.Container(
                  padding: pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey300, width: 1),
                  ),
                  child: pw.Image(
                    logoImage,
                    width: 80,
                    height: 40,
                    fit: pw.BoxFit.contain,
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
      // Resize logo to appropriate size (80x40 pixels)
      final resizedLogo = img.copyResize(
        logoImage,
        width: 80,
        height: 40,
        interpolation: img.Interpolation.linear,
      );

      // Calculate position (top right corner)
      final int x =
          resultImage.width - resizedLogo.width - 20; // 20px from right edge
      final int y = 20; // 20px from top

      // Draw white background rectangle
      img.fillRect(
        resultImage,
        x1: x - 8,
        y1: y - 8,
        x2: x + resizedLogo.width + 8,
        y2: y + resizedLogo.height + 8,
        color: img.ColorRgb8(255, 255, 255),
      );

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
  }) async {
    final pdfBytes = await addLogoToPdf(
      language: language,
      logoUrl: logoUrl,
    );

    try {
      // Try to get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = language == 'es' ? 'Folleto_ES.pdf' : 'Leaflet_EN.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      print('Failed to get application documents directory: $e');

      try {
        // Fallback to current directory
        final fileName = language == 'es' ? 'Folleto_ES.pdf' : 'Leaflet_EN.pdf';
        final file = File(fileName);

        await file.writeAsBytes(pdfBytes);
        return file.path;
      } catch (e2) {
        print('Failed to save to current directory: $e2');
        throw Exception('Failed to save PDF file: $e2');
      }
    }
  }

  // Download PNG to device
  static Future<String> downloadPng({
    required String language,
    String? logoUrl,
  }) async {
    final pngBytes = await addLogoToPng(
      language: language,
      logoUrl: logoUrl,
    );

    try {
      // Try to get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = language == 'es' ? 'Folleto_ES.png' : 'Leaflet_EN.png';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(pngBytes);
      return file.path;
    } catch (e) {
      print('Failed to get application documents directory: $e');

      try {
        // Fallback to current directory
        final fileName = language == 'es' ? 'Folleto_ES.png' : 'Leaflet_EN.png';
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
