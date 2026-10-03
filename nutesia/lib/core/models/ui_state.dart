import '../errors/app_error.dart';

/// Standard lifecycle status states across all screens and components in Nutesia.
enum UiStatus {
  initial,
  loading,
  success,
  empty,
  error,
  retrying,
  offline,
}

/// Generic reactive state container wrapping data, error metadata, and loading status.
class UiState<T> {
  final UiStatus status;
  final T? data;
  final AppError? error;
  final String? emptyMessage;

  const UiState({
    required this.status,
    this.data,
    this.error,
    this.emptyMessage,
  });

  const UiState.initial()
      : status = UiStatus.initial,
        data = null,
        error = null,
        emptyMessage = null;

  const UiState.loading({T? previousData})
      : status = UiStatus.loading,
        data = previousData,
        error = null,
        emptyMessage = null;

  const UiState.success(T successData)
      : status = UiStatus.success,
        data = successData,
        error = null,
        emptyMessage = null;

  const UiState.empty({String message = 'No data available'})
      : status = UiStatus.empty,
        data = null,
        error = null,
        emptyMessage = message;

  const UiState.error(AppError appError, {T? previousData})
      : status = UiStatus.error,
        data = previousData,
        error = appError,
        emptyMessage = null;

  const UiState.retrying({T? previousData})
      : status = UiStatus.retrying,
        data = previousData,
        error = null,
        emptyMessage = null;

  const UiState.offline({T? cachedData})
      : status = UiStatus.offline,
        data = cachedData,
        error = null,
        emptyMessage = null;

  bool get isInitial => status == UiStatus.initial;
  bool get isLoading => status == UiStatus.loading;
  bool get isSuccess => status == UiStatus.success;
  bool get isEmpty => status == UiStatus.empty;
  bool get isError => status == UiStatus.error;
  bool get isRetrying => status == UiStatus.retrying;
  bool get isOffline => status == UiStatus.offline;
  bool get hasData => data != null;

  UiState<T> copyWith({
    UiStatus? status,
    T? data,
    AppError? error,
    String? emptyMessage,
  }) {
    return UiState<T>(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
      emptyMessage: emptyMessage ?? this.emptyMessage,
    );
  }

  @override
  String toString() => 'UiState($status, hasData: $hasData, error: $error)';
}
