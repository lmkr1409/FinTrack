import 'package:flutter/material.dart';

/// A reusable generic autocomplete text field with a '+ Add New' button for form entries.
class AutocompleteField<T extends Object> extends StatefulWidget {
  final String label;
  final T? initialItem;
  final List<T> items;
  final String Function(T) displayStringForOption;
  final ValueChanged<T?> onChanged;
  final void Function(String currentText) onAddNew;

  const AutocompleteField({
    super.key,
    required this.label,
    this.initialItem,
    required this.items,
    required this.displayStringForOption,
    required this.onChanged,
    required this.onAddNew,
  });

  @override
  State<AutocompleteField<T>> createState() => _AutocompleteFieldState<T>();
}

class _AutocompleteFieldState<T extends Object> extends State<AutocompleteField<T>> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String? _lastSelectedText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialItem != null ? widget.displayStringForOption(widget.initialItem as T) : '',
    );
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(AutocompleteField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the external item changes (e.g., from creating a new one), update the text.
    if (widget.initialItem != oldWidget.initialItem) {
      if (widget.initialItem != null) {
        final newText = widget.displayStringForOption(widget.initialItem as T);
        if (_controller.text != newText) {
          _controller.text = newText;
        }
      } else {
        if (_controller.text.isNotEmpty) {
          _controller.clear();
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RawAutocomplete<T>(
            textEditingController: _controller,
            focusNode: _focusNode,
            displayStringForOption: widget.displayStringForOption,
            optionsBuilder: (TextEditingValue textEditingValue) {
              final query = textEditingValue.text.toLowerCase();
              if (_lastSelectedText != null && textEditingValue.text == _lastSelectedText) {
                return Iterable<T>.empty();
              }
              return widget.items.where((T item) {
                return widget.displayStringForOption(item).toLowerCase().contains(query);
              });
            },
            onSelected: (T selection) {
              // Use microtask to avoid disrupting RawAutocomplete's internal logic with a rebuild
              Future.microtask(() => widget.onChanged(selection));
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                scrollPadding: const EdgeInsets.only(bottom: 250),
                decoration: InputDecoration(
                  labelText: widget.label,
                  border: const OutlineInputBorder(),
                  suffixIcon: controller.text.isNotEmpty ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      widget.onChanged(null);
                    },
                  ) : null,
                ),
                onChanged: (val) {
                  _lastSelectedText = null;
                  // If they alter the text, we deselect the current item.
                  // Only if we already had a selection do we clear it in parent.
                  if (widget.initialItem != null && val != widget.displayStringForOption(widget.initialItem as T)) {
                    widget.onChanged(null);
                  }
                  // Rebuild to update suffix icon visibility
                  setState(() {});
                },
                onFieldSubmitted: (String value) {
                  onFieldSubmitted();
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    width: MediaQuery.of(context).size.width - 90, // Approx width of the field
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final T option = options.elementAt(index);
                        return ListTile(
                          title: Text(widget.displayStringForOption(option)),
                          onTap: () {
                            _lastSelectedText = widget.displayStringForOption(option);
                            onSelected(option);
                          },
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          icon: const Icon(Icons.add),
          tooltip: 'Add new ${widget.label}',
          onPressed: () => widget.onAddNew(_controller.text),
        ),
      ],
    );
  }
}
