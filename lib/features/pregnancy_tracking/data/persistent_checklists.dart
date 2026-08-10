class PersistentChecklistData {
  static const String categoryHospitalBagMom = 'hospital_bag_mom';
  static const String categoryHospitalBagBaby = 'hospital_bag_baby';
  static const String categoryHospitalBagPartner = 'hospital_bag_partner';
  static const String categoryBirthPlan = 'birth_plan';
  static const String categoryNursery = 'nursery_setup';

  static const Map<String, List<String>> checklists = {
    categoryHospitalBagMom: [
      'preg_item_comfort_clothes',
      'preg_item_slippers_socks',
      'preg_item_toiletries',
      'preg_item_nursing_gear',
      'preg_item_documents',
    ],
    categoryHospitalBagBaby: [
      'preg_item_baby_outfit',
      'preg_item_swaddle',
      'preg_item_diapers',
      'preg_item_car_seat',
    ],
    categoryHospitalBagPartner: [
      'preg_item_partner_clothes',
      'preg_item_snacks',
      'preg_item_charger',
    ],
    categoryBirthPlan: [
      'preg_item_pain_mgmt',
      'preg_item_birth_presence',
      'preg_item_cord_clamping',
      'preg_item_skin_to_skin',
    ],
    categoryNursery: [
      'preg_item_crib',
      'preg_item_changing_table',
      'preg_item_nursery_chair',
      'preg_item_baby_monitor',
      'preg_item_diaper_pail',
    ],
  };
}
