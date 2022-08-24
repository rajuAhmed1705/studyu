import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:studyu_core/core.dart';
import 'package:studyu_designer_v2/common_views/async_value_widget.dart';
import 'package:studyu_designer_v2/common_views/form_table_layout.dart';
import 'package:studyu_designer_v2/common_views/side_sheet_modal.dart';
import 'package:studyu_designer_v2/common_views/text_paragraph.dart';
import 'package:studyu_designer_v2/features/design/enrollment/consent_item_form_controller.dart';
import 'package:studyu_designer_v2/features/design/enrollment/consent_item_form_view.dart';
import 'package:studyu_designer_v2/features/design/shared/questionnaire/question/question_form_controller.dart';
import 'package:studyu_designer_v2/features/design/shared/questionnaire/question/question_form_view.dart';
import 'package:studyu_designer_v2/features/design/study_design_page_view.dart';
import 'package:studyu_designer_v2/features/design/study_form_providers.dart';
import 'package:studyu_designer_v2/features/forms/form_array_table.dart';
import 'package:studyu_designer_v2/features/study/study_controller.dart';
import 'package:studyu_designer_v2/localization/string_hardcoded.dart';
import 'package:studyu_designer_v2/routing/router_config.dart';
import 'package:studyu_designer_v2/utils/extensions.dart';

class StudyDesignEnrollmentFormView extends StudyDesignPageWidget {
  const StudyDesignEnrollmentFormView(super.studyId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(studyControllerProvider(studyId));

    return AsyncValueWidget<Study>(
      value: state.study,
      data: (study) {
        final formViewModel =
            ref.read(enrollmentFormViewModelProvider(studyId));
        return ReactiveForm(
          formGroup: formViewModel.form,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextParagraph(
                  text: "Define the questions you want to ask people to check "
                          "if they are eligible to participate in your study. "
                          "For invitation-based studies, you may choose not to add "
                          "any screening questions if you are manually qualifying "
                          "& recruiting participants before inviting them to "
                          "StudyU."
                      .hardcoded),
              const SizedBox(height: 32.0),
              FormTableLayout(rows: [
                FormTableRow(
                  control: formViewModel.enrollmentTypeControl,
                  label: "Recruiting".hardcoded,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  input: Column(
                    children: formViewModel.enrollmentTypeControlOptions
                        .map((option) => ReactiveRadioListTile<Participation>(
                            formControl:
                                formViewModel.enrollmentTypeControl,
                            value: option.value,
                            title: Text(option.label),
                            subtitle: (option.description) != null
                                ? TextParagraph(
                                    text: option.description!,
                                    selectable: false,
                                    style: TextStyle(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6)))
                                : null,
                          ) as Widget)
                        .toList()
                        .separatedBy(() => const SizedBox(height: 8.0)),
                  )),
              ], columnWidths: const {
                  0: FixedColumnWidth(140.0),
                  1: FlexColumnWidth(),
                },
              ),
              const SizedBox(height: 24.0),
              ReactiveFormConsumer(
                // [ReactiveFormConsumer] is needed to to rerender when descendant controls are updated
                // By default, ReactiveFormArray only updates when adding/removing controls
                  builder: (context, form, child) {
                    return ReactiveFormArray(
                      formArray: formViewModel.consentItemArray,
                      builder: (context, formArray, child) {
                        return FormArrayTable<ConsentItemFormViewModel>(
                          control: formViewModel.consentItemArray,
                          items: formViewModel.consentItemModels,
                          onSelectItem: (viewModel) {
                            final routeArgs =
                            formViewModel.buildConsentItemFormRouteArgs(viewModel);
                            _showConsentItemSidesheetWithArgs(routeArgs, context, ref);
                          },
                          getActionsAt: (viewModel, _) => [],
                          onNewItem: () {
                            final routeArgs = formViewModel.buildNewConsentItemFormRouteArgs();
                            _showConsentItemSidesheetWithArgs(routeArgs, context, ref);
                          },
                          onNewItemLabel: 'Add consent text'.hardcoded,
                          rowTitle: (viewModel) => viewModel.formData?.title ??
                              'Missing item title'.hardcoded,
                          leadingWidget: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Participant consent".hardcoded,
                                style: Theme.of(context).textTheme.headline6,
                              ),
                              (formViewModel.questionsArray.disabled)
                                  ? const SizedBox.shrink()
                                  : TextButton.icon(
                                onPressed: formViewModel.testScreener,
                                icon: const Icon(Icons.play_circle_fill),
                                label: Text("Test participant consent".hardcoded),
                              )
                            ],
                          ),
                          //emptyIcon: Icons.content_paste_off_rounded,
                          emptyTitle: "No terms of consent".hardcoded,
                          emptyDescription:
                          "Specify one or more texts that participants have to consent to when enrolling in your study via the StudyU app."
                              .hardcoded,
                        );
                      },
                    );
                  }),
              const SizedBox(height: 24.0),
              ReactiveFormConsumer(
                  // [ReactiveFormConsumer] is needed to to rerender when descendant controls are updated
                  // By default, ReactiveFormArray only updates when adding/removing controls
                  builder: (context, form, child) {
                return ReactiveFormArray(
                  formArray: formViewModel.questionsArray,
                  builder: (context, formArray, child) {
                    return FormArrayTable<QuestionFormViewModel>(
                      control: formViewModel.questionsArray,
                      items: formViewModel.questionModels,
                      onSelectItem: (viewModel) {
                        final routeArgs =
                            formViewModel.buildScreenerQuestionFormRouteArgs(viewModel);
                        _showScreenerQuestionSidesheetWithArgs(routeArgs, context, ref);
                      },
                      getActionsAt: (viewModel, _) =>
                          formViewModel.availablePopupActions(viewModel),
                      onNewItem: () {
                        final routeArgs = formViewModel.buildNewScreenerQuestionFormRouteArgs();
                        _showScreenerQuestionSidesheetWithArgs(routeArgs, context, ref);
                      },
                      onNewItemLabel: 'Add screener question'.hardcoded,
                      rowTitle: (viewModel) =>
                          viewModel.formData?.questionText ??
                          'Missing item title'.hardcoded,
                      leadingWidget: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Screening criteria".hardcoded,
                            style: Theme.of(context).textTheme.headline6,
                          ),
                          (formViewModel.questionsArray.disabled)
                            ? const SizedBox.shrink()
                            : TextButton.icon(
                                onPressed: formViewModel.testScreener,
                                icon: const Icon(Icons.play_circle_fill),
                                label: Text("Test screener".hardcoded),
                            )
                        ],
                      ),
                      //emptyIcon: Icons.content_paste_off_rounded,
                      emptyTitle: "No screening criteria".hardcoded,
                      emptyDescription:
                          "Optional screener questions can help determine whether a potential participant is qualified to participate in the study."
                              .hardcoded,
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // TODO: refactor to use [RoutingIntent] for sidesheet (so that it can be triggered from controller)
  _showScreenerQuestionSidesheetWithArgs(ScreenerQuestionFormRouteArgs routeArgs,
      BuildContext context, WidgetRef ref) {
    final surveyQuestionFormViewModel =
        ref.read(screenerQuestionFormViewModelProvider(routeArgs));
    showFormSideSheet<QuestionFormViewModel>(
      context: context,
      formViewModel: surveyQuestionFormViewModel,
      formViewBuilder: (formViewModel) =>
          SurveyQuestionFormView(formViewModel: formViewModel),
      ignoreAppBar: true,
    );
  }

  // TODO: refactor to use [RoutingIntent] for sidesheet (so that it can be triggered from controller)
  _showConsentItemSidesheetWithArgs(ConsentItemFormRouteArgs routeArgs,
      BuildContext context, WidgetRef ref) {
    final formViewModel = ref.read(consentItemFormViewModelProvider(routeArgs));
    showFormSideSheet<ConsentItemFormViewModel>(
      context: context,
      formViewModel: formViewModel,
      formViewBuilder: (formViewModel) =>
          ConsentItemFormView(formViewModel: formViewModel),
      ignoreAppBar: true,
    );
  }
}
