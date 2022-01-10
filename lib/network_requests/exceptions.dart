class AppException implements Exception {
  final _message;
  final _status;

  AppException([
    this._message,
    this._status,
  ]);

  String toString() {
    return "$_message";
  }
}

class FetchDataException extends AppException {
  FetchDataException([String message]) : super(message);
}
