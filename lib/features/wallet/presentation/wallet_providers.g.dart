// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Repository ví. Giao diện không bao giờ chạm tới DAO hay `AppDatabase` —
/// nó đi qua đây.

@ProviderFor(walletRepository)
final walletRepositoryProvider = WalletRepositoryProvider._();

/// Repository ví. Giao diện không bao giờ chạm tới DAO hay `AppDatabase` —
/// nó đi qua đây.

final class WalletRepositoryProvider
    extends
        $FunctionalProvider<
          WalletRepository,
          WalletRepository,
          WalletRepository
        >
    with $Provider<WalletRepository> {
  /// Repository ví. Giao diện không bao giờ chạm tới DAO hay `AppDatabase` —
  /// nó đi qua đây.
  WalletRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletRepositoryHash();

  @$internal
  @override
  $ProviderElement<WalletRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WalletRepository create(Ref ref) {
    return walletRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WalletRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WalletRepository>(value),
    );
  }
}

String _$walletRepositoryHash() => r'6f75939e68ab9ad09ebfe9e451400a60ffae55e3';

/// Danh sách ví kèm số dư, tự cập nhật khi có giao dịch mới.
///
/// Trả `Stream` nên Riverpod bọc thành `AsyncValue`: giao diện xử lý ba trạng
/// thái loading / error / data mà không phải tự quản cờ `isLoading`.

@ProviderFor(walletList)
final walletListProvider = WalletListFamily._();

/// Danh sách ví kèm số dư, tự cập nhật khi có giao dịch mới.
///
/// Trả `Stream` nên Riverpod bọc thành `AsyncValue`: giao diện xử lý ba trạng
/// thái loading / error / data mà không phải tự quản cờ `isLoading`.

final class WalletListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WalletWithBalance>>,
          List<WalletWithBalance>,
          Stream<List<WalletWithBalance>>
        >
    with
        $FutureModifier<List<WalletWithBalance>>,
        $StreamProvider<List<WalletWithBalance>> {
  /// Danh sách ví kèm số dư, tự cập nhật khi có giao dịch mới.
  ///
  /// Trả `Stream` nên Riverpod bọc thành `AsyncValue`: giao diện xử lý ba trạng
  /// thái loading / error / data mà không phải tự quản cờ `isLoading`.
  WalletListProvider._({
    required WalletListFamily super.from,
    required bool super.argument,
  }) : super(
         retry: null,
         name: r'walletListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$walletListHash();

  @override
  String toString() {
    return r'walletListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<WalletWithBalance>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WalletWithBalance>> create(Ref ref) {
    final argument = this.argument as bool;
    return walletList(ref, includeArchived: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WalletListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$walletListHash() => r'1a163f7436a4066df703c8f04cfc836409200557';

/// Danh sách ví kèm số dư, tự cập nhật khi có giao dịch mới.
///
/// Trả `Stream` nên Riverpod bọc thành `AsyncValue`: giao diện xử lý ba trạng
/// thái loading / error / data mà không phải tự quản cờ `isLoading`.

final class WalletListFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<WalletWithBalance>>, bool> {
  WalletListFamily._()
    : super(
        retry: null,
        name: r'walletListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Danh sách ví kèm số dư, tự cập nhật khi có giao dịch mới.
  ///
  /// Trả `Stream` nên Riverpod bọc thành `AsyncValue`: giao diện xử lý ba trạng
  /// thái loading / error / data mà không phải tự quản cờ `isLoading`.

  WalletListProvider call({bool includeArchived = false}) =>
      WalletListProvider._(argument: includeArchived, from: this);

  @override
  String toString() => r'walletListProvider';
}

/// Tổng tài sản — chỉ gồm ví có `includeInTotal` và chưa lưu trữ.

@ProviderFor(totalBalance)
final totalBalanceProvider = TotalBalanceProvider._();

/// Tổng tài sản — chỉ gồm ví có `includeInTotal` và chưa lưu trữ.

final class TotalBalanceProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Tổng tài sản — chỉ gồm ví có `includeInTotal` và chưa lưu trữ.
  TotalBalanceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalBalanceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalBalanceHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return totalBalance(ref);
  }
}

String _$totalBalanceHash() => r'2834e945e0c2375b6f011a80448e4443f8d15242';
