import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fluent/data/models/profile_model.dart';
import 'package:fluent/data/repository/auth_repository.dart';
import 'package:fluent/data/repository/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository profileRepository;
  final AuthRepository authRepository;

  ProfileCubit({required this.profileRepository, required this.authRepository})
    : super(ProfileInitial());

  ProfileViewData? _current;

  Future<void> loadProfile() async {
    emit(ProfileLoading());
    print('🟡 [ProfileCubit] Loading profile...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final role = (prefs.getString('user_role') ?? 'student').toLowerCase();
      final isTeacher = role == 'teacher';

      // Name / email: prefer /api/user, fall back to prefs
      String name = prefs.getString('user_name') ?? '';
      String email = prefs.getString('user_email') ?? '';

      try {
        final me = await authRepository.getCurrentUser();
        if (me['success'] == true) {
          final raw = me['user'] ?? me['data'];
          if (raw is Map) {
            final u = Map<String, dynamic>.from(raw);
            final first = u['first_name']?.toString() ?? '';
            final last = u['last_name']?.toString() ?? '';
            final full = '$first $last'.trim();
            if (full.isNotEmpty) {
              name = full;
              await prefs.setString('user_name', full);
            }
            final em = u['email']?.toString();
            if (em != null && em.isNotEmpty) {
              email = em;
              await prefs.setString('user_email', em);
            }
          }
        }
      } catch (e) {
        print('⚠️ [ProfileCubit] getCurrentUser failed: $e');
      }

      if (name.isEmpty) name = isTeacher ? 'Teacher' : 'Student';
      if (email.isEmpty) email = '—';

      if (isTeacher) {
        final result = await profileRepository.getTeacherProfile();
        if (result['success'] == true) {
          final p = result['data'] as TeacherProfileModel;
          _current = ProfileViewData(
            isTeacher: true,
            name: name,
            email: email,
            bio: p.bio,
            imageUrl: p.imageUrl,
          );
          print('🎉 [ProfileCubit] Teacher profile loaded');
          emit(ProfileLoaded(_current!));
        } else {
          print(
            '❌ [ProfileCubit] Teacher profile failed: ${result['message']}',
          );
          emit(
            ProfileFailure(
              result['message']?.toString() ?? 'Failed to load profile',
              errors: result['errors'] as Map<String, dynamic>?,
            ),
          );
        }
      } else {
        final result = await profileRepository.getStudentProfile();
        if (result['success'] == true) {
          final p = result['data'] as StudentProfileModel;
          _current = ProfileViewData(
            isTeacher: false,
            name: name,
            email: email,
            bio: p.bio,
            imageUrl: p.imageUrl,
            points: p.points,
            streak: p.streak,
            lastActivateDate: p.lastActivateDate,
          );
          print('🎉 [ProfileCubit] Student profile loaded');
          emit(ProfileLoaded(_current!));
        } else {
          print(
            '❌ [ProfileCubit] Student profile failed: ${result['message']}',
          );
          emit(
            ProfileFailure(
              result['message']?.toString() ?? 'Failed to load profile',
              errors: result['errors'] as Map<String, dynamic>?,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [ProfileCubit] Unexpected: $e');
      emit(ProfileFailure(e.toString()));
    }
  }

  /// Updates bio and/or profile image. Matches backend:
  /// POST multipart with optional `bio` and optional `image`.
  Future<void> updateProfile({String? bio, String? imagePath}) async {
    final previous = _current;
    if (previous != null) {
      emit(ProfileUpdating(previous));
    } else {
      emit(ProfileLoading());
    }

    print('🟡 [ProfileCubit] Updating profile...');

    try {
      final isTeacher =
          previous?.isTeacher ??
          ((await SharedPreferences.getInstance()).getString('user_role') ??
                      'student')
                  .toLowerCase() ==
              'teacher';

      final Map<String, dynamic> result;
      if (isTeacher) {
        result = await profileRepository.updateTeacherProfile(
          bio: bio,
          imagePath: imagePath,
        );
      } else {
        result = await profileRepository.updateStudentProfile(
          bio: bio,
          imagePath: imagePath,
        );
      }

      if (result['success'] == true) {
        if (isTeacher) {
          final p = result['data'] as TeacherProfileModel;
          _current =
              (previous ??
                      const ProfileViewData(
                        isTeacher: true,
                        name: 'Teacher',
                        email: '—',
                      ))
                  .copyWith(isTeacher: true, bio: p.bio, imageUrl: p.imageUrl);
        } else {
          final p = result['data'] as StudentProfileModel;
          _current =
              (previous ??
                      const ProfileViewData(
                        isTeacher: false,
                        name: 'Student',
                        email: '—',
                      ))
                  .copyWith(
                    isTeacher: false,
                    bio: p.bio,
                    imageUrl: p.imageUrl,
                    points: p.points,
                    streak: p.streak,
                    lastActivateDate: p.lastActivateDate,
                  );
        }

        final msg =
            result['message']?.toString() ?? 'Profile updated successfully';
        print('🎉 [ProfileCubit] Profile updated');
        emit(ProfileUpdateSuccess(_current!, msg));
        emit(ProfileLoaded(_current!));
      } else {
        print('❌ [ProfileCubit] Update failed: ${result['message']}');
        emit(
          ProfileFailure(
            result['message']?.toString() ?? 'Failed to update profile',
            errors: result['errors'] as Map<String, dynamic>?,
            profile: previous,
          ),
        );
        if (previous != null) emit(ProfileLoaded(previous));
      }
    } catch (e) {
      print('❌ [ProfileCubit] Update unexpected: $e');
      emit(ProfileFailure(e.toString(), profile: previous));
      if (previous != null) emit(ProfileLoaded(previous));
    }
  }
}
