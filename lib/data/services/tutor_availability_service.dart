import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutor_app/data/models/tutor_availability_model.dart';

class TutorAvailabilityService {
  final _fs = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _fs.collection('tutorAvailability');

  Future<TutorAvailability?> getForTutor(String tutorId) async {
    final doc = await _col.doc(tutorId).get();
    if (!doc.exists) return null;
    return TutorAvailability.fromDoc(tutorId, doc);
  }

  Future<void> saveForTutor(TutorAvailability availability) async {
    await _col.doc(availability.tutorId).set(availability.toMap());
  }
}
