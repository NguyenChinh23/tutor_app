import 'package:flutter/material.dart';
import 'package:tutor_app/data/models/tutor_model.dart';
import 'package:tutor_app/data/repositories/tutor_repository.dart';

class TutorProvider extends ChangeNotifier{
  final _repo = TutorRepository();
  List<TutorModel> _tutors = [];
  bool _loading = true;

  List<TutorModel> get tutors => _tutors;
  bool get isLoading => _loading;

  TutorProvider(){
    _listenTutors();
  }

  void _listenTutors() {
    _repo.getApprovedTuTor().listen((list){
      _tutors = list;
      _loading= false;
      notifyListeners();
    });
  }
  TutorModel? getTutorById(String uid){
    try{
      return _tutors.firstWhere((t)=> t.uid == uid);
    }catch(_){
      return null;
    }
  }




}
