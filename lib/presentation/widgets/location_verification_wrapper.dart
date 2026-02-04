import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/location_provider.dart';

class LocationVerificationWrapper extends StatelessWidget {
  final Widget child;
  final bool showErrorScreen;

  const LocationVerificationWrapper({
    super.key,
    required this.child,
    this.showErrorScreen = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, _) {
        if (locationProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!locationProvider.isWithinShopPerimeter && showErrorScreen) {
          return _buildLocationError(context, locationProvider);
        }

        return child;
      },
    );
  }

  Widget _buildLocationError(
      BuildContext context, LocationProvider locationProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Location Restriction',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              locationProvider.errorMessage ?? 'You are not at the shop',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Shop Location: ${locationProvider.shopAddress}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => locationProvider.checkLocation(),
            ),
          ],
        ),
      ),
    );
  }
}
