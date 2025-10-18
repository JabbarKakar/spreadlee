import 'package:flutter/material.dart';
// import 'package:pdfx/pdfx.dart';
import 'dart:io';
import 'dart:typed_data';

class ViewPdf extends StatefulWidget {
  const ViewPdf({
    super.key,
    this.messageDocument,
  });

  final String? messageDocument;

  @override
  State<ViewPdf> createState() => _ViewPdfState();
}

class _ViewPdfState extends State<ViewPdf> {
  // PdfController? pdfController;
  bool isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Only set initial state here, actual loading will happen in didChangeDependencies
    if (widget.messageDocument == null || widget.messageDocument!.isEmpty) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.messageDocument != null &&
        widget.messageDocument!.isNotEmpty &&
        isLoading) {
      // _loadPdf();
    }
  }

  // Future<void> _loadPdf() async {
  //   if (!mounted) return;
  //
  //   try {
  //     final docPath = widget.messageDocument!;
  //     if (docPath.startsWith('http')) {
  //       // Download from network
  //       final uri = Uri.parse(docPath);
  //       final response = await HttpClient().getUrl(uri);
  //       final httpResponse = await response.close();
  //       final bytes = await httpResponse.fold<Uint8List>(
  //         Uint8List(0),
  //         (previous, element) => Uint8List.fromList([...previous, ...element]),
  //       );
  //       if (!mounted) return;
  //       setState(() {
  //         pdfController = PdfController(
  //           document: PdfDocument.openData(bytes),
  //         );
  //         isLoading = false;
  //         _errorMessage = null;
  //       });
  //     } else {
  //       // Open from local file
  //       if (!mounted) return;
  //       setState(() {
  //         pdfController = PdfController(
  //           document: PdfDocument.openFile(docPath),
  //         );
  //         isLoading = false;
  //         _errorMessage = null;
  //       });
  //     }
  //   } catch (e) {
  //     if (!mounted) return;
  //     setState(() {
  //       isLoading = false;
  //       _errorMessage = 'Error loading PDF: $e';
  //     });
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Error loading PDF'),
  //             backgroundColor: Colors.red,
  //           ),
  //         );
  //       }
  //     });
  //   }
  // }

  @override
  void dispose() {
    // pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 24.0,
          ),
        ),
        title: Text(
          'PDF View',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.black,
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
        ),
        centerTitle: false,
        elevation: 0.0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                Expanded(
                  child: Center(
                    child: Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              // else if (widget.messageDocument != null &&
              //     widget.messageDocument!.isNotEmpty &&
              //     pdfController != null)
              //   Expanded(
              //     child: PdfView(
              //       controller: pdfController!,
              //       onDocumentLoaded: (document) {
              //         if (mounted) {
              //           setState(() {
              //             isLoading = false;
              //           });
              //         }
              //       },
              //       onDocumentError: (error) {
              //         if (mounted) {
              //           setState(() {
              //             isLoading = false;
              //             _errorMessage = 'Error loading PDF: $error';
              //           });
              //
              //           // Show error message after the widget is fully built
              //           WidgetsBinding.instance.addPostFrameCallback((_) {
              //             if (mounted) {
              //               ScaffoldMessenger.of(context).showSnackBar(
              //                 const SnackBar(
              //                   content: Text('Error loading PDF'),
              //                   backgroundColor: Colors.red,
              //                 ),
              //               );
              //             }
              //           });
              //         }
              //       },
              //       builders: PdfViewBuilders<DefaultBuilderOptions>(
              //         options: const DefaultBuilderOptions(),
              //         documentLoaderBuilder: (_) => const Center(
              //           child: CircularProgressIndicator(),
              //         ),
              //         pageLoaderBuilder: (_) => const Center(
              //           child: CircularProgressIndicator(),
              //         ),
              //         errorBuilder: (_, error) => const Center(
              //           child: Text('Error loading PDF'),
              //         ),
              //       ),
              //     ),
              //   )
              else
                Expanded(
                  child: Center(
                    child: Text(
                      'No PDF Available.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
