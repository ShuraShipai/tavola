import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../../auth/domain/entities/restaurant_membership.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/menu_entities.dart';
import '../providers/menu_providers.dart';
import '../widgets/menu_image_picker.dart';

/// The full-screen add/edit workflow from the Menu design handoff (screens 34–35).
class MenuItemEditorPage extends ConsumerStatefulWidget {
  const MenuItemEditorPage({this.itemId, super.key});

  final String? itemId;

  bool get isNew => itemId == null;

  @override
  ConsumerState<MenuItemEditorPage> createState() => _MenuItemEditorPageState();
}

class _MenuItemEditorPageState extends ConsumerState<MenuItemEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _taxRate = TextEditingController();
  final _description = TextEditingController();
  String? _categoryId;
  String? _foodType;
  bool _available = true;
  bool _trackStock = false;
  bool _chefRecommended = false;
  Uint8List? _imageBytes;
  String? _imageUrl;
  String _imageExtension = 'jpg';
  bool _initialised = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _taxRate.dispose();
    _description.dispose();
    super.dispose();
  }

  void _setInitialValues(MenuItem? item) {
    if (_initialised) return;
    _initialised = true;
    if (item == null) return;
    _name.text = item.name;
    _price.text = (item.priceMinor / 100).toStringAsFixed(2);
    _taxRate.text = (item.taxRateBasisPoints / 100).toStringAsFixed(2);
    _description.text = item.description ?? '';
    _categoryId = item.categoryId;
    _foodType = item.foodType;
    _available = item.isAvailable;
    _trackStock = item.tracksStock;
    _chefRecommended = item.isChefRecommended;
  }

  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: AppRoutes.menu,
    child: Padding(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: ref
          .watch(menuCatalogProvider)
          .when(
            loading: () =>
                const TavolaLoadingIndicator(label: 'Loading menu item…'),
            error: (error, _) => TavolaErrorState(
              message: 'Unable to load this menu item.',
              onRetry: () => ref.invalidate(menuCatalogProvider),
            ),
            data: (catalog) {
              final item = widget.isNew
                  ? null
                  : catalog.items
                        .where((candidate) => candidate.id == widget.itemId)
                        .firstOrNull;
              if (!widget.isNew && item == null) {
                return const TavolaEmptyState(
                  title: 'Menu item not found',
                  message:
                      'It may have been deleted or you may no longer have access.',
                  icon: Icons.restaurant_menu_outlined,
                );
              }
              _setInitialValues(item);
              return _EditorContent(
                catalog: catalog,
                item: item,
                formKey: _formKey,
                details: _itemDetails(catalog),
                availability: _availabilityControls(),
              );
            },
          ),
    ),
  );

  Widget _itemDetails(MenuCatalog catalog) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FormLabel(
        label: 'Item name',
        child: TextFormField(
          controller: _name,
          autofocus: true,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'e.g. Truffle Mushroom Pasta',
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Enter an item name'
              : null,
        ),
      ),
      const SizedBox(height: TavolaSpace.md),
      Row(
        children: [
          Expanded(child: _categoryField(catalog)),
          const SizedBox(width: TavolaSpace.md),
          Expanded(child: _foodTypeField()),
        ],
      ),
      const SizedBox(height: TavolaSpace.md),
      Row(
        children: [
          Expanded(child: _priceField()),
          const SizedBox(width: TavolaSpace.md),
          Expanded(child: _taxRateField()),
        ],
      ),
      const SizedBox(height: TavolaSpace.md),
      _FormLabel(
        label: 'Description',
        child: TextFormField(
          controller: _description,
          minLines: 4,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Ingredients and a short description',
          ),
        ),
      ),
    ],
  );

  Widget _categoryField(MenuCatalog catalog) => _FormLabel(
    label: 'Category',
    child: DropdownButtonFormField<String>(
      initialValue: _categoryId,
      items: catalog.categories
          .where((category) => category.isActive || category.id == _categoryId)
          .map(
            (category) => DropdownMenuItem(
              value: category.id,
              child: Text(category.name),
            ),
          )
          .toList(),
      validator: (value) => value == null ? 'Select a category' : null,
      onChanged: (value) => setState(() => _categoryId = value),
    ),
  );

  Widget _foodTypeField() => _FormLabel(
    label: 'Food type',
    child: DropdownButtonFormField<String>(
      initialValue: _foodType,
      hint: const Text('Select type'),
      items: const [
        DropdownMenuItem(value: 'Veg', child: Text('Vegetarian')),
        DropdownMenuItem(value: 'Non-veg', child: Text('Non-vegetarian')),
        DropdownMenuItem(value: 'Vegan', child: Text('Vegan')),
        DropdownMenuItem(value: 'Beverage', child: Text('Beverage')),
      ],
      onChanged: (value) => setState(() => _foodType = value),
    ),
  );

  Widget _priceField() => _FormLabel(
    label: 'Selling price',
    child: TextFormField(
      controller: _price,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(hintText: '₹ 0.00'),
      validator: (value) {
        final parsed = double.tryParse(value?.trim() ?? '');
        return parsed == null || parsed < 0 ? 'Enter a valid price' : null;
      },
    ),
  );

  Widget _taxRateField() => _FormLabel(
    label: 'Tax rate',
    child: TextFormField(
      controller: _taxRate,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(hintText: 'GST 5%'),
      validator: (value) {
        final rawValue = value?.trim() ?? '';
        if (rawValue.isEmpty) return null;
        final parsed = double.tryParse(rawValue);
        return parsed == null || parsed < 0 || parsed > 100
            ? 'Enter a tax rate from 0 to 100'
            : null;
      },
    ),
  );

  Widget _availabilityControls() => Column(
    children: [
      _AvailabilityRow(
        title: 'Available',
        subtitle: 'Show in new orders',
        value: _available,
        onChanged: (value) => setState(() => _available = value),
      ),
      const Divider(height: TavolaSpace.xl),
      _AvailabilityRow(
        title: 'Track stock',
        subtitle: 'Link with inventory',
        value: _trackStock,
        onChanged: (value) => setState(() => _trackStock = value),
      ),
      const Divider(height: TavolaSpace.xl),
      _AvailabilityRow(
        title: 'Chef recommendation',
        subtitle: 'Highlight this item for ordering staff.',
        value: _chefRecommended,
        onChanged: (value) => setState(() => _chefRecommended = value),
      ),
    ],
  );

  Future<void> _save(MenuItem? item) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final membership = await ref.read(currentMembershipProvider.future);
    if (!mounted) return;
    if (membership == null || !_canManageMenu(membership.role)) {
      setState(() => _error = 'Only an owner or manager can save menu items.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      String? imagePath;
      if (_imageBytes != null) {
        imagePath = await ref
            .read(menuRepositoryProvider)
            .uploadItemImage(
              restaurantId: membership.restaurantId,
              bytes: _imageBytes!,
              extension: _imageExtension,
            );
      } else if (_imageUrl != null) {
        imagePath = _imageUrl;
      }
      await ref
          .read(menuRepositoryProvider)
          .saveItem(
            restaurantId: membership.restaurantId,
            id: item?.id,
            name: _name.text,
            categoryId: _categoryId,
            description: _description.text,
            imagePath: imagePath ?? item?.imageStoragePath,
            priceMinor: (double.parse(_price.text.trim()) * 100).round(),
            isAvailable: _available,
            foodType: _foodType,
            taxRateBasisPoints: _taxRate.text.trim().isEmpty
                ? 0
                : (double.parse(_taxRate.text.trim()) * 100).round(),
            isActive: item?.isActive ?? true,
            sortOrder: item?.sortOrder ?? 0,
            tracksStock: _trackStock,
            isChefRecommended: _chefRecommended,
          );
      ref.invalidate(menuCatalogProvider);
      if (mounted) context.go(AppRoutes.menu);
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not save menu item: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete(MenuItem item) async {
    final membership = await ref.read(currentMembershipProvider.future);
    if (!mounted) return;
    if (membership == null || !_canManageMenu(membership.role)) {
      setState(
        () => _error = 'Only an owner or manager can delete menu items.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.error_outline_rounded,
          color: TavolaColors.error,
        ),
        title: Text('Delete “${item.name}”?'),
        content: const Text(
          'This removes the item from the menu permanently. Historical orders retain their item and price snapshots.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep item'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: TavolaColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete item'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(menuRepositoryProvider).deleteItem(item.id);
      ref.invalidate(menuCatalogProvider);
      if (mounted) context.go(AppRoutes.menu);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not delete menu item: $error');
      }
    }
  }

  bool _canManageMenu(TavolaRole role) =>
      role == TavolaRole.owner || role == TavolaRole.manager;

  void selectImage(Uint8List bytes, String extension) => setState(() {
    _imageBytes = bytes;
    _imageExtension = extension;
    _imageUrl = null;
  });

  void useImageUrl(String url) => setState(() {
    _imageUrl = url;
    _imageBytes = null;
  });
}

class _EditorContent extends StatelessWidget {
  const _EditorContent({
    required this.catalog,
    required this.item,
    required this.formKey,
    required this.details,
    required this.availability,
  });
  final MenuCatalog catalog;
  final MenuItem? item;
  final GlobalKey<FormState> formKey;
  final Widget details;
  final Widget availability;

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_MenuItemEditorPageState>()!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TavolaPageHeader(
                  title: item == null ? 'Add Menu Item' : 'Edit Menu Item',
                  subtitle: item == null
                      ? 'Create a new item for the restaurant menu'
                      : 'Update this item’s menu details.',
                ),
              ),
              const SizedBox(width: TavolaSpace.md),
              OutlinedButton(
                onPressed: state._saving
                    ? null
                    : () => context.go(AppRoutes.menu),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: TavolaSpace.sm),
              FilledButton(
                onPressed: state._saving ? null : () => state._save(item),
                style: FilledButton.styleFrom(
                  backgroundColor: TavolaColors.accent,
                  foregroundColor: TavolaColors.primary,
                ),
                child: Text(
                  state._saving
                      ? 'Saving…'
                      : item == null
                      ? 'Save Item'
                      : 'Save Changes',
                ),
              ),
            ],
          ),
          const SizedBox(height: TavolaSpace.lg),
          Form(
            key: formKey,
            child: LayoutBuilder(
              builder: (context, box) {
                final imagePanel = TavolaPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Image & availability',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: TavolaSpace.lg),
                      MenuImagePicker(
                        height: 150,
                        compactCopy: true,
                        imageBytes: state._imageBytes,
                        imageUrl:
                            state._imageUrl ??
                            (state._imageBytes == null
                                ? item?.imagePath
                                : null),
                        onImageSelected: state.selectImage,
                        onUrlPasted: state.useImageUrl,
                      ),
                      availability,
                    ],
                  ),
                );
                final detailPanel = TavolaPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item details',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: TavolaSpace.lg),
                      details,
                    ],
                  ),
                );
                if (box.maxWidth < 860) {
                  return Column(
                    children: [
                      detailPanel,
                      const SizedBox(height: TavolaSpace.lg),
                      imagePanel,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: detailPanel),
                    const SizedBox(width: TavolaSpace.md),
                    Expanded(flex: 2, child: imagePanel),
                  ],
                );
              },
            ),
          ),
          if (state._error != null) ...[
            const SizedBox(height: TavolaSpace.md),
            Text(
              state._error!,
              style: const TextStyle(color: TavolaColors.error),
            ),
          ],
          if (item != null) ...[
            const SizedBox(height: TavolaSpace.lg),
            OutlinedButton.icon(
              onPressed: state._saving
                  ? null
                  : () => state._confirmDelete(item!),
              style: OutlinedButton.styleFrom(
                foregroundColor: TavolaColors.error,
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete item'),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: TavolaSpace.xs),
      child,
    ],
  );
}

class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: TavolaSpace.xxs),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: TavolaColors.accent,
        activeThumbColor: Colors.white,
      ),
    ],
  );
}
