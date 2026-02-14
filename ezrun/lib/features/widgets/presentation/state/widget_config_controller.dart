import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../profile/presentation/state/settings_controller.dart';
import '../../data/models/widget_config.dart';
import '../../data/repositories/widget_repository.dart';
import '../../data/services/widget_platform_service.dart';

final widgetRepositoryProvider = Provider<WidgetRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final supabase = Supabase.instance.client;
  return WidgetRepository(prefs, supabase);
});

final widgetPlatformServiceProvider = Provider<WidgetPlatformService>((ref) {
  return WidgetPlatformService();
});

class WidgetConfigState {
  final WidgetConfig config;
  final bool isSaving;
  final bool widgetExists;
  final bool isRequestingPin;

  const WidgetConfigState({
    required this.config,
    this.isSaving = false,
    this.widgetExists = false,
    this.isRequestingPin = false,
  });

  factory WidgetConfigState.initial() {
    return WidgetConfigState(config: WidgetConfig.defaults());
  }

  WidgetConfigState copyWith({
    WidgetConfig? config,
    bool? isSaving,
    bool? widgetExists,
    bool? isRequestingPin,
  }) {
    return WidgetConfigState(
      config: config ?? this.config,
      isSaving: isSaving ?? this.isSaving,
      widgetExists: widgetExists ?? this.widgetExists,
      isRequestingPin: isRequestingPin ?? this.isRequestingPin,
    );
  }
}

class WidgetConfigController extends StateNotifier<WidgetConfigState> {
  final WidgetRepository _repository;
  final WidgetPlatformService _platformService;

  WidgetConfigController(this._repository, this._platformService)
    : super(WidgetConfigState.initial()) {
    _loadConfig();
    _refreshWidgetExists();
  }

  void _loadConfig() {
    state = state.copyWith(config: _repository.getConfig());
  }

  Future<void> _refreshWidgetExists() async {
    final exists = await _platformService.checkWidgetExists();
    state = state.copyWith(widgetExists: exists);
  }

  void updateGoalDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    state = state.copyWith(config: state.config.copyWith(goalDate: normalized));
  }

  void updateTitle(String title) {
    state = state.copyWith(config: state.config.copyWith(title: title));
  }

  void updateSubtitle(String subtitle) {
    state = state.copyWith(config: state.config.copyWith(subtitle: subtitle));
  }

  void updateTheme(WidgetThemeColor theme) {
    state = state.copyWith(config: state.config.copyWith(themeColor: theme));
  }

  void updateTextSize(WidgetTextSize size) {
    state = state.copyWith(config: state.config.copyWith(textSize: size));
  }

  void updateGoalDays(int days) {
    state = state.copyWith(config: state.config.copyWith(goalDays: days));
  }

  void setUseGoalDaysMode(bool useGoalDaysMode) {
    state = state.copyWith(config: state.config.copyWith(useGoalDaysMode: useGoalDaysMode));
  }

  Future<void> saveConfig() async {
    state = state.copyWith(isSaving: true);
    await _repository.saveConfig(state.config);
    await _platformService.updateWidget();
    state = state.copyWith(isSaving: false);
  }

  Future<bool> requestPinWidget() async {
    state = state.copyWith(isRequestingPin: true);
    final result = await _platformService.requestPinWidget();
    await _refreshWidgetExists();
    state = state.copyWith(isRequestingPin: false);
    return result;
  }
}

final widgetConfigControllerProvider =
    StateNotifierProvider<WidgetConfigController, WidgetConfigState>((ref) {
      final repository = ref.watch(widgetRepositoryProvider);
      final platformService = ref.watch(widgetPlatformServiceProvider);
      return WidgetConfigController(repository, platformService);
    });
