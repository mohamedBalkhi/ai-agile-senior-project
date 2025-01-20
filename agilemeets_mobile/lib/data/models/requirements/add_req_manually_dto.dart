import 'req_dto.dart';

class AddReqManuallyDTO {
  final String projectId;
  final List<ReqDTO> requirements;

  const AddReqManuallyDTO({
    required this.projectId,
    required this.requirements,
  });

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'requirements': requirements.map((e) => e.toJson()).toList(),
  };
} 