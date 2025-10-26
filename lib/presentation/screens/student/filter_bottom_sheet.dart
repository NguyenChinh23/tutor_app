import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tutor_app/config/theme.dart';

String _fmtVnd(num v) => NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
).format(v);

/// Mở bottom sheet filter và trả về Map kết quả (hoặc null nếu đóng).
Future<Map<String, dynamic>?> showFilterBottomSheet(
    BuildContext context, {
      List<String>? initialSubjects,
      double? initialMinPrice,
      double? initialMaxPrice,
      double? initialMinRating,
      required double priceMaxLimit, // max giá theo dữ liệu hiện có
    }) {
  final min = (initialMinPrice ?? 0).clamp(0, priceMaxLimit).toDouble();
  final max = (initialMaxPrice ?? priceMaxLimit).clamp(min, priceMaxLimit).toDouble();

  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _FilterSheetContent(
      initialSubjects: initialSubjects ?? const [],
      initialMinPrice: min,
      initialMaxPrice: max,
      initialMinRating: (initialMinRating ?? 0).clamp(0, 5).toDouble(),
      priceMaxLimit: priceMaxLimit,
    ),
  );
}

class _FilterSheetContent extends StatefulWidget {
  const _FilterSheetContent({
    required this.initialSubjects,
    required this.initialMinPrice,
    required this.initialMaxPrice,
    required this.initialMinRating,
    required this.priceMaxLimit,
  });

  final List<String> initialSubjects;
  final double initialMinPrice;
  final double initialMaxPrice;
  final double initialMinRating;
  final double priceMaxLimit;

  @override
  State<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends State<_FilterSheetContent> {
  final List<String> _allSubjects = const ['Math', 'English', 'Physics', 'Chemistry', 'IELTS'];

  late List<String> _selectedSubjects;
  late RangeValues _priceRange; // VND
  late double _minRating; // 0..5

  @override
  void initState() {
    super.initState();
    _selectedSubjects = [...widget.initialSubjects];
    _priceRange = RangeValues(
      widget.initialMinPrice.toDouble(),
      widget.initialMaxPrice.toDouble(),
    );
    _minRating = widget.initialMinRating.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Filter Tutors',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Subject'),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _allSubjects.map((s) {
                      final selected = _selectedSubjects.contains(s);
                      return ChoiceChip(
                        label: Text(s),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            selected
                                ? _selectedSubjects.remove(s)
                                : _selectedSubjects.add(s);
                          });
                        },
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                        selectedColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.25)),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  // Hiển thị khoảng giá hiện tại
                  const _SectionTitle('Price per hour (VND)'),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      "${_fmtVnd(_priceRange.start)} — ${_fmtVnd(_priceRange.end)}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: widget.priceMaxLimit,
                    onChanged: (values) => setState(() => _priceRange = values),
                    activeColor: AppTheme.primaryColor,
                    inactiveColor: AppTheme.primaryColor.withOpacity(0.15),
                  ),
                  const SizedBox(height: 8),

                  // Rating
                  const _SectionTitle('Minimum Rating'),
                  Slider(
                    value: _minRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label: "${_minRating.toStringAsFixed(1)} ⭐",
                    onChanged: (v) => setState(() => _minRating = v),
                    activeColor: Colors.amber,
                    inactiveColor: Colors.amber.withOpacity(0.25),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, {
                      "subjects": _selectedSubjects,
                      "minPrice": _priceRange.start,
                      "maxPrice": _priceRange.end,
                      "minRating": _minRating,
                    });
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("Apply Filters"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
  );
}
