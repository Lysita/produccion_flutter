import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product_item.dart';

class ReportGeneratorService {
  static Future<File?> generateReportImage({
    required String operatorName,
    required DateTime reportDate,
    required double hoursWorked,
    required int rotulos,
    required List<ProductItem> productList,
    required int totalUnits,
    required double estimatedHours,
  }) async {
    try {
      const double width = 1080;
      const double rowHeight = 76;
      const double headerHeight = 310;
      const double footerHeight = 180;
      const double leftMargin = 60;
      const double rightMargin = 1020;

      final activeItems = productList.where((p) => p.quantity > 0).toList();
      final activeCount = activeItems.isEmpty ? 1 : activeItems.length;

      const double tableHeaderHeight = 60;
      final double tableRowsHeight = activeCount * rowHeight;
      final double height = headerHeight + tableHeaderHeight + tableRowsHeight + footerHeight;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

      // White background
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = Colors.white);

      final blackPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;

      final linePaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final boxBgPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final boxBorderPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // Header Text
      _drawText(
        canvas: canvas,
        text: "CASA TADIELLO",
        x: width / 2,
        y: 55,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        align: TextAlign.center,
      );

      _drawText(
        canvas: canvas,
        text: "BOLETA DE PRODUCCIÓN",
        x: width / 2,
        y: 92,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        align: TextAlign.center,
      );

      // Header Divider
      canvas.drawLine(const Offset(leftMargin, 115), const Offset(rightMargin, 115), linePaint);

      // Metadata
      final dateStr = DateFormat("dd/MM/yyyy HH:mm").format(reportDate);
      double metaY = 160;

      _drawText(
        canvas: canvas,
        text: "OPERADOR: ${operatorName.toUpperCase()}",
        x: leftMargin,
        y: metaY,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      );

      metaY += 40;
      _drawText(
        canvas: canvas,
        text: "FECHA: $dateStr",
        x: leftMargin,
        y: metaY,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      );

      metaY += 44;
      _drawText(
        canvas: canvas,
        text: "HORAS TRABAJADAS:",
        x: leftMargin,
        y: metaY,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      );
      final hoursStr = (hoursWorked < 0 ? 0 : hoursWorked).toStringAsFixed(2);
      _drawValueBox(canvas, hoursStr, rightMargin, metaY - 7, boxBgPaint, boxBorderPaint);

      metaY += 48;
      _drawText(
        canvas: canvas,
        text: "ROTULOS:",
        x: leftMargin,
        y: metaY,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      );
      _drawValueBox(canvas, rotulos.toString(), rightMargin, metaY - 7, boxBgPaint, boxBorderPaint);

      // Metadata Divider
      linePaint.strokeWidth = 1.5;
      canvas.drawLine(Offset(leftMargin, metaY + 22), Offset(rightMargin, metaY + 22), linePaint);

      // Table Header
      double currentY = metaY + 62;
      _drawText(
        canvas: canvas,
        text: "PRODUCTO",
        x: leftMargin,
        y: currentY,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      );

      _drawText(
        canvas: canvas,
        text: "CANTIDAD",
        x: rightMargin,
        y: currentY,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        align: TextAlign.right,
      );

      currentY += 15;
      linePaint.strokeWidth = 2.0;
      canvas.drawLine(Offset(leftMargin, currentY), Offset(rightMargin, currentY), linePaint);

      // Table Rows
      currentY += 42;

      if (activeItems.isEmpty) {
        _drawText(
          canvas: canvas,
          text: "Sin producción registrada",
          x: leftMargin,
          y: currentY,
          fontSize: 22,
          fontWeight: FontWeight.normal,
        );
        currentY += rowHeight;
      } else {
        for (var item in activeItems) {
          _drawText(
            canvas: canvas,
            text: item.name,
            x: leftMargin,
            y: currentY,
            fontSize: 22,
            fontWeight: FontWeight.normal,
            maxWidth: 600,
          );

          _drawValueBox(canvas, item.quantity.toString(), rightMargin, currentY - 7, boxBgPaint, boxBorderPaint);
          currentY += rowHeight;
        }
      }

      // Footer Divider
      canvas.drawLine(Offset(leftMargin, currentY - 10), Offset(rightMargin, currentY - 10), linePaint);

      currentY += 30;
      _drawText(
        canvas: canvas,
        text: "TOTAL UNIDADES:",
        x: leftMargin,
        y: currentY,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      );
      _drawValueBox(canvas, totalUnits.toString(), rightMargin, currentY - 7, boxBgPaint, boxBorderPaint);

      currentY += 48;
      _drawText(
        canvas: canvas,
        text: "HORAS RENDIMIENTO:",
        x: leftMargin,
        y: currentY,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      );
      _drawValueBox(canvas, estimatedHours.toStringAsFixed(2), rightMargin, currentY - 7, boxBgPaint, boxBorderPaint);

      final picture = recorder.endRecording();
      final image = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/boleta_produccion_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return file;
    } catch (e) {
      debugPrint("Error generating report image: $e");
      return null;
    }
  }

  static void _drawText({
    required Canvas canvas,
    required String text,
    required double x,
    required double y,
    required double fontSize,
    required FontWeight fontWeight,
    TextAlign align = TextAlign.left,
    double? maxWidth,
  }) {
    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: 'sans-serif',
    );

    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
      ellipsis: maxWidth != null ? '...' : null,
    );

    textPainter.layout(maxWidth: maxWidth ?? double.infinity);

    double drawX = x;
    if (align == TextAlign.center) {
      drawX = x - (textPainter.width / 2);
    } else if (align == TextAlign.right) {
      drawX = x - textPainter.width;
    }

    textPainter.paint(canvas, Offset(drawX, y - (fontSize * 0.8)));
  }

  static void _drawValueBox(
    Canvas canvas,
    String text,
    double rightX,
    double centerY,
    Paint bgPaint,
    Paint borderPaint,
  ) {
    final textStyle = const TextStyle(
      color: Colors.black,
      fontSize: 24,
      fontWeight: FontWeight.bold,
      fontFamily: 'sans-serif',
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    const double boxPaddingH = 22;
    const double boxHeight = 44;
    final double boxWidth = (textPainter.width + (boxPaddingH * 2)).clamp(110.0, double.infinity);

    final double left = rightX - boxWidth;
    final double top = centerY - (boxHeight / 2);
    final double right = rightX;
    final double bottom = centerY + (boxHeight / 2);

    final rect = RRect.fromLTRBR(left, top, right, bottom, const Radius.circular(6));

    canvas.drawRRect(rect, bgPaint);
    canvas.drawRRect(rect, borderPaint);

    final double textX = left + (boxWidth / 2) - (textPainter.width / 2);
    final double textY = centerY - (textPainter.height / 2);

    textPainter.paint(canvas, Offset(textX, textY));
  }
}
