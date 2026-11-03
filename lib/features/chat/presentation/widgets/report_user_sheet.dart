import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../../domain/entities/submit_report_result.dart';
import '../providers/chat_providers.dart';

const _maxReportImages = 5;

/// Reachable from a chat thread's AppBar or a match's profile screen.
/// Submits straight to the admin review queue (reviewed from the c2c-admin
/// panel's Reports module, not in this app).
Future<void> showReportUserSheet(
  BuildContext context,
  String reportedUserId,
  String reportedUserName,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ReportUserSheet(
      reportedUserId: reportedUserId,
      reportedUserName: reportedUserName,
    ),
  );
}

class ReportUserSheet extends ConsumerStatefulWidget {
  const ReportUserSheet({
    super.key,
    required this.reportedUserId,
    required this.reportedUserName,
  });

  final String reportedUserId;
  final String reportedUserName;

  @override
  ConsumerState<ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends ConsumerState<ReportUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _detailsController = TextEditingController();
  final _images = <XFile>[];
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = _maxReportImages - _images.length;
    if (remaining <= 0) return;
    final picked = await ImagePicker().pickMultiImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked.isEmpty || !mounted) return;
    setState(() => _images.addAll(picked.take(remaining)));
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final imageUrls = <String>[];
      for (final image in _images) {
        imageUrls.add(
          await ref.read(uploadReportImageProvider)(File(image.path)),
        );
      }
      if (!mounted) return;

      final result = await ref.read(submitReportProvider)(
        widget.reportedUserId,
        reason: _reasonController.text.trim(),
        details: _detailsController.text.trim(),
        imageUrls: imageUrls,
      );
      if (!mounted) return;
      if (result == SubmitReportResult.ok) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.reportUserSuccess)));
        return;
      }
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.reportUserError)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.reportUserError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.reportUserTitle(widget.reportedUserName),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _reasonController,
              label: '${l10n.reportUserReasonLabel} *',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.reportUserErrorReasonRequired
                  : null,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _detailsController,
              label: '${l10n.reportUserDetailsLabel} *',
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.reportUserErrorDetailsRequired
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.reportUserImagesLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (_images.length < _maxReportImages)
                  TextButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 18,
                    ),
                    label: Text(l10n.reportUserAddImage),
                  ),
              ],
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_images[index].path),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(index)),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppColors.destructive,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryGradientButton(
              label: l10n.reportUserSubmit,
              loading: _submitting,
              onPressed: () => _submit(l10n),
            ),
          ],
        ),
      ),
    );
  }
}
