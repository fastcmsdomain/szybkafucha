import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../providers/location_provider.dart';
import '../services/location_service.dart';
import '../theme/theme.dart';

/// Address autocomplete widget for Poland addresses
///
/// Uses Nominatim (OpenStreetMap) for address search.
/// User MUST select from dropdown suggestions.
class SFAddressAutocomplete extends ConsumerStatefulWidget {
  /// Callback when an address is selected
  final void Function(AddressSuggestion suggestion) onAddressSelected;

  /// Initial address to display
  final String? initialAddress;

  /// Hint text for the input
  final String hintText;

  /// Whether the field is enabled
  final bool enabled;

  /// Error text to display
  final String? errorText;

  const SFAddressAutocomplete({
    super.key,
    required this.onAddressSelected,
    this.initialAddress,
    this.hintText = 'np. ul. Marszałkowska, Warszawa',
    this.enabled = true,
    this.errorText,
  });

  @override
  ConsumerState<SFAddressAutocomplete> createState() =>
      _SFAddressAutocompleteState();
}

class _SFAddressAutocompleteState extends ConsumerState<SFAddressAutocomplete> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;
  bool _isSearching = false;
  List<AddressSuggestion> _suggestions = [];
  AddressSuggestion? _selectedSuggestion;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _controller.text = widget.initialAddress!;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _debounceTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _onTextChanged(String value) {
    // Clear previous selection if text changed
    if (_selectedSuggestion != null &&
        value != _selectedSuggestion!.shortName) {
      _selectedSuggestion = null;
    }

    _debounceTimer?.cancel();

    if (value.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      _removeOverlay();
      return;
    }

    setState(() => _isSearching = true);

    // Debounce search by 300ms
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchAddresses(value);
    });
  }

  Future<void> _searchAddresses(String query) async {
    final service = ref.read(locationServiceProvider);
    final results = await service.searchAddresses(query);

    if (mounted) {
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });

      if (results.isNotEmpty && _focusNode.hasFocus) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getTextFieldWidth(),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 4,
            borderRadius: AppRadius.radiusMD,
            color: AppColors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: _buildSuggestionsList(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  double _getTextFieldWidth() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 300;
  }

  void _onSuggestionSelected(AddressSuggestion suggestion) {
    setState(() {
      _selectedSuggestion = suggestion;
      _controller.text = suggestion.shortName;
      _suggestions = [];
    });
    _removeOverlay();
    _focusNode.unfocus();
    widget.onAddressSelected(suggestion);
  }

  Widget _buildSuggestionsList() {
    if (_isSearching) {
      return Container(
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: AppSpacing.gapMD),
            Text(
              'Szukam...',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        child: Text(
          'Brak wyników',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.gray500,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return _buildSuggestionItem(suggestion);
      },
    );
  }

  Widget _buildSuggestionItem(AddressSuggestion suggestion) {
    return InkWell(
      onTap: () => _onSuggestionSelected(suggestion),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingMD,
          vertical: AppSpacing.paddingSM,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.gray100,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: AppColors.gray400,
              size: 20,
            ),
            SizedBox(width: AppSpacing.gapSM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.shortName,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (suggestion.city != null ||
                      suggestion.postcode != null) ...[
                    SizedBox(height: 2),
                    Text(
                      [
                        suggestion.postcode,
                        suggestion.city,
                      ].where((s) => s != null).join(', '),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gray500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            onChanged: _onTextChanged,
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray400,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.gray400,
              ),
              suffixIcon: _isSearching
                  ? Padding(
                      padding: EdgeInsets.all(AppSpacing.paddingSM),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: AppColors.gray400,
                          ),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _selectedSuggestion = null;
                              _suggestions = [];
                            });
                            _removeOverlay();
                          },
                        )
                      : null,
              filled: true,
              fillColor: AppColors.gray50,
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.error),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.paddingMD,
                vertical: AppSpacing.paddingMD,
              ),
              errorText: widget.errorText,
            ),
          ),
          if (_selectedSuggestion != null)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.gapXS),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppColors.success,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Wybrano: ${_selectedSuggestion!.shortName}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.success,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Address input with current location option
class SFAddressInput extends ConsumerStatefulWidget {
  /// Callback when location is selected (from GPS or address search)
  final void Function(LatLng latLng, String address) onLocationSelected;

  /// Initial address to display
  final String? initialAddress;

  /// Initial coordinates
  final LatLng? initialLatLng;

  /// Error text to display
  final String? errorText;

  const SFAddressInput({
    super.key,
    required this.onLocationSelected,
    this.initialAddress,
    this.initialLatLng,
    this.errorText,
  });

  @override
  ConsumerState<SFAddressInput> createState() => _SFAddressInputState();
}

class _SFAddressInputState extends ConsumerState<SFAddressInput> {
  bool _useCurrentLocation = false;
  bool _isLoadingGps = false;
  String? _currentAddress;
  LatLng? _currentLatLng;
  String? _gpsError;

  @override
  void initState() {
    super.initState();
    _currentAddress = widget.initialAddress;
    _currentLatLng = widget.initialLatLng;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingGps = true;
      _gpsError = null;
    });

    final service = ref.read(locationServiceProvider);

    // Check permission first
    final permissionStatus = await service.checkPermission();
    debugPrint('Location permission status: $permissionStatus');

    if (permissionStatus == LocationPermissionStatus.deniedForever) {
      setState(() {
        _isLoadingGps = false;
        _gpsError = 'Dostęp do lokalizacji zablokowany. Włącz w ustawieniach.';
      });
      _showPermissionDialog(permanently: true);
      return;
    }

    if (permissionStatus != LocationPermissionStatus.granted) {
      // Request permission
      final newStatus = await service.requestPermission();
      debugPrint('Permission request result: $newStatus');

      if (newStatus != LocationPermissionStatus.granted) {
        setState(() {
          _isLoadingGps = false;
          _gpsError = 'Dostęp do lokalizacji jest wymagany';
        });
        if (newStatus == LocationPermissionStatus.deniedForever) {
          _showPermissionDialog(permanently: true);
        } else {
          _showPermissionDialog(permanently: false);
        }
        return;
      }
    }

    final latLng = await service.getCurrentLatLng();

    if (latLng == null) {
      setState(() {
        _isLoadingGps = false;
        _gpsError = 'Nie udało się pobrać lokalizacji. Sprawdź GPS.';
      });
      return;
    }

    // Validate that location is within Poland
    if (!LocationService.isInPoland(latLng)) {
      setState(() {
        _isLoadingGps = false;
        _gpsError = 'Lokalizacja poza Polską. Aplikacja działa tylko w Polsce.';
        _useCurrentLocation = false;
      });
      return;
    }

    final address = await service.getAddressFromLatLng(latLng);

    setState(() {
      _isLoadingGps = false;
      _currentLatLng = latLng;
      _currentAddress = address ?? 'Nieznany adres';
      _useCurrentLocation = true;
    });

    widget.onLocationSelected(latLng, _currentAddress!);
  }

  void _onAddressSelected(AddressSuggestion suggestion) {
    setState(() {
      _currentLatLng = suggestion.latLng;
      _currentAddress = suggestion.shortName;
      _useCurrentLocation = false;
      _gpsError = null;
    });

    widget.onLocationSelected(suggestion.latLng, suggestion.shortName);
  }

  void _showPermissionDialog({required bool permanently}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dostęp do lokalizacji'),
        content: Text(
          permanently
              ? 'Dostęp do lokalizacji został trwale zablokowany. Aby użyć GPS, przejdź do ustawień aplikacji i przyznaj uprawnienia.'
              : 'Szybka Fucha potrzebuje dostępu do Twojej lokalizacji, aby automatycznie ustawić adres zlecenia.\n\nMożesz też wpisać adres ręcznie.',
        ),
        actions: [
          if (!permanently)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (permanently) {
                await ref.read(locationServiceProvider).openAppSettings();
              } else {
                // Try again
                _getCurrentLocation();
              }
            },
            child: Text(permanently ? 'Otwórz ustawienia' : 'Spróbuj ponownie'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // GPS Location option
        GestureDetector(
          onTap: _isLoadingGps ? null : _getCurrentLocation,
          child: Container(
            padding: EdgeInsets.all(AppSpacing.paddingMD),
            decoration: BoxDecoration(
              color: _useCurrentLocation
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.gray50,
              borderRadius: AppRadius.radiusMD,
              border: Border.all(
                color: _useCurrentLocation
                    ? AppColors.primary
                    : AppColors.gray200,
              ),
            ),
            child: Row(
              children: [
                _isLoadingGps
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(
                        Icons.my_location,
                        color: _useCurrentLocation
                            ? AppColors.primary
                            : AppColors.gray600,
                      ),
                SizedBox(width: AppSpacing.gapMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Użyj mojej lokalizacji',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: _useCurrentLocation
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (_useCurrentLocation && _currentAddress != null) ...[
                        SizedBox(height: 4),
                        Text(
                          _currentAddress!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.gray600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else if (_gpsError != null) ...[
                        SizedBox(height: 4),
                        Text(
                          _gpsError!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Automatycznie wykryj lokalizację GPS',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_useCurrentLocation)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
        ),

        SizedBox(height: AppSpacing.gapMD),

        // Divider with "lub"
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.gray200)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingMD),
              child: Text(
                'lub',
                style: AppTypography.caption.copyWith(
                  color: AppColors.gray400,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.gray200)),
          ],
        ),

        SizedBox(height: AppSpacing.gapMD),

        // Address autocomplete
        Text(
          'Wpisz adres',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.gray600,
          ),
        ),
        SizedBox(height: AppSpacing.gapSM),
        SFAddressAutocomplete(
          onAddressSelected: _onAddressSelected,
          initialAddress:
              !_useCurrentLocation ? widget.initialAddress : null,
          enabled: !_isLoadingGps,
          errorText: widget.errorText,
        ),
      ],
    );
  }
}
