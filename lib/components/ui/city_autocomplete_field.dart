import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/app_form_field.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/services/dadata_service.dart';

typedef CitySelectedCallback = void Function(DadataCitySuggestion city);

/// Поле города с подсказками DaData: можно печатать и выбирать из списка.
class CityAutocompleteField extends StatefulWidget {
  const CityAutocompleteField({
    super.key,
    required this.initialCity,
    required this.onSelected,
    this.onTextChanged,
    this.label = 'Город',
  });

  final String initialCity;
  final CitySelectedCallback onSelected;
  final ValueChanged<String>? onTextChanged;
  final String label;

  @override
  State<CityAutocompleteField> createState() => _CityAutocompleteFieldState();
}

class _CityAutocompleteFieldState extends State<CityAutocompleteField> {
  final _service = DadataService();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();

  OverlayEntry? _overlay;
  Timer? _debounce;
  List<DadataCitySuggestion> _suggestions = [];
  bool _loading = false;
  String? _error;
  double _fieldWidth = 0;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialCity;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant CityAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCity != widget.initialCity &&
        !_focusNode.hasFocus &&
        _controller.text != widget.initialCity) {
      _controller.text = widget.initialCity;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      if (_suggestions.isNotEmpty) _showOverlay();
    } else {
      // Даём время на tap по пункту списка.
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (!_focusNode.hasFocus) _removeOverlay();
      });
    }
  }

  void _onChanged(String value) {
    widget.onTextChanged?.call(value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search(value);
    });
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.length < 2) {
      setState(() {
        _suggestions = [];
        _error = null;
        _loading = false;
      });
      _removeOverlay();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _service.suggestCities(q);
      if (!mounted) return;
      setState(() {
        _suggestions = items;
        _loading = false;
      });
      if (_focusNode.hasFocus) {
        if (items.isEmpty) {
          _removeOverlay();
        } else {
          _showOverlay();
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить города';
        _suggestions = [];
      });
      _removeOverlay();
    }
  }

  void _select(DadataCitySuggestion city) {
    _controller.text = city.name;
    _controller.selection = TextSelection.collapsed(offset: city.name.length);
    widget.onSelected(city);
    setState(() => _suggestions = []);
    _removeOverlay();
    _focusNode.unfocus();
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    _overlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: _fieldWidth > 0 ? _fieldWidth : null,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 52),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(AppFormMetrics.radius),
              color: Colors.white,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  separatorBuilder:
                      (_, __) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final item = _suggestions[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle:
                          item.region == null
                              ? null
                              : Text(
                                item.region!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.gray,
                                ),
                              ),
                      onTap: () => _select(item),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        CompositedTransformTarget(
          link: _layerLink,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _fieldWidth = constraints.maxWidth;
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.ulight,
                  borderRadius: BorderRadius.circular(AppFormMetrics.radius),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Начните вводить город',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    suffixIcon:
                        _loading
                            ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                            : const Icon(Icons.search, color: AppColors.gray),
                  ),
                ),
              );
            },
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
