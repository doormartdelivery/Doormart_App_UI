import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/banner_model.dart';
import '../../providers/app_state.dart';
import '../app_page.dart';

class ManageBannersScreen extends StatefulWidget {
  const ManageBannersScreen({super.key});

  @override
  State<ManageBannersScreen> createState() => _ManageBannersScreenState();
}

class _ManageBannersScreenState extends State<ManageBannersScreen> {
  List<BannerModel> _banners = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final banners = await context.read<AppState>().adminBanners();
      if (!mounted) return;
      setState(() => _banners = banners);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _openEditor({BannerModel? banner}) async {
    final result = await showDialog<_BannerResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BannerEditorDialog(initial: banner),
    );
    if (result == null || !mounted) return;

    try {
      final state = context.read<AppState>();
      if (banner == null) {
        // ── CREATE ──
        await state.createBanner(
          title: result.title,
          imageUrl: result.imageUrl,
          active: result.active,
        );
        if (!mounted) return;
        _showSnack('Banner "${result.title}" created');
      } else {
        // ── UPDATE ──
        await state.updateBanner(
          bannerId: banner.id,
          title: result.title,
          imageUrl: result.imageUrl,
          active: result.active,
        );
        if (!mounted) return;
        _showSnack('Banner "${result.title}" updated');
      }
      await _load(); // refresh list immediately
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e', error: true);
    }
  }

  Future<void> _delete(BannerModel banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(title: banner.title),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<AppState>().deleteBanner(banner.id);
      if (!mounted) return;

      // Optimistically remove from local list for instant UI update
      setState(() => _banners.removeWhere((b) => b.id == banner.id));
      _showSnack('"${banner.title}" deleted');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Delete failed: $e', error: true);
      await _load(); // re-sync if delete failed
    }
  }

  Future<void> _toggleActive(BannerModel banner) async {
    // Optimistic update
    setState(() {
      final i = _banners.indexWhere((b) => b.id == banner.id);
      if (i != -1) {
        _banners[i] = BannerModel(
          id: banner.id,
          title: banner.title,
          imageUrl: banner.imageUrl,
          active: !banner.active,
        );
      }
    });

    try {
      await context.read<AppState>().updateBanner(
            bannerId: banner.id,
            title: banner.title,
            imageUrl: banner.imageUrl,
            active: !banner.active,
          );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Toggle failed: $e', error: true);
      await _load(); // revert on error
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : const Color(0xFF0F9D58),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Manage banners',
      actions: [
        IconButton.filled(
          tooltip: 'Add banner',
          onPressed: _loading ? null : () => _openEditor(),
          icon: const Icon(Icons.add),
        ),
      ],
      children: [_buildBody()],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_banners.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.slideshow_rounded,
                  size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text(
                'No banners yet',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
                label: const Text('Add first banner'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _banners
          .map(
            (banner) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BannerCard(
                banner: banner,
                onEdit: () => _openEditor(banner: banner),
                onDelete: () => _delete(banner),
                onToggleActive: () => _toggleActive(banner),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─── Banner Card ──────────────────────────────────────────────────────────────

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.banner,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final BannerModel banner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E8DF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail ───────────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: SizedBox(
              width: double.infinity,
              height: 140,
              child: _BannerThumb(imageUrl: banner.imageUrl),
            ),
          ),
          // ── Info + Actions ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Active / hidden chip
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: banner.active
                              ? const Color(0xFFEAF7EF)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              banner.active
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              size: 12,
                              color: banner.active
                                  ? const Color(0xFF0F9D58)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              banner.active ? 'Visible' : 'Hidden',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: banner.active
                                    ? const Color(0xFF0F9D58)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle active
                Tooltip(
                  message: banner.active ? 'Hide banner' : 'Show banner',
                  child: Switch.adaptive(
                    value: banner.active,
                    activeColor: const Color(0xFF0F9D58),
                    onChanged: (_) => onToggleActive(),
                  ),
                ),
                // Edit
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  tooltip: 'Edit',
                ),
                // Delete
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 20, color: Colors.red),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Banner Thumb ─────────────────────────────────────────────────────────────

class _BannerThumb extends StatelessWidget {
  const _BannerThumb({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _ThumbFallback(),
      );
    }
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _ThumbFallback(),
      );
    }
    return const _ThumbFallback();
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF1F5F9),
      child: Center(
        child: Icon(Icons.slideshow_rounded,
            size: 48, color: Color(0xFF0F9D58)),
      ),
    );
  }
}

// ─── Delete Confirm Dialog ────────────────────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: const Icon(Icons.delete_outline_rounded,
          color: Colors.red, size: 40),
      title: const Text('Delete banner',
          style: TextStyle(fontWeight: FontWeight.w900)),
      content: Text(
        'Are you sure you want to delete "$title"?\nThis cannot be undone.',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

// ─── Result carrier (replaces bool) ──────────────────────────────────────────

class _BannerResult {
  const _BannerResult({
    required this.title,
    required this.imageUrl,
    required this.active,
  });
  final String title;
  final String imageUrl;
  final bool active;
}

// ─── Banner Editor Dialog ─────────────────────────────────────────────────────

class _BannerEditorDialog extends StatefulWidget {
  const _BannerEditorDialog({required this.initial});
  final BannerModel? initial;

  @override
  State<_BannerEditorDialog> createState() => _BannerEditorDialogState();
}

class _BannerEditorDialogState extends State<_BannerEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _imageCtrl;
  late bool _active;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initial?.title ?? '');
    _imageCtrl = TextEditingController(text: widget.initial?.imageUrl ?? '');
    _active = widget.initial?.active ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final url =
          await context.read<AppState>().uploadCategoryImage(picked.path);
      if (!mounted) return;
      setState(() => _imageCtrl.text = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // Return the result to the parent — the parent handles the API call
    Navigator.pop(
      context,
      _BannerResult(
        title: _titleCtrl.text.trim(),
        imageUrl: _imageCtrl.text.trim(),
        active: _active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(
            isEdit ? Icons.edit_rounded : Icons.add_photo_alternate_rounded,
            color: const Color(0xFF0F9D58),
          ),
          const SizedBox(width: 8),
          Text(
            isEdit ? 'Edit banner' : 'Add banner',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Preview ────────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    color: const Color(0xFFF1F5F9),
                    child: _imageCtrl.text.trim().isEmpty
                        ? const Center(
                            child: Icon(Icons.slideshow_rounded,
                                size: 56, color: Color(0xFF94A3B8)),
                          )
                        : _imageCtrl.text.trim().startsWith('http')
                            ? Image.network(_imageCtrl.text.trim(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image_rounded,
                                          size: 56, color: Color(0xFF94A3B8)),
                                    ))
                            : Image.asset(_imageCtrl.text.trim(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image_rounded,
                                          size: 56, color: Color(0xFF94A3B8)),
                                    )),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Title ──────────────────────────────────────────────
                TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Banner title *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    prefixIcon: const Icon(Icons.title_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Title required' : null,
                ),

                const SizedBox(height: 12),

                // ── Image URL + Upload ─────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _imageCtrl,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Image *',
                          hintText: 'Upload from gallery',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          prefixIcon: const Icon(Icons.image_rounded),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Image required'
                                : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: _uploading ? null : _pickImage,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F9D58),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _uploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.upload_rounded),
                        label: Text(_uploading ? 'Uploading…' : 'Upload'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Active toggle ──────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE3E8DF)),
                  ),
                  child: SwitchListTile.adaptive(
                    value: _active,
                    activeColor: const Color(0xFF0F9D58),
                    onChanged: (v) => setState(() => _active = v),
                    title: const Text(
                      'Visible on home screen',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      _active
                          ? 'Users can see this banner'
                          : 'Banner is hidden from users',
                      style: const TextStyle(fontSize: 12),
                    ),
                    secondary: Icon(
                      _active
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: _active
                          ? const Color(0xFF0F9D58)
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F9D58),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _uploading ? null : _submit,
          icon: Icon(isEdit ? Icons.save_rounded : Icons.add_rounded),
          label: Text(isEdit ? 'Save changes' : 'Add banner'),
        ),
      ],
    );
  }
}