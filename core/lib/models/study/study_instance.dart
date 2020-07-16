import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:studyou_core/models/results/result.dart';

import '../../util/extensions.dart';
import '../interventions/intervention.dart';
import '../interventions/intervention_set.dart';
import '../observations/observation.dart';

class StudyInstance extends ParseObject implements ParseCloneable {
  static const _keyTableName = 'UserStudy';

  StudyInstance() : super(_keyTableName);

  StudyInstance.clone() : this();

  @override
  StudyInstance clone(Map<String, dynamic> map) => StudyInstance.clone()..fromJson(map);

  static const keyStudyId = 'study_id';
  String get studyId => get<String>(keyStudyId);
  set studyId(String studyId) => set<String>(keyStudyId, studyId);

  static const keyUserId = 'user_id';
  String get userId => get<String>(keyUserId);
  set userId(String userId) => set<String>(keyUserId, userId);

  static const keyTitle = 'title';
  String get title => get<String>(keyTitle);
  set title(String title) => set<String>(keyTitle, title);

  static const keyDescription = 'description';
  String get description => get<String>(keyDescription);
  set description(String description) => set<String>(keyDescription, description);

  static const keyIconName = 'icon_name';
  String get iconName => get<String>(keyIconName);
  set iconName(String iconName) => set<String>(keyIconName, iconName);

  static const keyStartDate = 'start_date';
  DateTime get startDate => get<DateTime>(keyStartDate);
  set startDate(DateTime startDate) => set<DateTime>(keyStartDate, startDate);

  static const keyPhaseDuration = 'phase_duration';
  int get phaseDuration => get<int>(keyPhaseDuration);
  set phaseDuration(int phaseDuration) => set<int>(keyPhaseDuration, phaseDuration);

  static const keyInterventionOrder = 'intervention_order_ids';
  List<String> get interventionOrder => get<List<dynamic>>(keyInterventionOrder).map<String>((e) => e).toList();
  set interventionOrder(List<String> interventionOrder) => set<List<String>>(keyInterventionOrder, interventionOrder);

  static const keyInterventionSet = 'intervention_set';
  InterventionSet get interventionSet => InterventionSet.fromJson(get<Map<String, dynamic>>(keyInterventionSet));
  set interventionSet(InterventionSet interventionSet) =>
      set<Map<String, dynamic>>(keyInterventionSet, interventionSet.toJson());

  static const keyObservations = 'observations';
  List<Observation> get observations =>
      get<List<dynamic>>(keyObservations)?.map((e) => Observation.fromJson(e))?.toList() ?? [];
  set observations(List<Observation> observations) =>
      set<List<dynamic>>(keyObservations, observations.map((e) => e.toJson()).toList());

  static const keyResults = 'results';

  Map<String, List<Result>> get results {
    final savedMap = get<Map<String, dynamic>>(keyResults) ?? <String, dynamic>{};
    final resultMap = <String, List<Result>>{};
    savedMap.forEach((key, value) {
      resultMap[key] = (value as List<dynamic>).map<Result>((resultData) => Result.fromJson(resultData)).toList();
    });
    return resultMap;
  }

  set results(Map<String, List<Result>> results) {
    final savedMap = <String, dynamic>{};
    results.forEach((key, value) => savedMap[key] = value.map<dynamic>((result) => result.toJson()).toList());
    set<Map<String, dynamic>>(keyResults, savedMap);
  }

  void addResults(List<Result> newResults) {
    if (newResults.isEmpty) {
      return;
    }
    final returnResults = results;
    newResults.forEach((result) {
      if (returnResults[result.taskId] != null) {
        returnResults[result.taskId].add(result);
      } else {
        returnResults[result.taskId] = [result];
      }
    });
    results = returnResults;
  }

  int getInterventionIndexForDate(DateTime date) {
    final test = date.differenceInDays(startDate).inDays;
    return test ~/ phaseDuration;
  }

  Intervention getInterventionForDate(DateTime date) {
    final index = getInterventionIndexForDate(date);
    if (index < 0 || index >= interventionOrder.length) {
      print('Study is over or has not begun.');
      return null;
    }
    final interventionId = interventionOrder[index];
    return interventionSet.interventions
        .firstWhere((intervention) => intervention.id == interventionId, orElse: () => null);
  }

  List<Intervention> getInterventionsInOrder() {
    return interventionOrder
        .map((key) => interventionSet.interventions.firstWhere((intervention) => intervention.id == key))
        .toList();
  }
}
