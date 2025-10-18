import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:pdfx/pdfx.dart';

/// Project spreadLee

enum DocumentType {
  policyEnglish(docPath: "assets/pdfs/en_privacy.pdf", label: "Privacy Policy"),
  policyArabic(docPath: "assets/pdfs/ar_privacy.pdf", label: "سياسة الخصوصية"),
  termsEnglish(docPath: "assets/pdfs/en_terms.pdf", label: "Terms and Conditions"),
  termsArabic(docPath: "assets/pdfs/ar_terms.pdf", label: "الشروط والاحكام");

  final String docPath;
  final String label;

  const DocumentType({required this.docPath, required this.label});
}

class PolicyAndTerms extends StatefulWidget {
  const PolicyAndTerms({super.key, required this.documentType});

  final DocumentType documentType;

  @override
  State<PolicyAndTerms> createState() => _PolicyAndTermsState();
}

class _PolicyAndTermsState extends State<PolicyAndTerms> {
  // late final PdfController controller;
  int totalPageCount = 0;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    // controller = PdfController(document: PdfDocument.openAsset(widget.documentType.docPath));
  }

  @override
  void dispose() {
    // controller.dispose();
    super.dispose();
  }

  void _goToPreviousPage() {
    if (currentPage > 1) {
      HapticFeedback.mediumImpact();
      // controller.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.linear);
    }
  }

  void _goToNextPage() {
    if (currentPage < totalPageCount) {
      HapticFeedback.mediumImpact();
      // controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.linear);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(widget.documentType.label, style: const TextStyle(color: Colors.black)),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: currentPage > 1 ? _goToPreviousPage : null,
            icon: const Icon(Icons.arrow_circle_up, size: 40),
          ),
          IconButton(
            onPressed: currentPage < totalPageCount ? _goToNextPage : null,
            icon: const Icon(Icons.arrow_circle_down, size: 40),
          ),
        ],
      ),
      body: Container(),
      // body: PdfView(
      //   controller: controller,
      //   scrollDirection: Axis.vertical,
      //   pageSnapping: false,
      //   onDocumentLoaded: (document) => setState(() => totalPageCount = document.pagesCount),
      //   onPageChanged: (page) => setState(() => currentPage = page),
      // ),
    );
  }
}
