import 'package:flutter/material.dart';
import '../store/trip_store.dart';
import '../models/destination_model.dart';
import 'planning_screen.dart';

class PlanTripScreen extends StatefulWidget {
  final Destination destination;

  const PlanTripScreen({
    super.key,
    required this.destination,
  });

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  DateTime? fromDate;
  DateTime? toDate;

  final TextEditingController budgetController = TextEditingController();

  final List<String> moods = const [
    "Food",
    "Cultural",
    "Entertainment",
    "Peaceful",
    "Adventurous",
    "Nature",
  ];

  final Set<String> selectedMoods = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ WHITE APP BAR (NO BLACK, NO PURPLE)
      appBar: AppBar(
        title: const Text(
          "Plan Trip",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        surfaceTintColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _datePicker("From Date", fromDate, () => _pickDate(true)),
            const SizedBox(height: 12),
            _datePicker("To Date", toDate, () => _pickDate(false)),
            const SizedBox(height: 24),

            const Text(
              "What kind of trip do you want?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _moodChips(),

            const SizedBox(height: 24),

            const Text(
              "Budget",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: budgetController,
              keyboardType: TextInputType.number,
              cursorColor: Colors.black,
              decoration: InputDecoration(
                hintText: "Enter your budget",
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 40),

            _completeButton(),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // DATE PICKER
  // --------------------------------------------------

  Widget _datePicker(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date == null
                  ? label
                  : "${date.day}/${date.month}/${date.year}",
            ),
            const Icon(Icons.calendar_today, color: Colors.black),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // MOOD CHIPS (NO PURPLE)
  // --------------------------------------------------

  Widget _moodChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: moods.map((mood) {
        final selected = selectedMoods.contains(mood);
        return ChoiceChip(
          label: Text(mood),
          selected: selected,
          selectedColor: Colors.black,
          backgroundColor: Colors.grey.shade200,
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
          onSelected: (_) {
            setState(() {
              selected
                  ? selectedMoods.remove(mood)
                  : selectedMoods.add(mood);
            });
          },
        );
      }).toList(),
    );
  }

  // --------------------------------------------------
  // COMPLETE BUTTON (DARK, NOT PURPLE)
  // --------------------------------------------------

  Widget _completeButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: GestureDetector(
        onTap: _completeTrip,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF111111),
                Color(0xFF2E2E2E),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.30),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            "Complete",
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // DATE PICK LOGIC (NO PURPLE)
  // --------------------------------------------------

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        isFrom ? fromDate = picked : toDate = picked;
      });
    }
  }

  // --------------------------------------------------
  // MOOD MAPPING
  // --------------------------------------------------

  List<Mood> _mapMoodsToEnum() {
    return selectedMoods.map((m) {
      switch (m) {
        case 'Food':
          return Mood.food;
        case 'Cultural':
          return Mood.cultural;
        case 'Entertainment':
          return Mood.entertainment;
        case 'Peaceful':
          return Mood.peaceful;
        case 'Adventurous':
          return Mood.adventurous;
        case 'Nature':
          return Mood.nature;
        default:
          return Mood.peaceful;
      }
    }).toList();
  }

  // --------------------------------------------------
  // COMPLETE TRIP
  // --------------------------------------------------

  void _completeTrip() async {
    if (fromDate == null ||
        toDate == null ||
        selectedMoods.isEmpty ||
        budgetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final budget = double.tryParse(budgetController.text) ?? 0;

    final tripId = await TripStore().addPlannedTrip(
      destination: widget.destination,
      fromDate: fromDate!,
      toDate: toDate!,
      moods: _mapMoodsToEnum(),
      budget: budget,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PlanningScreen(
          destination: widget.destination.name,
          tripId: tripId,
          fromDate: fromDate!,
          toDate: toDate!,
          moods: _mapMoodsToEnum(),
          budget: budget,
        ),
      ),
    );
  }
}
