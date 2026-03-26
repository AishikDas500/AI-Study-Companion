import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Study Companion',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Modern Midnight Blue
        fontFamily: 'Segoe UI', 
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- Variables & Controllers ---
  final TextEditingController _controller = TextEditingController();
  String result = "";
  PlatformFile? selectedFile;
  bool isLoading = false;

  // --- Backend Logic ---

  // 1. Summarize Plain Text
  Future<void> summarizeText() async {
    if (_controller.text.trim().isEmpty) return;
    
    setState(() => isLoading = true);
    try {
      final url = Uri.parse("http://127.0.0.1:8000/summarize");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": _controller.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          result = (data["summary"] as List).join("\n");
        });
      } else {
        setState(() => result = "❌ Error: Server returned ${response.statusCode}");
      }
    } catch (e) {
      setState(() => result = "❌ Connection Error: Ensure FastAPI is running!");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 2. Pick a PDF
  Future<void> pickPDF() async {
    FilePickerResult? filePickerResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (filePickerResult != null) {
      setState(() {
        selectedFile = filePickerResult.files.first;
      });
    }
  }

  // 3. Upload & Summarize PDF
  Future<void> uploadPDF() async {
    if (selectedFile == null) return;

    setState(() => isLoading = true);
    try {
      final url = Uri.parse("http://127.0.0.1:8000/upload-pdf");
      var request = http.MultipartRequest("POST", url);

      // Handle both Web and Desktop/Mobile bytes
      if (selectedFile!.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          selectedFile!.bytes!,
          filename: selectedFile!.name,
        ));
      } else if (selectedFile!.path != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          selectedFile!.path!,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          result = (data["summary"] as List).join("\n");
        });
      } else {
        setState(() => result = "❌ Error: Could not process PDF");
      }
    } catch (e) {
      setState(() => result = "❌ Connection Error: Check your backend!");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // --- UI Building Blocks ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "AI STUDY COMPANION",
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Glow (Optional subtle effect)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyanAccent.withOpacity(0.05),
              ),
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Input Study Material", Icons.auto_stories),
                _buildGlassCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        maxLines: 5,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Paste your chapter notes or concepts here...",
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.03),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        label: "Summarize Text",
                        icon: Icons.flash_on,
                        color: Colors.cyanAccent.shade700,
                        onPressed: summarizeText,
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text("— OR —", style: TextStyle(color: Colors.grey))),
                ),

                _buildSectionHeader("Upload PDF Document", Icons.file_upload),
                _buildGlassCard(
                  child: Column(
                    children: [
                      _buildSecondaryButton(
                        label: selectedFile == null ? "Select PDF" : selectedFile!.name,
                        icon: selectedFile == null ? Icons.add_rounded : Icons.check_circle,
                        onPressed: pickPDF,
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        label: "Analyze Document",
                        icon: Icons.analytics_outlined,
                        color: Colors.indigoAccent,
                        onPressed: selectedFile != null ? uploadPDF : null,
                      ),
                    ],
                  ),
                ),

                if (result.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _buildSectionHeader("AI Summary Results", Icons.tips_and_updates),
                  
                  // Use AnimatedOpacity to make it fade in beautifully
                  AnimatedOpacity(
                    opacity: result.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 800), // Smooth 0.8 second fade
                    curve: Curves.easeIn,
                    child: _buildResultDisplay(result),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Loading Overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.cyanAccent),
                    SizedBox(height: 20),
                    Text("AI is processing...", style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Helper Widgets for UI ---

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 20),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }

  Widget _buildActionButton({
    required String label, 
    required IconData icon, 
    required Color color, 
    required VoidCallback? onPressed
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        // Logic: If isLoading is true, passing null disables the button (greys it out)
        onPressed: isLoading ? null : onPressed, 
        
        // Show a mini spinner inside the button while loading
        icon: isLoading 
            ? const SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(
                  strokeWidth: 2, 
                  color: Colors.white70,
                ),
              )
            : Icon(icon, size: 20),
        
        // Change text to "Summarizing..." while the AI is thinking
        label: Text(
          isLoading ? "SUMMARIZING..." : label, 
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)
        ),
        
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          // Customizing the "Disabled" look
          disabledBackgroundColor: Colors.white.withOpacity(0.05), 
          disabledForegroundColor: Colors.white24,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
      ),
    );
  }
  
  Widget _buildSecondaryButton({required String label, required IconData icon, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: Colors.cyanAccent),
        label: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Widget _buildResultDisplay(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.cyanAccent.withOpacity(0.05), Colors.blueAccent.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(fontSize: 15, height: 1.8, color: Colors.white, letterSpacing: 0.2),
      ),
    );
  }
}