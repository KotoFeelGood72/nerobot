class CleanPhone {
  static String cleanPhoneNumber(String phoneNumber) {
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    return cleanedNumber;
  }
}
