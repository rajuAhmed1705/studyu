import 'package:reactive_forms/reactive_forms.dart';

/// Signature for a boolean predicate evaluated on [value] of type [T]
typedef CountWherePredicate<T> = bool Function(T? value);

/// Custom validator for use with [FormArray]
///
/// Validates that the number of times the given [predicate] evaluates to
/// true is between [minCount] and [maxCount].
class CountWhereValidator<T> extends Validator<T> {
  CountWhereValidator(this.predicate, {this.minCount, this.maxCount});

  final CountWherePredicate<T> predicate;
  final int? minCount;
  final int? maxCount;

  static const kValidationMessageMinCount = 'countMin';
  static const kValidationMessageMaxCount = 'countMax';

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    // don't validate empty values to allow optional controls
    if (control.value == null) {
      return null;
    }
    if (control is! FormArray<T>) {
      throw Exception(
          "CountWhereValidator must be used with AbstractControl of "
          "type FormArray.");
    }

    final List<T?> collection = (control as FormArray<T>).value!;
    int countPredicateTrue = 0;

    for (final value in collection) {
      if (predicate(value)) {
        countPredicateTrue += 1;
      }
    }

    final Map<String, dynamic> errors = {};
    if (minCount != null && countPredicateTrue < minCount!) {
      errors[kValidationMessageMinCount] = countPredicateTrue;
    }
    if (maxCount != null && countPredicateTrue > maxCount!) {
      errors[kValidationMessageMaxCount] = countPredicateTrue;
    }

    if (errors.isNotEmpty) {
      return errors;
    }
    return null;
  }
}

ValidatorFunction mustMatch({
  AbstractControl? control,
  String? controlName,
  AbstractControl? matchingControl,
  String? matchingControlName,
}) {
  if ((controlName == null && control == null) ||
      (matchingControlName == null && matchingControl == null)) {
    throw Exception(
        "Must provide either the control's reference or name for each control");
  }

  return (AbstractControl<dynamic> form) {
    form = form as FormGroup;

    final formControl = control ?? form.control(controlName!);
    final matchingFormControl =
        matchingControl ?? form.control(matchingControlName!);

    if (formControl.value != matchingFormControl.value) {
      matchingFormControl.setErrors({'mustMatch': true});

      // force messages to show up as soon as possible
      matchingFormControl.markAsTouched();
    } else {
      matchingFormControl.removeError('mustMatch');
    }

    return null;
  };
}

// todo replace this with reactive forms validator
class FieldValidators {
  static String? emailValidator(String? email) {
    if (email == null) {
      return 'Not a valid email'; //return null;
    }
    if (!RegExp(Patterns.emailFormatString).hasMatch(email)) {
      return 'Not a valid email';
    }
    return null;
  }
}

class Patterns {
  /// Regex pattern for hh:mm time format (with or without leading zero)
  //static const timeFormatString = r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$';
  static const timeFormatString = r'^[ab]$';
  static const emailFormatString =
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
  static const url =
      r'[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)';
}
