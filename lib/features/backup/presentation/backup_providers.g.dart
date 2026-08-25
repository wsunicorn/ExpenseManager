// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(exportService)
final exportServiceProvider = ExportServiceProvider._();

final class ExportServiceProvider
    extends $FunctionalProvider<ExportService, ExportService, ExportService>
    with $Provider<ExportService> {
  ExportServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportServiceHash();

  @$internal
  @override
  $ProviderElement<ExportService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ExportService create(Ref ref) {
    return exportService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExportService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExportService>(value),
    );
  }
}

String _$exportServiceHash() => r'41ebd045020f67f8b035ce39bf9edc0abcbb105b';

@ProviderFor(restoreService)
final restoreServiceProvider = RestoreServiceProvider._();

final class RestoreServiceProvider
    extends $FunctionalProvider<RestoreService, RestoreService, RestoreService>
    with $Provider<RestoreService> {
  RestoreServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restoreServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restoreServiceHash();

  @$internal
  @override
  $ProviderElement<RestoreService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RestoreService create(Ref ref) {
    return restoreService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RestoreService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RestoreService>(value),
    );
  }
}

String _$restoreServiceHash() => r'ec01a6ab1383bd80a027ad18fd042735d0802e9d';
