import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:studyu_designer_v2/common_views/form_table_layout.dart';

class EmailTextField extends StatefulWidget {
  const EmailTextField({
    this.labelText = 'Email', // .hardcoded
    this.formControlName,
    this.formControl,
    this.hintText = 'mail@example.com', //.hardcoded
    Key? key,
  })  : assert(
  (formControlName != null && formControl == null) ||
      (formControlName == null && formControl != null),
  "Must provide either formControlName or formControl"),
        super(key: key);

  final String labelText;
  final String? hintText;
  final String? formControlName;
  final FormControl? formControl;

  @override
  _EmailTextFieldState createState() => _EmailTextFieldState();
}

class _EmailTextFieldState extends State<EmailTextField> {
  @override
  Widget build(BuildContext context) {
    return FormTableLayout(
      rowLayout: FormTableRowLayout.vertical,
      rows: [
        FormTableRow(
          label: widget.labelText,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          input: ReactiveTextField(
            formControl: widget.formControl,
            formControlName: widget.formControlName,
            decoration: InputDecoration(
              hintText: widget.hintText,
            ),
          ),
        )
      ],
    );
  }
}

class PasswordTextField extends StatefulWidget {
  const PasswordTextField({
    this.labelText = 'Password', // .hardcoded
    this.formControlName,
    this.formControl,
    this.hintText = 'Enter password', //.hardcoded
    Key? key,
  })  : assert(
            (formControlName != null && formControl == null) ||
                (formControlName == null && formControl != null),
            "Must provide either formControlName or formControl"),
        super(key: key);

  final String labelText;
  final String? hintText;
  final String? formControlName;
  final FormControl? formControl;

  @override
  _PasswordTextFieldState createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  late bool passwordVisibility = false;

  @override
  Widget build(BuildContext context) {
    return FormTableLayout(
      rowLayout: FormTableRowLayout.vertical,
      rows: [
        FormTableRow(
            label: widget.labelText,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            input: ReactiveTextField(
              formControl: widget.formControl,
              formControlName: widget.formControlName,
              obscureText: !passwordVisibility,
              decoration: InputDecoration(
                hintText: widget.hintText,
                suffixIcon: InkWell(
                  onTap: () => setState(
                    () => passwordVisibility = !passwordVisibility,
                  ),
                  focusNode: FocusNode(skipTraversal: true),
                  child: Icon(
                    passwordVisibility
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ))
      ],
    );
  }
}
