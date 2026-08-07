import 'package:fluent/data/models/profile_model.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ProfileViewData profile;
  ProfileLoaded(this.profile);
}

class ProfileUpdating extends ProfileState {
  final ProfileViewData profile;
  ProfileUpdating(this.profile);
}

class ProfileUpdateSuccess extends ProfileState {
  final ProfileViewData profile;
  final String message;
  ProfileUpdateSuccess(this.profile, this.message);
}

class ProfileFailure extends ProfileState {
  final String message;
  final Map<String, dynamic>? errors;
  final ProfileViewData? profile;
  ProfileFailure(this.message, {this.errors, this.profile});
}
