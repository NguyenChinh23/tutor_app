import 'package:flutter/material.dart';
import 'package:tutor_app/config/theme.dart';

class FilterTutorsScreen extends StatefulWidget {
  const FilterTutorsScreen({super.key});

  @override
  State<FilterTutorsScreen> createState() => _FilterTutorsScreenState();
}

class _FilterTutorsScreenState extends State<FilterTutorsScreen> {
  final List<String> subjects = ['Math', 'English', 'Physics', 'Chemistry', 'IELTS'];
  final List<String> selectedSubjects = [];
  double minPrice = 0;
  double maxPrice = 100;
  double minRating = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Filter Tutors"),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text("Subjects", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: subjects.map((s) {
                final selected = selectedSubjects.contains(s);
                return ChoiceChip(
                  label: Text(s),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      selected
                          ? selectedSubjects.remove(s)
                          : selectedSubjects.add(s);
                    });
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text("Price per hour (\$)",
                style: TextStyle(fontWeight: FontWeight.bold)),
            RangeSlider(
              values: RangeValues(minPrice, maxPrice),
              min: 0,
              max: 200,
              divisions: 20,
              labels: RangeLabels("\$${minPrice.round()}", "\$${maxPrice.round()}"),
              onChanged: (values) => setState(() {
                minPrice = values.start;
                maxPrice = values.end;
              }),
              activeColor: AppTheme.primaryColor,
            ),
            const SizedBox(height: 20),
            const Text("Minimum Rating",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: minRating,
              min: 1,
              max: 5,
              divisions: 4,
              label: "${minRating.toStringAsFixed(1)} ⭐",
              onChanged: (v) => setState(() => minRating = v),
              activeColor: Colors.amber,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Gửi bộ lọc này về StudentHome / TutorList
                Navigator.pop(context, {
                  "subjects": selectedSubjects,
                  "minPrice": minPrice,
                  "maxPrice": maxPrice,
                  "minRating": minRating,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Apply Filters"),
            ),
          ],
        ),
      ),
    );
  }
}
