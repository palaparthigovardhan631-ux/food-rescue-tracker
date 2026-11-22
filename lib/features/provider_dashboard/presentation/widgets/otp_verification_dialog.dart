import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../receiver_dashboard/data/models/claim_model.dart';
import '../controllers/provider_inventory_controller.dart';

class OtpVerificationDialog extends ConsumerStatefulWidget {
  final ClaimModel claim;

  const OtpVerificationDialog({super.key, required this.claim});

  @override
  ConsumerState<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends ConsumerState<OtpVerificationDialog> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showQrScanner = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp([String? code]) async {
    final otp = code ?? _otpController.text.trim();
    if (otp.length < 4) {
      setState(() => _errorMessage = "Please enter 4-digit OTP.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(providerFoodRepositoryProvider);
      final verified = await repo.verifyAndCompleteHandover(
        claimId: widget.claim.id,
        enteredOtp: otp,
      );

      if (verified && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('🎉 Handover confirmed! Impact stats updated.'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showQrScanner) {
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 380,
          child: Column(
            children: [
              AppBar(
                title: const Text('Scan Recipient QR', style: TextStyle(fontSize: 16)),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _showQrScanner = false),
                ),
              ),
              Expanded(
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final rawValue = barcode.rawValue;
                      if (rawValue != null && rawValue.isNotEmpty) {
                        // QR format: RESCUE_CLAIM_{claimId}_{otp} or direct OTP
                        String otp = rawValue;
                        if (rawValue.contains('_')) {
                          otp = rawValue.split('_').last;
                        }
                        setState(() => _showQrScanner = false);
                        _verifyOtp(otp);
                        break;
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('Handover Verification', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recipient: ${widget.claim.recipientName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Claiming: ${widget.claim.claimedQuantity.value} ${widget.claim.claimedQuantity.unit} of ${widget.claim.foodTitle}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const Divider(height: 24),
            const Text(
              'Ask recipient for their 4-digit pickup code or scan their QR code:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                letterSpacing: 14,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '0000',
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() => _showQrScanner = true),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Or Scan QR Code'),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _verifyOtp(),
          child: _isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Confirm Handover'),
        ),
      ],
    );
  }
}
