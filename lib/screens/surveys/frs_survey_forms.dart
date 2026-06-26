import '../../models/data_models.dart';

class FrsSurveyForms {
  static SurveyModule? moduleFor(String surveyCode) {
    switch (surveyCode) {
      case 'recce':
      case 'borehole_recce':
        return _recceModule();
      case 'baseline':
      case 'baseline_survey':
        return _baselineModule();
      case 'rehabilitation':
        return _rehabilitationModule();
      case 'monitoring':
      case 'monitoring_survey':
        return _monitoringModule();
      case 'lsc':
      case 'lsc_survey':
        return _lscModule();
      case 'grievance':
        return _grievanceModule();
      case 'water_testing':
        return _waterTestingModule();
      default:
        return null;
    }
  }

  static SurveyModule _recceModule() => _module(
        slug: 'borehole_recce',
        name: 'Borehole Recce',
        description: 'FRS 11.8 borehole recce survey',
        sections: [
          _section('Identification Form', 0, [
            _field('country', '1. Country', 'dropdown', required: true, options: {'South Africa': 0}),
            _field('province', '2. Province', 'dropdown', required: true, options: {'Limpopo': 0, 'Others': 0}),
            _field('district', 'District', 'dropdown', required: true),
            _field('village', '3. Village', 'dropdown', required: true),
            _field('gps_location', '4. GPS Location', 'gps', required: true),
            _field('ownership_of_borehole', '5. Ownership of Borehole', 'radio', required: true, options: {'Municipality': 2, 'Community Representative': 3, 'Private': 0, 'Unknown': 0}),
            _field('type_of_borehole', '6. Type of Borehole', 'radio', required: true, options: {'Electric': 0, 'Solar': 1, 'Manual - Afridev': 3, 'Manual - T7 Mono': 3, 'Manual - India Mark II': 3, 'Fossil Fuel': 0, 'Wind': 1}),
            _field('year_of_installation', '7. Year of Installation', 'number', required: true),
            _field('borehole_image_front', '8. Upload Borehole Image (Front)', 'image', required: true),
            _field('borehole_image_back', '9. Upload Borehole Image (Back)', 'image', required: true),
            _field('borehole_video', '10. Upload Borehole Video', 'video'),
          ]),
          _section('Status Form', 1, [
            _field('is_functional', '10. Is borehole functional?', 'radio', required: true, options: {'Yes': 0, 'Partially Functional': 1, 'No': 2}),
            _field('non_functional_since', '11. If non-functional, since when?', 'radio', options: {'<3 months': 0, '>3 months': 1, '>6 months': 2, '>1 year': 3, '>3 years': 4}),
            _field('last_maintenance_done', '12. Last Maintenance Done', 'radio', required: true, options: {'<6 months': 0, '6-12 months': 1, '>1 year': 2, 'Never': 3}),
            _field('breakdown_reason', '13. Primary reason for breakdown', 'radio', required: true, options: {'Mechanical Failure': 1, 'Corrosion': 2, 'Installation Issue': 2, 'Water Quality': 1, 'Poor Management': 2, 'Others': 1}),
            _field('maintenance_planned', '14. Is maintenance planned?', 'yes_no', required: true, options: {'Yes': 0, 'No': 1}),
            _field('nearby_borehole_1km_status', '15. Any borehole within 1 km?', 'radio', required: true, options: {'Yes': 0, 'No': 1, 'Not Known': 0}),
            _field('depth_of_borehole', '16. Depth of Borehole (if known)', 'number'),
            _field('platform_condition', '17. Platform Condition', 'radio', required: true, options: {'Good': 0, 'Damaged': 0, 'Not Available': 0}),
            _field('water_flow_rate', '18. Water Flow Rate', 'radio', required: true, options: {'Strong': 0, 'Moderate': 0, 'Low': 1, 'Dry': 2}),
            _field('manual_handpump', '19. Is the Borehole a Manual Handpump?', 'yes_no', required: true),
            _field('manual_handpump_type', '19a. If Yes - Select Type', 'dropdown', options: {'T7 Mono Handpump': 0, 'Afridev': 0}),
          ]),
          _section('T7 Mono Handpump Assessment', 2, [
            _field('t7_pump_head_present', 'T7-1. Is the Mono T-7 pump head/drive head physically present and properly fixed?', 'radio', options: {'Yes': 0, 'No': 0, 'Damaged': 0}),
            _field('t7_mechanism_smooth', 'T7-2. When handle is operated, does pump mechanism move smoothly?', 'radio', options: {'Smooth': 0, 'Hard': 0, 'Jammed': 0, 'Loose': 0}),
            _field('t7_water_outlet', 'T7-3. Does water come out from the outlet after operating for a reasonable time?', 'radio', options: {'Yes': 0, 'No': 0, 'Low flow': 0}),
            _field('t7_abnormal_sound', 'T7-4. Is there any abnormal sound, vibration, or grinding during operation?', 'yes_no'),
            _field('t7_visible_leakage', 'T7-5. Is there any visible leakage from pump head, outlet, joints, or rising main?', 'yes_no'),
            _field('t7_repairability', 'T7-6. Does the pump appear repairable or require full replacement?', 'radio', options: {'Minor repair': 0, 'Major repair': 0, 'Full replacement': 0, 'Further inspection required': 0}),
          ]),
          _section('Afridev Handpump Assessment', 3, [
            _field('afridev_assembly_present', 'A-1. Is the Afridev pump handle, stand, spout, and head assembly present and fixed?', 'radio', options: {'Yes': 0, 'No': 0, 'Damaged': 0}),
            _field('afridev_handle_movement', 'A-2. Does the handle move freely, or is it loose/tight/jammed?', 'radio', options: {'Free movement': 0, 'Loose': 0, 'Tight': 0, 'Jammed': 0}),
            _field('afridev_water_discharge', 'A-3. When handle is operated, does water discharge from the spout?', 'radio', options: {'Yes': 0, 'No': 0, 'Low flow': 0}),
            _field('afridev_excessive_strokes', 'A-4. Does the pump require excessive strokes before water comes?', 'radio', options: {'Normal strokes': 0, 'Excessive strokes': 0, 'No water': 0}),
            _field('afridev_visible_leakage', 'A-5. Is there any visible leakage around pump head, spout, platform, or rising main?', 'yes_no'),
            _field('afridev_repairability', 'A-6. Does the issue appear repairable or does full pump need replacement?', 'radio', options: {'Minor repair': 0, 'Major repair': 0, 'Full replacement': 0, 'Further inspection required': 0}),
          ]),
          _section('Water Access & Usage Form', 4, [
            _field('main_drinking_source', '19. Is the borehole main drinking water source in area?', 'yes_no', required: true, options: {'Yes': 2, 'No': 0}),
            _field('households_served', '20. Households served from the borehole', 'radio', required: true, options: {'<50': 0, '50-100': 1, '100-150': 2, '150-200': 3, '200-500': 4, '>500': 5}),
            _field('nearby_alternative_sources', '21. Nearby alternative water sources', 'checkbox', options: {'River': 3, 'Stream': 2, 'Canal': 3, 'Pond': 2, 'Lake': 3, 'Open Well': 2, 'Hand-dug Well': 3, 'Spring': 2, 'Reservoir': 2, 'Rainwater': 0, 'Tanker': 0, 'Community Point': 0, 'Piped Water': 1, 'Other': 0}),
            _field('water_clear', '22. Is water from borehole clear (no visible particles)?', 'yes_no'),
            _field('water_colour_issue', '22a. Is there any yellow, brown, green, or cloudy colour in the water?', 'yes_no'),
            _field('smell_or_taste', '23. Any smell or unusual taste from borehole water?', 'yes_no'),
            _field('visible_particles', '23a. Are there visible particles, mud, sand, or floating materials in the water?', 'yes_no'),
            _field('water_testing_done_before', '24. Water Quality Testing done before?', 'yes_no'),
            _field('known_quality_issues', '25. Any known water quality issues (fluoride, salinity etc.)?', 'radio', options: {'Yes': 0, 'No': 0, 'Unknown': 0}),
            _field('known_quality_issues_details', '25a. If Yes, please specify', 'text'),
            _field('contamination_risk', '26. Is there any risk of contamination nearby borehole?', 'yes_no'),
            _field('boil_drinking_water', '27. Do people in the area boil water for drinking?', 'yes_no', options: {'Yes': 2, 'No': 1}),
          ]),
          _section('Additional Observations Form', 5, [
            _field('nearby_borehole_1km_observation', '27. Any nearby borehole within 1 km?', 'radio', options: {'Yes': 0, 'No': 0, 'Unknown': 0}),
            _field('suitable_for_rehabilitation', '28. Is the borehole suitable for rehabilitation?', 'radio', required: true, options: {'Yes': 0, 'No': 0, 'Needs technical inspection': 0}),
            _field('site_feasibility_priority', '29. Overall site feasibility (Need of repair) Priority', 'radio', required: true, options: {'High': 0, 'Medium': 0, 'Low': 0}),
            _field('repair_required', '30. Repair required', 'radio', required: true, options: {'Minor repair': 0, 'Major repair': 0, 'Full pump replacement': 0, 'New Drill': 0}),
            _field('surveyor_remarks', '31. Surveyor Remarks', 'textarea'),
          ]),
        ],
      );

  static SurveyModule _baselineModule() => _module(
        slug: 'baseline_survey',
        name: 'Baseline Survey',
        description: 'FRS 11.9 household and community representative survey',
        sections: [
          _section('Household - Basic Details', 0, [
            _field('survey_date', '32. Date of Survey', 'date', required: true),
            _field('respondent_name', '33. Respondent Name', 'text', required: true),
            _field('gender', '34. Gender', 'radio', required: true, options: {'Male': 0, 'Female': 0}),
            _field('contact_number', '35. Contact Number', 'number'),
            _field('survey_method', '36. Survey Method', 'radio', options: {'Face-to-Face': 0, 'Remote': 0, 'Telephonic': 0}),
            _field('community_type', '37. Type of Community', 'radio', options: {'Rural': 2, 'Urban': 0, 'Semi-Urban': 1}),
            _field('household_members', '38. No. of Household Members', 'number'),
          ]),
          _section('Household - Water Source', 1, [
            _field('primary_drinking_source', '39. Primary drinking water source for household?', 'checkbox', required: true, options: {'River': 2, 'Rainwater': 2, 'Spring - Protected': 0, 'Spring - Unprotected': 1, 'Surface Water': 2, 'Lake/Pond': 2, 'Borehole': 2, 'Tap Water': 1, 'Well': 0, 'Other': 0}),
            _field('borehole_non_functional_months', '40. Since how many months is the borehole non-functional?', 'number'),
          ]),
          _section('Household - Water Usage', 2, [
            _field('fetch_time_hours', '41. Time taken to fetch water (hrs/day)', 'number'),
            _field('distance_to_source_km', '42. Distance to water source (kms)', 'number'),
            _field('who_fetches_water', '43. Who fetches water mostly in family?', 'checkbox', options: {'Male': 0, 'Female': 2, 'Children': 1}),
            _field('fetching_frequency', '44. Frequency of fetching water', 'number'),
            _field('water_consumption_litres_day', '45. Water consumption (litres/day)', 'number'),
          ]),
          _section('Household - Boiling Water Behaviour', 3, [
            _field('boil_water', '46. Do you boil water for drinking?', 'yes_no', options: {'Yes': 1, 'No': 0}),
            _field('stove_type_boiling', '47. Type of Stove/Device used for boiling', 'radio', options: {'Three-stone': 2, 'Improved Cookstove': 1, 'Electric': 0, 'Other': 0}),
            _field('time_spent_boiling', '48. Time spent boiling water (mins/day)', 'number'),
            _field('water_boiled_quantity', '49. Water boiled (litres/day)', 'number'),
            _field('fuel_type_boiling', '50. Fuel type used in stove', 'radio', options: {'Wood': 3, 'Charcoal': 2, 'Pellets': 2, 'Briquettes': 2, 'LPG': 0, 'Electricity': 0, 'Other': 0}),
            _field('fuel_quantity_daily', '51. Fuel quantity/day', 'number'),
            _field('daily_fuel_cost', '52. Daily fuel cost', 'number'),
          ]),
          _section('Household - Health Impact', 4, [
            _field('illness_due_to_water', '53. Any illness due to water in family?', 'yes_no', options: {'Yes': 1, 'No': 0}),
            _field('who_affected', '54. Who mostly gets affected?', 'checkbox', options: {'Male': 0, 'Female': 0, 'Children': 0}),
            _field('common_illnesses', '55. Common illnesses?', 'checkbox', options: {'Diarrhoea': 2, 'Stomach Infection': 2, 'Skin Infection': 0, 'Vomiting': 1, 'Fever': 0}),
            _field('boiling_issues', '56. Issues faced due to boiling', 'checkbox', options: {'Smoke': 0, 'Breathing': 0, 'Eye irritation': 0, 'Other': 0}),
            _field('extra_medical_expenses', '57. Any extra medical expenses due to illness?', 'yes_no', options: {'Yes': 1, 'No': 0}),
            _field('stove_image', '58. Upload stove image', 'image'),
            _field('beneficiary_photo', '59. Upload photo of Beneficiary', 'image'),
            _field('consent_declaration', '60. Consent declaration + Tick Box', 'checkbox', required: true, options: {'confirmed': 0}),
            _field('beneficiary_name', '60a. Name of Beneficiary', 'text', required: true),
            _field('beneficiary_signature', '60b. Signature of Beneficiary', 'signature', required: true),
          ]),
          _section('Community Representative Survey', 5, [
            _field('community_rep_name', '59. Name', 'text', required: true),
            _field('community_rep_role', '60. Role', 'radio', options: {'Representative': 0, 'Leader': 0, 'Caretaker': 0}),
            _field('community_borehole_functional', '61. Is the Borehole functional?', 'radio', options: {'Yes': 0, 'No': 2, 'Partially': 1}),
            _field('community_breakdown_reason', '62. Reason for breakdown of Borehole', 'text'),
            _field('community_used_for_drinking', '63. Is the borehole used for drinking?', 'yes_no', options: {'Yes': 1, 'No': 0}),
            _field('community_total_households', '64. Total Households using borehole?', 'number'),
            _field('community_water_collection_responsible', '65. Who is mainly responsible for water collection?', 'radio', options: {'Women': 2, 'Children': 1, 'All': 1}),
            _field('community_alternative_source', '66. Any alternative water source nearby?', 'text'),
            _field('community_boil_water', '67. Do people boil water before consuming?', 'yes_no', options: {'Yes': 1, 'No': 0}),
            _field('community_fuel_type', '68. Commonly used fuel for boiling water?', 'radio', options: {'Firewood': 2, 'Charcoal': 1, 'Other': 0}),
            _field('community_unsafe_water_illness', '69. Is illness from unsafe water common in area?', 'yes_no', options: {'Yes': 1, 'No': 0}),
            _field('community_collection_time', '70. Total time to collect water daily? (mins)', 'number'),
            _field('community_water_committee', '71. Any water committee for maintenance?', 'yes_no', options: {'Yes': 0, 'No': 1}),
            _field('community_maintenance_fee', '72. Any maintenance fee collected?', 'yes_no', options: {'Yes': 0, 'No': 1}),
            _field('community_agree_rehab', '73. Do you agree for rehabilitation of borehole?', 'yes_no'),
            _field('community_carbon_consent', '74. Can you give consent for carbon project?', 'yes_no', options: {'Yes': 1, 'No': 0}),
            _field('community_agreement_signature', '75. Agreement Page signature', 'signature'),
          ]),
        ],
      );
  static SurveyModule _rehabilitationModule() => _module(
        slug: 'rehabilitation',
        name: 'Rehabilitation Report',
        description: 'FRS 11.10 rehabilitation survey',
        sections: [
          _section('Borehole Details', 0, [
            _field('borehole_id', '1. Borehole ID', 'dropdown', required: true),
            _field('village_gps_location', '2. Village & GPS Location', 'gps', required: true),
            _field('rehabilitation_date', '3. Date of Rehabilitation', 'date', required: true),
            _field('agency_name', '4. Contractor / Agency Name', 'text'),
            _field('technician_name', '5. Technician Name', 'text'),
            _field('technician_contact', '6. Technician Contact Number', 'number'),
          ]),
          _section('Pre-Rehabilitation Assessment', 1, [
            _field('pre_rehab_status', '7. Borehole status before rehab', 'checkbox', required: true, options: {'Non-functional': 2, 'Partially Functional': 1}),
            _field('non_functional_duration', '8. Duration of non-functionality', 'radio', options: {'<3 months': 0, '3-6 months': 1, '6-12 months': 2, '>1 year': 3, '>3 years': 4}),
            _field('technical_faults', '9. Technical faults identified', 'checkbox', options: {'Pump damage': 2, 'Seals worn': 2, 'Pipes broken': 2, 'Rods damaged': 2, 'Pump head failure': 2, 'Apron damage': 2, 'Drainage issue': 2, 'Other': 0}),
            _field('pre_flow_test', '10. Pre-rehabilitation flow rate test conducted?', 'yes_no', options: {'Yes': 1, 'No': 0}),
            _field('pre_flow_rate', '11. Flow rate before rehab', 'number'),
            _field('pre_flow_method', '12. Method used for flow rate testing', 'radio', options: {'Bucket method': 2, 'Flow meter': 1, 'Other': 0}),
            _field('pre_discharge_condition', '13. Water discharge condition before rehab', 'radio', options: {'No flow': 2, 'Very low': 1, 'Moderate': 1}),
            _field('before_rehab_photos', '14. Upload Before Rehabilitation Photos', 'image', required: true),
          ]),
          _section('Rehabilitation Activities', 2, [
            _field('mechanical_parts', '15. Mechanical parts repaired/replaced', 'checkbox', options: {'Pump head': 1, 'Cylinder': 1, 'Piston': 1, 'Seals': 1, 'Pipes': 1, 'Rods': 1, 'Bearings': 1, 'Handle': 1, 'Other': 0}),
            _field('civil_works', '16. Civil works completed', 'checkbox', options: {'Apron repair': 0, 'Drainage': 0, 'Soak pit': 0, 'Platform sealing': 0}),
            _field('new_components_installed', '17. Any new components installed', 'yes_no', options: {'Yes': 1, 'No': 2}),
            _field('new_components_details', '18. If yes, specify', 'text'),
            _field('rehab_duration', '19. Duration of rehabilitation work', 'number'),
            _field('during_rehab_photos', '20. Upload During Rehabilitation Photos', 'image'),
          ]),
          _section('Chlorine Dispenser Installation', 3, [
            _field('cd_installed', 'CD-1. Is a chlorine dispenser installed on the Afridev pump?', 'checkbox', options: {'Yes': 0, 'No': 0}),
            _field('cd_functional', 'CD-2. Is the chlorine dispenser functional at time of installation?', 'checkbox', options: {'Fully Functional': 0, 'Partially Functional': 0, 'Not Functional': 0}),
            _field('cd_loaded', 'CD-3. Was chlorine loaded into the dispenser during installation?', 'checkbox', options: {'Yes': 0, 'No': 0}),
            _field('cd_community_informed', 'CD-4. Has the community been informed about the purpose of chlorination?', 'checkbox', options: {'Yes': 0, 'No': 0}),
            _field('cd_users_trained', 'CD-5. Were users trained on safe use of chlorinated water?', 'checkbox', options: {'Yes': 0, 'No': 0}),
            _field('cd_water_smell', 'CD-6. Does the water have any noticeable smell immediately after installation?', 'checkbox', options: {'No Smell': 0, 'Slight Chlorine Smell': 0, 'Strong Chlorine Smell': 0}),
          ]),
          _section('Post-Rehabilitation Testing', 4, [
            _field('post_flow_test', '21. Pumping/Flow rate test conducted after rehab?', 'yes_no', options: {'Yes': 1, 'No': 0}),
            _field('post_flow_rate', '22. Flow rate after rehabilitation', 'number'),
            _field('post_test_method', '23. Method used for testing', 'radio', options: {'Bucket': 2, 'Flow meter': 1, 'Other': 0}),
            _field('pumping_test_duration', '24. Pumping test duration', 'number'),
            _field('water_discharge_status', '25. Water discharge status', 'radio', options: {'Good': 2, 'Moderate': 1, 'Low': 0}),
            _field('leakage_after_repair', '26. Any leakage after repair?', 'yes_no', options: {'Yes': 0, 'No': 1}),
            _field('borehole_functionality', '27. Borehole functionality', 'radio', options: {'Fully Functional': 1, 'Partially Functional': 0}),
            _field('pump_operates_smoothly', '28. Pump operates smoothly without noise', 'yes_no', options: {'Yes': 1, 'No': 0}),
            _field('after_rehab_photos', '29. Upload After Rehabilitation Photos', 'image'),
          ]),
          _section('FRS Missing Fields 30-34', 5, [
            _field('frs_missing_30_34_note', 'Sr. Nos 30-34 are undefined in the FRS source document', 'textarea'),
          ]),
          _section('Community Handover & Training', 6, [
            _field('handover_completed', '35. Borehole handed over to community?', 'yes_no', options: {'Yes': 1, 'No': 0}),
            _field('community_representative_name', '36. Name of community representative', 'text'),
            _field('training_provided', '37. Training provided', 'yes_no'),
            _field('training_type', '38. Type of training', 'checkbox', options: {'Operation': 0, 'Maintenance': 0, 'Hygiene': 0}),
            _field('water_committee_exists', '39. Water committee exists in the area', 'yes_no'),
          ]),
          _section('Documentation & Carbon Compliance', 7, [
            _field('completion_date', '40. Date of completion', 'date'),
            _field('contractor_signature', '41. Contractor signature', 'signature'),
            _field('community_rep_signature', '42. Community representative signature', 'signature'),
            _field('carbon_transfer_agreement', '43. Upload Carbon Transfer Agreement', 'file'),
            _field('frs_missing_44_note', '44. Undefined field in FRS source document', 'textarea'),
            _field('gps_tagged_photos', '45. GPS-tagged photos uploaded', 'image'),
            _field('additional_remarks', '46. Any additional remarks', 'textarea'),
          ]),
        ],
      );

  static SurveyModule _monitoringModule() => _module(
        slug: 'monitoring_survey',
        name: 'Monitoring Survey',
        description: 'FRS 11.12 monitoring survey',
        sections: [
          _section('Basic Information', 0, [
            _field('borehole_id', '1. Borehole ID', 'dropdown', required: true),
            _field('survey_date', '2. Date of Survey', 'date', required: true),
            _field('surveyor_name', '3. Name of Surveyor', 'text'),
            _field('rehab_date', '4. Date of Borehole Rehabilitation', 'date'),
            _field('community_rep_name', '5. Name of Community Representative', 'text'),
            _field('contact_number', '6. Contact Number', 'number'),
            _field('gender', '7. Gender', 'radio', options: {'Male': 0, 'Female': 0}),
            _field('address', '8. Address', 'text'),
          ]),
          _section('Borehole Status & Functionality', 1, [
            _field('rehab_operational', '9. Is the rehabilitated borehole operational?', 'yes_no', options: {'Yes': 1, 'No': 0}),
            _field('parts_fixed', '10. Which parts were fixed during rehabilitation?', 'textarea'),
            _field('current_drinking_source', '11. Current source of drinking water', 'radio', options: {'Borehole': 1, 'Nearby River': 0}),
            _field('distance_from_household', '12. Distance of borehole from household', 'number'),
            _field('water_availability_per_day', '13. Water availability per day', 'radio', options: {'<4 hrs': 0, '4-6 hrs': 1, '6-8 hrs': 2, '>8 hrs': 3}),
            _field('fetch_time_daily', '14. Time taken to fetch water daily', 'number'),
            _field('water_quantity_daily', '15. Quantity of water fetched daily', 'number'),
          ]),
          _section('Water Access Improvement', 2, [
            _field('water_per_person_day', '16. Water available per person per day', 'radio', options: {'<5 L': 1, '5-10 L': 2, '10-20 L': 3, '>20 L': 4}),
            _field('fetching_frequency', '17. Frequency of fetching water', 'radio', options: {'Daily': 4, 'Alternate days': 3, 'Twice a week': 2, 'Weekly': 1}),
            _field('consistent_access', '18. Consistent access to borehole', 'yes_no', options: {'Yes': 1, 'No': 0}),
          ]),
          _section('Chlorine Dispenser Survey', 3, [
            _field('mcd_present', 'MCD-1. Is the chlorine dispenser present on the pump?', 'checkbox', options: {'Yes': 0, 'No': 0}),
            _field('mcd_working', 'MCD-2. Is the chlorine dispenser working properly?', 'checkbox', options: {'Yes': 0, 'No': 0, 'Needs Repair': 0}),
            _field('mcd_chlorine_available', 'MCD-3. Is chlorine available in the dispenser?', 'checkbox', options: {'Full': 0, 'Partially Available': 0, 'Empty': 0}),
            _field('mcd_refilled', "MCD-4. Has chlorine been refilled since the last visit?", 'checkbox', options: {'Yes': 0, 'No': 0, "Don't Know": 0}),
            _field('mcd_photo_taken', 'MCD-P. Photo of Chlorine Dispenser Taken?', 'checkbox', options: {'Yes': 0, 'No': 0}),
            _field('mcd_users_taste_smell', 'MCD-5. Do users report a chlorine taste or smell in the water?', 'checkbox', options: {'Yes': 0, 'No': 0}),
            _field('mcd_taste_acceptability', 'MCD-6. Is the chlorine taste/smell acceptable to users?', 'checkbox', options: {'Acceptable': 0, 'Too Strong': 0, 'Too Weak': 0, 'No Opinion': 0}),
            _field('mcd_complaints', 'MCD-7. Have any users complained about water quality since last visit?', 'checkbox', options: {'No Complaints': 0, 'Taste': 0, 'Smell': 0, 'Colour': 0, 'Other': 0}),
            _field('mcd_households_continue', 'MCD-8. Do households continue to collect drinking water from this borehole?', 'checkbox', options: {'Yes, Regularly': 0, 'Occasionally': 0, 'No': 0}),
            _field('mcd_water_safer', 'MCD-9. Compared to before rehabilitation, do users believe water is safer?', 'checkbox', options: {'Yes': 0, 'No': 0, "Don't Know": 0}),
            _field('mcd_committee_checked', 'MCD-10. Has the community water committee/operator checked the chlorine dispenser?', 'checkbox', options: {'Yes': 0, 'No': 0}),
          ]),
          _section('Fuel Use & Cost Impact', 4, [
            _field('fuel_expenses_reduced', '19. Reduction in fuel expenses', 'yes_no', options: {'Yes': 1, 'No': 0}),
            _field('cookstove_still_used', '20. Is cookstove still used to boil water?', 'yes_no', options: {'Yes': 0, 'No': 1}),
            _field('previous_fuel_used', '21. Previous fuel used for boiling', 'radio', options: {'Firewood': 2, 'Charcoal': 1, 'Other': 0}),
            _field('traditional_fuel_dependency_reduced', '22. Has dependency on traditional fuel reduced?', 'yes_no', options: {'Yes': 1, 'No': 0}),
            _field('frs_missing_23_24_note', 'Sr. Nos 23-24 are undefined in the FRS source document', 'textarea'),
          ]),
          _section('Health & Social Impact', 5, [
            _field('health_improvement', '25. Improvement in health after using borehole', 'yes_no', options: {'Yes': 1, 'No': 0}),
            _field('training_received', '26. Any training received on borehole use/maintenance', 'yes_no', options: {'Yes': 1, 'No': 0}),
            _field('maintenance_frequency', '27. Frequency of borehole maintenance', 'radio', options: {'Every 3 months': 0, 'Every 6 months': 1, 'Annually': 2}),
            _field('rehabilitated_borehole_image', '28. Upload rehabilitated borehole image', 'image'),
          ]),
        ],
      );
  static SurveyModule _lscModule() => _module(
        slug: 'lsc_survey',
        name: 'LSC / Stakeholder Consultation',
        description: 'FRS 11.13 LSC stakeholder consultation',
        sections: [
          _section('Basic Details', 0, [
            _field('meeting_date', '75. Date of meeting', 'date', required: true),
            _field('venue_location', '76. Venue/Location', 'text', required: true),
            _field('organizer_details', '77. Organizer details', 'text', required: true),
            _field('purpose_explained', '63. Purpose explained in the meeting?', 'yes_no'),
            _field('total_attendees', '64. Total attendees in Meeting?', 'number'),
            _field('attendance_sheet_signed', '65. Attendance sheet filled & signed properly?', 'yes_no'),
            _field('attendance_photos', '66. Upload photos of attendance sheet & attendees (5-6 photos)', 'image'),
            _field('minutes_of_meeting', '66a. Put Minutes of Meeting of LSC', 'textarea'),
            _field('fpic_photos', '67. Upload photos of FPIC forms', 'image'),
          ]),
          _section('Feedback from Community', 1, [
            _field('project_explained_clearly', '68. Did the project get explained clearly?', 'yes_no'),
            _field('questions_allowed', '69. Did you have the opportunity to ask questions?', 'yes_no'),
            _field('expect_improved_access', '70. Are you expecting improved water access after rehabilitation?', 'yes_no'),
            _field('concerns_suggestions', '71. Any concerns or suggestions from the project?', 'textarea'),
            _field('women_participation', '72. Did we have women participation in meeting?', 'yes_no'),
            _field('support_project', '73. Do you support the Borehole Rehabilitation project?', 'yes_no'),
          ]),
          _section('Additional LSC Fields', 2, [
            _field('lsc_category', 'LSC-A. LSC Category', 'dropdown', required: true, options: {'Chief': 0, 'Councilor': 0, 'Community': 0, 'King': 0, 'Municipality': 0, 'Others': 0}),
            _field('agenda', 'LSC-B. Agenda', 'dropdown', required: true),
            _field('lsc_photos', 'LSC-C. LSC Photos', 'image'),
            _field('lsc_video', 'LSC-D. LSC Video', 'video'),
            _field('attendance_register', 'LSC-E. Attendance Register', 'file'),
            _field('signed_documents', 'LSC-F. Signed Documents', 'file'),
          ]),
        ],
      );

  static SurveyModule _grievanceModule() => _module(
        slug: 'grievance',
        name: 'Grievance Report',
        description: 'FRS 11.14.4 create grievance form',
        sections: [
          _section('Borehole Details', 0, [
            _field('village_area', '1. Village / Area', 'dropdown', required: true),
            _field('borehole_reference', '2. Borehole ID / Serial Number', 'dropdown', required: true),
            _field('gps_location', '3. GPS Location', 'gps', required: true),
          ]),
          _section('Issue Details', 1, [
            _field('category', '4. What is the issue?', 'checkbox', required: true, options: {'Not working': 0, 'Low water': 0, 'Water quality': 0, 'Access problem': 0, 'Health & safety': 0, 'Social': 0, 'Other': 0}),
            _field('description', '5. Describe the problem', 'textarea', required: true),
            _field('issue_since', '6. Since when is the issue?', 'dropdown', required: true, options: {'Today': 0, 'Few days': 0, 'Long time': 0}),
            _field('issue_photo', '7. Upload photo (if any)', 'image'),
            _field('expected_action', '8. What do you expect?', 'dropdown', required: true, options: {'Repair': 0, 'Inspection': 0, 'Improve access': 0, 'Other': 0}),
          ]),
          _section('User Details & Declaration', 2, [
            _field('reporter_name', '9. Name', 'text', required: true),
            _field('phone_number', '10. Phone Number', 'number', required: true),
            _field('declaration', '11. I confirm the information is correct', 'checkbox', required: true, options: {'Yes': 0}),
            _field('signature', '12. Signature', 'signature', required: true),
          ]),
        ],
      );

  static SurveyModule _waterTestingModule() => _module(
        slug: 'water_testing',
        name: 'Water Testing',
        description: 'FRS 11.15.3 water testing form',
        sections: [
          _section('Basic Information', 0, [
            _field('borehole_id', '1. Borehole ID', 'text', required: true),
            _field('test_date', '2. Test Date', 'date', required: true),
            _field('sample_collection_date', '3. Sample Collection Date', 'date', required: true),
            _field('collected_by', '4. Collected By', 'text', required: true),
          ]),
          _section('Sample Details', 1, [
            _field('sample_description', '5. Sample Description', 'textarea'),
            _field('water_appearance', '6. Water Appearance', 'dropdown', options: {'Clear': 0, 'Cloudy': 0, 'Yellow-Brown': 0, 'Green': 0, 'Coloured': 0, 'Other': 0}),
            _field('testing_remarks', '7. Testing Remarks', 'textarea'),
          ]),
          _section('Media Upload', 2, [
            _field('borehole_water_images', '8. Borehole Water Images', 'image', required: true),
            _field('nearby_water_source_images', '9. Nearby Water Source Images', 'image', required: true),
            _field('supporting_attachments', '10. Supporting Attachments', 'file'),
          ]),
        ],
      );

  static SurveyModule _module({required String slug, required String name, required String description, required List<SurveySection> sections}) {
    return SurveyModule(id: 'frs_$slug', slug: slug, name: name, description: description, isMultiStep: sections.length > 1, sections: sections);
  }

  static SurveySection _section(String title, int orderIndex, List<SurveyField> fields) {
    return SurveySection(id: 'frs_section_$orderIndex_${title.toLowerCase().replaceAll(' ', '_')}', title: title, orderIndex: orderIndex, fields: fields);
  }

  static SurveyField _field(String key, String label, String type, {bool required = false, Map<String, num> options = const {}}) {
    return SurveyField(
      id: 'frs_field_$key',
      fieldKey: key,
      label: label,
      fieldType: type,
      isRequired: required,
      hasScoring: options.values.any((score) => score != 0),
      orderIndex: 0,
      options: options.entries.map((entry) => FieldOption(id: entry.key, label: entry.key, value: entry.key, score: entry.value.toDouble())).toList(),
      validations: const [],
      conditions: const [],
    );
  }
}
