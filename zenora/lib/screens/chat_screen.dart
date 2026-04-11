// ════════════════════════════════════════════════════════════════════════════
// lib/screens/chat_screen.dart
//
// Rule-based AI Chatbot — uses live AppProvider data for dynamic responses.
// No external API required.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  _ChatMessage({required this.text, required this.isUser})
      : time = DateTime.now();
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  static const List<String> _suggestions = [
    'Why is my stress high?',
    'How to reduce heart rate?',
    'What should I do now?',
    'Am I okay?',
    'Show my health summary',
    'What is pressure therapy?',
  ];

  @override
  void initState() {
    super.initState();
    _addBot(
      '👋 Hi! I\'m Zenora AI. I can analyze your real-time health data and give you personalized advice.\n\nAsk me anything or tap a suggestion below!',
    );
  }

  void _addBot(String text) {
    setState(() => _messages.add(_ChatMessage(text: text, isUser: false)));
    _scrollToBottom();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _controller.clear();

    setState(() => _messages.add(_ChatMessage(text: text, isUser: true)));
    _scrollToBottom();

    final provider = context.read<AppProvider>();
    final response = _generateResponse(text.trim().toLowerCase(), provider);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _addBot(response);
    });
  }

  String _generateResponse(String input, AppProvider p) {
    final stress = p.stressIndex;
    final hr = p.heartRate;
    final temp = p.bodyTemp;

    // Stress related
    if (input.contains('stress') && input.contains('high') ||
        input.contains('why') && input.contains('stress')) {
      if (stress > 85) {
        return '⚠️ Your stress index is critically high at ${stress.toStringAsFixed(0)}.\n\nPossible reasons:\n• High cognitive load or workload\n• Lack of sleep or rest\n• Environmental pressure\n\nImmediate action: Try 4-7-8 breathing — inhale 4s, hold 7s, exhale 8s. Do 3 cycles right now.';
      } else if (stress > 70) {
        return '📈 Your stress is elevated at ${stress.toStringAsFixed(0)}.\n\nThis typically happens due to:\n• Prolonged concentration\n• Physical tension\n• Mental fatigue\n\nTry box breathing or a 10-min walk to reset.';
      } else if (stress > 50) {
        return '🟡 Moderate stress detected (${stress.toStringAsFixed(0)}).\n\nYou\'re managing, but watch out. A short mindfulness break now can prevent escalation.';
      } else {
        return '✅ Your stress looks normal at ${stress.toStringAsFixed(0)}. You\'re doing well! Keep up your current routine.';
      }
    }

    // Heart rate
    if (input.contains('heart rate') || input.contains('bpm') || input.contains('heart')) {
      if (hr > 100) {
        return '❤️ Your heart rate is elevated at ${hr.toStringAsFixed(0)} BPM.\n\nTo reduce it:\n• Sit down and take slow, deep breaths\n• Avoid caffeine right now\n• Drink a glass of cold water\n• Practice diaphragmatic breathing for 5 minutes';
      } else if (hr < 60) {
        return '💙 Your heart rate is at ${hr.toStringAsFixed(0)} BPM — slightly low.\n\nThis is often normal at rest. If you feel dizzy or faint, sit down and eat something light.';
      } else {
        return '✅ Heart rate is healthy at ${hr.toStringAsFixed(0)} BPM. Ideal range is 60–100 BPM. You\'re in the zone!';
      }
    }

    // What to do now
    if (input.contains('what should') || input.contains('do now') || input.contains('suggest')) {
      return _whatToDoNow(stress, hr, temp);
    }

    // Health summary
    if (input.contains('summary') || input.contains('status') || input.contains('overview')) {
      return '📊 Your current health summary:\n\n'
          '• Stress Index: ${stress.toStringAsFixed(0)} — ${_stressLabel(stress)}\n'
          '• Heart Rate: ${hr.toStringAsFixed(0)} BPM\n'
          '• Body Temp: ${temp.toStringAsFixed(1)}°C\n\n'
          '${_overallMessage(stress, hr, temp)}';
    }

    // Am I okay
    if (input.contains('okay') || input.contains('fine') || input.contains('normal') || input.contains('safe')) {
      if (stress < 60 && hr < 95 && temp < 37.5) {
        return '✅ Yes! All your vitals look within normal range. Keep it up!';
      } else {
        return '⚠️ Some readings are elevated:\n${stress > 60 ? '• Stress is ${stress.toStringAsFixed(0)} (elevated)\n' : ''}'
            '${hr > 95 ? '• Heart rate is ${hr.toStringAsFixed(0)} BPM\n' : ''}'
            '${temp > 37.5 ? '• Temp is ${temp.toStringAsFixed(1)}°C (slightly high)\n' : ''}'
            '\nConsider resting and doing breathing exercises.';
      }
    }

    // Pressure therapy
    if (input.contains('pressure') || input.contains('therapy') || input.contains('vibration') || input.contains('haptic')) {
      return '💆 Pressure Therapy simulates rhythmic haptic pressure to calm your nervous system.\n\nHow it works:\n• The app vibrates in increasing then decreasing patterns\n• This mimics calming pressure stimulation\n• Best used when stress is above 75\n\nFind it in the Exercises tab → Recommended section.';
    }

    // Fall detection
    if (input.contains('fall') || input.contains('emergency') || input.contains('alert')) {
      return '🚨 Fall Detection monitors your stress levels and can detect sudden falls.\n\nWhen triggered:\n• Your GPS location is fetched\n• An SMS is sent to your emergency contacts\n• A call is placed to your primary contact\n\nSet up contacts in the Profile tab.';
    }

    // Temperature
    if (input.contains('temp') || input.contains('fever') || input.contains('hot')) {
      if (temp > 37.5) {
        return '🌡️ Your temperature is ${temp.toStringAsFixed(1)}°C — slightly elevated.\n\nDrink water, rest, and avoid intense activity. If above 38°C, consider consulting a doctor.';
      } else {
        return '🌡️ Temperature is ${temp.toStringAsFixed(1)}°C — normal range. No concerns!';
      }
    }

    // Default
    return '🤔 I didn\'t quite catch that.\n\nHere\'s what I can help with:\n• Stress analysis & advice\n• Heart rate guidance\n• Health summary\n• Emergency features\n• Breathing exercises\n\nTry one of the suggestion chips below!';
  }

  String _whatToDoNow(double stress, double hr, double temp) {
    if (stress > 85) {
      return '🆘 HIGH PRIORITY ACTIONS:\n\n1. Stop current activity immediately\n2. Sit down and do 4-7-8 breathing\n3. Drink water\n4. Use Pressure Therapy in Exercises tab\n5. Call someone you trust if needed';
    } else if (stress > 70) {
      return '⚠️ RECOMMENDED NOW:\n\n1. Take a 10-min break from your screen\n2. Do box breathing (4 counts each)\n3. Go for a short walk\n4. Avoid caffeine for now';
    } else if (hr > 100) {
      return '❤️ TO CALM YOUR HEART RATE:\n\n1. Sit or lie down\n2. Breathe in slowly for 5s, out for 7s\n3. Drink cold water\n4. Avoid stimulants';
    } else {
      return '✅ You\'re doing well!\n\nMaintain your current state:\n1. Keep hydrated\n2. Take short breaks every hour\n3. Continue mindful breathing\n4. Get 7–8 hours of sleep tonight';
    }
  }

  String _stressLabel(double s) {
    if (s <= 30) return 'Calm';
    if (s <= 50) return 'Relaxed';
    if (s <= 70) return 'Moderate';
    if (s <= 85) return 'High';
    return 'Very High';
  }

  String _overallMessage(double s, double hr, double temp) {
    if (s < 50 && hr < 85 && temp < 37.2) {
      return '🌟 Overall: Excellent health state. Keep it up!';
    } else if (s < 75) {
      return '🟡 Overall: Moderate. Some areas need attention.';
    } else {
      return '🔴 Overall: Take immediate steps to reduce stress and rest.';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessageList()),
            _buildSuggestions(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppTheme.cardBg,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accentPurple, AppTheme.accentCyan],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zenora AI',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Health Intelligence Assistant',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accentGreen.withOpacity(0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: AppTheme.accentGreen, size: 6),
                SizedBox(width: 4),
                Text(
                  'LOCAL AI',
                  style: TextStyle(
                    color: AppTheme.accentGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.accentCyan.withOpacity(0.15)
              : AppTheme.cardBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser
                ? AppTheme.accentCyan.withOpacity(0.3)
                : AppTheme.borderColor,
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: isUser ? AppTheme.accentCyan : AppTheme.textPrimary,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          return GestureDetector(
            onTap: () => _sendMessage(_suggestions[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.accentPurple.withOpacity(0.35),
                ),
              ),
              child: Text(
                _suggestions[i],
                style: const TextStyle(
                  color: AppTheme.accentPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: AppTheme.cardBg,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask me anything...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: _sendMessage,
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accentPurple, AppTheme.accentCyan],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
