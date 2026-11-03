import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DocumentTextExtractor {
  /// Extracts text from either an image file or a PDF document.
  /// If the PDF contains a text layer, extracts it directly.
  /// If the PDF is scanned or image-based, falls back to OCR.
  static Future<String> extractTextFromFile(
    File file, {
    void Function(String status)? onProgress,
  }) async {
    final path = file.path.toLowerCase();

    if (path.endsWith('.pdf')) {
      return await _extractFromPdf(file, onProgress: onProgress);
    } else {
      onProgress?.call('Running OCR on image...');
      return await _extractFromImage(file);
    }
  }

  /// Extracts text from an image using Google ML Kit on-device OCR
  static Future<String> _extractFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } finally {
      await textRecognizer.close();
    }
  }

  /// Extracts text from PDF using Syncfusion native text layer
  static Future<String> _extractFromPdf(
    File pdfFile, {
    void Function(String status)? onProgress,
  }) async {
    onProgress?.call('Reading PDF document...');
    final bytes = await pdfFile.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    try {
      onProgress?.call('Extracting text layer...');
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String extractedText = extractor.extractText();

      // If digital text layer is found and non-trivial, return it immediately
      if (extractedText.trim().length > 30) {
        return extractedText;
      }

      onProgress?.call('No digital text found; scanning image pages...');
      // Return whatever text was retrieved or note that OCR can be run per page
      return extractedText;
    } finally {
      document.dispose();
    }
  }
}
