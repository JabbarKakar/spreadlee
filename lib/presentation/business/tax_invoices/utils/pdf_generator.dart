import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:spreadlee/domain/tax_invoice_model.dart';

Future<Uint8List> generateQrCodeImage(String qrData) async {
  final qrCode = QrPainter(
    data: qrData,
    version: QrVersions.auto,
    gapless: true,
  );
  final picData = await qrCode.toImageData(120);
  return picData!.buffer.asUint8List();
}

pw.Widget buildTextEn(String text, PdfColor color, double fontSize,
    {pw.Font? font, pw.FontWeight fontWeight = pw.FontWeight.normal}) {
  return pw.Text(
    text,
    style: pw.TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      font: font,
    ),
  );
}

pw.Widget buildTextAr(String text, PdfColor color, double fontSize,
    {pw.Font? font,
    required List<pw.Font> fontFallback,
    pw.FontWeight fontWeight = pw.FontWeight.normal}) {
  return pw.Text(
    text,
    textDirection: pw.TextDirection.rtl,
    style: pw.TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFallback: fontFallback,
      font: font,
    ),
  );
}

pw.Widget buildSectionHeader(String englishText, String arabicText,
    PdfColor backgroundColor, pw.Font arabicFont) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      color: backgroundColor,
      borderRadius: pw.BorderRadius.circular(5.0),
    ),
    child: pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(10.0, 2.0, 10.0, 2.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          buildTextEn(englishText, PdfColors.white, 14.0,
              fontWeight: pw.FontWeight.bold),
          buildTextAr(arabicText, PdfColors.white, 14.0,
              fontFallback: [arabicFont], fontWeight: pw.FontWeight.bold),
        ],
      ),
    ),
  );
}

Future<Uint8List> generateTaxInvoicePdf(TaxInvoiceData invoice) async {
  final qrData =
      'Invoice ID: ${invoice.invoice_id?.toString() ?? 'N/A'}\nDate: ${invoice.invoice_creation_date}';
  final qrImageData = await generateQrCodeImage(qrData);

  final pdf = pw.Document();
  final textGray = PdfColor.fromHex('#57636C');
  final dividerColor = PdfColor.fromHex('#EAECF0');
  final greenContainer = PdfColor.fromHex('#7C9587');

  final font = await rootBundle.load('assets/fonts/Hacen Tunisia.ttf');
  final arabi = pw.Font.ttf(font);
  final font1 = await rootBundle.load('assets/fonts/Hacen Tunisia Bold.ttf');
  final arabicFontBold = pw.Font.ttf(font1);

  pdf.addPage(
    pw.Page(
      theme: pw.ThemeData.withFont(
        bold: arabicFontBold,
      ),
      build: (pw.Context context) {
        return pw.Column(
          mainAxisSize: pw.MainAxisSize.max,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            buildTextEn(
                'Invoice ID: ${invoice.invoice_id?.toString() ?? 'N/A'}',
                textGray,
                14.0),
            pw.Padding(
              padding:
                  const pw.EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 5.0),
              child: buildTextEn(
                'Date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(invoice.invoice_creation_date!))}',
                textGray,
                14.0,
              ),
            ),
            pw.Divider(
              height: 1.0,
              thickness: 2.0,
              color: dividerColor,
            ),
            pw.Padding(
              padding:
                  const pw.EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 0.0),
              child: buildSectionHeader('Seller information', 'معلومات البائع',
                  greenContainer, arabi),
            ),
            buildSellerDetailsSection(arabi, invoice.seller!),
            pw.SizedBox(height: 10),
            buildSectionHeader(
                'Buyer information', 'معلومات المشتري', greenContainer, arabi),
            buildBuyerDetailsSection(arabi, invoice.buyer!),
            pw.SizedBox(height: 10),
            buildSectionHeader(
                'Product details', 'تفاصيل المنتج', greenContainer, arabi),
            pw.SizedBox(height: 5),
            buildProductTableDetailsSection(arabi, invoice),
            buildProductDetailsSection(
              arabi,
              invoice,
              invoice.vat_on_service_fee ?? 0.0,
              invoice.invoice_total ?? 0.0,
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(
                  width: 120,
                  height: 120,
                  child: pw.Image(pw.MemoryImage(qrImageData)),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

pw.Widget buildSellerDetailsSection(pw.Font arabicFont, Seller seller) {
  final textGray = PdfColor.fromHex('#57636C');
  final dividerColor = PdfColor.fromHex('#EAECF0');

  return pw.Padding(
    padding: const pw.EdgeInsetsDirectional.fromSTEB(5.0, 5.0, 5.0, 0.0),
    child: pw.Column(
      mainAxisSize: pw.MainAxisSize.max,
      children: [
        buildDetailsRow('Company Name :', ': اسم الشركة', arabicFont),
        buildTextEn(seller.companyName ?? '', textGray, 10.0),
        pw.Divider(height: 1.0, thickness: 2.0, color: dividerColor),
        buildDetailsRow('Address :', ': العنوان', arabicFont),
        buildTextEn(seller.address ?? '', textGray, 10.0),
        pw.Divider(height: 1.0, thickness: 2.0, color: dividerColor),
        buildDetailsRow('VAT Number :', ': الرقم الضريبي', arabicFont),
        buildTextEn(seller.vatNumber ?? '', textGray, 10.0),
        pw.Divider(height: 1.0, thickness: 2.0, color: dividerColor),
        buildDetailsRow(
            'Commercial Number :', ': رقم السجل التجاري', arabicFont),
        buildTextEn(seller.commercialNumber ?? '', textGray, 10.0),
        pw.Divider(height: 1.0, thickness: 2.0, color: dividerColor),
      ],
    ),
  );
}

pw.Widget buildBuyerDetailsSection(pw.Font arabicFont, Buyer buyer) {
  final textGray = PdfColor.fromHex('#57636C');
  final dividerColor = PdfColor.fromHex('#EAECF0');

  return pw.Padding(
    padding: const pw.EdgeInsetsDirectional.fromSTEB(5.0, 5.0, 5.0, 0.0),
    child: pw.Column(
      mainAxisSize: pw.MainAxisSize.max,
      children: [
        buildDetailsRow('Name :', ': اسم', arabicFont),
        buildTextEn(buyer.companyName ?? '', textGray, 10.0),
        pw.Divider(height: 1.0, thickness: 2.0, color: dividerColor),
        buildDetailsRow('Address :', ': عنوان', arabicFont),
        buildTextEn(buyer.address ?? '', textGray, 10.0),
        pw.Divider(height: 1.0, thickness: 2.0, color: dividerColor),
        buildDetailsRow('VAT Number :', ': الرقم الضريبي', arabicFont),
        buildTextEn(buyer.vatNumber?.toString() ?? '', textGray, 10.0),
        pw.Divider(height: 1.0, thickness: 2.0, color: dividerColor),
        buildDetailsRow(
            'Commercial Number :', ': رقم السجل التجاري', arabicFont),
        buildTextEn(buyer.commercialNumber ?? '', textGray, 10.0),
        pw.Divider(height: 1.0, thickness: 2.0, color: dividerColor),
      ],
    ),
  );
}

pw.Widget buildProductTableDetailsSection(
    pw.Font arabicFont, TaxInvoiceData invoice) {
  final headerColor = PdfColor.fromHex('#F3F3F3');
  final textGray = PdfColor.fromHex('#57636C');
  final dividerColor = PdfColor.fromHex('#DBDBDB');

  return pw.ClipRRect(
    horizontalRadius: 5.0,
    verticalRadius: 5.0,
    child: pw.Table(
      border:
          pw.TableBorder.symmetric(inside: pw.BorderSide(color: dividerColor)),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(5.0),
              alignment: pw.Alignment.center,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  buildTextEn("Product ", PdfColors.black, 10.0,
                      fontWeight: pw.FontWeight.bold),
                  buildTextAr("منتج", PdfColors.black, 10.0,
                      fontFallback: [arabicFont],
                      fontWeight: pw.FontWeight.bold),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(5.0),
              alignment: pw.Alignment.center,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  buildTextEn("Price ", PdfColors.black, 10.0,
                      fontWeight: pw.FontWeight.bold),
                  buildTextAr("سعر", PdfColors.black, 10.0,
                      fontFallback: [arabicFont],
                      fontWeight: pw.FontWeight.bold),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(5.0),
              alignment: pw.Alignment.center,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  buildTextEn("Quantity ", PdfColors.black, 10.0,
                      fontWeight: pw.FontWeight.bold),
                  buildTextAr("كمية", PdfColors.black, 10.0,
                      fontFallback: [arabicFont],
                      fontWeight: pw.FontWeight.bold),
                ],
              ),
            ),
          ],
        ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5.0),
              child: buildTextEn(
                invoice.invoice_description ?? 'Advertisement commission',
                textGray,
                10.0,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5.0),
              child: buildTextEn(
                invoice.formattedInvoiceAmount,
                textGray,
                10.0,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5.0),
              child: buildTextEn(
                '${invoice.quantity ?? 1}',
                textGray,
                10.0,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget buildProductDetailsSection(
    pw.Font arabicFont, TaxInvoiceData invoice, double vat, double gt) {
  final textGray = PdfColor.fromHex('#57636C');
  final dividerColor = PdfColor.fromHex('#EAECF0');

  return pw.Padding(
    padding: const pw.EdgeInsetsDirectional.fromSTEB(5.0, 5.0, 5.0, 0.0),
    child: pw.Column(
      mainAxisSize: pw.MainAxisSize.max,
      children: [
        buildDetailsRow(
            'VAT percentage :', ': نسبة ضريبة القيمة المضافة', arabicFont),
        buildTextEn(invoice.formattedVatPercentage, textGray, 10.0),
        pw.Divider(height: 1.0, thickness: 2.0, color: dividerColor),
        buildDetailsRow(
            'VAT value :', ': قيمة ضريبة القيمة المضافة', arabicFont),
        buildTextEn(invoice.formattedVatOnServiceFee, textGray, 10.0),
        pw.Divider(height: 1.0, thickness: 2.0, color: dividerColor),
        buildDetailsRow('Total without VAT :',
            ': الإجمالي بدون ضريبة القيمة المضافة', arabicFont),
        buildTextEn(invoice.formattedInvoiceAmount, textGray, 10.0),
        pw.Divider(height: 1.0, thickness: 2.0, color: dividerColor),
        buildDetailsRow('Total with VAT :',
            ': الإجمالي مع ضريبة القيمة المضافة', arabicFont),
        buildTextEn(invoice.formattedInvoiceTotal, textGray, 10.0),
        pw.Divider(height: 1.0, thickness: 2.0, color: dividerColor),
      ],
    ),
  );
}

pw.Widget buildDetailsRow(
    String englishText, String arabicText, pw.Font arabicFont) {
  englishText = englishText.replaceAll(":", '');
  arabicText = arabicText.replaceAll(":", '');
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      buildTextEn(englishText, PdfColors.black, 10.0,
          fontWeight: pw.FontWeight.bold),
      buildTextAr(arabicText, PdfColors.black, 10.0,
          fontFallback: [arabicFont], fontWeight: pw.FontWeight.bold),
    ],
  );
}
