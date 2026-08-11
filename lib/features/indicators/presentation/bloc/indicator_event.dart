import '../../domain/entities/indicator.dart';

sealed class IndicatorEvent {
  const IndicatorEvent();
}

class LoadIndicatorsEvent extends IndicatorEvent {
  const LoadIndicatorsEvent();
}

class LoadIndicatorEvent extends IndicatorEvent {
  const LoadIndicatorEvent(this.id);

  final String id;
}

class CreateIndicatorEvent extends IndicatorEvent {
  const CreateIndicatorEvent(this.indicator);

  final Indicator indicator;
}

class UpdateIndicatorEvent extends IndicatorEvent {
  const UpdateIndicatorEvent(this.indicator);

  final Indicator indicator;
}
