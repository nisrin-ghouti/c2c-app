import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../../../core/widgets/filter_chip_row.dart';
import '../../../../core/widgets/inline_banner.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../../admin/domain/entities/option_list_item.dart';
import '../../../admin/domain/entities/option_list_type.dart';
import '../../../admin/presentation/providers/admin_providers.dart';
import '../../domain/entities/campus_event.dart';
import '../../domain/entities/event_draft.dart';
import '../../domain/entities/event_kind.dart';
import '../../domain/entities/event_session_draft.dart';
import '../../domain/entities/event_visibility.dart';
import '../../domain/entities/event_visibility_target.dart';
import '../controllers/event_form_controller.dart';
import '../providers/events_providers.dart';

final _eventCategoryOptionsProvider =
    FutureProvider.autoDispose<List<OptionListItem>>((ref) {
      return ref
          .watch(adminRepositoryProvider)
          .listOptions(OptionListType.eventCategory);
    });

final _facultyOptionsProvider =
    FutureProvider.autoDispose<List<OptionListItem>>((ref) {
      return ref
          .watch(adminRepositoryProvider)
          .listOptions(OptionListType.faculty);
    });

/// One session row's editable state in the Program sub-form — a plain data
/// holder (not a widget), kept in a `List` on the screen's State so rows
/// can be added/removed freely.
class _SessionFormRow {
  _SessionFormRow({String? title, this.startsAt, this.endsAt, String? location})
    : titleController = TextEditingController(text: title ?? ''),
      locationController = TextEditingController(text: location ?? '');

  final TextEditingController titleController;
  final TextEditingController locationController;
  DateTime? startsAt;
  DateTime? endsAt;

  void dispose() {
    titleController.dispose();
    locationController.dispose();
  }
}

/// Host + admin create/edit form. `event == null` is create mode; otherwise
/// the form is pre-filled and submits go through `update_event_or_program`.
class EventCreateEditScreen extends ConsumerStatefulWidget {
  const EventCreateEditScreen({super.key, this.event});

  final CampusEvent? event;

  @override
  ConsumerState<EventCreateEditScreen> createState() =>
      _EventCreateEditScreenState();
}

class _EventCreateEditScreenState extends ConsumerState<EventCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _pointsController;
  String? _imageUrl;
  bool _uploadingImage = false;
  late final TextEditingController _organizerController;
  late final TextEditingController _capacityController;
  late final TextEditingController _groupTagsController;

  DateTime? _startsAt;
  DateTime? _endsAt;
  String? _category;
  late final TextEditingController _organizerDescriptionController;
  late final TextEditingController _externalLinkController;
  late EventVisibility _visibility;
  late EventKind _eventKind;
  final Set<String> _selectedFaculties = {};
  final List<_SessionFormRow> _sessions = [];

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _locationController = TextEditingController(text: event?.location ?? '');
    _pointsController = TextEditingController(
      text: (event?.points ?? 20).toString(),
    );
    _imageUrl = event?.imageUrl;
    _organizerController = TextEditingController(
      text: event?.organizerName ?? '',
    );
    _capacityController = TextEditingController(
      text: event?.capacity?.toString() ?? '',
    );
    _groupTagsController = TextEditingController();
    _startsAt = event?.startsAt;
    _endsAt = event?.endsAt;
    _category = event?.category;
    _organizerDescriptionController = TextEditingController(
      text: event?.organizerDescription ?? '',
    );
    _externalLinkController = TextEditingController(
      text: event?.externalLink ?? '',
    );
    _visibility = event?.visibility ?? EventVisibility.everyone;
    _eventKind = event?.eventKind ?? EventKind.single;

    if (event != null && event.eventKind == EventKind.program) {
      Future.microtask(() async {
        final sessions = await ref.read(getEventSessionsProvider)(event.id);
        if (!mounted) return;
        setState(() {
          _sessions.addAll(
            sessions.map(
              (s) => _SessionFormRow(
                title: s.title,
                startsAt: s.startsAt,
                endsAt: s.endsAt,
                location: s.location,
              ),
            ),
          );
        });
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _organizerDescriptionController.dispose();
    _externalLinkController.dispose();
    _locationController.dispose();
    _pointsController.dispose();
    _organizerController.dispose();
    _capacityController.dispose();
    _groupTagsController.dispose();
    for (final session in _sessions) {
      session.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: initial != null
          ? TimeOfDay(hour: initial.hour, minute: initial.minute)
          : TimeOfDay.now(),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    final d =
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d · $t';
  }

  void _addSession() => setState(() => _sessions.add(_SessionFormRow()));

  void _removeSession(int index) => setState(() {
    _sessions[index].dispose();
    _sessions.removeAt(index);
  });

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    if (_startsAt == null || _endsAt == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.eventFormErrorDatesRequired)));
      return;
    }
    if (!_endsAt!.isAfter(_startsAt!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventFormErrorEndBeforeStart)),
      );
      return;
    }

    List<EventSessionDraft> sessionDrafts = const [];
    if (_eventKind == EventKind.program) {
      if (_sessions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.eventFormErrorSessionsRequired)),
        );
        return;
      }
      for (final row in _sessions) {
        if (row.titleController.text.trim().isEmpty ||
            row.startsAt == null ||
            row.endsAt == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.eventFormErrorSessionIncomplete)),
          );
          return;
        }
        if (!row.endsAt!.isAfter(row.startsAt!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.eventFormErrorEndBeforeStart)),
          );
          return;
        }
      }
      sessionDrafts = _sessions
          .map(
            (row) => EventSessionDraft(
              title: row.titleController.text.trim(),
              startsAt: row.startsAt!,
              endsAt: row.endsAt!,
              location: row.locationController.text.trim().isEmpty
                  ? null
                  : row.locationController.text.trim(),
            ),
          )
          .toList();
    }

    final visibilityTargets = <EventVisibilityTarget>[
      if (_visibility == EventVisibility.specificFaculties)
        ..._selectedFaculties.map(
          (f) => EventVisibilityTarget(type: 'faculty', value: f),
        ),
      if (_visibility == EventVisibility.specificGroups)
        ..._groupTagsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .map((t) => EventVisibilityTarget(type: 'group_tag', value: t)),
    ];

    final draft = EventDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      category: _category,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      startsAt: _startsAt!,
      endsAt: _endsAt!,
      points: int.tryParse(_pointsController.text.trim()) ?? 20,
      imageUrl: _imageUrl,
      organizerDescription: _organizerDescriptionController.text.trim().isEmpty
          ? null
          : _organizerDescriptionController.text.trim(),
      externalLink: _externalLinkController.text.trim().isEmpty
          ? null
          : _externalLinkController.text.trim(),
      organizerName: _organizerController.text.trim().isEmpty
          ? null
          : _organizerController.text.trim(),
      visibility: _visibility,
      capacity: int.tryParse(_capacityController.text.trim()),
      visibilityTargets: visibilityTargets,
      eventKind: _eventKind,
      sessions: sessionDrafts,
    );

    final controller = ref.read(eventFormControllerProvider.notifier);
    final ok = _isEdit
        ? await controller.submitUpdate(
            widget.event!.id,
            draft,
            l10n.eventFormErrorGeneric,
          )
        : await controller.submitCreate(draft, l10n.eventFormErrorGeneric);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickImage(AppLocalizations l10n) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingImage = true);
    try {
      final url = await ref.read(uploadEventImageProvider)(File(picked.path));
      if (!mounted) return;
      setState(() => _imageUrl = url);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profilePhotoUploadError)));
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formState = ref.watch(eventFormControllerProvider);
    final categoryOptionsAsync = ref.watch(_eventCategoryOptionsProvider);
    final facultyOptionsAsync = ref.watch(_facultyOptionsProvider);

    final visibilityLabels = {
      l10n.eventVisibilityEveryone: EventVisibility.everyone,
      l10n.eventVisibilityOnlyMe: EventVisibility.onlyMe,
      l10n.eventVisibilitySpecificFaculties: EventVisibility.specificFaculties,
      l10n.eventVisibilitySpecificGroups: EventVisibility.specificGroups,
    };
    final visibilityLabelFor = {
      for (final e in visibilityLabels.entries) e.value: e.key,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? l10n.eventFormEditTitle : l10n.eventFormCreateTitle,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SegmentedToggle<EventKind>(
                options: [
                  SegmentOption(
                    value: EventKind.single,
                    label: l10n.eventTypeSingle,
                  ),
                  SegmentOption(
                    value: EventKind.program,
                    label: l10n.eventTypeProgram,
                  ),
                ],
                value: _eventKind,
                onChanged: (v) => setState(() => _eventKind = v),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _titleController,
                label: l10n.eventFormTitleLabel,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.eventFormErrorTitleRequired
                    : null,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _descriptionController,
                label: l10n.eventFormDescriptionLabel,
              ),
              const SizedBox(height: 12),
              // Category is dropdown-only per spec — the list is curated by
              // admins in Option Lists, so free text would let a typo create a
              // category that filters can never match.
              categoryOptionsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => Text(
                  l10n.profileOptionsLoadError,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
                data: (options) {
                  final active = options.where((o) => o.active).toList();
                  final labels = active.map((o) => o.label).toList();
                  final language = Localizations.localeOf(context).languageCode;
                  if (labels.isEmpty) {
                    return Text(
                      l10n.profileOptionsEmpty,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    );
                  }
                  // A category removed from the list after this event was saved
                  // would otherwise trip the dropdown's value assertion.
                  return DropdownButtonFormField<String>(
                    initialValue: labels.contains(_category) ? _category : null,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.eventFormCategoryLabel,
                    ),
                    items: active
                        .map(
                          (o) => DropdownMenuItem(
                            value: o.label,
                            child: Text(o.labelFor(language)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _category = v),
                  );
                },
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _locationController,
                label: l10n.eventFormLocationLabel,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await _pickDateTime(_startsAt);
                        if (picked != null) setState(() => _startsAt = picked);
                      },
                      child: Text(
                        _startsAt == null
                            ? l10n.eventFormStartLabel
                            : '${l10n.eventFormStartLabel}: ${_formatDateTime(_startsAt)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await _pickDateTime(_endsAt);
                        if (picked != null) setState(() => _endsAt = picked);
                      },
                      child: Text(
                        _endsAt == null
                            ? l10n.eventFormEndLabel
                            : '${l10n.eventFormEndLabel}: ${_formatDateTime(_endsAt)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _pointsController,
                label: l10n.eventFormPointsLabel,
                keyboardType: TextInputType.number,
                forceLtr: true,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _capacityController,
                label: l10n.eventFormCapacityLabel,
                keyboardType: TextInputType.number,
                forceLtr: true,
              ),
              const SizedBox(height: 12),
              _EventImagePickerField(
                imageUrl: _imageUrl,
                uploading: _uploadingImage,
                label: l10n.eventFormImageLabel,
                onPick: () => _pickImage(l10n),
                onRemove: () => setState(() => _imageUrl = null),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _organizerController,
                label: l10n.eventFormOrganizerLabel,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _organizerDescriptionController,
                label: l10n.eventProfileOrganizerDescriptionLabel,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _externalLinkController,
                label: l10n.eventProfileExternalLinkLabel,
                forceLtr: true,
              ),
              if (_eventKind == EventKind.program) ...[
                const SizedBox(height: 24),
                Text(
                  l10n.programSessionsFormTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < _sessions.length; i++)
                  _buildSessionCard(i, l10n),
                TextButton.icon(
                  onPressed: _addSession,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.programAddSessionAction),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                l10n.eventFormVisibilityLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              FilterChipRow(
                options: visibilityLabels.keys.toList(),
                selected: visibilityLabelFor[_visibility]!,
                onSelected: (label) =>
                    setState(() => _visibility = visibilityLabels[label]!),
              ),
              if (_visibility == EventVisibility.specificFaculties) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.eventFormFacultiesLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                facultyOptionsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (options) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.where((o) => o.active).map((option) {
                      final selected = _selectedFaculties.contains(
                        option.label,
                      );
                      final language = Localizations.localeOf(
                        context,
                      ).languageCode;
                      return FilterChip(
                        label: Text(option.labelFor(language)),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (next) => setState(() {
                          if (next) {
                            _selectedFaculties.add(option.label);
                          } else {
                            _selectedFaculties.remove(option.label);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                ),
              ],
              if (_visibility == EventVisibility.specificGroups) ...[
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _groupTagsController,
                  label: l10n.eventFormGroupTagsLabel,
                ),
              ],
              if (formState.errorMessage != null) ...[
                const SizedBox(height: 16),
                InlineBanner(
                  message: formState.errorMessage!,
                  tone: BannerTone.error,
                ),
              ],
              const SizedBox(height: 24),
              PrimaryGradientButton(
                label: _isEdit
                    ? l10n.eventFormSubmitUpdate
                    : l10n.eventFormSubmitCreate,
                loading: formState.loading,
                onPressed: () => _submit(l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(int index, AppLocalizations l10n) {
    final row = _sessions[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.programSessionLabel} ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _removeSession(index),
                child: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.destructive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AuthTextField(
            controller: row.titleController,
            label: l10n.eventFormTitleLabel,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await _pickDateTime(row.startsAt);
                    if (picked != null) setState(() => row.startsAt = picked);
                  },
                  child: Text(
                    row.startsAt == null
                        ? l10n.eventFormStartLabel
                        : _formatDateTime(row.startsAt),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await _pickDateTime(row.endsAt);
                    if (picked != null) setState(() => row.endsAt = picked);
                  },
                  child: Text(
                    row.endsAt == null
                        ? l10n.eventFormEndLabel
                        : _formatDateTime(row.endsAt),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AuthTextField(
            controller: row.locationController,
            label: l10n.eventFormLocationLabel,
          ),
        ],
      ),
    );
  }
}

/// Tap-to-upload event art. Uploads immediately on pick (rather than on form
/// submit) so the admin sees the real stored image and a failed upload is
/// reported while they can still react to it.
class _EventImagePickerField extends StatelessWidget {
  const _EventImagePickerField({
    required this.imageUrl,
    required this.uploading,
    required this.label,
    required this.onPick,
    required this.onRemove,
  });

  final String? imageUrl;
  final bool uploading;
  final String label;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: uploading ? null : onPick,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: uploading
                ? const Center(child: CircularProgressIndicator())
                : (imageUrl != null && imageUrl!.isNotEmpty)
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(imageUrl!, fit: BoxFit.cover),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.white,
                            ),
                            onPressed: onRemove,
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 34,
                      color: AppColors.mutedForeground,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
