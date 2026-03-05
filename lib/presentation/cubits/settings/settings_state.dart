import 'package:equatable/equatable.dart';
import '../../../../domain/entities/settings.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final Settings settings;
  final bool isSaving;
  final String? lastSavedField;

  const SettingsLoaded({
    required this.settings,
    this.isSaving = false,
    this.lastSavedField,
  });

  SettingsLoaded copyWith({
    Settings? settings,
    bool? isSaving,
    String? lastSavedField,
  }) {
    return SettingsLoaded(
      settings: settings ?? this.settings,
      isSaving: isSaving ?? this.isSaving,
      lastSavedField: lastSavedField ?? this.lastSavedField,
    );
  }

  @override
  List<Object?> get props => [settings, isSaving, lastSavedField];
}

class SettingsError extends SettingsState {
  final String message;
  final Settings? lastKnownSettings;

  const SettingsError({required this.message, this.lastKnownSettings});

  @override
  List<Object?> get props => [message, lastKnownSettings];
}
