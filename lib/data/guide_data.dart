import 'package:matfixer/models/guide_model.dart';

final List<InstallationStep> installationSteps = 
[
  InstallationStep(
    title: "Step 1: Clone the Repository",
    content: """
git clone https://github.com/yourusername/yourflutterproject.git
cd yourflutterproject
    """,
    language: "bash", // Bash code
  ),
  InstallationStep(
    title: "Step 2: Install Dependencies",
    content: """
flutter pub get
    """,
    language: "bash", // Bash code
  ),
  InstallationStep(
    title: "Step 3: Run the App",
    content: """
flutter run
    """,
    language: "bash", // Bash code
  )
];