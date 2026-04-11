import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Exercise data model ────────────────────────────────────────────────────
class Exercise {
  final String id;
  final String name;
  final String category;
  final String emoji;
  final String description;
  final String duration;
  final Color color;
  final List<ExerciseStep> steps;
  final String benefit;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.emoji,
    required this.description,
    required this.duration,
    required this.color,
    required this.steps,
    required this.benefit,
  });
}

class ExerciseStep {
  final String label;
  final int seconds;
  final String? instruction;

  const ExerciseStep(this.label, this.seconds, {this.instruction});
}

// ── Exercise catalogue ─────────────────────────────────────────────────────
final List<Exercise> exercises = [
  Exercise(
    id: 'box_breathing',
    name: 'Box Breathing',
    category: 'Breathing',
    emoji: '📦',
    description:
        'A powerful technique used by Navy SEALs. Inhale, hold, exhale, hold — each for 4 seconds.',
    duration: '4 min',
    color: AppTheme.accentCyan,
    benefit: 'Reduces anxiety & improves focus',
    steps: [
      ExerciseStep('Inhale', 4, instruction: 'Breathe in slowly through your nose'),
      ExerciseStep('Hold', 4, instruction: 'Hold your breath gently'),
      ExerciseStep('Exhale', 4, instruction: 'Breathe out slowly through your mouth'),
      ExerciseStep('Hold', 4, instruction: 'Hold before next breath'),
    ],
  ),
  Exercise(
    id: '478_breathing',
    name: '4-7-8 Breathing',
    category: 'Breathing',
    emoji: '🌬️',
    description:
        'Inhale for 4, hold for 7, exhale for 8. A natural tranquilizer for the nervous system.',
    duration: '5 min',
    color: AppTheme.accentPurple,
    benefit: 'Instant stress & anxiety relief',
    steps: [
      ExerciseStep('Inhale', 4, instruction: 'Breathe in quietly through the nose'),
      ExerciseStep('Hold', 7, instruction: 'Hold the breath completely'),
      ExerciseStep('Exhale', 8, instruction: 'Exhale completely through the mouth'),
    ],
  ),
  Exercise(
    id: 'diaphragmatic',
    name: 'Diaphragmatic Breathing',
    category: 'Breathing',
    emoji: '🫁',
    description:
        'Deep belly breathing that activates your parasympathetic nervous system for calm.',
    duration: '5 min',
    color: AppTheme.accentGreen,
    benefit: 'Lowers heart rate & blood pressure',
    steps: [
      ExerciseStep('Breathe In', 5, instruction: 'Expand your belly, not your chest'),
      ExerciseStep('Breathe Out', 6, instruction: 'Let belly fall, exhale fully'),
    ],
  ),
  Exercise(
    id: 'alternate_nostril',
    name: 'Alternate Nostril',
    category: 'Breathing',
    emoji: '👃',
    description:
        'Nadi Shodhana pranayama — balances both hemispheres of the brain for clarity.',
    duration: '6 min',
    color: const Color(0xFFEC4899),
    benefit: 'Balances mind & calms nervous system',
    steps: [
      ExerciseStep('Close Right, Inhale Left', 4),
      ExerciseStep('Close Both, Hold', 4),
      ExerciseStep('Close Left, Exhale Right', 4),
      ExerciseStep('Close Both, Hold', 4),
      ExerciseStep('Close Left, Inhale Right', 4),
      ExerciseStep('Close Both, Hold', 4),
      ExerciseStep('Close Right, Exhale Left', 4),
    ],
  ),
  Exercise(
    id: 'mindful_walk',
    name: 'Mindful Walking',
    category: 'Movement',
    emoji: '🚶',
    description:
        'Walk slowly and deliberately, paying full attention to each step and breath.',
    duration: '10 min',
    color: AppTheme.accentYellow,
    benefit: 'Clears mental fog, boosts mood',
    steps: [
      ExerciseStep('Ground Yourself', 30, instruction: 'Stand still, feel the ground under your feet'),
      ExerciseStep('Walk Slowly', 240, instruction: 'Take small steps, feel each foot contact the ground'),
      ExerciseStep('Observe Surroundings', 180, instruction: 'Notice 5 things you can see around you'),
      ExerciseStep('Cool Down', 60, instruction: 'Slow to a stop, take 3 deep breaths'),
    ],
  ),
  Exercise(
    id: 'progressive_muscle',
    name: 'Progressive Muscle Relaxation',
    category: 'Movement',
    emoji: '💪',
    description:
        'Tense and release each muscle group to release physical tension stored in your body.',
    duration: '12 min',
    color: AppTheme.accentOrange,
    benefit: 'Releases physical tension & improves sleep',
    steps: [
      ExerciseStep('Hands & Arms', 10, instruction: 'Clench fists tight, then release'),
      ExerciseStep('Shoulders', 10, instruction: 'Shrug shoulders to ears, release'),
      ExerciseStep('Neck', 10, instruction: 'Gently tense neck muscles, release'),
      ExerciseStep('Face', 10, instruction: 'Scrunch all face muscles, release'),
      ExerciseStep('Chest', 10, instruction: 'Take deep breath, tense chest, release'),
      ExerciseStep('Stomach', 10, instruction: 'Tighten abs, hold, release'),
      ExerciseStep('Legs & Feet', 10, instruction: 'Tense thighs, calves, feet, release'),
      ExerciseStep('Full Body Scan', 30, instruction: 'Scan body for any remaining tension'),
    ],
  ),
  Exercise(
    id: 'neck_stretch',
    name: 'Neck & Shoulder Stretch',
    category: 'Movement',
    emoji: '🤸',
    description:
        'Target the areas where stress accumulates most — neck, shoulders, and upper back.',
    duration: '5 min',
    color: const Color(0xFF06B6D4),
    benefit: 'Relieves tension headaches',
    steps: [
      ExerciseStep('Neck Right', 20, instruction: 'Gently tilt head to right shoulder'),
      ExerciseStep('Neck Left', 20, instruction: 'Gently tilt head to left shoulder'),
      ExerciseStep('Neck Forward', 20, instruction: 'Drop chin to chest gently'),
      ExerciseStep('Shoulder Rolls', 30, instruction: '5 rolls forward, 5 rolls back'),
      ExerciseStep('Chest Opener', 30, instruction: 'Clasp hands behind back, open chest'),
    ],
  ),
  Exercise(
    id: 'body_scan',
    name: 'Body Scan Meditation',
    category: 'Mindfulness',
    emoji: '🧘',
    description:
        'A guided awareness practice scanning from head to toe, releasing tension at each point.',
    duration: '10 min',
    color: AppTheme.accentPurple,
    benefit: 'Deep relaxation & self-awareness',
    steps: [
      ExerciseStep('Settle In', 30, instruction: 'Lie down or sit comfortably. Close your eyes.'),
      ExerciseStep('Scalp & Head', 45, instruction: 'Notice any tension in your scalp, forehead, jaw'),
      ExerciseStep('Neck & Shoulders', 45, instruction: 'Let your shoulders drop away from your ears'),
      ExerciseStep('Arms & Hands', 45, instruction: 'Feel the weight of your arms. Let them sink.'),
      ExerciseStep('Chest & Heart', 45, instruction: 'Notice your heartbeat. Breathe into your chest.'),
      ExerciseStep('Stomach', 45, instruction: 'Let your belly be soft. Notice rising and falling.'),
      ExerciseStep('Hips & Lower Back', 45, instruction: 'Release any tightness in your hips.'),
      ExerciseStep('Legs & Feet', 45, instruction: 'Feel your legs heavy. Release tension in feet.'),
      ExerciseStep('Whole Body', 60, instruction: 'Feel your whole body. You are completely relaxed.'),
    ],
  ),
  Exercise(
    id: 'visualization',
    name: 'Guided Visualization',
    category: 'Mindfulness',
    emoji: '🌊',
    description:
        'A peaceful mental journey to a calming place — your safe space to escape stress.',
    duration: '8 min',
    color: const Color(0xFF14B8A6),
    benefit: 'Reduces cortisol & restores calm',
    steps: [
      ExerciseStep('Close Eyes & Breathe', 30, instruction: 'Take 3 deep breaths to settle in'),
      ExerciseStep('Find Your Place', 60, instruction: 'Imagine a peaceful place — beach, forest, meadow'),
      ExerciseStep('See It', 60, instruction: 'Notice the colors, light, and details around you'),
      ExerciseStep('Hear It', 60, instruction: 'What sounds do you hear? Waves? Birds? Wind?'),
      ExerciseStep('Feel It', 60, instruction: 'Feel the warmth, the breeze, the ground beneath you'),
      ExerciseStep('Rest Here', 120, instruction: 'Stay in this safe place. You are at peace.'),
      ExerciseStep('Return Slowly', 30, instruction: 'Gently bring awareness back to your body'),
    ],
  ),
  Exercise(
    id: 'cold_water',
    name: 'Cold Water Reset',
    category: 'Quick Relief',
    emoji: '💧',
    description:
        'Splash cold water on your face or wrists to activate the dive reflex and instantly calm.',
    duration: '2 min',
    color: const Color(0xFF38BDF8),
    benefit: 'Instant heart rate reduction',
    steps: [
      ExerciseStep('Breathe First', 10, instruction: 'Take one deep breath before starting'),
      ExerciseStep('Cold Water on Face', 15, instruction: 'Splash cold water on forehead, cheeks, chin'),
      ExerciseStep('Cold Wrists', 20, instruction: 'Run cold water over pulse points on wrists'),
      ExerciseStep('Pat Dry', 10, instruction: 'Gently pat dry with a towel'),
      ExerciseStep('Slow Breath', 20, instruction: 'Take 3 slow breaths. Notice the calm.'),
    ],
  ),
  Exercise(
    id: 'journaling',
    name: 'Stress Journaling',
    category: 'Mindfulness',
    emoji: '📝',
    description:
        'Writing about stress helps process emotions and gain perspective on what\'s bothering you.',
    duration: '10 min',
    color: AppTheme.accentYellow,
    benefit: 'Emotional processing & clarity',
    steps: [
      ExerciseStep('What am I feeling right now?', 120, instruction: 'Write without judgment. Let it flow.'),
      ExerciseStep('What triggered this stress?', 120, instruction: 'Identify the specific cause'),
      ExerciseStep('Is this in my control?', 120, instruction: 'Separate what you can vs cannot control'),
      ExerciseStep('One action I can take', 60, instruction: 'Write one small step to feel better'),
      ExerciseStep('3 things I\'m grateful for', 60, instruction: 'Shift focus to positivity'),
    ],
  ),
  Exercise(
    id: 'music_therapy',
    name: 'Music Therapy',
    category: 'Quick Relief',
    emoji: '🎵',
    description:
        'Intentionally listening to calming music at ~60 BPM naturally slows your heart rate.',
    duration: '5–15 min',
    color: const Color(0xFFA78BFA),
    benefit: 'Lowers cortisol & heart rate',
    steps: [
      ExerciseStep('Choose Calm Music', 20, instruction: 'Pick instrumental, 60 BPM, no lyrics preferred'),
      ExerciseStep('Sit Comfortably', 10, instruction: 'Close eyes. Focus only on the music.'),
      ExerciseStep('Listen Actively', 300, instruction: 'Follow the melody, the instruments, the rhythm'),
      ExerciseStep('Breathe With It', 60, instruction: 'Let your breath sync with the music\'s pace'),
    ],
  ),
];

// ── Exercises Screen ───────────────────────────────────────────────────────
class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  String _selectedCategory = 'All';
  final categories = ['All', 'Breathing', 'Movement', 'Mindfulness', 'Quick Relief'];

  List<Exercise> get filtered => _selectedCategory == 'All'
      ? exercises
      : exercises.where((e) => e.category == _selectedCategory).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exercises',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Science-backed stress reduction practices',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  // Category chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final cat = categories[i];
                        final active = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppTheme.accentCyan.withOpacity(0.2)
                                  : AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? AppTheme.accentCyan.withOpacity(0.6)
                                    : AppTheme.borderColor,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: active
                                    ? AppTheme.accentCyan
                                    : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Exercise list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ExerciseCard(exercise: filtered[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ExerciseDetailScreen(exercise: exercise)),
      ),
      child: Container(
        decoration: AppTheme.glowDecoration(exercise.color),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: exercise.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child:
                    Text(exercise.emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: exercise.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          exercise.category,
                          style: TextStyle(
                              color: exercise.color, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    exercise.description,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          color: exercise.color, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        exercise.duration,
                        style: TextStyle(
                            color: exercise.color, fontSize: 11),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.favorite_outline,
                          color: AppTheme.textSecondary, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        exercise.benefit,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: exercise.color, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Exercise Detail / Player Screen ───────────────────────────────────────
class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isRunning = false;
  int _currentStep = 0;
  int _secondsLeft = 0;
  int _totalRounds = 0;
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _resetStep(0);
  }

  void _resetStep(int step) {
    _currentStep = step;
    _secondsLeft = widget.exercise.steps[step].seconds;
  }

  void _start() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          if (_currentStep < widget.exercise.steps.length - 1) {
            _resetStep(_currentStep + 1);
          } else {
            _totalRounds++;
            _resetStep(0);
          }
        }
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _resetStep(0);
      _totalRounds = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final step = ex.steps[_currentStep];
    final progress = 1 - (_secondsLeft / step.seconds);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(ex.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Exercise header
              Container(
                decoration: AppTheme.glowDecoration(ex.color),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(ex.emoji,
                        style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ex.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ex.benefit,
                            style: TextStyle(
                                color: ex.color, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '$_totalRounds',
                          style: TextStyle(
                            color: ex.color,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('rounds',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Main timer circle
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  final scale = _isRunning
                      ? 1.0 + _pulseController.value * 0.04
                      : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Progress ring
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 10,
                              backgroundColor:
                                  AppTheme.borderColor,
                              valueColor:
                                  AlwaysStoppedAnimation(ex.color),
                            ),
                          ),
                          Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                _secondsLeft.toString(),
                                style: TextStyle(
                                  color: ex.color,
                                  fontSize: 64,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'seconds',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Current step
              Container(
                decoration: AppTheme.cardDecoration(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      step.label,
                      style: TextStyle(
                        color: ex.color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (step.instruction != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        step.instruction!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Steps progress row
              SizedBox(
                height: 6,
                child: Row(
                  children: List.generate(
                    ex.steps.length,
                    (i) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                            right: i < ex.steps.length - 1 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: i < _currentStep
                              ? ex.color
                              : i == _currentStep
                                  ? ex.color.withOpacity(0.5)
                                  : AppTheme.borderColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _controlBtn(
                    icon: Icons.stop,
                    color: AppTheme.accentRed,
                    onTap: _stop,
                  ),
                  const SizedBox(width: 24),
                  GestureDetector(
                    onTap: _isRunning ? _pause : _start,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: ex.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: ex.color.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRunning ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  _controlBtn(
                    icon: Icons.skip_next,
                    color: AppTheme.textSecondary,
                    onTap: () {
                      if (_currentStep < ex.steps.length - 1) {
                        setState(() => _resetStep(_currentStep + 1));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controlBtn(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
