abstract class ContactUsState {
  const ContactUsState();
}

class ContactUsInitial extends ContactUsState {
  const ContactUsInitial();
}

class ContactUsLoading extends ContactUsState {
  const ContactUsLoading();
}

class ContactUsSuccess extends ContactUsState {
  final String message;
  const ContactUsSuccess(this.message);
}

class ContactUsFailure extends ContactUsState {
  final String message;
  final Map<String, dynamic>? errors;
  const ContactUsFailure(this.message, {this.errors});
}
