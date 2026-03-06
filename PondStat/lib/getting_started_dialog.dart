import 'package:flutter/material.dart';

// --- THIS MAKES THE FILE RUNNABLE FOR TESTING ---
void main() {
  // Use the custom blue for the theme
  const Color customBlue = Color.fromARGB(255, 33, 130, 243);

  runApp(
    MaterialApp(
      title: 'PondStat (Test)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: customBlue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false, 
      home: const _GettingStartedTestHarness(),
    ),
  );
}

// A helper widget to host and launch the dialog
class _GettingStartedTestHarness extends StatefulWidget {
  const _GettingStartedTestHarness();

  @override
  State<_GettingStartedTestHarness> createState() =>
      _GettingStartedTestHarnessState();
}

class _GettingStartedTestHarnessState
    extends State<_GettingStartedTestHarness> {
  @override
  void initState() {
    super.initState();
    // Show the dialog immediately after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return const GettingStartedDialog();
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color customBlue = Color.fromARGB(255, 33, 130, 243);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: customBlue, // Use custom blue
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.water_drop, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'PondStat',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  'Dashboard',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: customBlue),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const Center(
        child: Text('This screen immediately launches the dialog.'),
      ),
    );
  }
}
// ------------------------------------


class GettingStartedDialog extends StatelessWidget {
  const GettingStartedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // This is the main blue color you requested
    const Color primaryBlue = Color.fromARGB(255, 33, 130, 243);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // Reduced padding for a more compact look
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER (No "x" icon) ---
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.help_outline, color: primaryBlue),
                    SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Getting Started with PondStat',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16), // Reduced space

              // 2. Step Items with Numbers
              _buildStepItem(
                context,
                number: '1',
                icon: Icons.person_outline, // The icon *next* to the title
                title: 'For Team Leaders',
                subtitle: 'Open your profile and toggle your role to "Leader" to access the leader homepage.',
                color: primaryBlue,
              ),
              _buildStepItem(
                context,
                number: '2',
                icon: Icons.waves,
                title: 'Choose your Pond',
                subtitle: 'Select an available pond. Once chosen it becomes unavailable to other leaders.',
                color: primaryBlue,
              ),
              _buildStepItem(
                context,
                number: '3',
                icon: Icons.group_add_outlined, // Corrected icon name
                title: 'Add Team Members',
                subtitle: 'Add students who signed up with "Member" roles to your pond group.',
                color: primaryBlue,
              ),
              _buildStepItem(
                context,
                number: '4',
                icon: Icons.check_circle_outline, // Check icon for the last step
                title: 'Start Recording',
                subtitle: 'After confirming your team, access the parameters page to begin tracking data.',
                color: primaryBlue,
                isCheck: true, // Use a check instead of a number
              ),
              const SizedBox(height: 16), // Reduced space

              // 3. Info Box
              _buildDialogInfoBox(
                context,
                icon: Icons.lock_outline,
                title: 'Pond Availability',
                text: 'Leaders can leave their pond anytime, making it available for other leaders.',
                color: primaryBlue,
              ),
              const SizedBox(height: 12), // Reduced space
              
              // 4. Warning Box (Colors are from the mockup)
              _buildWarningBox(
                context,
                icon: Icons.warning_amber_rounded,
                title: 'Please note: ',
                text: 'Students are expected to select their correct roles. Any issues from incorrect role selection or team management are the students\' responsibility.',
              ),
              const SizedBox(height: 16), // Reduced space

              // 5. "Got it!" Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue, // Use custom blue
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Got it!',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // This helper builds the new step items (1, 2, 3, 4)
  Widget _buildStepItem(
    BuildContext context, {
    required String number,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool isCheck = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0), // Reduced vertical padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The Numbered Circle
          CircleAvatar(
            radius: 12, // Made smaller
            backgroundColor: color, // This is your custom blue
            child: isCheck 
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
          ),
          const SizedBox(width: 12), // Reduced space
          // The text on the right
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20), // Icon next to title
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle( // <-- 1. TITLE COLOR CHANGED
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Changed from 'color' to 'Colors.black'
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 26.0), // Indent subtitle
                  child: Text(
                    subtitle,
                    style: TextStyle( // <-- 2. SUBTITLE COLOR CHANGED
                      color: Colors.grey[700], // Changed from 'Colors.grey'
                      fontSize: 13
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // This helper builds the blue "Pond Availability" box
  Widget _buildDialogInfoBox(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // Use light version of custom blue
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(text, style: TextStyle(color: color.withOpacity(0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // This helper builds the orange "Please note" box
  Widget _buildWarningBox(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String text,
  }) {
    const Color warningColor = Color(0xFFE65100); // Orange/Red color

    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // Light orange/yellow background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: warningColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: const TextStyle(
                      color: warningColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: const TextStyle(
                      color: warningColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}