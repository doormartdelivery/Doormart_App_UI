import 'package:flutter/material.dart';

const _sheetAccent = Color(0xFFE8541A);
const _sheetAccentLight = Color(0xFFFFF0EB);
const _sheetText = Color(0xFF1A1A1A);
const _sheetMuted = Color(0xFF8E8882);

class PremiumSelectionSheet extends StatefulWidget {
  const PremiumSelectionSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selectedValues,
    required this.onApply,
    required this.actionLabel,
    required this.icon,
    this.multiSelect = false,
    this.listMode = false,
  });

  final String title;
  final String subtitle;
  final List<String> options;
  final Set<String> selectedValues;
  final ValueChanged<Set<String>> onApply;
  final String actionLabel;
  final IconData icon;
  final bool multiSelect;
  final bool listMode;

  @override
  State<PremiumSelectionSheet> createState() => _PremiumSelectionSheetState();
}

class _PremiumSelectionSheetState extends State<PremiumSelectionSheet> {
  late Set<String> _selected = {...widget.selectedValues};

  void _toggle(String option) {
    setState(() {
      if (widget.multiSelect) {
        if (!_selected.add(option)) _selected.remove(option);
      } else {
        _selected = {option};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFCFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3D9D1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFEFE7), Color(0xFFFFD8C3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(widget.icon, color: _sheetAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: _sheetText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: _sheetMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              widget.listMode
                  ? Column(
                      children: [
                        for (final option in widget.options)
                          _PremiumSelectionOption(
                            label: option,
                            selected: _selected.contains(option),
                            listMode: true,
                            multiSelect: widget.multiSelect,
                            onTap: () => _toggle(option),
                          ),
                      ],
                    )
                  : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final option in widget.options)
                          _PremiumSelectionOption(
                            label: option,
                            selected: _selected.contains(option),
                            multiSelect: widget.multiSelect,
                            onTap: () => _toggle(option),
                          ),
                      ],
                    ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF26522), Color(0xFFE54518)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: _sheetAccent.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: () => widget.onApply({..._selected}),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      widget.actionLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.15,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumSelectionOption extends StatelessWidget {
  const _PremiumSelectionOption({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.multiSelect,
    this.listMode = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool multiSelect;
  final bool listMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: listMode
          ? const EdgeInsets.symmetric(vertical: 4)
          : EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: BoxConstraints(
              minHeight: 44,
              maxWidth: listMode
                  ? double.infinity
                  : MediaQuery.sizeOf(context).width - 56,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? _sheetAccentLight : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _sheetAccent : const Color(0xFFE8E2DD),
                width: selected ? 1.4 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _sheetAccent.withValues(alpha: 0.14),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: listMode ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : (multiSelect
                            ? Icons.radio_button_unchecked_rounded
                            : Icons.circle_outlined),
                  size: 18,
                  color: selected ? _sheetAccent : const Color(0xFFB7B0A6),
                ),
                const SizedBox(width: 8),
                if (listMode)
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: selected ? _sheetAccent : _sheetText,
                      ),
                    ),
                  )
                else
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: selected ? _sheetAccent : _sheetText,
                    ),
                  ),
                if (listMode)
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_ios_rounded,
                    size: selected ? 18 : 13,
                    color: selected ? _sheetAccent : const Color(0xFFC9BFB7),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
