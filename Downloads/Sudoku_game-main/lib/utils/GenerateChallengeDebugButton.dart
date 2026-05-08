import 'package:flutter/material.dart';
import 'package:sudokugame/utils/daily_challenge_service.dart';

// Optional Debug Widget - Add to home_screen.dart temporarily to generate challenges

class GenerateChallengeDebugButton extends StatefulWidget {
  const GenerateChallengeDebugButton({super.key});

  @override
  State<GenerateChallengeDebugButton> createState() =>
      _GenerateChallengeDebugButtonState();
}

class _GenerateChallengeDebugButtonState
    extends State<GenerateChallengeDebugButton> {
  bool _isGenerating = false;
  String? _lastMessage;

  void _generateChallenge() async {
    setState(() {
      _isGenerating = true;
      _lastMessage = null;
    });

    try {
      final today = DateTime.now();
      final dateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      print('🔧 DEBUG: Generating challenge for $dateString');

      await DailyChallengeService.generateAndSaveChallengeToFirebase(
        dateString,
      );

      if (!mounted) return;

      setState(() {
        _lastMessage = '✅ Challenge generated for $dateString!';
        _isGenerating = false;
      });

      print('✅ Success!');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _lastMessage = '❌ Error: $e';
        _isGenerating = false;
      });

      print('❌ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: _isGenerating
              ? Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text(
                      '🔧 DEBUG: Generate Today\'s Challenge',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _generateChallenge,
                  ),
                ),
        ),
        if (_lastMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _lastMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _lastMessage!.startsWith('✅')
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
      ],
    );
  }
}
