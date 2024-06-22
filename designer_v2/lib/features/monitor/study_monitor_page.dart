import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyu_core/core.dart';
import 'package:studyu_designer_v2/common_views/async_value_widget.dart';
import 'package:studyu_designer_v2/common_views/empty_body.dart';
import 'package:studyu_designer_v2/common_views/form_buttons.dart';
import 'package:studyu_designer_v2/common_views/sidesheet/sidesheet.dart';
import 'package:studyu_designer_v2/common_views/utils.dart';
import 'package:studyu_designer_v2/domain/study_monitoring.dart';
import 'package:studyu_designer_v2/features/monitor/participant_details_view.dart';
import 'package:studyu_designer_v2/features/monitor/study_monitor_table.dart';
import 'package:studyu_designer_v2/features/study/study_controller.dart';
import 'package:studyu_designer_v2/features/study/study_page_view.dart';
import 'package:studyu_designer_v2/localization/app_translation.dart';

class StudyMonitorScreen extends StudyPageWidget {
  const StudyMonitorScreen(super.studyId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studyControllerProvider(studyId));
    return AsyncValueWidget<Study>(
        value: state.study,
        data: (study) {
          final studyMonitorData = study.monitorData;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _monitorSectionHeader(context, studyMonitorData),
              const SizedBox(height: 40.0), // spacing between body elements
              if (studyMonitorData.items.isNotEmpty) StudyMonitorTable(
                      ref: ref,
                      studyMonitorItems: studyMonitorData.items,
                      onSelectItem: (item) => _onSelectParticipant(context, ref, item, study),
                    ) else EmptyBody(
                      icon: Icons.person_off_rounded,
                      title: tr.monitoring_no_participants_title,
                      description: tr.monitoring_no_participants_description,),
            ],
          );
        },);
  }

  Widget _monitorSectionHeader(BuildContext context, StudyMonitorData monitorData) {
    final enrolled =
        monitorData.activeParticipants + monitorData.dropoutParticipants + monitorData.completedParticipants;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(tr.monitoring_participants_title, style: Theme.of(context).textTheme.headlineSmall),
        const Spacer(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                  child: _buildStat(context, tr.monitoring_active, tr.monitoring_active_tooltip,
                      monitorData.activeParticipants, enrolled,),),
              const SizedBox(width: 20.0),
              Expanded(
                  child: _buildStat(context, tr.monitoring_dropout, tr.monitoring_dropout_tooltip,
                      monitorData.dropoutParticipants, enrolled,),),
              const SizedBox(width: 20.0),
              Expanded(
                  child: _buildStat(context, tr.monitoring_completed, tr.monitoring_completed_tooltip,
                      monitorData.completedParticipants, enrolled,),),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStat(BuildContext context, String title, String tooltip, int value, int total) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Column(
        children: [
          Row(
            children: [
              Text("$title:"),
              const SizedBox(width: 8.0),
              Text("$value/$total", style: theme.textTheme.headlineSmall),
            ],
          ),
          SizedBox(
              height: 4.0,
              child: LinearProgressIndicator(
                value: total <= 0 ? 0 : value / total,
                backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.secondary),
              ),),
        ],
      ),
    );
  }

  _onSelectParticipant(BuildContext context, WidgetRef ref, StudyMonitorItem item, Study study) {
    // TODO: refactor to use [RoutingIntent] for sidesheet (so that it can be triggered from controller)
    showModalSideSheet(
      context: context,
      title: tr.participant_details_title,
      body: ParticipantDetailsView(
          monitorItem: item, interventions: study.interventions, observations: study.observations,),
      actionButtons: [
        retainSizeInAppBar(DismissButton(
          text: tr.dialog_close,
          onPressed: () => Navigator.maybePop(context),
        ),),
      ],
    );
  }
}
