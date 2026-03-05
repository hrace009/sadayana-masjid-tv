import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/islamic_colors.dart';
import '../../../../core/theme/islamic_typography.dart';
import '../../../cubits/settings/settings_cubit.dart';
import '../../../cubits/settings/settings_state.dart';

/// Section untuk mengedit identitas masjid: nama dan alamat.
///
/// Perubahan disimpan otomatis ke database via [SettingsCubit].
class IdentitySection extends StatefulWidget {
  const IdentitySection({super.key});

  @override
  State<IdentitySection> createState() => _IdentitySectionState();
}

class _IdentitySectionState extends State<IdentitySection> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Inisialisasi controller dari settings yang sudah loaded.
  void _initControllers(SettingsLoaded state) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = state.settings.mosqueName;
    _addressController.text = state.settings.mosqueAddress;
  }

  Future<void> _save(BuildContext context) async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    if (name.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama masjid minimal 3 karakter'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<SettingsCubit>().updateIdentity(
        mosqueName: name,
        mosqueAddress: address,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Identitas masjid berhasil disimpan'),
            backgroundColor: IslamicColors.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        if (state is SettingsLoaded) {
          _initControllers(state);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identitas Masjid',
              style: IslamicTypography.title(
                color: IslamicColors.goldAmber,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Nama dan alamat akan ditampilkan di pojok kiri atas layar.',
              style: IslamicTypography.body(color: IslamicColors.textSecondary),
            ),
            SizedBox(height: 32.h),

            // Nama Masjid
            _buildLabel('Nama Masjid *'),
            SizedBox(height: 8.h),
            _buildTextField(
              controller: _nameController,
              hint: 'contoh: Masjid Al-Ikhlas',
              maxLines: 1,
            ),
            SizedBox(height: 24.h),

            // Alamat Masjid
            _buildLabel('Alamat Masjid'),
            SizedBox(height: 8.h),
            _buildTextField(
              controller: _addressController,
              hint: 'contoh: Jl. Raya No. 1, Bandung',
              maxLines: 2,
            ),
            SizedBox(height: 40.h),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _save(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: IslamicColors.goldAmber,
                  foregroundColor: IslamicColors.deepTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Simpan Identitas',
                        style: IslamicTypography.body(
                          color: IslamicColors.deepTeal,
                          fontWeight: FontWeight.bold,
                        ).copyWith(fontSize: 32.sp),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: IslamicTypography.body(
        color: IslamicColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: IslamicTypography.body(color: IslamicColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: IslamicTypography.body(color: IslamicColors.textMuted),
        filled: true,
        fillColor: IslamicColors.glassWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: IslamicColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: IslamicColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: IslamicColors.goldAmber, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      ),
    );
  }
}
