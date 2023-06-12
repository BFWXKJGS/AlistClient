class RedirectException implements Exception {
  final String message;

  RedirectException(this.message);

  @override
  String toString() {
    String report = "Location: $message";
    return report;
  }
}
