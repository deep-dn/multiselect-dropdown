part of '../multi_dropdown.dart';

/// Dropdown widget for the multiselect dropdown.
class _Dropdown<T> extends StatefulWidget {
  /// Creates a dropdown widget.
  const _Dropdown({
    required this.decoration,
    required this.width,
    required this.searchEnabled,
    required this.dropdownItemDecoration,
    required this.searchDecoration,
    required this.maxSelections,
    required this.items,
    required this.onItemTap,
    Key? key,
    this.onSearchChange,
    this.itemBuilder,
    this.itemSeparator,
    this.singleSelect = false,
  }) : super(key: key);

  /// The decoration of the dropdown.
  final DropdownDecoration decoration;

  /// Whether the search field is enabled.
  final bool searchEnabled;

  /// The width of the dropdown.
  final double width;

  /// The decoration of the dropdown items.
  final DropdownItemDecoration dropdownItemDecoration;

  /// Dropdown item builder, if not provided, the default ListTile will be used.
  final DropdownItemBuilder<T>? itemBuilder;

  /// The separator between the dropdown items.
  final Widget? itemSeparator;

  /// The decoration of the search field.
  final SearchFieldDecoration searchDecoration;

  /// The maximum number of selections allowed.
  final int maxSelections;

  /// The list of dropdown items.
  final List<DropdownItem<T>> items;

  /// The callback when an item is tapped.
  final ValueChanged<DropdownItem<T>> onItemTap;

  /// The callback when the search field value changes.
  final ValueChanged<String>? onSearchChange;

  /// Whether the selection is single.
  final bool singleSelect;

  @override
  State<_Dropdown<T>> createState() => _DropdownState<T>();
}

class _DropdownState<T> extends State<_Dropdown<T>> {
  int get _selectedCount =>
      widget.items.where((element) => element.selected).length;

  static const Map<ShortcutActivator, Intent> _webShortcuts =
      <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowDown):
        DirectionalFocusIntent(TraversalDirection.down),
    SingleActivator(LogicalKeyboardKey.arrowUp):
        DirectionalFocusIntent(TraversalDirection.up),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final child = Material(
      elevation: widget.decoration.elevation,
      borderRadius: widget.decoration.borderRadius,
      clipBehavior: Clip.antiAlias,
      color: widget.decoration.backgroundColor,
      surfaceTintColor: widget.decoration.backgroundColor,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: widget.decoration.borderRadius,
            color: widget.decoration.backgroundColor,
            backgroundBlendMode: BlendMode.dstATop,
          ),
          constraints: BoxConstraints(
            maxWidth: widget.width,
            maxHeight: widget.decoration.maxHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.searchEnabled)
                _SearchField(
                  decoration: widget.searchDecoration,
                  onChanged: _onSearchChange,
                ),
              if (widget.decoration.header != null)
                Flexible(child: widget.decoration.header!),
              Flexible(
                child: ListView.separated(
                  separatorBuilder: (_, __) =>
                      widget.itemSeparator ?? const SizedBox.shrink(),
                  shrinkWrap: true,
                  itemCount: widget.items.length,
                  itemBuilder: (_, int index) => _buildOption(index, theme),
                ),
              ),
              if (widget.items.isEmpty && widget.searchEnabled)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'No items found',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              if (widget.decoration.footer != null)
                Flexible(child: widget.decoration.footer!),
            ],
          ),
        ),
      ),
    );

    if (kIsWeb || Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      return Shortcuts(shortcuts: _webShortcuts, child: child);
    }

    return child;
  }

  Widget _buildOption(int index, ThemeData theme) {
    final option = widget.items[index];

    if (widget.itemBuilder != null) {
      return widget.itemBuilder!(option, index, () => _handleItemTap(option));
    }

    final disabledColor =
        widget.dropdownItemDecoration.disabledBackgroundColor ??
            widget.dropdownItemDecoration.backgroundColor?.withAlpha(100);

    final tileColor = option.disabled
        ? disabledColor
        : option.selected
            ? widget.dropdownItemDecoration.selectedBackgroundColor ??
                Colors.blue.shade200
            : widget.dropdownItemDecoration.backgroundColor ?? Colors.white;

    final textColor = option.selected
        ? widget.dropdownItemDecoration.selectedTextColor ?? Colors.black
        : widget.dropdownItemDecoration.textColor ??
            theme.colorScheme.onSurface;

    final trailing = option.disabled
        ? widget.dropdownItemDecoration.disabledIcon
        : option.selected
            ? widget.dropdownItemDecoration.selectedIcon
            : null;

    return Ink(
      color: tileColor, // Ensure tile color is applied
      child: ListTile(
        title: Text(
          option.label,
          style: TextStyle(
            color: textColor, // Ensure text color updates when selected
            fontWeight: option.selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: trailing,
        dense: true,
        enabled: !option.disabled,
        selected: option.selected,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        tileColor: tileColor,
        // Apply background color to selected item
        selectedTileColor:
            widget.dropdownItemDecoration.selectedBackgroundColor ??
                Colors.blueAccent,
        onTap: () => _handleItemTap(option),
      ),
    );
  }

  void _handleItemTap(DropdownItem<T> option) {
    if (option.disabled) return;

    setState(() {
      if (widget.singleSelect) {
        // Clear all selections before selecting the new one
        for (var item in widget.items) {
          item.selected = false;
        }
        option.selected = true;
      } else if (!_reachedMaxSelection(option)) {
        option.selected = !option.selected;
      }

      widget.onItemTap(option);
    });
  }

  void _onSearchChange(String value) => widget.onSearchChange?.call(value);

  bool _reachedMaxSelection(DropdownItem<dynamic> option) {
    return !option.selected &&
        widget.maxSelections > 0 &&
        _selectedCount >= widget.maxSelections;
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.decoration,
    required this.onChanged,
  });

  final SearchFieldDecoration decoration;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        decoration: InputDecoration(
          isDense: true,
          hintText: decoration.hintText,
          border: decoration.border,
          focusedBorder: decoration.focusedBorder,
          suffixIcon: decoration.searchIcon,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
