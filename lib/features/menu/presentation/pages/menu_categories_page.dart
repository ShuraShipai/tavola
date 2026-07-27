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
import '../../domain/repositories/menu_repository.dart';
import '../providers/menu_providers.dart';
import '../widgets/category_field.dart';

/// Category overview and editor for the Menu handoff screens 30–32 and 114.
class MenuCategoriesPage extends ConsumerWidget {
  const MenuCategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => TavolaAppShell(
    activeRoute: AppRoutes.menu,
    child: Padding(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: ref
          .watch(menuCatalogProvider)
          .when(
            loading: () =>
                const TavolaLoadingIndicator(label: 'Loading categories…'),
            error: (error, _) => TavolaErrorState(
              message: 'Unable to load menu categories.',
              onRetry: () => ref.invalidate(menuCatalogProvider),
            ),
            data: (catalog) => _CategoryContent(catalog: catalog),
          ),
    ),
  );
}

class _CategoryContent extends ConsumerWidget {
  const _CategoryContent({required this.catalog});
  final MenuCatalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1120),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Back to menu',
                  onPressed: () => context.go(AppRoutes.menu),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: TavolaPageHeader(
                    title: 'Menu categories',
                    subtitle:
                        'Organise menu items and choose their display order.',
                    actionLabel: 'Add category',
                    onAction: () => _showEditor(context, ref),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TavolaSpace.lg),
            if (catalog.categories.isEmpty)
              const TavolaEmptyState(
                title: 'No categories yet',
                message: 'Create a category before adding menu items.',
                icon: Icons.category_outlined,
              )
            else
              LayoutBuilder(
                builder: (context, box) => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: box.maxWidth >= 920
                        ? 3
                        : box.maxWidth >= 600
                        ? 2
                        : 1,
                    childAspectRatio: 1.7,
                    mainAxisSpacing: TavolaSpace.md,
                    crossAxisSpacing: TavolaSpace.md,
                  ),
                  itemCount: catalog.categories.length,
                  itemBuilder: (context, index) {
                    final category = catalog.categories[index];
                    final itemCount = catalog.items
                        .where((item) => item.categoryId == category.id)
                        .length;
                    return _CategoryCard(
                      category: category,
                      itemCount: itemCount,
                      onEdit: () =>
                          _showEditor(context, ref, category: category),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Future<void> _showEditor(
    BuildContext context,
    WidgetRef ref, {
    MenuCategory? category,
  }) async {
    final membership = await ref.read(currentMembershipProvider.future);
    if (!context.mounted) return;
    if (membership == null || !_canManage(membership.role)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only an owner or manager can manage categories.'),
        ),
      );
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      barrierColor: TavolaColors.overlay.withValues(alpha: 0.46),
      builder: (_) => _CategoryEditorDialog(
        category: category,
        catalog: catalog,
        repository: ref.read(menuRepositoryProvider),
        restaurantId: membership.restaurantId,
      ),
    );
    if (saved == true) ref.invalidate(menuCatalogProvider);
  }

  bool _canManage(TavolaRole role) =>
      role == TavolaRole.owner || role == TavolaRole.manager;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.itemCount,
    required this.onEdit,
  });
  final MenuCategory category;
  final int itemCount;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: TavolaColors.surface,
      border: Border.all(color: TavolaColors.border),
      borderRadius: TavolaRadius.medium,
      boxShadow: [
        BoxShadow(
          color: TavolaColors.shadow.withValues(alpha: 0.07),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(TavolaSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: TavolaColors.accentLight,
                  borderRadius: TavolaRadius.small,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(TavolaSpace.xs),
                  child: Icon(
                    Icons.category_outlined,
                    color: TavolaColors.accentDark,
                  ),
                ),
              ),
              const Spacer(),
              TavolaStatusBadge(
                label: category.isActive ? 'Active' : 'Hidden',
                color: category.isActive
                    ? TavolaColors.success
                    : TavolaColors.textMuted,
              ),
            ],
          ),
          const Spacer(),
          Text(
            category.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: TavolaSpace.xxs),
          Text(
            '$itemCount ${itemCount == 1 ? 'item' : 'items'} · Display order ${category.sortOrder}',
            style: const TextStyle(
              color: TavolaColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: TavolaSpace.xs),
          TextButton(onPressed: onEdit, child: const Text('Edit category')),
        ],
      ),
    ),
  );
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({
    required this.category,
    required this.catalog,
    required this.repository,
    required this.restaurantId,
  });
  final MenuCategory? category;
  final MenuCatalog catalog;
  final MenuRepository repository;
  final String restaurantId;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.category?.name ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.category?.description ?? '',
  );
  late final TextEditingController _order = TextEditingController(
    text: widget.category == null ? '' : '${widget.category!.sortOrder}',
  );
  late final FocusNode _orderFocus = FocusNode()..addListener(_selectOrder);
  late bool _active = widget.category?.isActive ?? true;
  final _form = GlobalKey<FormState>();
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _order.dispose();
    _orderFocus
      ..removeListener(_selectOrder)
      ..dispose();
    super.dispose();
  }

  void _selectOrder() {
    if (!_orderFocus.hasFocus) return;
    _order.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _order.text.length,
    );
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.saveCategory(
        restaurantId: widget.restaurantId,
        id: widget.category?.id,
        name: _name.text,
        sortOrder: _order.text.trim().isEmpty
            ? _nextDisplayOrder()
            : int.parse(_order.text),
        isActive: _active,
        description: _description.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not save category: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Category positions are one-based in the staff UI. Counting is more
  /// resilient than `max + 1` while older restaurants still have legacy
  /// categories whose database default was all zero.
  int _nextDisplayOrder() => widget.catalog.categories.length + 1;

  Future<void> _delete() async {
    final category = widget.category;
    if (category == null) return;
    final replacement = await showDialog<String?>(
      context: context,
      builder: (context) => _MoveItemsDialog(
        category: category,
        categories: widget.catalog.categories
            .where((item) => item.id != category.id)
            .toList(),
        itemCount: widget.catalog.items
            .where((item) => item.categoryId == category.id)
            .length,
      ),
    );
    // The dialog returns a selection (including the explicit uncategorised
    // choice) only after the destructive action is confirmed.
    if (!mounted || replacement == _cancelled) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.deleteCategory(
        category.id,
        moveItemsToCategoryId: replacement,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = _deleteCategoryError(error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(TavolaSpace.lg),
    shape: const RoundedRectangleBorder(borderRadius: TavolaRadius.large),
    child: SizedBox(
      width: 468,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TavolaSpace.lg,
              TavolaSpace.lg,
              TavolaSpace.lg,
              TavolaSpace.xs,
            ),
            child: Text(
              widget.category == null
                  ? 'Add menu category'
                  : 'Edit “${widget.category!.name}”',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(TavolaSpace.lg),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CategoryField(
                    label: 'Category name',
                    child: TextFormField(
                      controller: _name,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Seasonal Specials',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter a category name'
                          : null,
                    ),
                  ),
                  const SizedBox(height: TavolaSpace.md),
                  CategoryField(
                    label: 'Description',
                    child: TextFormField(
                      controller: _description,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Short description shown to staff',
                      ),
                    ),
                  ),
                  const SizedBox(height: TavolaSpace.md),
                  CategoryField(
                    label: 'Display order',
                    child: TextFormField(
                      controller: _order,
                      focusNode: _orderFocus,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '6'),
                      validator: (value) =>
                          value == null ||
                              value.trim().isEmpty ||
                              int.tryParse(value.trim()) != null
                          ? null
                          : 'Enter a whole number',
                    ),
                  ),
                  const SizedBox(height: TavolaSpace.md),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Available for ordering'),
                    subtitle: const Text(
                      'Staff can add items from this category',
                    ),
                    value: _active,
                    activeTrackColor: TavolaColors.accent,
                    activeThumbColor: TavolaColors.surface,
                    onChanged: (value) => setState(() => _active = value),
                  ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: TavolaColors.error),
                    ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(TavolaSpace.md),
            decoration: const BoxDecoration(
              color: TavolaColors.background,
              border: Border(top: BorderSide(color: TavolaColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.category != null) ...[
                  TextButton(
                    onPressed: _saving ? null : _delete,
                    style: TextButton.styleFrom(
                      foregroundColor: TavolaColors.error,
                    ),
                    child: const Text('Delete category'),
                  ),
                  const Spacer(),
                ],
                OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: TavolaSpace.sm),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(
                    _saving
                        ? 'Saving…'
                        : widget.category == null
                        ? 'Create Category'
                        : 'Save Changes',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  String _deleteCategoryError(Object error) {
    final message = error.toString();
    if (message.contains('delete_menu_category') &&
        message.contains('PGRST202')) {
      return 'Category deletion needs the latest Tavola database migration. Run 20260727140000_complete_menu_management.sql in Supabase, then try again.';
    }
    return 'Could not delete category. Please try again.';
  }
}

const _cancelled = '__cancelled__';

class _MoveItemsDialog extends StatefulWidget {
  const _MoveItemsDialog({
    required this.category,
    required this.categories,
    required this.itemCount,
  });
  final MenuCategory category;
  final List<MenuCategory> categories;
  final int itemCount;

  @override
  State<_MoveItemsDialog> createState() => _MoveItemsDialogState();
}

class _MoveItemsDialogState extends State<_MoveItemsDialog> {
  String? _destination;

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const Icon(Icons.error_outline_rounded, color: TavolaColors.error),
    title: Text('Delete “${widget.category.name}”?'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.itemCount == 0
                ? 'This category will be permanently removed.'
                : '${widget.itemCount} menu items must be moved before this category is deleted.',
          ),
          if (widget.itemCount > 0) ...[
            const SizedBox(height: TavolaSpace.md),
            DropdownButtonFormField<String?>(
              initialValue: _destination,
              decoration: const InputDecoration(labelText: 'Move items to'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Uncategorised'),
                ),
                ...widget.categories.map(
                  (category) => DropdownMenuItem<String?>(
                    value: category.id,
                    child: Text(category.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _destination = value),
            ),
          ],
          const SizedBox(height: TavolaSpace.sm),
          const Text(
            'Historical orders retain their category snapshots.',
            style: TextStyle(color: TavolaColors.textSecondary),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, _cancelled),
        child: const Text('Keep category'),
      ),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: TavolaColors.error),
        onPressed: () => Navigator.pop(context, _destination),
        child: const Text('Delete category'),
      ),
    ],
  );
}
