// core/utils/form_validators.dart
class FormValidators {
  // Email validator
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    
    // Simple regex for email validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  // Password validator
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    return null;
  }
  
  // Strong password validator (for registration)
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one digit
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    // Check for at least one special character
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }
  
  // Name validator
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    
    if (value.trim().length < 2) {
      return 'Must be at least 2 characters';
    }
    
    return null;
  }
  
  // Phone number validator
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    
    // Simple regex for phone validation (allows +, spaces, and digits)
    final phoneRegex = RegExp(r'^\+?[\d\s]+$');
    
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    
    if (value.trim().length < 9) {
      return 'Phone number is too short';
    }
    
    return null;
  }
  
  // Required field validator
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    return null;
  }
  
  // URL validator
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // URL is optional
    }
    
    // Simple regex for URL validation
    final urlRegex = RegExp(
      r'^(http|https)://[a-zA-Z0-9-\.]+\.[a-zA-Z]{2,}(/\S*)?$',
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }
  
  // Date validator (checks if date is in the future)
  static String? validateFutureDate(DateTime? date) {
    if (date == null) {
      return 'Please select a date';
    }
    
    if (date.isBefore(DateTime.now())) {
      return 'Date must be in the future';
    }
    
    return null;
  }
  
  // End date validator (checks if end date is after start date)
  static String? validateEndDate(DateTime? endDate, DateTime? startDate) {
    if (endDate == null) {
      return 'Please select an end date';
    }
    
    if (startDate == null) {
      return 'Please select a start date first';
    }
    
    if (endDate.isBefore(startDate) || endDate.isAtSameMomentAs(startDate)) {
      return 'End date must be after start date';
    }
    
    return null;
  }
  
  // Confirm password validator
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
}