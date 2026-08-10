import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../../../l10n/app_localizations.dart';
import '../models/pregnancy_model.dart';
import '../models/weight_entry_model.dart';
import '../models/kick_session_model.dart';
import '../models/contraction_model.dart';

class PregnancyReportGenerator {
  static Future<void> generateAndShare(
    BuildContext context, {
    required Pregnancy pregnancy,
    required List<WeightEntry> weights,
    required List<KickSession> kicks,
    required List<ContractionEntry> contractions,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final fontItalic = await PdfGoogleFonts.nunitoItalic();

    final babyName = pregnancy.babyName ?? l10n.preg_baby_default_name;

    // Feature colors in PDF format
    const kickColor = PdfColor.fromInt(0xFFE8909C); // Menu Kick Counter Color
    const contractionColor = PdfColor.fromInt(0xFFF4A261); // Menu Contraction Timer Color
    const weightColor = PdfColor.fromInt(0xFF5FBDAC); // Menu Weight Color
    const primaryPurple = PdfColor.fromInt(0xFF8E76FF); // App Primary Purple

    // Statistics calculation
    final totalKicks = kicks.fold<int>(0, (sum, s) => sum + s.count);
    final avgKicks = kicks.isNotEmpty
        ? (totalKicks / kicks.length).toStringAsFixed(1)
        : '0';

    final totalContractions = contractions.length;
    final avgContractionSecs = contractions.isNotEmpty
        ? (contractions.fold<int>(0, (sum, c) => sum + c.duration.inSeconds) /
                contractions.length)
            .round()
        : 0;

    final initialWeight = pregnancy.initialWeight;
    final finalWeight = weights.isNotEmpty ? weights.first.weightValue : initialWeight;
    final totalGain = (finalWeight != null && initialWeight != null)
        ? finalWeight - initialWeight
        : 0.0;

    final end = pregnancy.birthDate ?? pregnancy.updatedAt;
    final totalDays = end.difference(pregnancy.lastPeriodDate).inDays;
    final durationStr = pregnancy.getDuration(
      l10n.unit_weeks_short,
      l10n.unit_days_short,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
          italic: fontItalic,
        ),
        build: (pw.Context context) => [
          // ── Header ─────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PREGNANCY KEEPSAKE & HEALTH REPORT',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 16,
                      color: primaryPurple,
                      letterSpacing: 0.5,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Ayla Journey Memory • $babyName',
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF8F4FF),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: primaryPurple, width: 1),
                ),
                child: pw.Text(
                  AppConstants.appName,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 14,
                    color: primaryPurple,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.grey300, thickness: 1),
          pw.SizedBox(height: 14),

          // ── Baby & Arrival Milestone Profile ────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFAF9FF),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFE8E5F8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      babyName,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 18,
                        color: PdfColors.black,
                      ),
                    ),
                    if (pregnancy.babyGender != null)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Text(
                          pregnancy.babyGender!.toUpperCase(),
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                            color: primaryPurple,
                          ),
                        ),
                      ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoTile('Gestational Duration', durationStr, fontBold),
                    _buildInfoTile(
                      'Arrival Date',
                      DateFormat.yMMMMd(l10n.localeName).format(end),
                      fontBold,
                    ),
                    if (pregnancy.birthWeight != null)
                      _buildInfoTile(
                        'Birth Weight',
                        '${pregnancy.birthWeight} kg',
                        fontBold,
                      ),
                    if (pregnancy.birthLength != null)
                      _buildInfoTile(
                        'Birth Length',
                        '${pregnancy.birthLength} cm',
                        fontBold,
                      ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // ── Journey Milestone Grid ──────────────────────────────
          pw.Text(
            'JOURNEY HIGHLIGHTS & MILESTONES',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 12,
              color: PdfColors.grey800,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildMetricCard(
                  title: 'Little Kicks',
                  value: '$totalKicks',
                  subtitle: '$avgKicks avg / session',
                  color: kickColor,
                  fontBold: fontBold,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildMetricCard(
                  title: 'Labor Contractions',
                  value: '$totalContractions',
                  subtitle: avgContractionSecs > 0 ? '${avgContractionSecs}s avg' : '--',
                  color: contractionColor,
                  fontBold: fontBold,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildMetricCard(
                  title: "Mom's Weight Gain",
                  value: '${totalGain > 0 ? '+' : ''}${totalGain.toStringAsFixed(1)} kg',
                  subtitle: 'Start: ${initialWeight?.toStringAsFixed(1) ?? '--'} kg',
                  color: weightColor,
                  fontBold: fontBold,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildMetricCard(
                  title: 'Days of Love',
                  value: '$totalDays',
                  subtitle: 'Total Days',
                  color: primaryPurple,
                  fontBold: fontBold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // ── Delivery Notes / Memory Message ──────────────────────
          if (pregnancy.deliveryNotes != null &&
              pregnancy.deliveryNotes!.trim().isNotEmpty) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFFFF9F5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: const PdfColor.fromInt(0xFFFFE5D0)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DELIVERY & ARRIVAL NOTES',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 10,
                      color: contractionColor,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    '"${pregnancy.deliveryNotes}"',
                    style: pw.TextStyle(
                      font: fontItalic,
                      fontSize: 11,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          // ── Kick Sessions Table ─────────────────────────────────
          if (kicks.isNotEmpty) ...[
            pw.Text(
              'KICK COUNTER LOGS (${kicks.length} Sessions)',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 12,
                color: kickColor,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: kickColor),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              data: <List<String>>[
                <String>['Session #', 'Date & Time', 'Total Kicks', 'Duration'],
                ...kicks.take(8).map((s) {
                  final durationStr = s.endTime != null
                      ? '${s.duration.inMinutes} mins'
                      : '--';
                  return [
                    '#${kicks.indexOf(s) + 1}',
                    DateFormat('MMM d, yyyy  h:mm a').format(s.startTime),
                    '${s.count} kicks',
                    durationStr,
                  ];
                }),
              ],
            ),
            if (kicks.length > 8)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                  '+ ${kicks.length - 8} more kick sessions recorded',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ),
            pw.SizedBox(height: 20),
          ],

          // ── Contraction Logs Table ──────────────────────────────
          if (contractions.isNotEmpty) ...[
            pw.Text(
              'LABOR & CONTRACTIONS SUMMARY (${contractions.length} Recorded)',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 12,
                color: contractionColor,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: contractionColor),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              data: <List<String>>[
                <String>['#', 'Start Time', 'Duration', 'Intensity'],
                ...contractions.take(8).map((c) {
                  final duration = c.endTime != null
                      ? '${c.duration.inSeconds}s'
                      : '--';
                  final intensityStr = c.intensity?.name.toUpperCase() ?? 'NORMAL';
                  return [
                    '#${contractions.indexOf(c) + 1}',
                    DateFormat('MMM d, yyyy  h:mm:ss a').format(c.startTime),
                    duration,
                    intensityStr,
                  ];
                }),
              ],
            ),
            if (contractions.length > 8)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                  '+ ${contractions.length - 8} more contractions recorded during labor',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ),
            pw.SizedBox(height: 20),
          ],

          // ── Weight Journey Log Table ────────────────────────────
          if (weights.isNotEmpty) ...[
            pw.Text(
              "MOM'S WEIGHT PROGRESSION (${weights.length} Entries)",
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 12,
                color: weightColor,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: weightColor),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              data: <List<String>>[
                <String>['Date', 'Gestational Week', 'Recorded Weight', 'Net Change'],
                ...weights.take(8).map((w) {
                  final days = w.date.difference(pregnancy.lastPeriodDate).inDays;
                  final week = (days / 7).floor() + 1;
                  final diffFromStart = initialWeight != null
                      ? w.weightValue - initialWeight
                      : 0.0;
                  final changeStr = initialWeight != null
                      ? '${diffFromStart >= 0 ? '+' : ''}${diffFromStart.toStringAsFixed(1)} kg'
                      : '--';
                  return [
                    DateFormat.yMMMd().format(w.date),
                    'Week $week',
                    '${w.weightValue.toStringAsFixed(1)} kg',
                    changeStr,
                  ];
                }),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // ── Footer ──────────────────────────────────────────────
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated on ${DateFormat.yMMMMd().format(DateTime.now())} • Ayla Tracker',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
              pw.Text(
                'A precious keepsake for you and your little one',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );

    // Save and Share/Print
    final bytes = await pdf.save();
    final sanitizedTitle = babyName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final fileName = 'Ayla_Pregnancy_Keepsake_${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);

    if (!context.mounted) return;

    await PlatformUI.share(
      files: [XFile(file.path, mimeType: 'application/pdf')],
      subject: '$babyName - Pregnancy Keepsake Report',
    );
  }

  static pw.Widget _buildInfoTile(String label, String value, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 12,
            color: PdfColors.grey900,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required PdfColor color,
    required pw.Font fontBold,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: color, width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 9,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 14,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            subtitle,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }
}
