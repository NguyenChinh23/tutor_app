import 'package:tutor_app/data/models/tutor_model.dart';
import 'package:tutor_app/data/services/tutor_service.dart';

class TutorRepository{
  final _service = TutorService();

  // Lấy danh sách tutor đã duyệt
  Stream<List<TutorModel>> getApprovedTuTor(){
    return _service.getApprovedTutor();
  }

  Future<TutorModel?> fetchTutorById(String uid){
    return _service.getTutorById(uid);
  }
}