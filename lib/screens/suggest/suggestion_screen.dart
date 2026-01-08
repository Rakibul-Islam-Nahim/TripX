import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/bd_locations.dart';
import '../../services/geocode_service.dart';
import '../../providers/booked_places_provider.dart';

class SuggestionScreen extends StatefulWidget {
  final List<Map<String, dynamic>> allPlaces;

  const SuggestionScreen({super.key, required this.allPlaces});

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  final TextEditingController offDayController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();

  String? selectedDivision;
  String? selectedDistrict;
  bool isLoading = false;

  List<Map<String, dynamic>> suggestions = [];
  int step =
      0; // 0 = off days, 1 = budget, 2 = division, 3 = district, 4 = results

  final GeocodeService _geocodeService = GeocodeService();

  Future<void> nextStep() async {
    if (step == 0 && offDayController.text.isEmpty) {
      showError("Enter off days");
      return;
    }

    if (step == 1 && budgetController.text.isEmpty) {
      showError("Enter your budget");
      return;
    }

    if (step == 2 && selectedDivision == null) {
      showError("Select a division");
      return;
    }

    if (step == 3 && selectedDistrict == null) {
      showError("Select a district");
      return;
    }

    if (step == 3) {
      await generateSuggestions();
      if (!mounted) return;
      setState(() => step = 4);
      return;
    }

    setState(() => step++);
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------- DISTANCE & COST LOGIC ----------------
  Future<void> generateSuggestions() async {
    final int? offDays = int.tryParse(offDayController.text);
    final int? budget = int.tryParse(budgetController.text);
    final String? homeDistrict = selectedDistrict;

    if (offDays == null || budget == null || homeDistrict == null) return;

    setState(() {
      isLoading = true;
      suggestions = [];
    });

    final Coordinate? homeCoord = await _geocodeService
        .getCoordinatesForDistrict(homeDistrict);
    if (!mounted) return;

    if (homeCoord == null) {
      setState(() => isLoading = false);
      showError("Couldn't locate $homeDistrict");
      return;
    }

    final List<Map<String, dynamic>> ranked = [];

    for (var place in widget.allPlaces) {
      final placeDistrict = place["district"] as String?;
      if (placeDistrict == null) continue;

      final Coordinate? placeCoord = await _geocodeService
          .getCoordinatesForDistrict(placeDistrict);
      if (placeCoord == null) continue;

      final double distanceKm = _geocodeService.distanceInKm(
        homeCoord,
        placeCoord,
      );

      // Cost & time buffers derived from actual distance.
      final int baseCost = place["estimated_cost"] as int;
      final double baseMin = (place["min_days"] as num).toDouble();
      final double baseMax = (place["max_days"] as num).toDouble();

      final int travelCost = (distanceKm * 15).round(); // ~15 BDT per km.
      final int adjustedCost = baseCost + travelCost;
      final double travelBufferDays = (distanceKm / 350).clamp(0, 5);
      final double adjustedMinDays = baseMin + travelBufferDays;
      final double adjustedMaxDays = baseMax + travelBufferDays;

      int score = 0;
      if (offDays >= adjustedMinDays && offDays <= adjustedMaxDays) score += 3;
      if (budget >= adjustedCost) score += 3;
      if (distanceKm <= 150) {
        score += 2;
      } else if (distanceKm <= 350) {
        score += 1;
      }

      if (score > 0) {
        ranked.add({
          ...place,
          "adjusted_cost": adjustedCost,
          "adjusted_min": adjustedMinDays,
          "adjusted_max": adjustedMaxDays,
          "distance_km": distanceKm,
          "score": score,
        });
      }
    }

    ranked.sort((a, b) {
      final int scoreCmp = b["score"].compareTo(a["score"]);
      if (scoreCmp != 0) return scoreCmp;
      return (a["distance_km"] as double).compareTo(b["distance_km"] as double);
    });

    if (!mounted) return;
    setState(() {
      suggestions = ranked;
      isLoading = false;
    });
  }

  // ------------------ DYNAMIC QUESTION UI ------------------
  Widget getQuestionUI() {
    if (step == 0) {
      return fadeSlide(
        Column(
          key: const ValueKey(0),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How many off days do you have?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: offDayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter days",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            nextButton("Next"),
          ],
        ),
      );
    }

    if (step == 1) {
      return fadeSlide(
        Column(
          key: const ValueKey(1),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What is your maximum budget?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter budget",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            nextButton("Next"),
          ],
        ),
      );
    }

    if (step == 2) {
      return fadeSlide(
        Column(
          key: const ValueKey(2),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Which division are you from?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: selectedDivision,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Select Division",
              ),
              items:
                  kBdDivisions
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
              onChanged: (val) {
                setState(() {
                  selectedDivision = val;
                  selectedDistrict = null;
                });
              },
            ),
            const SizedBox(height: 20),
            nextButton("Next"),
          ],
        ),
      );
    }

    if (step == 3) {
      final districts =
          selectedDivision != null
              ? kBdDivisionToDistricts[selectedDivision] ?? []
              : <String>[];

      return fadeSlide(
        Column(
          key: const ValueKey(3),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Which district are you from?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedDistrict,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Select District",
              ),
              items:
                  districts
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
              onChanged: (val) => setState(() => selectedDistrict = val),
            ),
            const SizedBox(height: 20),
            nextButton("Show Suggestions"),
          ],
        ),
      );
    }

    return const SizedBox();
  }

  Widget nextButton(String text) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: isLoading ? null : () => nextStep(),
      child:
          isLoading
              ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Text(text),
    ),
  );

  Widget fadeSlide(Widget child) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder:
          (c, anim) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(anim),
            child: FadeTransition(opacity: anim, child: c),
          ),
      child: child,
    );
  }

  // ------------------ RESULTS UI ------------------
  Widget getSuggestionUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed:
              () => setState(() {
                step = 0;
                selectedDivision = null;
                selectedDistrict = null;
                suggestions = [];
              }),
          child: const Text("Re-adjust Filters"),
        ),
        const SizedBox(height: 20),

        suggestions.isEmpty
            ? const Text("No results found. Try changing your inputs.")
            : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final place = suggestions[index];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        place["image"],
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place["name"],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),

                            Text(place["description"]),
                            const SizedBox(height: 10),

                            Text(
                              "Cost: ${place["adjusted_cost"]} BDT",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "Recommended Days: ${(place["adjusted_min"] as double).toStringAsFixed(1)} Days",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "Max Days: ${(place["adjusted_max"] as double).toStringAsFixed(1)} Days",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "Location: ${place["district"]}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "Distance: ${(place["distance_km"] as double).toStringAsFixed(1)} km",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Consumer<BookedPlacesProvider>(
                              builder: (context, bookedProvider, child) {
                                final isBooked = bookedProvider.isBooked(
                                  place['name'],
                                );
                                return SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      bookedProvider.toggleBooking(
                                        place['name'],
                                      );
                                    },
                                    icon: Icon(
                                      isBooked
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                    ),
                                    label: Text(isBooked ? 'Booked' : 'Book'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          isBooked
                                              ? Colors.green
                                              : const Color(0xFF005E53),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      ],
    );
  }

  // ------------------ MAIN UI ------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trip Suggestion")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: step < 4 ? getQuestionUI() : getSuggestionUI(),
      ),
    );
  }

  @override
  void dispose() {
    offDayController.dispose();
    budgetController.dispose();
    super.dispose();
  }
}
