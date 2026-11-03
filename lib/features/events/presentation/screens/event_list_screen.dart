import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header_bar.dart';
import '../../../../core/widgets/filter_chip_row.dart';
import '../../../roles/domain/entities/user_role.dart';
import '../../../roles/presentation/providers/roles_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/campus_event.dart';
import '../../domain/entities/event_action_result.dart';
import '../../domain/entities/event_kind.dart';
import '../../domain/usecases/event_capacity.dart';
import '../../domain/usecases/event_permissions.dart';
import '../controllers/event_actions_controller.dart';
import '../providers/events_providers.dart';
import '../widgets/campus_event_card.dart';
import 'event_attendance_scan_screen.dart';
import 'event_detail_screen.dart';
import 'event_statistics_screen.dart';

class EventListScreen extends ConsumerStatefulWidget {
  const EventListScreen({super.key, this.onlyNextThirtyDays = false});

  /// Restricts the list to the events Home's "Events in the Next Month"
  /// section shows, so its "See All" opens the same set the section itself
  /// previews instead of every open event.
  ///
  /// The window test is not re-implemented here: this reads
  /// `eventsNextThirtyDaysProvider`, the exact provider that backs the
  /// section, so the two can't drift. Defaults to false, which leaves the
  /// Events tab (and every other entry point) showing all events as before.
  final bool onlyNextThirtyDays;

  @override
  ConsumerState<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends ConsumerState<EventListScreen> {
  String? _type;
  String? _category;
  String? _organizer;

  List<String> _optionsFor(Iterable<String?> values, String allLabel) {
    final distinct = values
        .whereType<String>()
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList();
    return [allLabel, ...distinct];
  }

  Future<void> _confirmDelete(CampusEvent event, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteEventTitle),
        content: Text(l10n.deleteEventMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteEventConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await ref
        .read(eventActionsControllerProvider.notifier)
        .delete(event.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.deleteEventSuccess : l10n.deleteEventError),
      ),
    );
  }

  Future<void> _openFilterSheet({
    required AppLocalizations l10n,
    required List<String> typeOptions,
    required List<String> categories,
    required List<String> organizers,
  }) async {
    var draftType = _type!;
    var draftCategory = _category!;
    var draftOrganizer = _organizer!;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    l10n.eventFiltersTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.eventFilterTypeLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilterChipRow(
                    options: typeOptions,
                    selected: draftType,
                    onSelected: (v) => setSheetState(() => draftType = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.eventFilterCategoryLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilterChipRow(
                    options: categories,
                    selected: draftCategory,
                    onSelected: (v) => setSheetState(() => draftCategory = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.eventFilterOrganizerLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilterChipRow(
                    options: organizers,
                    selected: draftOrganizer,
                    onSelected: (v) => setSheetState(() => draftOrganizer = v),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setSheetState(() {
                            draftType = l10n.filterAll;
                            draftCategory = l10n.filterAll;
                            draftOrganizer = l10n.filterAll;
                          }),
                          child: Text(l10n.eventFiltersReset),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _type = draftType;
                              _category = draftCategory;
                              _organizer = draftOrganizer;
                            });
                            Navigator.of(sheetContext).pop();
                          },
                          child: Text(l10n.eventFiltersApply),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final eventsAsync = ref.watch(
      widget.onlyNextThirtyDays
          ? eventsNextThirtyDaysProvider
          : eventListProvider,
    );
    // One RPC for the whole list; absent while it loads, which leaves the
    // cards registerable until the real counts land.
    final registrationCounts =
        ref.watch(eventRegistrationCountsProvider).valueOrNull ??
        const <String, int>{};
    final busyIds = ref.watch(eventActionsControllerProvider);
    // Programs the viewer has been accepted onto. Null while it loads, which
    // reads as "not pending" so a card never flashes a status that may not
    // apply. See `myAcceptedProgramIdsProvider`.
    final acceptedProgramIds =
        ref.watch(myAcceptedProgramIdsProvider).valueOrNull;
    final myRoles =
        ref.watch(myRolesProvider).valueOrNull ?? const <UserRole>{};
    final hostAccessIds =
        ref.watch(myHostAccessEventIdsProvider).valueOrNull ?? const <String>{};
    final viewerId = ref.watch(currentAuthSessionProvider).userId ?? '';

    return Scaffold(
      appBar: AppHeaderBar(
        title: widget.onlyNextThirtyDays
            ? l10n.homeEventsNextMonth
            : l10n.eventsTitle,
      ),
      body: Padding(
        // Leaves the system navigation buttons their own strip. Padding the
        // scroll instead still lets cards slide underneath them.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: RefreshIndicator(
        // Both variants are refreshed through `eventListProvider`: the
        // next-month list is derived from it, so refreshing the source is
        // what actually refetches.
        onRefresh: () => ref.refresh(eventListProvider.future),
        child: eventsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(child: Text(l10n.homeLoadError)),
            ],
          ),
          data: (events) {
            final typeOptions = [
              l10n.filterAll,
              l10n.eventTypeSingle,
              l10n.eventTypeProgram,
            ];
            final categories = _optionsFor(
              events.map((e) => e.category),
              l10n.filterAll,
            );
            final organizers = _optionsFor(
              events.map((e) => e.organizerName),
              l10n.filterAll,
            );
            _type ??= l10n.filterAll;
            _category ??= l10n.filterAll;
            _organizer ??= l10n.filterAll;

            final filtered = events.where((event) {
              final matchesType =
                  _type == l10n.filterAll ||
                  (_type == l10n.eventTypeProgram) ==
                      (event.eventKind == EventKind.program);
              final matchesCategory =
                  _category == l10n.filterAll || event.category == _category;
              final matchesOrganizer =
                  _organizer == l10n.filterAll ||
                  event.organizerName == _organizer;
              return matchesType && matchesCategory && matchesOrganizer;
            }).toList();

            final activeFilterCount = [
              if (_type != l10n.filterAll) _type,
              if (_category != l10n.filterAll) _category,
              if (_organizer != l10n.filterAll) _organizer,
            ].length;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Material(
                        color: activeFilterCount > 0
                            ? AppColors.primary.withValues(alpha: 0.18)
                            : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => _openFilterSheet(
                            l10n: l10n,
                            typeOptions: typeOptions,
                            categories: categories,
                            organizers: organizers,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.tune,
                                  size: 18,
                                  color: AppColors.primaryStrong,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.eventFiltersButton,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                if (activeFilterCount > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryStrong,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '$activeFilterCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          l10n.homeEmptyEvents,
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final event = filtered[index];
                        return CampusEventCard(
                          event: event,
                          canManage: EventPermissions.canManage(
                            event,
                            roles: myRoles,
                            viewerId: viewerId,
                            hasHostAccessGrant: hostAccessIds.contains(
                              event.id,
                            ),
                          ),
                          registerBusy: busyIds.contains(event.id),
                          // Covers BOTH "no places left" and "an admin
                          // closed registration" — the card renders the same
                          // grey "האירוע מלא" for either.
                          isFull: registrationBlocked(event, registrationCounts),
                          // Same rule the detail screen applies, so the card
                          // and the screen it opens can't disagree.
                          awaitingApproval:
                              event.eventKind == EventKind.program &&
                              event.registrationStatus ==
                                  EventRegistrationStatus.registered &&
                              acceptedProgramIds != null &&
                              !acceptedProgramIds.contains(event.id),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EventDetailScreen(event: event),
                            ),
                          ),
                          onCheckIn: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  EventAttendanceScanScreen(event: event),
                            ),
                          ),
                          onRegister: () async {
                            final result = await ref
                                .read(eventActionsControllerProvider.notifier)
                                .register(event.id);
                            if (!context.mounted) return;
                            final message = switch (result) {
                              EventActionResult.ok => l10n.registerSuccess,
                              EventActionResult.alreadyRegistered =>
                                l10n.registerErrorAlready,
                              EventActionResult.full => l10n.registerErrorFull,
                              EventActionResult.ended =>
                                l10n.registerErrorEnded,
                              EventActionResult.notPublished =>
                                l10n.registerErrorNotPublished,
                              EventActionResult.notFound =>
                                l10n.registerErrorNotFound,
                              EventActionResult.unknown =>
                                l10n.registerErrorGeneric,
                            };
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(message)));
                          },
                          onDelete: () => _confirmDelete(event, l10n),
                          onViewRegistrants: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  EventStatisticsScreen(eventId: event.id),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
        ),
      ),
    );
  }
}
