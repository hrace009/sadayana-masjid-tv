import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/islamic_colors.dart';
import '../../../../core/theme/islamic_typography.dart';
import '../../../../domain/entities/city.dart';
import '../../../../domain/repositories/city_repository.dart';
import '../../../../domain/entities/setup_wizard_data.dart';
import '../../../cubits/setup_wizard/setup_wizard_cubit.dart';
import '../../../cubits/setup_wizard/setup_wizard_state.dart';
import '../../../widgets/focusable_widget.dart';
import '../../../widgets/glassmorphism_card.dart';

class LocationStep extends StatefulWidget {
  const LocationStep({super.key});

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  // State for dropdowns
  List<String> _provinces = [];
  List<City> _cities = [];

  String? _selectedProvince;
  City? _selectedCity;

  bool _isLoadingProvinces = true;
  bool _isLoadingCities = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  /// Load existing data from Cubit if available (back navigation)
  void _syncWithCubit() {
    final state = context.read<SetupWizardCubit>().state;
    final cubitData = (state is SetupWizardInProgress)
        ? state.data
        : const SetupWizardData();
    if (cubitData.cityName.isNotEmpty) {
      if (_selectedCity == null ||
          _selectedCity!.cityName != cubitData.cityName) {
        setState(() {
          _selectedCity = City(
            id: 0, // Dummy ID
            cityName: cubitData.cityName,
            provinceName: cubitData.provinceName,
            latitude: cubitData.latitude,
            longitude: cubitData.longitude,
          );
          _selectedProvince = _selectedCity!.provinceName;
        });
        // If we have a city, we need to load the cities for that province
        if (_selectedProvince != null) {
          _loadCities(_selectedProvince!);
        }
      }
    }
  }

  Future<void> _loadProvinces() async {
    try {
      setState(() => _isLoadingProvinces = true);
      // Access repository from context (assuming it is provided in main.dart)
      // If not yet provided, this might fail unless we implement a mock/temporary repo access
      // or inject it properly.
      // For now, assume context.read<CityRepository>() works.
      final repo = context.read<CityRepository>();
      final provinces = await repo.getProvinces();

      if (mounted) {
        setState(() {
          _provinces = provinces;
          _isLoadingProvinces = false;
        });
        _syncWithCubit();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProvinces = false);
        // Show error snackbar or text
      }
    }
  }

  Future<void> _loadCities(String provinceName) async {
    try {
      setState(() => _isLoadingCities = true);
      final repo = context.read<CityRepository>();
      final cities = await repo.getCitiesByProvince(provinceName);

      if (mounted) {
        setState(() {
          _cities = cities;
          _isLoadingCities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCities = false);
      }
    }
  }

  void _onProvinceChanged(String? newProvince) {
    if (newProvince == null || newProvince == _selectedProvince) return;

    setState(() {
      _selectedProvince = newProvince;
      _selectedCity = null; // Reset city when province changes
      _cities = []; // Clear cities
    });

    // Clear in cubit too
    // But cubit only accepts City object, so we verify location validity in cubit
    // We can't clear 'partially' in cubit easily without a dedicated method or passing null city
    // For now we just don't update cubit until city is selected.

    _loadCities(newProvince);
  }

  void _onCityChanged(City? newCity) {
    if (newCity == null) return;

    setState(() {
      _selectedCity = newCity;
    });

    // Update Cubit
    context.read<SetupWizardCubit>().selectCity(newCity);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: SizedBox(
                width: 700.w,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lokasi Masjid',
                      style: IslamicTypography.heading(
                        color: IslamicColors.goldAmber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Pilih lokasi untuk penyesuaian jadwal sholat otomatis.',
                      style: IslamicTypography.body(
                        color: IslamicColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 48.h),

                    // Form Fields
                    GlassmorphismCard(
                      child: Padding(
                        padding: EdgeInsets.all(32.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Province Dropdown
                            _buildLabel('Provinsi'),
                            SizedBox(height: 8.h),
                            _buildDropdown<String>(
                              hint: 'Pilih Provinsi',
                              value: _selectedProvince,
                              items: _provinces,
                              isLoading: _isLoadingProvinces,
                              itemLabel: (item) => item,
                              onChanged: _onProvinceChanged,
                            ),
                            SizedBox(height: 24.h),

                            // City Dropdown
                            _buildLabel('Kota / Kabupaten'),
                            SizedBox(height: 8.h),
                            _buildDropdown<City>(
                              hint: _selectedProvince == null
                                  ? 'Pilih Provinsi Terlebih Dahulu'
                                  : 'Pilih Kota',
                              value: _selectedCity,
                              items: _cities,
                              isLoading: _isLoadingCities,
                              isDisabled: _selectedProvince == null,
                              itemLabel: (city) => city.cityName,
                              onChanged: _onCityChanged,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 48.h),

                    // Navigation Buttons
                    BlocBuilder<SetupWizardCubit, SetupWizardState>(
                      builder: (context, state) {
                        // Check if valid data is present in State to enable Next button logic visually
                        // Though Cubit logic handles canGoNext
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildNavButton(
                              label: 'Kembali',
                              isPrimary: false,
                              onPressed: () => context
                                  .read<SetupWizardCubit>()
                                  .goToPreviousStep(),
                            ),
                            SizedBox(width: 24.w),
                            _buildNavButton(
                              label: 'Selanjutnya',
                              isPrimary: true,
                              onPressed: () {
                                // Simple validation check before calling cubit
                                if (_selectedCity != null) {
                                  context
                                      .read<SetupWizardCubit>()
                                      .goToNextStep();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Silakan pilih kota terlebih dahulu',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: IslamicTypography.title(
        color: IslamicColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required bool isLoading,
    bool isDisabled = false,
    required String Function(T) itemLabel,
    required Function(T?) onChanged,
  }) {
    return FocusableWidget(
      builder: (isFocused) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: isFocused
                ? IslamicColors.surfaceLight
                : IslamicColors.surfaceDark,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isFocused
                  ? IslamicColors.goldAmber
                  : IslamicColors.glassBorder,
              width: 1.5,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: IslamicColors.goldAmber.withValues(alpha: 0.2),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: isLoading
              ? SizedBox(
                  height: 56.h,
                  child: Center(
                    child: SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: IslamicColors.goldAmber,
                      ),
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    hint: Text(
                      hint,
                      style: IslamicTypography.body(
                        color: isDisabled
                            ? IslamicColors.textMuted.withValues(alpha: 0.5)
                            : IslamicColors.textMuted,
                      ),
                    ),
                    isExpanded: true,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: isDisabled
                          ? IslamicColors.glassBorder
                          : IslamicColors.textSecondary,
                    ),
                    dropdownColor: IslamicColors.surfaceDark,
                    style: IslamicTypography.body(
                      color: IslamicColors.textPrimary,
                    ),
                    items: isDisabled
                        ? []
                        : items.map((T item) {
                            return DropdownMenuItem<T>(
                              value: item,
                              child: Text(itemLabel(item)),
                            );
                          }).toList(),
                    onChanged: isDisabled ? null : onChanged,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildNavButton({
    required String label,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return FocusableWidget(
      onSelect: onPressed,
      builder: (isFocused) {
        final baseColor = isPrimary
            ? IslamicColors.goldAmber
            : IslamicColors.surfaceLight;
        final textColor = isPrimary
            ? IslamicColors.deepTeal
            : IslamicColors.textPrimary;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 280.w,
          height: 56.h,
          decoration: BoxDecoration(
            color: isFocused ? baseColor.withValues(alpha: 0.9) : baseColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isFocused
                  ? IslamicColors.textPrimary
                  : (isPrimary
                        ? Colors.transparent
                        : IslamicColors.glassBorder),
              width: 2.0,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                label,
                style: IslamicTypography.title(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
