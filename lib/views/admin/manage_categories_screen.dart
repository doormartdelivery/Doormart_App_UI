import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/category_model.dart';
import '../../providers/app_state.dart';
import '../app_page.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  static const routeName = '/admin/categories';

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  bool _uploading = false;

  Future<void> _openEditor({CategoryModel? category}) async {
    final form = _CategoryFormData.fromCategory(category);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _CategoryEditorSheet(
          initial: form,
          isEditing: category != null,
          onSave: (updated) async {
            Navigator.pop(sheetContext, true);
            final state = context.read<AppState>();

            if (category == null) {
              await state.createCategory(
                name: updated.name,
                description: updated.description,
                imageUrl: updated.imageUrl,
              );
            } else {
              await state.updateCategory(
                categoryId: category.id,
                name: updated.name,
                description: updated.description,
                imageUrl: updated.imageUrl,
              );
            }

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  category == null
                      ? 'Category added successfully'
                      : 'Category updated successfully',
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true) {
      setState(() {});
    }
  }

  Future<void> _delete(CategoryModel category) async {
    await context.read<AppState>().deleteCategory(category.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${category.name} removed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Manage categories',
      actions: [
        if (_uploading)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        IconButton.filled(
          tooltip: 'Add category',
          onPressed: () => _openEditor(),
          icon: const Icon(Icons.add),
        ),
      ],
      children: [
        Consumer<AppState>(
          builder: (context, state, _) {
            final categories = state.categoryCatalog;
            if (categories.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No categories yet'),
              );
            }
            return Column(
              children: [
                ...categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: _CategoryPreview(imageUrl: category.imageUrl),
                          ),
                        ),
                        title: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          category.description.isEmpty
                              ? 'No description'
                              : category.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              onPressed: () => _openEditor(category: category),
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              onPressed: () => _delete(category),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CategoryPreview extends StatelessWidget {
  const _CategoryPreview({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('http')) {
      return Image.network(imageUrl, fit: BoxFit.cover);
    }
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(imageUrl, fit: BoxFit.cover);
    }
    return Container(
      color: const Color(0xFFF3F5F2),
      alignment: Alignment.center,
      child: const Icon(Icons.category, color: Color(0xFF0F766E)),
    );
  }
}

class _CategoryEditorSheet extends StatefulWidget {
  const _CategoryEditorSheet({
    required this.initial,
    required this.onSave,
    required this.isEditing,
  });

  final _CategoryFormData initial;
  final Future<void> Function(_CategoryFormData updated) onSave;
  final bool isEditing;

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  final ImagePicker _imagePicker = ImagePicker();
  bool _saving = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial.name);
    _descriptionController = TextEditingController(text: widget.initial.description);
    _imageUrlController = TextEditingController(text: widget.initial.imageUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(
        _CategoryFormData(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrl: _imageUrlController.text.trim(),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploadingImage = true);
    try {
      final imageUrl = await context.read<AppState>().uploadCategoryImage(picked.path);
      if (!mounted) return;
      _imageUrlController.text = imageUrl;
      setState(() {});
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF7FAF4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isEditing ? 'Edit category' : 'Add category',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add a category image URL and write a short description for the user app.',
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE3E8DF)),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    color: const Color(0xFFF3F5F2),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_imageUrlController.text.trim().startsWith('http'))
                          Image.network(
                            _imageUrlController.text.trim(),
                            fit: BoxFit.cover,
                          )
                        else if (_imageUrlController.text.trim().startsWith('assets/'))
                          Image.asset(
                            _imageUrlController.text.trim(),
                            fit: BoxFit.cover,
                          )
                        else
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 52,
                            color: Color(0xFF0F766E),
                          ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _imageUrlController.text.trim().isEmpty
                                        ? 'No image selected'
                                        : 'Image selected',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _uploadingImage ? null : _pickAndUploadImage,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.black.withValues(alpha: 0.2),
                                  ),
                                  icon: _uploadingImage
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.upload),
                                  label: Text(_uploadingImage ? 'Uploading' : 'Upload'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _imageUrlController,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Image URL or asset path',
              hintText: 'Upload from phone or paste https://... or assets/images/categories/...',
              filled: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Category name',
              hintText: 'Vegetables, Dairy, Fruits...',
              filled: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Short description shown on the user page',
              filled: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryFormData {
  _CategoryFormData({
    required this.name,
    required this.description,
    required this.imageUrl,
  });

  factory _CategoryFormData.fromCategory(CategoryModel? category) {
    return _CategoryFormData(
      name: category?.name ?? '',
      description: category?.description ?? '',
      imageUrl: category?.imageUrl ?? '',
    );
  }

  final String name;
  final String description;
  final String imageUrl;
}
