String? validateIndianPhone(String? value) {
  final phone = value?.replaceAll(RegExp(r'[\s-]'), '') ?? '';
  final valid = RegExp(r'^(?:\+91[6-9]\d{9}|[6-9]\d{9})$').hasMatch(phone);
  return valid ? null : 'Please enter a valid phone number.';
}
