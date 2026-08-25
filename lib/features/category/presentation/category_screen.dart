import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';
import '../../../core/db/enums.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/money_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/providers/database_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/category_repository.dart';

part 'category_screen.g.dart';

@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(Ref ref) =>
    CategoryRepository(ref.watch(appDatabaseProvider));

/// Danh mục theo loại, **gồm cả những cái đã ẩn** — màn hình quản lý phải thấy
/// hết, khác với lưới chọn ở màn hình Nhập vào.
///
/// Viết tay vì kiểu trả về nhắc tới `Category`, lớp drift nằm trong file `part`
/// mà `riverpod_generator` không sinh được tham chiếu tới.
final manageableCategoriesProvider =
    StreamProvider.family<List<Category>, CategoryType>(
  (ref, type) => ref
      .watch(categoryRepositoryProvider)
      .watchByType(type, includeArchived: true),
);

/// Quản lý danh mục. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục F.2.
///
/// MoneyNote cho sửa danh mục ngay trong lưới chọn, nhưng chỉ đổi được tên.
/// Ở đây đổi được cả icon, màu, thứ tự, và ẩn đi mà không mất lịch sử.
class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Danh mục'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chi tiêu'),
              Tab(text: 'Thu nhập'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CategoryList(type: CategoryType.expense),
            _CategoryList(type: CategoryType.income),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({required this.type});

  final CategoryType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(manageableCategoriesProvider(type)).value;
    if (list == null) return const SizedBox.shrink();

    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.category_outlined,
        message: 'Chưa có danh mục ${type == CategoryType.expense ? 'chi' : 'thu'} nào.',
        actionLabel: 'Thêm danh mục',
        onAction: () => CategoryEditSheet.show(context, type: type),
      );
    }

    return Scaffold(
      // ReorderableListView cần chiều cao xác định; Scaffold lồng cho phép có
      // FAB riêng cho từng tab.
      body: ReorderableListView.builder(
        padding: const EdgeInsets.only(bottom: Tokens.xxxl * 2),
        itemCount: list.length,
        // `onReorderItem` thay cho `onReorder` đã khai tử: bản mới tự bù chỉ
        // số cho phần tử vừa bị gỡ, nên không phải tự trừ 1 khi kéo xuống —
        // đúng chỗ mà bản cũ hay bị lệch một ô.
        onReorderItem: (cu, moi) {
          final ids = list.map((c) => c.id).toList();
          final id = ids.removeAt(cu);
          ids.insert(moi, id);
          ref.read(categoryRepositoryProvider).reorder(ids);
        },
        itemBuilder: (context, i) => _CategoryRow(
          key: ValueKey(list[i].id),
          category: list[i],
          index: i,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CategoryEditSheet.show(context, type: type),
        icon: const Icon(Icons.add),
        label: const Text('Thêm'),
      ),
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({
    required this.category,
    required this.index,
    super.key,
  });

  final Category category;
  final int index;

  Future<void> _xoa(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(categoryRepositoryProvider);
    final ketQua = await repo.deleteCategory(category.id);
    if (!context.mounted) return;

    switch (ketQua) {
      case CategoryActionOk():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xoá "${category.name}".')),
        );
      // Còn giao dịch: không xoá được, mời ẩn thay thế.
      case CategoryActionRejected(:final reason):
        final an = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Không xoá được danh mục'),
            content: Text(reason),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Để nguyên'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ẩn danh mục'),
              ),
            ],
          ),
        );
        if (an ?? false) {
          await repo.setArchived(category.id, archived: true);
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(category.colorValue);
    final daAn = category.isArchived;

    return ListTile(
      minTileHeight: Tokens.minTouchTarget,
      onTap: () => CategoryEditSheet.show(
        context,
        type: category.type,
        existing: category,
      ),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: daAn ? 0.08 : 0.16),
        child: Icon(
          AppIcons.resolve(category.iconCode),
          color: daAn ? context.colorScheme.onSurfaceVariant : color,
          size: 20,
        ),
      ),
      title: Text(
        category.name,
        style: context.textTheme.titleMedium?.copyWith(
          color: daAn ? context.colorScheme.onSurfaceVariant : null,
          decoration: daAn ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: daAn
          ? Text('Đã ẩn — không hiện trong lưới chọn',
              style: context.textTheme.labelSmall)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'edit':
                  await CategoryEditSheet.show(
                    context,
                    type: category.type,
                    existing: category,
                  );
                case 'archive':
                  await ref
                      .read(categoryRepositoryProvider)
                      .setArchived(category.id, archived: true);
                case 'unarchive':
                  await ref
                      .read(categoryRepositoryProvider)
                      .setArchived(category.id, archived: false);
                case 'delete':
                  await _xoa(context, ref);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Sửa')),
              if (daAn)
                const PopupMenuItem(value: 'unarchive', child: Text('Bỏ ẩn'))
              else
                const PopupMenuItem(value: 'archive', child: Text('Ẩn')),
              const PopupMenuItem(value: 'delete', child: Text('Xoá')),
            ],
          ),
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(right: Tokens.sm),
              child: Icon(
                Icons.drag_handle,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bảng thêm / sửa danh mục.
class CategoryEditSheet extends ConsumerStatefulWidget {
  const CategoryEditSheet({required this.type, super.key, this.existing});

  final CategoryType type;
  final Category? existing;

  static Future<void> show(
    BuildContext context, {
    required CategoryType type,
    Category? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CategoryEditSheet(type: type, existing: existing),
    );
  }

  @override
  ConsumerState<CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends ConsumerState<CategoryEditSheet> {
  late final TextEditingController _nameCtrl;
  late int _iconCode;
  late int _colorValue;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _iconCode = e?.iconCode ?? AppIcons.category.first.codePoint;
    _colorValue = e?.colorValue ?? AppPalette.colors.first.toARGB32();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _luu() async {
    final ten = _nameCtrl.text.trim();
    if (ten.isEmpty) {
      setState(() => _error = 'Danh mục cần có tên.');
      return;
    }

    final repo = ref.read(categoryRepositoryProvider);
    if (_isEditing) {
      await repo.updateCategory(
        widget.existing!,
        name: ten,
        iconCode: _iconCode,
        colorValue: _colorValue,
      );
    } else {
      await repo.createCategory(
        name: ten,
        type: widget.type,
        iconCode: _iconCode,
        colorValue: _colorValue,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                Tokens.screenPadding,
                Tokens.screenPadding,
                Tokens.screenPadding,
                Tokens.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing ? 'Sửa danh mục' : 'Danh mục mới',
                    style: context.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Tokens.sm),
                  Text(
                    widget.type == CategoryType.expense
                        ? 'Danh mục chi tiêu'
                        : 'Danh mục thu nhập',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Tokens.xl),

                  TextField(
                    controller: _nameCtrl,
                    maxLength: 50,
                    autofocus: !_isEditing,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Tên danh mục',
                      hintText: 'Ăn uống, Đi lại…',
                      errorText: _error,
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  const SizedBox(height: Tokens.lg),

                  Text('Icon', style: context.textTheme.labelSmall),
                  const SizedBox(height: Tokens.sm),
                  Wrap(
                    spacing: Tokens.sm,
                    runSpacing: Tokens.sm,
                    children: [
                      for (final icon in AppIcons.category)
                        _PickTile(
                          selected: _iconCode == icon.codePoint,
                          onTap: () =>
                              setState(() => _iconCode = icon.codePoint),
                          child: Icon(
                            icon,
                            size: 22,
                            color: Color(_colorValue),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Tokens.lg),

                  Text('Màu', style: context.textTheme.labelSmall),
                  const SizedBox(height: Tokens.sm),
                  Wrap(
                    spacing: Tokens.sm,
                    runSpacing: Tokens.sm,
                    children: [
                      for (final color in AppPalette.colors)
                        _PickTile(
                          selected: _colorValue == color.toARGB32(),
                          onTap: () =>
                              setState(() => _colorValue = color.toARGB32()),
                          child: Container(
                            width: Tokens.xl,
                            height: Tokens.xl,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: Tokens.brFull,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Nút ghim ở đáy — cùng nguyên tắc với mọi bảng trượt khác.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.screenPadding,
              Tokens.sm,
              Tokens.screenPadding,
              Tokens.lg,
            ),
            child: SizedBox(
              width: double.infinity,
              height: Tokens.minTouchTarget + Tokens.sm,
              child: FilledButton(
                onPressed: _luu,
                child: Text(_isEditing ? 'Lưu thay đổi' : 'Thêm danh mục'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return SizedBox(
      width: Tokens.minTouchTarget,
      height: Tokens.minTouchTarget,
      child: Material(
        color: selected ? cs.secondaryContainer : cs.surfaceContainerHigh,
        borderRadius: Tokens.brSm,
        child: InkWell(
          borderRadius: Tokens.brSm,
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}
