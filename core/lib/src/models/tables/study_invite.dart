import 'package:json_annotation/json_annotation.dart';

import '../../../core.dart';
import '../../util/supabase_object.dart';

part 'study_invite.g.dart';

@JsonSerializable()
class StudyInvite extends SupabaseObjectFunctions<StudyInvite> {
  static const String tableName = 'study_invite';

  @override
  Map<String, dynamic> get primaryKeys => {'code': code};

  String code;
  String studyId;

  StudyInvite(this.code, this.studyId);

  factory StudyInvite.fromJson(Map<String, dynamic> json) => _$StudyInviteFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StudyInviteToJson(this);
}
