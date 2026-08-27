import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'package:geolocator/geolocator.dart';

import 'google_api_key.dart';
import 'nav_bar.dart';

class FinderPage extends StatefulWidget {
  const FinderPage({super.key});

  @override
  State<FinderPage> createState() => _FinderPageState();
}

class _FinderPageState extends State<FinderPage> {
  final TextEditingController searchController = TextEditingController();

  late final FlutterGooglePlacesSdk _places;

  Timer? _searchDebounce;

  // ===========================================================================
  // LOCATION
  // ===========================================================================

  Position? _currentPosition;

  bool _isLoadingLocation = true;
  bool _isLoadingPlaces = false;

  String? _locationError;
  String? _placesError;

  // ===========================================================================
  // PLACES
  // ===========================================================================

  List<Place> _placesList = [];
  List<Place> _filteredPlaces = [];

  // ===========================================================================
  // SETTINGS
  // ===========================================================================

  // Maximum distance for the "Nearby" results.
  // 25 km keeps results genuinely local instead of showing places hundreds
  // or thousands of kilometres away.
  static const double _nearbyRadiusKm = 25.0;

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _places = FlutterGooglePlacesSdk(
      googlePlacesApiKey,
      useNewApi: true,
    );

    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // LOCATION
  // ===========================================================================

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = true;
      _isLoadingPlaces = false;
      _locationError = null;
      _placesError = null;
      _placesList = [];
      _filteredPlaces = [];
    });

    try {
      // -----------------------------------------------------------------------
      // Check GPS
      // -----------------------------------------------------------------------

      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          _isLoadingLocation = false;
          _locationError =
              'Location services are turned off. Please turn on GPS.';
        });

        return;
      }

      // -----------------------------------------------------------------------
      // Check permission
      // -----------------------------------------------------------------------

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Location permission was denied.';
        });

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          _isLoadingLocation = false;
          _locationError =
              'Location permission is permanently denied. Please enable it in Android settings.';
        });

        return;
      }

      // -----------------------------------------------------------------------
      // Get GPS location
      // -----------------------------------------------------------------------

      debugPrint('MEDMINDER: Requesting GPS location...');

      Position position;

      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 20),
          ),
        );
      } on TimeoutException {
        debugPrint('MEDMINDER: GPS timeout. Trying last known location...');

        final Position? lastPosition = await Geolocator.getLastKnownPosition();

        if (lastPosition == null) {
          rethrow;
        }

        position = lastPosition;
      }

      debugPrint(
        'MEDMINDER: LOCATION SUCCESS '
        '${position.latitude}, ${position.longitude}',
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
        _locationError = null;
      });

      // -----------------------------------------------------------------------
      // Load nearby places
      // -----------------------------------------------------------------------

      await _loadNearbyPlaces();
    } catch (e) {
      debugPrint('MEDMINDER: LOCATION ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingLocation = false;
        _locationError = 'Unable to get your location. Please try again.';
      });
    }
  }

  // ===========================================================================
  // LOCATION BOUNDS
  // ===========================================================================

  LatLngBounds _nearbyBounds(Position position) {
    /*
     * Approximately 25 km around the user's location.
     *
     * 1 degree latitude is approximately 111 km.
     *
     * Longitude changes depending on latitude, so we calculate it using
     * cos(latitude).
     */

    const double radiusKm = _nearbyRadiusKm;

    final double latitudeDelta = radiusKm / 111.0;

    final double longitudeDelta =
        radiusKm / (111.0 * _cosineDegrees(position.latitude));

    final double south = (position.latitude - latitudeDelta).clamp(-90.0, 90.0);

    final double north = (position.latitude + latitudeDelta).clamp(-90.0, 90.0);

    final double west =
        (position.longitude - longitudeDelta).clamp(-180.0, 180.0);

    final double east =
        (position.longitude + longitudeDelta).clamp(-180.0, 180.0);

    return LatLngBounds(
      southwest: LatLng(
        lat: south,
        lng: west,
      ),
      northeast: LatLng(
        lat: north,
        lng: east,
      ),
    );
  }

  double _cosineDegrees(double degrees) {
    final double radians = degrees * 3.141592653589793 / 180.0;

    // Prevent longitudeDelta from becoming unreasonable near the poles.
    final double value = _cos(radians);

    if (value.abs() < 0.01) {
      return 0.01;
    }

    return value.abs();
  }

  double _cos(double radians) {
    // Small local implementation so no extra math package is required.
    // Taylor approximation is more than sufficient for this calculation.
    final double x = radians;

    double result = 1.0;
    double term = 1.0;

    for (int n = 1; n <= 8; n++) {
      term *= -(x * x) / ((2 * n - 1) * (2 * n));
      result += term;
    }

    return result;
  }

  // ===========================================================================
  // LOAD NEARBY MEDICAL PLACES
  // ===========================================================================

  Future<void> _loadNearbyPlaces() async {
    final Position? position = _currentPosition;

    if (position == null) {
      debugPrint(
        'MEDMINDER: Cannot search places because location is null.',
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoadingPlaces = true;
      _placesError = null;
    });

    try {
      final LatLng origin = LatLng(
        lat: position.latitude,
        lng: position.longitude,
      );

      final LatLngBounds bounds = _nearbyBounds(position);

      debugPrint(
        'MEDMINDER: Searching around '
        '${position.latitude}, ${position.longitude}',
      );

      debugPrint(
        'MEDMINDER: Nearby radius: $_nearbyRadiusKm km',
      );

      // -----------------------------------------------------------------------
      // Medical categories
      // -----------------------------------------------------------------------

      const List<String> searches = [
        'hospital',
        'clinic',
        'pharmacy',
        'doctor',
        'medical center',
        'health center',
        'medical clinic',
      ];

      final Map<String, AutocompletePrediction> predictions = {};

      // -----------------------------------------------------------------------
      // Search each category
      //
      // IMPORTANT:
      //
      // We use findAutocompletePredictions because this is the API exposed
      // by flutter_google_places_sdk.
      //
      // We DO NOT use:
      //   searchByText()
      //   searchNearby()
      //
      // because those methods are not exposed by your installed package.
      //
      // locationRestriction is important here. origin by itself does not
      // guarantee that all returned predictions are nearby.
      // -----------------------------------------------------------------------

      for (final String query in searches) {
        try {
          debugPrint(
            'MEDMINDER: Searching "$query"...',
          );

          final FindAutocompletePredictionsResponse response =
              await _places.findAutocompletePredictions(
            query,
            origin: origin,
            locationRestriction: bounds,
          );

          debugPrint(
            'MEDMINDER: "$query" returned '
            '${response.predictions.length} predictions.',
          );

          for (final AutocompletePrediction prediction
              in response.predictions) {
            predictions[prediction.placeId] = prediction;
          }
        } catch (e) {
          debugPrint(
            'MEDMINDER: Search failed for "$query": $e',
          );
        }
      }

      debugPrint(
        'MEDMINDER: Total unique predictions: '
        '${predictions.length}',
      );

      // -----------------------------------------------------------------------
      // Fetch details
      // -----------------------------------------------------------------------

      final List<Place> loadedPlaces = [];

      for (final AutocompletePrediction prediction in predictions.values) {
        try {
          final FetchPlaceResponse response = await _places.fetchPlace(
            prediction.placeId,
            fields: [
              PlaceField.Address,
              PlaceField.BusinessStatus,
              PlaceField.Id,
              PlaceField.Location,
              PlaceField.Name,
              PlaceField.OpeningHours,
              PlaceField.PhoneNumber,
              PlaceField.Rating,
              PlaceField.Types,
              PlaceField.UserRatingsTotal,
              PlaceField.WebsiteUri,
            ],
          );

          final Place? place = response.place;

          if (place == null) {
            continue;
          }

          if (!_isMedicalPlace(place)) {
            continue;
          }

          // -------------------------------------------------------------------
          // IMPORTANT:
          //
          // Google can still return a result outside the desired radius.
          // Therefore we perform a second hard distance check.
          // -------------------------------------------------------------------

          final double distance = _distanceFromCurrentLocation(place);

          if (distance == double.infinity) {
            continue;
          }

          if (distance > _nearbyRadiusKm * 1000) {
            debugPrint(
              'MEDMINDER: Ignoring far place '
              '${place.name} '
              '(${(distance / 1000).toStringAsFixed(1)} km)',
            );

            continue;
          }

          loadedPlaces.add(place);
        } catch (e) {
          debugPrint(
            'MEDMINDER: Could not fetch place '
            '${prediction.placeId}: $e',
          );
        }
      }

      // -----------------------------------------------------------------------
      // Remove duplicates
      // -----------------------------------------------------------------------

      final Map<String, Place> uniquePlaces = {};

      for (final Place place in loadedPlaces) {
        final String id = place.id ?? '${place.name}_${place.address}';

        uniquePlaces[id] = place;
      }

      final List<Place> finalPlaces = uniquePlaces.values.toList();

      // -----------------------------------------------------------------------
      // Sort by distance
      // -----------------------------------------------------------------------

      finalPlaces.sort((a, b) {
        return _distanceFromCurrentLocation(a).compareTo(
          _distanceFromCurrentLocation(b),
        );
      });

      debugPrint(
        'MEDMINDER: Final nearby medical places: '
        '${finalPlaces.length}',
      );

      if (!mounted) return;

      setState(() {
        _placesList = finalPlaces;
        _filteredPlaces = finalPlaces;
        _isLoadingPlaces = false;
        _placesError = null;
      });
    } catch (e) {
      debugPrint(
        'MEDMINDER: PLACES ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoadingPlaces = false;
        _placesError = 'Could not load nearby places. Please try again.';
      });
    }
  }

  // ===========================================================================
  // MEDICAL PLACE CHECK
  // ===========================================================================

  bool _isMedicalPlace(Place place) {
    final List<PlaceType>? types = place.types;

    if (types == null || types.isEmpty) {
      return true;
    }

    for (final PlaceType type in types) {
      switch (type) {
        case PlaceType.HOSPITAL:
        case PlaceType.PHARMACY:
        case PlaceType.DOCTOR:
        case PlaceType.DENTIST:
        case PlaceType.PHYSIOTHERAPIST:
        case PlaceType.MEDICAL_LAB:
        case PlaceType.HEALTH:
          return true;

        default:
          break;
      }
    }

    return false;
  }

  // ===========================================================================
  // DISTANCE
  // ===========================================================================

  double _distanceFromCurrentLocation(Place place) {
    final Position? position = _currentPosition;

    if (position == null) {
      return double.infinity;
    }

    final LatLng? placeLocation = place.latLng;

    if (placeLocation == null) {
      return double.infinity;
    }

    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      placeLocation.lat,
      placeLocation.lng,
    );
  }

  // ===========================================================================
  // DISTANCE TEXT
  // ===========================================================================

  String _distanceText(Place place) {
    final double distance = _distanceFromCurrentLocation(place);

    if (distance == double.infinity) {
      return 'Distance unavailable';
    }

    if (distance < 1000) {
      return '${distance.round()} m away';
    }

    return '${(distance / 1000).toStringAsFixed(1)} km away';
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () {
        _searchPlaces(query);
      },
    );
  }

  Future<void> _searchPlaces(String query) async {
    final String q = query.trim();

    // -------------------------------------------------------------------------
    // Empty search
    // -------------------------------------------------------------------------

    if (q.isEmpty) {
      if (!mounted) return;

      setState(() {
        _filteredPlaces = _placesList;
        _placesError = null;
      });

      return;
    }

    final Position? position = _currentPosition;

    if (position == null) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoadingPlaces = true;
      _placesError = null;
    });

    try {
      final LatLng origin = LatLng(
        lat: position.latitude,
        lng: position.longitude,
      );

      final LatLngBounds bounds = _nearbyBounds(position);

      debugPrint(
        'MEDMINDER: User search "$q"',
      );

      final FindAutocompletePredictionsResponse response =
          await _places.findAutocompletePredictions(
        q,
        origin: origin,
        locationRestriction: bounds,
      );

      debugPrint(
        'MEDMINDER: Search returned '
        '${response.predictions.length} predictions.',
      );

      final Map<String, Place> uniqueResults = {};

      for (final AutocompletePrediction prediction in response.predictions) {
        try {
          final FetchPlaceResponse details = await _places.fetchPlace(
            prediction.placeId,
            fields: [
              PlaceField.Address,
              PlaceField.BusinessStatus,
              PlaceField.Id,
              PlaceField.Location,
              PlaceField.Name,
              PlaceField.OpeningHours,
              PlaceField.PhoneNumber,
              PlaceField.Rating,
              PlaceField.Types,
              PlaceField.UserRatingsTotal,
              PlaceField.WebsiteUri,
            ],
          );

          final Place? place = details.place;

          if (place == null) {
            continue;
          }

          // Only display medical places.
          if (!_isMedicalPlace(place)) {
            continue;
          }

          // Hard distance limit.
          final double distance = _distanceFromCurrentLocation(place);

          if (distance == double.infinity) {
            continue;
          }

          if (distance > _nearbyRadiusKm * 1000) {
            continue;
          }

          final String id = place.id ?? '${place.name}_${place.address}';

          uniqueResults[id] = place;
        } catch (e) {
          debugPrint(
            'MEDMINDER: Search detail error: $e',
          );
        }
      }

      final List<Place> finalResults = uniqueResults.values.toList();

      // -----------------------------------------------------------------------
      // Sort by distance
      // -----------------------------------------------------------------------

      finalResults.sort((a, b) {
        return _distanceFromCurrentLocation(a).compareTo(
          _distanceFromCurrentLocation(b),
        );
      });

      if (!mounted) return;

      setState(() {
        _filteredPlaces = finalResults;
        _isLoadingPlaces = false;
        _placesError = null;
      });
    } catch (e) {
      debugPrint(
        'MEDMINDER: SEARCH ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoadingPlaces = false;
        _placesError = 'Search failed. Please try again.';
      });
    }
  }

  // ===========================================================================
  // PLACE TYPE
  // ===========================================================================

  String _placeTypeText(Place place) {
    final List<PlaceType>? types = place.types;

    if (types == null || types.isEmpty) {
      return 'Medical facility';
    }

    for (final PlaceType type in types) {
      switch (type) {
        case PlaceType.HOSPITAL:
          return 'Hospital';

        case PlaceType.PHARMACY:
          return 'Pharmacy';

        case PlaceType.DOCTOR:
          return 'Doctor';

        case PlaceType.DENTIST:
          return 'Dentist';

        case PlaceType.PHYSIOTHERAPIST:
          return 'Physiotherapist';

        case PlaceType.MEDICAL_LAB:
          return 'Medical laboratory';

        case PlaceType.HEALTH:
          return 'Health center';

        default:
          break;
      }
    }

    return 'Medical facility';
  }

  // ===========================================================================
  // RATING
  // ===========================================================================

  double? _ratingValue(Place place) {
    return place.rating;
  }

  // ===========================================================================
  // OPEN / CLOSED
  // ===========================================================================

  String _openStatusText(Place place) {
    final BusinessStatus? status = place.businessStatus;

    if (status == BusinessStatus.Operational) {
      return 'Open / operational';
    }

    if (status == BusinessStatus.ClosedTemporarily) {
      return 'Temporarily closed';
    }

    if (status == BusinessStatus.ClosedPermanently) {
      return 'Permanently closed';
    }

    return 'Status unavailable';
  }

  // ===========================================================================
  // WEBSITE
  // ===========================================================================

  Future<void> _showWebsite(
    BuildContext context,
    Place place,
  ) async {
    final Uri? website = place.websiteUri;

    if (website == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This place does not have a website listed.',
          ),
        ),
      );

      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text: website.toString(),
      ),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Website link copied.',
        ),
      ),
    );
  }

  // ===========================================================================
  // DIRECTIONS
  // ===========================================================================

  Future<void> _showDirections(
    BuildContext context,
    Place place,
  ) async {
    final LatLng? destination = place.latLng;

    if (destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location is unavailable for this place.',
          ),
        ),
      );

      return;
    }

    // Correct Google Maps URL.
    //
    // The old code accidentally contained Markdown:
    //
    // [https://www.google.com/maps/...](https://...)
    //
    // That is NOT a valid URL.
    final String mapsUrl = 'https://www.google.com/maps/dir/?api=1'
        '&origin=${_currentPosition?.latitude},${_currentPosition?.longitude}'
        '&destination=${destination.lat},${destination.lng}';

    await Clipboard.setData(
      ClipboardData(
        text: mapsUrl,
      ),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Directions link copied. Open it in Google Maps.',
        ),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM NAVIGATION
  // ===========================================================================

  void _onBottomTap(
    BuildContext context,
    int index,
  ) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(
          context,
          '/home',
        );
        break;

      case 1:
        Navigator.pushReplacementNamed(
          context,
          '/reminder',
        );
        break;

      case 2:
        Navigator.pushReplacementNamed(
          context,
          '/finder',
        );
        break;

      case 3:
        Navigator.pushReplacementNamed(
          context,
          '/sos',
        );
        break;

      case 4:
        Navigator.pushReplacementNamed(
          context,
          '/profile',
        );
        break;
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 2,
        onTap: (index) {
          _onBottomTap(
            context,
            index,
          );
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.045,
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // =================================================================
              // SEARCH
              // =================================================================

              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE7EAEE),
                  ),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Search hospital, clinic...',
                    hintStyle: TextStyle(
                      color: Colors.black45,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Color(0xFF555E68),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // =================================================================
              // LOCATION HEADER
              // =================================================================

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFD8EDF1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF3D84A8),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isLoadingLocation
                            ? 'Getting your location...'
                            : _locationError != null
                                ? _locationError!
                                : _isLoadingPlaces
                                    ? 'Finding nearby clinics & pharmacies...'
                                    : 'Nearby clinics & pharmacies',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF27313A),
                        ),
                      ),
                    ),
                    if (!_isLoadingLocation &&
                        (_locationError != null || _placesError != null))
                      IconButton(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF3D84A8),
                        ),
                        tooltip: 'Try again',
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // =================================================================
              // TITLE
              // =================================================================

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Available places',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF20252B),
                    ),
                  ),
                  Text(
                    '${_filteredPlaces.length} found',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // =================================================================
              // LOADING
              // =================================================================

              if (_isLoadingPlaces)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: LinearProgressIndicator(
                    minHeight: 2,
                  ),
                ),

              // =================================================================
              // LIST
              // =================================================================

              Expanded(
                child: _filteredPlaces.isEmpty
                    ? Center(
                        child: _isLoadingPlaces
                            ? const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(
                                        0xFF3D84A8,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 14,
                                  ),
                                  Text(
                                    'Finding nearby places...',
                                    style: TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFEAF2F5,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        16,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.location_searching_rounded,
                                      color: Color(
                                        0xFF3D84A8,
                                      ),
                                      size: 27,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  Text(
                                    _placesError ?? 'No places found nearby.',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 15,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          bottom: 20,
                        ),
                        itemCount: _filteredPlaces.length,
                        itemBuilder: (context, index) {
                          final Place place = _filteredPlaces[index];

                          return _PlaceCard(
                            place: place,
                            distanceText: _distanceText(
                              place,
                            ),
                            typeText: _placeTypeText(
                              place,
                            ),
                            rating: _ratingValue(
                              place,
                            ),
                            openStatusText: _openStatusText(
                              place,
                            ),
                            onWebsite: () {
                              _showWebsite(
                                context,
                                place,
                              );
                            },
                            onDirections: () {
                              _showDirections(
                                context,
                                place,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PLACE CARD
// =============================================================================

class _PlaceCard extends StatelessWidget {
  final Place place;

  final String distanceText;
  final String typeText;
  final double? rating;
  final String openStatusText;

  final VoidCallback onWebsite;
  final VoidCallback onDirections;

  const _PlaceCard({
    required this.place,
    required this.distanceText,
    required this.typeText,
    required this.rating,
    required this.openStatusText,
    required this.onWebsite,
    required this.onDirections,
  });

  // ===========================================================================
  // MEDICAL ICON
  // ===========================================================================

  IconData _placeIcon() {
    final List<PlaceType>? types = place.types;

    if (types != null) {
      for (final PlaceType type in types) {
        switch (type) {
          case PlaceType.PHARMACY:
            return Icons.medication_outlined;

          case PlaceType.HOSPITAL:
            return Icons.local_hospital_outlined;

          case PlaceType.DOCTOR:
            return Icons.medical_services_outlined;

          case PlaceType.DENTIST:
            return Icons.health_and_safety_outlined;

          case PlaceType.PHYSIOTHERAPIST:
            return Icons.accessibility_new_outlined;

          case PlaceType.MEDICAL_LAB:
            return Icons.science_outlined;

          case PlaceType.HEALTH:
            return Icons.health_and_safety_outlined;

          default:
            break;
        }
      }
    }

    return Icons.local_hospital_outlined;
  }

  // ===========================================================================
  // ICON BACKGROUND
  // ===========================================================================

  Color _iconBackground() {
    final List<PlaceType>? types = place.types;

    if (types != null) {
      for (final PlaceType type in types) {
        switch (type) {
          case PlaceType.PHARMACY:
            return const Color(0xFFEAF4F1);

          case PlaceType.HOSPITAL:
            return const Color(0xFFEAF2F7);

          case PlaceType.DOCTOR:
            return const Color(0xFFF0EEF8);

          case PlaceType.DENTIST:
            return const Color(0xFFEDF4F8);

          case PlaceType.PHYSIOTHERAPIST:
            return const Color(0xFFF1F3EC);

          case PlaceType.MEDICAL_LAB:
            return const Color(0xFFF1EEF7);

          case PlaceType.HEALTH:
            return const Color(0xFFEAF4F1);

          default:
            break;
        }
      }
    }

    return const Color(0xFFEAF2F7);
  }

  Color _iconColor() {
    final List<PlaceType>? types = place.types;

    if (types != null) {
      for (final PlaceType type in types) {
        switch (type) {
          case PlaceType.PHARMACY:
            return const Color(0xFF438C76);

          case PlaceType.HOSPITAL:
            return const Color(0xFF3D84A8);

          case PlaceType.DOCTOR:
            return const Color(0xFF70639A);

          case PlaceType.DENTIST:
            return const Color(0xFF4C819B);

          case PlaceType.PHYSIOTHERAPIST:
            return const Color(0xFF72815C);

          case PlaceType.MEDICAL_LAB:
            return const Color(0xFF77669B);

          case PlaceType.HEALTH:
            return const Color(0xFF438C76);

          default:
            break;
        }
      }
    }

    return const Color(0xFF3D84A8);
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final String placeName =
        place.name?.trim().isNotEmpty == true ? place.name! : 'Unknown place';

    final String address = place.address?.trim().isNotEmpty == true
        ? place.address!
        : 'Address unavailable';

    final bool operational = place.businessStatus == BusinessStatus.Operational;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8EBEF),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===================================================================
          // TOP
          // ===================================================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _iconBackground(),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _placeIcon(),
                  color: _iconColor(),
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      placeName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF20252B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      typeText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF737A82),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ===================================================================
          // INFO CHIPS
          // ===================================================================

          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              if (rating != null) _ratingChip(rating!),
              _simpleChip(
                distanceText,
                icon: Icons.near_me_outlined,
              ),
              if (operational) _statusChip(),
            ],
          ),

          const SizedBox(height: 11),

          // ===================================================================
          // ADDRESS
          // ===================================================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 17,
                  color: Color(0xFF7A828A),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF68717A),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          // ===================================================================
          // STATUS
          // ===================================================================

          Text(
            openStatusText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: operational
                  ? const Color(0xFF3E9B5D)
                  : const Color(0xFF7A828A),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          // ===================================================================
          // BUTTONS
          // ===================================================================

          Row(
            children: [
              Expanded(
                child: _outlineButton(
                  text: 'Website',
                  icon: Icons.language_outlined,
                  onPressed: onWebsite,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _primaryButton(
                  text: 'Directions',
                  icon: Icons.directions_outlined,
                  onPressed: onDirections,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // RATING CHIP
  // ===========================================================================

  Widget _ratingChip(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 15,
            color: Color(0xFFD19A24),
          ),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5F5640),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SIMPLE CHIP
  // ===========================================================================

  Widget _simpleChip(
    String text, {
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF68717A),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF555D65),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STATUS CHIP
  // ===========================================================================

  Widget _statusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF3E9B5D),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'Open',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF3E8B56),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PRIMARY BUTTON
  // ===========================================================================

  Widget _primaryButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 43,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 18,
        ),
        label: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3D84A8),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // OUTLINE BUTTON
  // ===========================================================================

  Widget _outlineButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 43,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 18,
        ),
        label: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF3D84A8),
          side: const BorderSide(
            color: Color(0xFFB9D5E1),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }
}
