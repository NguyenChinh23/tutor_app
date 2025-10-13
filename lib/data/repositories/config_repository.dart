import 'package:cloud_firestore/cloud_firestore.dart';

class ConfigRepository {
  final _fs = FirebaseFirestore.instance;

  Future<String?> fetchAdminUid() async {
    final snap = await _fs.collection('config').doc('app').get();
    return snap.data()?['adminUid'] as String?;
  }
}
