import 'package:flutter/foundation.dart';

class BookedPlacesProvider extends ChangeNotifier {
  final Set<String> _bookedPlaceNames = {};

  bool isBooked(String placeName) => _bookedPlaceNames.contains(placeName);

  void toggleBooking(String placeName) {
    if (_bookedPlaceNames.contains(placeName)) {
      _bookedPlaceNames.remove(placeName);
    } else {
      _bookedPlaceNames.add(placeName);
    }
    notifyListeners();
  }

  void removeBooking(String placeName) {
    _bookedPlaceNames.remove(placeName);
    notifyListeners();
  }

  Set<String> get bookedPlaceNames => Set.unmodifiable(_bookedPlaceNames);
}
