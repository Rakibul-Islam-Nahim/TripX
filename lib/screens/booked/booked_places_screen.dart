import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/booked_places_provider.dart';

class BookedPlacesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> allPlaces;

  const BookedPlacesScreen({super.key, required this.allPlaces});

  @override
  Widget build(BuildContext context) {
    final bookedProvider = context.watch<BookedPlacesProvider>();
    final bookedPlaceNames = bookedProvider.bookedPlaceNames;

    // Filter the places that are booked
    final bookedPlaces =
        allPlaces
            .where((place) => bookedPlaceNames.contains(place['name']))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Booked Places')),
      body:
          bookedPlaces.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_border, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No booked places yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bookedPlaces.length,
                itemBuilder: (context, index) {
                  final place = bookedPlaces[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          place['image'] ?? 'assets/images/default.jpg',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image),
                              ),
                        ),
                      ),
                      title: Text(
                        place['name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Cost: ${place['estimated_cost']} BDT'),
                          Text('Location: ${place['district']}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Remove Booking'),
                                  content: Text(
                                    'Remove ${place['name']} from booked places?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        bookedProvider.removeBooking(
                                          place['name'],
                                        );
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        'Remove',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
