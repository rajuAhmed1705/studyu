import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:studyu_app/screens/study/onboarding/eligibility_screen.dart';
import 'package:studyu_app/screens/study/tasks/task_screen.dart';
import 'package:studyu_core/core.dart';
import 'package:studyu_flutter_common/studyu_flutter_common.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_state.dart';
import '../../routes.dart';
import '../../util/notifications.dart';
import 'preview.dart';

class LoadingScreen extends StatefulWidget {
  final String sessionString;
  final Map<String, String> queryParameters;

  const LoadingScreen({Key key, this.sessionString, this.queryParameters}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends SupabaseAuthState<LoadingScreen> {
  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    final hasRecovered = await recoverSupabaseSession();
    if (!hasRecovered) {
      await Supabase.instance.client.auth.recoverSession(widget.sessionString);
    }

    initStudy();
  }

  Future<void> initStudy() async {
    final model = context.read<AppState>();
    final preview = Preview(widget.queryParameters ?? {});
    // print("INIT STUDY");
    if (preview.containsQueryPair('mode', 'preview')) {
      // print("INIT PREVIEW");
      model.isPreview = true;
      await preview.init();

      // Authorize
      if (!await preview.handleAuthorization()) return;
      model.selectedStudy = preview.study;
      print("Got study: " + model.selectedStudy.toString());

      await preview.runCommands();
      print("init listener");

      html.window.onMessage.listen((event) {
        final message = event.data as String;
        final messageContent = jsonDecode(message) as Map<String, dynamic>;
        //if (messageContent['intervention'] != null) {
        //  print(messageContent['intervention']);
          model.selectedStudy = Study.fromJson(messageContent);
          print("App:" + messageContent.toString());
        //}
      });
      if (preview.hasRoute()) {
        print("has route: " + preview.selectedRoute);

        // ELIGIBILITY CHECK
        if (preview.selectedRoute == '/eligibilityCheck') {
          if (!mounted) return;
            // if we remove the await, we can push multiple times. warning: do not run in while(true)
            final result = await Navigator.push<EligibilityResult>(context, EligibilityScreen.routeFor(study: preview.study));
            // either do the same navigator push again or --> send a message back to designer and let it reload the whole page <--
            // todo refactor webcontent
            html.window.parent.postMessage("routeFinished", '*');
            return;
        }

        // INTERVENTION SELECTION
        if (preview.selectedRoute == Routes.interventionSelection) {
          if (!mounted) return;
          final interventionSelected = await Navigator.pushNamed(context, Routes.interventionSelection);
          html.window.parent.postMessage("routeFinished", '*');
          return;
        }

        model.activeSubject = await preview.createFakeSubject(preview.extra);

        // CONSENT
        if (preview.selectedRoute == Routes.consent) {
          if (!mounted) return;
          final consentGiven = await Navigator.pushNamed<bool>(context, Routes.consent);
          html.window.parent.postMessage("routeFinished", '*');
          return;
        }

        // DASHBOARD
        if (preview.selectedRoute == Routes.dashboard) {
          if (!mounted) return;
          await Navigator.pushReplacementNamed(context, Routes.dashboard);
          html.window.parent.postMessage("routeFinished", '*');
          return;
        }

        // OBSERVATION [i]
        if (preview.selectedRoute == '/observation') {
          print("getting tasks for observation");
          print(model.selectedStudy.observations.first.id);
          final tasks = <Task>[
            ...model.selectedStudy.observations.where((observation) => observation.id == preview.extra).toList(),
          ];
          print("observation with tasks: " + tasks.first.toString());
          if (!mounted) return;
          final result = await Navigator.push<TaskScreen>(context, TaskScreen.routeFor(task: tasks.first, taskId: preview.extra));
          print("FINISHED OBSERVATION");
          html.window.parent.postMessage("routeFinished", '*');
          return;
        }

        // INTERVENTION [i]
        if (preview.selectedRoute == '/intervention') {
          print("getting tasks for intervention");
          model.selectedStudy.schedule.includeBaseline = false;
          if (!mounted) return;
          await Navigator.pushReplacementNamed(context, Routes.dashboard);
          print("FINISHED INTERVENTION");
          html.window.parent.postMessage("routeFinished", '*');
          return;
        }
        //}
      } else {
        if (!mounted) return;
        if (isUserLoggedIn()) {
          print("Return to studyOverview");
          Navigator.pushReplacementNamed(context, Routes.studyOverview);
          return;
        }
        print("Return to welcome");
        Navigator.pushReplacementNamed(context, Routes.welcome);
        return;
      }
      // WE NEED TO HAVE RETURNED BY HERE
    }
    // todo is this necessary to run?
    if (!mounted) return;
    if (context.read<AppState>().isPreview) {
      previewSubjectIdKey();
    }

    final selectedStudyObjectId = await getActiveSubjectId();
    print('Selected study: $selectedStudyObjectId');
    if (!mounted) return;
    if (selectedStudyObjectId == null) {
      if (isUserLoggedIn()) {
        Navigator.pushReplacementNamed(context, Routes.studySelection);
        return;
      }
      Navigator.pushReplacementNamed(context, Routes.welcome);
      return;
    }
    StudySubject subject;
    try {
      subject = await SupabaseQuery.getById<StudySubject>(
        selectedStudyObjectId,
        selectedColumns: [
          '*',
          'study!study_subject_studyId_fkey(*)',
          'subject_progress(*)',
        ],
      );
    } catch (e) {
      // Try signing in again. Needed if JWT is expired
      await signInParticipant();
      subject = await SupabaseQuery.getById<StudySubject>(
        selectedStudyObjectId,
        selectedColumns: [
          '*',
          'study!study_subject_studyId_fkey(*)',
          'subject_progress(*)',
        ],
      );
    }
    if (!mounted) return;

    if (subject != null) {
      model.activeSubject = subject;
      if (!kIsWeb) {
        // Notifications not supported on web
        scheduleStudyNotifications(context);
      }
      Navigator.pushReplacementNamed(context, Routes.dashboard);
    } else {
      Navigator.pushReplacementNamed(context, Routes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${AppLocalizations
                    .of(context)
                    .loading}...',
                style: Theme
                    .of(context)
                    .textTheme
                    .headline4,
              ),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void onAuthenticated(Session session) {}

  @override
  void onErrorAuthenticating(String message) {}

  @override
  void onPasswordRecovery(Session session) {}

  @override
  void onUnauthenticated() {}
}
