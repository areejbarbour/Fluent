import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repository/level_repository.dart';
// import 'student_levels_state.dart';
import 'package:fluent/cubit/student/levels/levels_state.dart';

class StudentLevelsCubit extends Cubit<StudentLevelsState> {
  final LevelRepository levelRepository;
  StudentLevelsCubit(this.levelRepository) : super(StudentLevelsInitial());

  Future<void> fetchStudentLevels() async {
    emit(StudentLevelsLoading());
    print("🟡 [StudentLevelsCubit] Fetching student levels...");

    final result = await levelRepository.getStudentLevels();

    if (result['success'] == true) {
      print("🎉 [StudentLevelsCubit] Levels loaded successfully");
      emit(StudentLevelsSuccess(result['data']));
    } else {
      print("❌ [StudentLevelsCubit] Failed: ${result['message']}");
      emit(StudentLevelsFailure(result['message'] ?? 'فشل تحميل المستويات'));
    }
  }
}