import 'package:restro/domain/entities/sop_entity.dart';

abstract class SOPRepositoryInterface{
  Future<List<SOPEntity>> getSOPs();
  Future<SOPEntity?> getSOPById(String id);
  Future<void> createSOP(SOPEntity sop);
  Future<void> updateSOP(SOPEntity sop);
  Future<void> deleteSOP(String id);
  Future<List<SOPEntity>> getSOPsByFrequency(String frequency);
}