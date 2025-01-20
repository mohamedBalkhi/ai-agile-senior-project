// class ValidationError {
//   final String propertyName;
//   final String errorMessage;

//   ValidationError({required this.propertyName, required this.errorMessage});

//   factory ValidationError.fromJson(Map<String, dynamic> json) {
//     final propertyName = json['PropertyName'] as String?;
//     final errorMessage = json['ErrorMessage'] as String?;
    
//     if (propertyName == null || errorMessage == null) {
//       return ValidationError(propertyName: '', errorMessage: '');
//     }

//     return ValidationError(
//       propertyName: propertyName,
//       errorMessage: errorMessage,
//     );
//   }
// }
