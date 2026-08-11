import '../../domain/entities/indicator.dart';

enum IndicatorStatus { initial, loading, success, error }

class IndicatorState {
  const IndicatorState({
    this.status = IndicatorStatus.initial,
    this.indicators = const [],
    this.selectedIndicator,
    this.errorMessage = '',
  });

  final IndicatorStatus status;
  final List<Indicator> indicators;
  final Indicator? selectedIndicator;
  final String errorMessage;

  IndicatorState copyWith({
    IndicatorStatus? status,
    List<Indicator>? indicators,
    Indicator? selectedIndicator,
    bool clearSelectedIndicator = false,
    String? errorMessage,
  }) {
    return IndicatorState(
      status: status ?? this.status,
      indicators: indicators ?? this.indicators,
      selectedIndicator:
          clearSelectedIndicator ? null : selectedIndicator ?? this.selectedIndicator,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
