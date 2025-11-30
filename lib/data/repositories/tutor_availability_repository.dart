import 'package:tutor_app/data/models/tutor_availability_model.dart';
import 'package:tutor_app/data/services/tutor_availability_service.dart';

class TutorAvailabilityRepository {
  final TutorAvailabilityService service;

  TutorAvailabilityRepository(this.service);

  Future<TutorAvailability?> getForTutor(String tutorId) =>
      service.getForTutor(tutorId);

  Future<void> saveForTutor(TutorAvailability availability) =>
      service.saveForTutor(availability);
}
