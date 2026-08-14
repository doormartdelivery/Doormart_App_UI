import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../models/user_model.dart';
import '../../../../providers/app_state.dart';
import '../../../../services/session_service.dart';
import '../providers/delivery_provider.dart';
import 'delivery_login_screen.dart';
import 'delivery_status_screen.dart';

const _kOrange = Color(0xFFE8541A);
const _kOrangeDeep = Color(0xFFD44010);
const _kOrangeLight = Color(0xFFFFF0EB);
const _kBg = Color(0xFFF7F7F8);
const _kCard = Colors.white;
const _kTextDark = Color(0xFF1A1A2E);
const _kTextMid = Color(0xFF8A8A9A);
const _kBorder = Color(0xFFE5E5EA);
const _kRed = Color(0xFFEF4444);

class DeliveryRegisterScreen extends StatefulWidget {
  const DeliveryRegisterScreen({super.key});

  static const routeName = '/delivery/register';

  @override
  State<DeliveryRegisterScreen> createState() => _DeliveryRegisterScreenState();
}

class _DeliveryRegisterScreenState extends State<DeliveryRegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _termsAccepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;
  String? _photoUrl;
  String? _photoName;
  String? _panCard;
  String? _licenseCard;
  String? _aadhaarCard;
  String? _panCardName;
  String? _licenseCardName;
  String? _aadhaarCardName;
  String? _uploadingField;

  late final AnimationController _entryCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _entryCtrl,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.05),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _vehicleCtrl.dispose();
    _licenseCtrl.dispose();
    _panCtrl.dispose();
    _aadhaarCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAsset({
    required String field,
    required List<XTypeGroup> acceptedTypeGroups,
    required void Function(String value) onSelected,
    required void Function(String value) onNameSelected,
  }) async {
    try {
      setState(() => _uploadingField = field);
      final appState = context.read<AppState>();
      final file = await openFile(acceptedTypeGroups: acceptedTypeGroups);
      if (file == null) return;
      final fileName = file.name;
      final uploaded = kIsWeb
          ? await appState.apiService.uploadImage(
              '/auth/vendor/upload-image',
              bytes: await file.readAsBytes(),
              fileName: fileName,
              fieldName: 'image',
            )
          : await appState.apiService.uploadImage(
              '/auth/vendor/upload-image',
              filePath: file.path,
              fileName: fileName,
              fieldName: 'image',
            );
      final url = uploaded['url']?.toString();
      if (url == null || url.isEmpty) {
        throw StateError('Document upload failed');
      }
      onSelected(url);
      onNameSelected(fileName);
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error =
            'Upload failed: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => _uploadingField = null);
    }
  }

  Future<void> _register() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      setState(() => _error = 'Please accept the Terms & Conditions');
      return;
    }
    if (_passwordCtrl.text.trim() != _confirmCtrl.text.trim()) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (_photoUrl == null) {
      setState(() => _error = 'Please upload a delivery person photo');
      return;
    }
    if (_panCard == null || _licenseCard == null || _aadhaarCard == null) {
      setState(
        () => _error = 'Please upload PAN card, licence photo and Aadhaar card',
      );
      return;
    }

    HapticFeedback.selectionClick();
    final navigator = Navigator.of(context);
    setState(() => _loading = true);
    try {
      final provider = context.read<DeliveryProvider>();
      final error = await provider.register(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        avatarUrl: _photoUrl,
        password: _passwordCtrl.text,
        vehicleNumber: _vehicleCtrl.text.trim().isEmpty
            ? null
            : _vehicleCtrl.text.trim(),
        panNumber: _panCtrl.text.trim(),
        panCardUrl: _panCard,
        licenseNumber: _licenseCtrl.text.trim(),
        licenseCardUrl: _licenseCard,
        aadhaarNumber: _aadhaarCtrl.text.trim(),
        aadhaarCardUrl: _aadhaarCard,
      );
      if (!mounted) return;
      if (error != null) {
        setState(() => _error = error);
        return;
      }
      if (provider.authToken != null && provider.authUser != null) {
        final user = UserModel.fromJson(provider.authUser!);
        final appState = context.read<AppState>();
        appState.token = provider.authToken;
        appState.user = user;
        await SessionService().saveSession(
          token: provider.authToken!,
          user: user,
        );
      }
      HapticFeedback.mediumImpact();
      navigator.pushNamedAndRemoveUntil(
        DeliveryStatusScreen.routeName,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const _HeroHeader(),
            FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(22, 22, 22, 28 + bottomInset),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _WelcomeCard(),
                        const SizedBox(height: 24),
                        _FieldLabel('Profile photo'),
                        const SizedBox(height: 8),
                        _DocumentUploadField(
                          fileName: _photoName,
                          hint: 'Upload delivery person photo',
                          uploading: _uploadingField == 'photo',
                          onTap: () => _pickAsset(
                            field: 'photo',
                            acceptedTypeGroups: const [
                              XTypeGroup(
                                label: 'Images',
                                extensions: ['png', 'jpg', 'jpeg', 'webp'],
                              ),
                            ],
                            onSelected: (value) => _photoUrl = value,
                            onNameSelected: (value) => _photoName = value,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FieldLabel('Full name'),
                        const SizedBox(height: 8),
                        _Field(
                          controller: _nameCtrl,
                          hint: 'John Doe',
                          icon: Icons.person_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter your name'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _FieldLabel('Phone number'),
                        const SizedBox(height: 8),
                        _Field(
                          controller: _phoneCtrl,
                          hint: '9876543210',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter your phone number'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _FieldLabel('Email address'),
                        const SizedBox(height: 8),
                        _Field(
                          controller: _emailCtrl,
                          hint: 'partner@doormart.com',
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            final text = v?.trim() ?? '';
                            if (text.isEmpty) return null;
                            if (!text.contains('@'))
                              return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _FieldLabel('Vehicle number'),
                        const SizedBox(height: 8),
                        _Field(
                          controller: _vehicleCtrl,
                          hint: 'TN01AB1234',
                          icon: Icons.two_wheeler_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter your vehicle number'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _FieldLabel('Licence number'),
                        const SizedBox(height: 8),
                        _Field(
                          controller: _licenseCtrl,
                          hint: 'DL1234567890123',
                          icon: Icons.drive_eta_rounded,
                          validator: (v) {
                            final text = v?.trim() ?? '';
                            if (text.isEmpty)
                              return 'Enter your licence number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _FieldLabel('PAN number'),
                        const SizedBox(height: 8),
                        _Field(
                          controller: _panCtrl,
                          hint: 'ABCDE1234F',
                          icon: Icons.badge_rounded,
                          validator: (v) {
                            final text = v?.trim().toUpperCase() ?? '';
                            if (text.isEmpty) return 'Enter PAN number';
                            if (!RegExp(
                              r'^[A-Z]{5}[0-9]{4}[A-Z]$',
                            ).hasMatch(text)) {
                              return 'Enter a valid PAN number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _FieldLabel('PAN card'),
                        const SizedBox(height: 8),
                        _DocumentUploadField(
                          fileName: _panCardName,
                          hint: 'Upload PAN card image or PDF',
                          uploading: _uploadingField == 'pan',
                          onTap: () => _pickAsset(
                            field: 'pan',
                            acceptedTypeGroups: const [
                              XTypeGroup(
                                label: 'Documents',
                                extensions: [
                                  'png',
                                  'jpg',
                                  'jpeg',
                                  'webp',
                                  'pdf',
                                ],
                              ),
                            ],
                            onSelected: (value) => _panCard = value,
                            onNameSelected: (value) => _panCardName = value,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FieldLabel('Licence photo'),
                        const SizedBox(height: 8),
                        _DocumentUploadField(
                          fileName: _licenseCardName,
                          hint: 'Upload driving licence photo',
                          uploading: _uploadingField == 'license',
                          onTap: () => _pickAsset(
                            field: 'license',
                            acceptedTypeGroups: const [
                              XTypeGroup(
                                label: 'Documents',
                                extensions: [
                                  'png',
                                  'jpg',
                                  'jpeg',
                                  'webp',
                                  'pdf',
                                ],
                              ),
                            ],
                            onSelected: (value) => _licenseCard = value,
                            onNameSelected: (value) => _licenseCardName = value,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FieldLabel('Aadhaar number'),
                        const SizedBox(height: 8),
                        _Field(
                          controller: _aadhaarCtrl,
                          hint: '1234 5678 9012',
                          icon: Icons.credit_card_rounded,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final text =
                                v?.replaceAll(RegExp(r'\s+'), '') ?? '';
                            if (text.isEmpty) return 'Enter Aadhaar number';
                            if (!RegExp(r'^\d{12}$').hasMatch(text)) {
                              return 'Enter a valid 12-digit Aadhaar number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _FieldLabel('Aadhaar card'),
                        const SizedBox(height: 8),
                        _DocumentUploadField(
                          fileName: _aadhaarCardName,
                          hint: 'Upload Aadhaar card image or PDF',
                          uploading: _uploadingField == 'aadhaar',
                          onTap: () => _pickAsset(
                            field: 'aadhaar',
                            acceptedTypeGroups: const [
                              XTypeGroup(
                                label: 'Documents',
                                extensions: [
                                  'png',
                                  'jpg',
                                  'jpeg',
                                  'webp',
                                  'pdf',
                                ],
                              ),
                            ],
                            onSelected: (value) => _aadhaarCard = value,
                            onNameSelected: (value) => _aadhaarCardName = value,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FieldLabel('Password'),
                        const SizedBox(height: 8),
                        _Field(
                          controller: _passwordCtrl,
                          hint: 'Create password',
                          icon: Icons.lock_rounded,
                          obscure: _obscurePassword,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: _kTextMid,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Use at least 6 characters'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _FieldLabel('Confirm password'),
                        const SizedBox(height: 8),
                        _Field(
                          controller: _confirmCtrl,
                          hint: 'Confirm password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscureConfirm,
                          suffix: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: _kTextMid,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Confirm password'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _TermsRow(
                          value: _termsAccepted,
                          onChanged: (value) =>
                              setState(() => _termsAccepted = value ?? false),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          _ErrorBanner(message: _error!),
                        ],
                        const SizedBox(height: 22),
                        _PrimaryBtn(
                          label: 'Create Delivery Account',
                          icon: Icons.person_add_alt_rounded,
                          loading: _loading,
                          onTap: _register,
                        ),
                        const SizedBox(height: 18),
                        _SecondaryAction(
                          label: 'Already have an account?',
                          action: 'Login',
                          onTap: () =>
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                DeliveryLoginScreen.routeName,
                                (route) => false,
                              ),
                        ),
                        const SizedBox(height: 24),
                        const _InfoStrip(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF26522), Color(0xFFD44010)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -40,
              right: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -25,
              left: -40,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.delivery_dining_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Doormart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '🚴 Delivery Partner Registration',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Container(
                  height: 28,
                  decoration: const BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kOrangeLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kOrange.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF26522), Color(0xFFD44010)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _kOrange.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text('🚀', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join the delivery team',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _kTextDark,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Create your account and start delivering',
                  style: TextStyle(fontSize: 12.5, color: _kTextMid),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _kTextDark,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        validator: validator,
        style: const TextStyle(
          color: _kTextDark,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: _kTextMid.withValues(alpha: 0.6),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(icon, color: _kOrange, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 46),
          suffixIcon: suffix,
          errorStyle: const TextStyle(
            color: _kRed,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DocumentUploadField extends StatelessWidget {
  const _DocumentUploadField({
    required this.fileName,
    required this.hint,
    required this.uploading,
    required this.onTap,
  });

  final String? fileName;
  final String hint;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: uploading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _kOrangeLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.upload_file_rounded,
                color: _kOrangeDeep,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName ?? hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fileName == null ? _kTextMid : _kTextDark,
                      fontSize: 14.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    uploading ? 'Uploading...' : 'Tap to select a file',
                    style: const TextStyle(
                      color: _kTextMid,
                      fontSize: 11.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (uploading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(_kOrangeDeep),
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: _kTextMid,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          activeColor: _kOrangeDeep,
          onChanged: onChanged,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(width: 4),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 11),
            child: Text(
              'I agree to the Terms & Conditions and confirm the details provided are correct.',
              style: TextStyle(color: _kTextMid, fontSize: 12.5, height: 1.35),
            ),
          ),
        ),
      ],
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.label,
    required this.action,
    required this.onTap,
  });

  final String label;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: _kTextMid,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(text: '$label '),
              TextSpan(
                text: action,
                style: const TextStyle(
                  color: _kOrangeDeep,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_rounded, color: _kRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _kRed,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryBtn extends StatefulWidget {
  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;

  @override
  State<_PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<_PrimaryBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
  );
  late final Animation<double> _s = Tween<double>(
    begin: 1.0,
    end: 0.96,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.loading ? null : (_) => _c.forward(),
      onTapUp: widget.loading
          ? null
          : (_) {
              _c.reverse();
              widget.onTap();
            },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: widget.loading
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFF26522), Color(0xFFD44010)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: widget.loading ? const Color(0xFFE0E0E0) : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.loading
                ? []
                : [
                    BoxShadow(
                      color: _kOrange.withValues(alpha: 0.38),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.shield_rounded, 'Verified\nPartners'),
      (Icons.payments_rounded, 'Fast\nPayouts'),
      (Icons.support_agent_rounded, 'Live\nSupport'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kOrangeLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kOrange.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          return Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _kOrange.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(item.$1, color: _kOrange, size: 20),
              ),
              const SizedBox(height: 7),
              Text(
                item.$2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: _kTextDark,
                  height: 1.3,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
