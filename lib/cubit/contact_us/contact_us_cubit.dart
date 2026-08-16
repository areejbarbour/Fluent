import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import 'package:fluent/data/repository/contact_us_repository.dart';
import 'contact_us_state.dart';

class ContactUsCubit extends SafeCubit<ContactUsState> {
  final ContactUsRepository repository;

  ContactUsCubit(this.repository) : super(const ContactUsInitial());

  /// Backend: text required, min 10, max 2000.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.length < 10) {
      emit(
        const ContactUsFailure(
          'Message must be at least 10 characters.',
          errors: {
            'text': ['Message must be at least 10 characters.'],
          },
        ),
      );
      return;
    }
    if (trimmed.length > 2000) {
      emit(
        const ContactUsFailure(
          'Message must be at most 2000 characters.',
          errors: {
            'text': ['Message must be at most 2000 characters.'],
          },
        ),
      );
      return;
    }

    emit(const ContactUsLoading());
    final result = await repository.sendMessage(trimmed);
    if (result['success'] == true) {
      emit(
        ContactUsSuccess(
          result['message']?.toString() ??
              'Your message has been sent successfully.',
        ),
      );
    } else {
      emit(
        ContactUsFailure(
          result['message']?.toString() ?? 'Failed to send message',
          errors: result['errors'] as Map<String, dynamic>?,
        ),
      );
    }
  }

  void reset() => emit(const ContactUsInitial());
}
