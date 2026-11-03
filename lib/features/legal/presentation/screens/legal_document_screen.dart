import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../roles/presentation/providers/roles_providers.dart';
import '../../legal.dart';

/// Reader for a legal document (Privacy Policy or Terms & Conditions), open to
/// every signed-in user. The super admin — and only the super admin — gets an
/// edit action in the app bar that opens [_LegalDocumentEditor].
class LegalDocumentScreen extends ConsumerWidget {
  const LegalDocumentScreen({super.key, required this.kind});

  final LegalDocumentKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final docAsync = ref.watch(legalDocumentProvider(kind));
    final isSuperAdmin = ref.watch(isSuperAdminProvider).valueOrNull ?? false;

    final fallbackTitle = kind == LegalDocumentKind.privacy
        ? l10n.legalPrivacyTitle
        : l10n.legalTermsTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          docAsync.valueOrNull?.title.isNotEmpty == true
              ? docAsync.value!.title
              : fallbackTitle,
        ),
        actions: [
          if (isSuperAdmin && docAsync.hasValue)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.legalEditAction,
              onPressed: () async {
                final saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => _LegalDocumentEditor(
                      kind: kind,
                      initial: docAsync.value,
                      fallbackTitle: fallbackTitle,
                    ),
                  ),
                );
                if (saved == true) ref.invalidate(legalDocumentProvider(kind));
              },
            ),
        ],
      ),
      body: SafeArea(
        child: docAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.legalLoadError)),
          data: (doc) {
            if (doc == null || doc.body.trim().isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.legalEmpty,
                    style: const TextStyle(color: AppColors.mutedForeground),
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text(
                doc.body,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LegalDocumentEditor extends ConsumerStatefulWidget {
  const _LegalDocumentEditor({
    required this.kind,
    required this.initial,
    required this.fallbackTitle,
  });

  final LegalDocumentKind kind;
  final LegalDocument? initial;
  final String fallbackTitle;

  @override
  ConsumerState<_LegalDocumentEditor> createState() =>
      _LegalDocumentEditorState();
}

class _LegalDocumentEditorState extends ConsumerState<_LegalDocumentEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final title = widget.initial?.title;
    _titleController = TextEditingController(
      text: (title == null || title.isEmpty) ? widget.fallbackTitle : title,
    );
    _bodyController = TextEditingController(text: widget.initial?.body ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l10n) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(legalRepositoryProvider)
          .saveDocument(
            widget.kind,
            _titleController.text.trim(),
            _bodyController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on LegalEditDenied {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l10n.legalEditDenied;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l10n.legalSaveError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.legalEditAction),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(l10n),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.actionSave),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.legalTitleLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                minLines: 12,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: l10n.legalBodyLabel,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.destructive,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
