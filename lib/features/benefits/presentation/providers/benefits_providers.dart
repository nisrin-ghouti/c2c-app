import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgresChangeEvent, SupabaseClient;

import '../../../../main.dart' show supabase;
import '../../data/datasources/benefits_remote_data_source.dart';
import '../../data/repositories/benefits_repository_impl.dart';
import '../../domain/entities/benefit.dart';
import '../../domain/entities/digital_card.dart';
import '../../domain/repositories/benefits_repository.dart';
import '../../domain/usecases/benefits_usecases.dart';

final _supabaseClientProvider = Provider<SupabaseClient>((ref) => supabase);

final _benefitsRemoteDataSourceProvider = Provider<BenefitsRemoteDataSource>((
  ref,
) {
  return BenefitsRemoteDataSource(ref.watch(_supabaseClientProvider));
});

final benefitsRepositoryProvider = Provider<BenefitsRepository>((ref) {
  return BenefitsRepositoryImpl(ref.watch(_benefitsRemoteDataSourceProvider));
});

final listBenefitsProvider = Provider(
  (ref) => ListBenefits(ref.watch(benefitsRepositoryProvider)),
);
final uploadBenefitImageProvider = Provider(
  (ref) => UploadBenefitImage(ref.watch(benefitsRepositoryProvider)),
);
final listMyDigitalCardsProvider = Provider(
  (ref) => ListMyDigitalCards(ref.watch(benefitsRepositoryProvider)),
);
final redeemBenefitProvider = Provider(
  (ref) => RedeemBenefit(ref.watch(benefitsRepositoryProvider)),
);
final adminListBenefitsProvider = Provider(
  (ref) => AdminListBenefits(ref.watch(benefitsRepositoryProvider)),
);
final createBenefitProvider = Provider(
  (ref) => CreateBenefit(ref.watch(benefitsRepositoryProvider)),
);
final updateBenefitProvider = Provider(
  (ref) => UpdateBenefit(ref.watch(benefitsRepositoryProvider)),
);
final setBenefitActiveProvider = Provider(
  (ref) => SetBenefitActive(ref.watch(benefitsRepositoryProvider)),
);

final benefitsCatalogProvider = FutureProvider.autoDispose<List<Benefit>>((
  ref,
) {
  return ref.watch(listBenefitsProvider)();
});

final myDigitalCardsProvider = FutureProvider.autoDispose<List<DigitalCard>>((
  ref,
) {
  return ref.watch(listMyDigitalCardsProvider)();
});

/// Drops the cached benefits catalog whenever a benefit changes in the
/// database, so an edit made in the admin panel shows up in the app without
/// the student doing anything.
///
/// Why this is needed: `benefitsCatalogProvider` is `autoDispose`, but the
/// Benefits tab is a bottom-nav branch that `StatefulShellRoute.indexedStack`
/// keeps mounted for the whole session — so nothing ever disposed it and the
/// session's first fetch was its only fetch. Short of pull-to-refresh, an
/// edited benefit stayed stale until the process was killed, which is exactly
/// what was reported.
///
/// Mounted once by `AppShell`, so it lives exactly as long as the signed-in
/// session and is torn down with it. The same shape (and the same reasoning)
/// as `eventsLiveRefreshProvider`.
///
/// Requires `benefits` to be in the `supabase_realtime` publication
/// (migration 0087). Without it this subscribes, reports healthy, and never
/// fires — the same silent failure 0005 documents.
final benefitsLiveRefreshProvider = Provider<void>((ref) {
  final channel = supabase.channel('public:benefits');

  // An admin save arrives as a burst: the benefit row, then a second write a
  // moment later when the translate function fills the other languages.
  // Coalescing means one refetch per burst rather than one per row touched.
  Timer? debounce;

  void invalidateBenefitCaches() {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 400), () {
      ref.invalidate(benefitsCatalogProvider);
      // Family: invalidating the provider itself clears every argument. The
      // detail screen derives from the catalog, so this is what repaints it.
      ref.invalidate(benefitByIdProvider);
    });
  }

  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'benefits',
    callback: (_) => invalidateBenefitCaches(),
  );

  channel.subscribe();

  ref.onDispose(() {
    debounce?.cancel();
    supabase.removeChannel(channel);
  });
});

/// Drops the cached wallet whenever one of the viewer's `digital_cards` rows
/// changes, so a card redeemed by the partner's scanner updates on the screen
/// the student is holding up — no back-out-and-reopen.
///
/// Watched by `CardDetailScreen`, so it lives exactly as long as a card is
/// open and is torn down with it. Scoped that way deliberately: the only place
/// a row is expected to change under the user is while they are showing it.
///
/// Realtime honours RLS and `digital_cards` is owner-restricted, so this
/// stream only ever carries the viewer's own cards.
///
/// Requires `digital_cards` to be in the `supabase_realtime` publication
/// (migration 0067). Without it this subscribes, reports healthy, and never
/// fires — the same silent failure 0005 documents.
final digitalCardsLiveRefreshProvider = Provider<void>((ref) {
  final channel = supabase.channel('public:digital_cards');

  // The redeem path writes the row and its trigger fans out a notification a
  // moment later; coalescing means one refetch rather than one per event.
  Timer? debounce;

  void invalidateWallet() {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 250), () {
      ref.invalidate(myDigitalCardsProvider);
    });
  }

  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'digital_cards',
    callback: (_) => invalidateWallet(),
  );

  channel.subscribe();

  ref.onDispose(() {
    debounce?.cancel();
    supabase.removeChannel(channel);
  });
});

/// One wallet card by id, kept current by [digitalCardsLiveRefreshProvider].
///
/// Derived from the same wallet fetch the Benefits screen already uses rather
/// than a second lookup. Null once the card is no longer in the wallet; the
/// detail screen falls back to the snapshot it was pushed with, so a slow or
/// failed refetch can never blank out a card the student is showing.
final digitalCardByIdProvider = FutureProvider.autoDispose
    .family<DigitalCard?, String>((ref, id) async {
      final cards = await ref.watch(myDigitalCardsProvider.future);
      for (final card in cards) {
        if (card.id == id) return card;
      }
      return null;
    });

/// A single benefit by id, derived from the same catalog fetch the Benefits
/// screen already uses — e.g. so a notification can deep-link straight to
/// the benefit it's about. Null if it's no longer active (catalog is
/// filtered server-side) or was deleted.
final benefitByIdProvider = FutureProvider.autoDispose.family<Benefit?, String>(
  (ref, id) async {
    final benefits = await ref.watch(benefitsCatalogProvider.future);
    for (final benefit in benefits) {
      if (benefit.id == id) return benefit;
    }
    return null;
  },
);
