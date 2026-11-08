import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../data/mock_app_state.dart';
import '../../../services/receipt_pdf_service.dart';

/// Full-width "Download receipt" action shared by the order confirmation and
/// order tracking screens. Shows a spinner while the PDF is generated and
/// confirms with a SnackBar once the share sheet has the file.
class ReceiptDownloadButton extends StatefulWidget {
  const ReceiptDownloadButton({super.key, required this.order});

  final Order order;

  @override
  State<ReceiptDownloadButton> createState() => _ReceiptDownloadButtonState();
}

class _ReceiptDownloadButtonState extends State<ReceiptDownloadButton> {
  bool _loading = false;

  Future<void> _download() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await downloadReceipt(widget.order);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt ready — save or share it as a PDF.'),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: context.lunti.accent,
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(color: context.lunti.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuntiRadii.sm),
          ),
        ),
        onPressed: _loading ? null : _download,
        icon: _loading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.lunti.accent,
                ),
              )
            : const Icon(Icons.download_outlined, size: 18),
        label: const Text('Download receipt'),
      ),
    );
  }
}
