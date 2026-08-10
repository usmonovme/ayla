import '../models/checklist_item_model.dart';

abstract class ChecklistRepository {
  Future<List<ChecklistItem>> getChecklistItems(String pregnancyId);
  Future<void> updateChecklistItem(ChecklistItem item);
  Future<void> saveChecklistItems(List<ChecklistItem> items);
  Future<void> deleteChecklistItemsByPregnancy(String pregnancyId);
}
