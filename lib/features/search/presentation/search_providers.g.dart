// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Bộ lọc đang áp dụng ở màn hình Tìm kiếm.

@ProviderFor(SearchFilter)
final searchFilterProvider = SearchFilterProvider._();

/// Bộ lọc đang áp dụng ở màn hình Tìm kiếm.
final class SearchFilterProvider
    extends $NotifierProvider<SearchFilter, TransactionFilter> {
  /// Bộ lọc đang áp dụng ở màn hình Tìm kiếm.
  SearchFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchFilterHash();

  @$internal
  @override
  SearchFilter create() => SearchFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionFilter>(value),
    );
  }
}

String _$searchFilterHash() => r'87b3dfb8b7e48bdea30eb3f631c989d9a4f0c37f';

/// Bộ lọc đang áp dụng ở màn hình Tìm kiếm.

abstract class _$SearchFilter extends $Notifier<TransactionFilter> {
  TransactionFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TransactionFilter, TransactionFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TransactionFilter, TransactionFilter>,
              TransactionFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Kết quả tìm kiếm, tự cập nhật khi dữ liệu đổi.

@ProviderFor(searchResults)
final searchResultsProvider = SearchResultsProvider._();

/// Kết quả tìm kiếm, tự cập nhật khi dữ liệu đổi.

final class SearchResultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TransactionDetail>>,
          List<TransactionDetail>,
          Stream<List<TransactionDetail>>
        >
    with
        $FutureModifier<List<TransactionDetail>>,
        $StreamProvider<List<TransactionDetail>> {
  /// Kết quả tìm kiếm, tự cập nhật khi dữ liệu đổi.
  SearchResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchResultsHash();

  @$internal
  @override
  $StreamProviderElement<List<TransactionDetail>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TransactionDetail>> create(Ref ref) {
    return searchResults(ref);
  }
}

String _$searchResultsHash() => r'2443dedc7f3612a5dba264395fd27e7f26ca1830';

@ProviderFor(searchSummary)
final searchSummaryProvider = SearchSummaryProvider._();

final class SearchSummaryProvider
    extends $FunctionalProvider<SearchSummary, SearchSummary, SearchSummary>
    with $Provider<SearchSummary> {
  SearchSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchSummaryHash();

  @$internal
  @override
  $ProviderElement<SearchSummary> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SearchSummary create(Ref ref) {
    return searchSummary(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchSummary value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchSummary>(value),
    );
  }
}

String _$searchSummaryHash() => r'd6318b34b11ec2b17c189d97a048a701ba27ce1b';
