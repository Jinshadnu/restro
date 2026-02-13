import 'package:flutter/material.dart';
import 'package:restro/utils/navigation/app_routes.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  static const _prefsKey = 'terms_accepted_sop_001_v1';
  bool _saving = false;
  bool _agreed = false;

  Future<void> _accept() async {
    if (_saving) return;
    setState(() {
      _saving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, true);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.splash);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppTheme.primaryColor,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).maybePop();
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white,
                  ),
                  const Expanded(
                    child: Text(
                      'Terms and conditions',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE6E9EF)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'This is a placeholder for terms and conditions of the app.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Terms',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _sopText,
                        style: TextStyle(
                          fontSize: 12.8,
                          height: 1.45,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'I agree with the terms and conditions',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.75),
                      ),
                    ),
                  ),
                  Checkbox(
                    value: _agreed,
                    onChanged: _saving
                        ? null
                        : (v) {
                            setState(() {
                              _agreed = v ?? false;
                            });
                          },
                    activeColor: const Color(0xFF2F80ED),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: (_saving || !_agreed) ? null : _accept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppTheme.primaryColor.withOpacity(0.35),
                    disabledForegroundColor: Colors.white.withOpacity(0.9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Next',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const String _sopText = '''Standard Operating Procedure (SOP-001)

Shawarma Master & Helper – Daily Operations Checklist

Document Reference: SOP-001
Version: 1.0
Effective Date: November 06, 2025
Prepared By: Shawarmax Operations Team
Approved By: [Manager's Name/Title]

Purpose: This SOP outlines the standardized daily operations, hygiene protocols, food preparation, packaging, delivery, and closing procedures for the Shawarma Master and Helper to ensure consistent quality, food safety, and customer satisfaction at Shawarmax outlets. All team members must adhere to these guidelines without exception.

Scope: Applicable to all Shawarma Masters and Helpers across Shawarmax locations.

Responsibilities:

• Shawarma Master: Lead execution of all tasks, oversee Helper, and report deviations to the Manager.
• Shawarma Helper: Assist in all tasks, ensure timely completion, and maintain documentation.

General Guidelines:

• All procedures must comply with local food safety regulations (e.g., FSSAI standards in India).
• Maintain a hazard-free environment; report any safety concerns immediately.
• Sign off on the Daily Log Sheet for all checklist items, including timestamps where applicable.
• Conduct all activities in clean, designated uniforms (aprons, caps, gloves) to uphold Shawarmax hygiene standards.

A. Pre-Opening Preparation (Before 3:00 PM)

Complete all tasks by 3:00 PM to ensure seamless operations. Verify and sign off on each item.

• Dish & Utensil Readiness: Ensure all dishes and utensils washed the previous day are re-washed (if necessary), sanitized using approved sanitizers, dried thoroughly, and stored in their designated ready-to-use positions to prevent cross-contamination.
• Machinery Cleaning: Thoroughly clean and sanitize all kitchen equipment, including the shawarma machine, slicers, cutting boards, knives, blenders, and other tools. Confirm all items are in optimal ready-to-operate condition through functional testing.
• Raw Material Thawing: Retrieve the marinated chicken from the freezer and initiate defrosting under controlled, hygienic conditions (maintain temperature below 5°C until use) to preserve quality and safety.
• Quality Inspection: Inspect the defrosted chicken for indicators of freshness, including odor, color, texture, and overall appearance. Immediately report any deviations or anomalies to the Manager for corrective action.
• Incoming Supply Check: Confirm receipt and quality of all ordered supplies, including rumali roti, kuboos, aldan kuboos, iceberg lettuce, vegetables, and other essentials. Notify the Manager without delay of any shortages, damages, or discrepancies.
• Shawarma Setup: Securely position the stand and insert the steel skewer. Load the marinated chicken with tight stacking to achieve even balance and uniform cooking.
• Cooking Setup: Insert the shawarma stand into the machine precisely by 3:00 PM. Test and verify the rotation mechanism and burner functionality prior to commencing operations.
• Post-Use Stand Cleaning: Upon completion of setup, immediately clean and sanitize the stand and surrounding preparation area to maintain hygiene.
• Oil Management: Assess the oil's condition for clarity and quality, then filter it prior to use. Clearly label filtered oil for reuse or disposal as per guidelines. Fill the designated waste oil bottle, position it accessibly for collection, and record the filtration time in the Daily Log Sheet.
• Packing Materials Preparation: Organize all packing materials—including wraps, tissues, boxes, and stickers—in a neat, accessible arrangement for efficient use during service.
• Sauce & Salad Preparation: Prepare ketchup, salad mixes, and shawarma fillings according to standardized recipes. Label containers with contents, preparation date, and expiration, then store under hygienic conditions (e.g., refrigerated at appropriate temperatures).
• Egg Pasteurization: Calibrate the temperature-checking machine to sustain water temperature between 60°C and 62°C. Pasteurize eggs as per protocol, clean all equipment thoroughly afterward, and return the thermometer to its designated storage location.
• Mayonnaise Quality Check: Evaluate the mayonnaise for quality, color, and aroma. Verify adherence to the approved SOP for mayonnaise preparation; discard and remake if standards are not met.
• System Readiness: Power on the KOT (Kitchen Order Ticket) printer, confirm network connectivity, and perform a test print to validate operational integrity.
• Wear Gloves, Caps, and Aprons at All Times During Food Handling: All kitchen and service staff must don disposable gloves, clean aprons, and hair-restraining caps during all phases of food preparation, packing, and service. Change gloves frequently (e.g., after handling raw items or at regular intervals), launder aprons as needed during the shift, and ensure full hair coverage to mitigate contamination risks and uphold Shawarmax hygiene standards.

Pre-Opening Sign-Off: Shawarma Master: ________________ Date/Time: __________ Helper: ________________ Date/Time: __________

B. Operational & Mid-Shift Tasks

Monitor and execute these tasks throughout the shift to sustain workflow and inventory levels.

• Stock Refill: Monitor levels of mayonnaise, pickles, and sauces; prepare fresh batches in accordance with the relevant SOP if stocks fall below threshold (e.g., 25% remaining).
• Evening Prep (7:30 PM): Retrieve the subsequent batch of chicken from the freezer and commence defrosting under safe temperature controls (below 5°C).
• Night Prep (10:30 PM): Wash, trim, and portion the chicken precisely to meet marination specifications.
• Masala Preparation: Compound fresh masala adhering to the approved recipe ratios; measure ingredients accurately using calibrated tools for consistency.
• Chicken Marination: Thoroughly combine the chicken with masala to achieve uniform coating and optimal flavor absorption; allow sufficient marination time as per SOP.
• Batch Labeling & Freezing: Securely wrap the marinated chicken, affix labels with preparation date and batch number, and transfer to the freezer for next-day utilization.

Food Preparation, Packaging & Delivery Standards

Adhere to these protocols to deliver high-quality, safe, and appealing products.

A. Food Making & Cooking Standards

• Follow Standard Recipe Procedures: Prepare every shawarma, alfaham, or BBQ item in strict accordance with Shawarmax’s approved recipe cards to ensure product consistency.
• Consistent Portioning: Employ calibrated weighing scales and portion scoops to standardize quantities and presentation across all menu items.
• Cooking Temperature & Time: Grill or roast shawarma meat at the prescribed temperatures and durations per SOP. Continuously monitor internal meat temperature, rotation speed, and flame intensity to guarantee even roasting and food safety.
• Taste & Presentation Check: Perform daily sensory evaluations (taste tests) of sauces and fillings prior to service commencement. Ensure each shawarma is wrapped neatly, presented attractively, and free from drips or overfilling.
• Avoid Cross-Contamination: Utilize color-coded, separate knives, cutting boards, and gloves for raw and cooked foods. Sanitize all surfaces and tools after each use.

B. Packaging Standards

• Packaging Neatness: Wrap every shawarma and food item securely to prevent leaks and grease stains, utilizing only approved Shawarmax-branded materials.
• Labeling: Affix clear labels to each order, specifying item name, spice level, and order channel (e.g., Zomato, Swiggy, or Dine-in).
• Temperature Maintenance: Package hot items promptly into insulated carriers. Segregate cold drinks and desserts to preserve their integrity.
• Final Check Before Dispatch: Cross-verify that all orders match the KOT, including items, sauces, and add-ons. Mark parcels as “Checked” prior to handover.
• Hygienic Handling: Wear fresh gloves during wrapping and sealing; prohibit direct hand contact with ready-to-eat items.

C. Delivery & Service Standards

• Delivery Timing: Hand over all takeaway and online orders within two minutes of preparation completion. Ensure total delivery time from kitchen to customer does not exceed 25 minutes.
• Packaging Hand-Off: Provide delivery staff with neatly packed, sealed, and labeled items in clean, securely closed delivery bags.
• Communication: Relay any special customer instructions (e.g., extra spice, no mayonnaise) to delivery partners or waitstaff.
• Customer Experience Check: Inspect for completeness, absence of leaks or excess oil, and proper alignment of stickers and branding.
• Feedback & Reporting: Document customer complaints, packaging defects, or delivery delays in the Daily Delivery Log for managerial review and continuous improvement.

C. Closing & End-of-Day Hygiene

Execute these tasks post-service to prepare for the next operational day.

• Gas Supply Monitoring: Confirm availability of gas cylinders for the following day, with at least one spare cylinder on standby.
• Daily Order List: Compile and submit a requisition list for essentials (e.g., chicken, vegetables, bread) to the Manager.
• Weekly Inventory Check: Conduct stock audits of packing materials, masala mixes, and groceries; generate an order list aligned with supplier delivery schedules.
• Machinery & Equipment Cleaning: Clean and sanitize all utilized machines, tools, and work surfaces thoroughly.
• Equipment Power Check: Verify that freezers and refrigerators are powered on and operating correctly (e.g., temperatures within safe ranges).
• Oil & Food Storage: Securely cover oil containers to prevent exposure; ensure no oil remains uncovered overnight.
• Food Safety Storage: Enclose all refrigerated items with cling film or lids to avert contamination.
• Burner & Gas Safety: Inspect all burners and gas connections for integrity and secure wiring.
• Gas Leakage Inspection: Conduct an end-of-day leak test using a soap solution (never a naked flame) on all connections.
• Weighing Scale Calibration: Test the weighing scale's accuracy and recalibrate if deviations exceed tolerance levels.
• FIFO System: Apply the First-In-First-Out (FIFO) principle to all inventory rotation to minimize wastage and ensure freshness.
• Waste Disposal: Safely discard all leftovers, including chicken, mayonnaise, and perishables from the day; prohibit reuse under any circumstances.
• Refrigerator & Freezer Responsibility: The Shawarma Master and Helper shall ensure daily cleaning and organization of refrigerators and freezers:
  o Wipe away any visible spills or residues.
  o Verify temperature displays for proper cooling.
  o Notify the Manager if deep cleaning or defrosting is required.

Closing Sign-Off: Shawarma Master: ________________ Date/Time: __________ Helper: ________________ Date/Time: __________

Additional Best Practices

• Maintain a Daily Log Sheet (Signature-Based): Document all cleaning activities, oil filtrations, pasteurizations, and gas safety checks, with signatures from responsible staff for accountability.
• Keep a “Ready-to-Use Zone” Checklist: Both the Shawarma Master and Helper must sign this daily checklist prior to opening to confirm zone readiness.
• Use Labeled Containers: Store all sauces, masala mixes, and ingredients in clearly labeled containers to facilitate identification, rotation, and hygiene compliance.
• Conduct a Quick Pre-Closing Visual Audit: Prior to shutdown, the Manager and Shawarma Master shall perform a joint visual inspection to verify kitchen cleanliness, equipment deactivation, and secure storage.

Revision History:

Version
Date
Description of Changes
Approved By

1.0
2025-11-06
Initial Release
[Name/Title]
''';
