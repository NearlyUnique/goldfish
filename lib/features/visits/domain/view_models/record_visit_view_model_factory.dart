import 'package:goldfish/core/api/overpass_client.dart';
import 'package:goldfish/core/auth/auth_notifier.dart';
import 'package:goldfish/core/data/repositories/visit_repository.dart';
import 'package:goldfish/core/location/location_service.dart';
import 'package:goldfish/features/visits/domain/view_models/record_visit_view_model.dart';

/// Factory function for creating [RecordVisitViewModel] instances.
///
/// Centralises the creation of [RecordVisitViewModel] with all required
/// dependencies, improving testability and reducing coupling.
///
/// This factory function should be called from main.dart or an appropriate
/// dependency injection point, not from UI components.
RecordVisitViewModel createRecordVisitViewModel({
  required LocationService locationService,
  required OverpassClient overpassClient,
  required VisitRepository visitRepository,
  required AuthNotifier authNotifier,
}) {
  return RecordVisitViewModel(
    locationService: locationService,
    overpassClient: overpassClient,
    visitRepository: visitRepository,
    authNotifier: authNotifier,
  );
}
