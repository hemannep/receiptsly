import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Ads/banner_ads.dart';
import '../../Ads/interstitial_ads.dart';
import '../../Ads/rewared_ads.dart';
import '../../utils/game_state.dart';
import '../../widgets/bottom_actions.dart';
import '../../widgets/number_pad.dart';
import '../Settings Screen/app_settings.dart';
import 'game_header.dart';
import 'pause_overlay.dart';
import 'board_display.dart';

class GameScreen extends StatefulWidget {
  final String difficulty;
  final int removeCount;
  final bool isContinue;
  final bool isDailyChallenge;
  final DateTime? challengeDate;
  final dynamic customGame;

  const GameScreen({
    super.key,
    required this.difficulty,
    required this.removeCount,
    this.isContinue = false,
    this.isDailyChallenge = false,
    this.challengeDate,
    this.customGame,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Timer? _timer;
  bool _dialogShown = false;
  late NavigatorState _navigator;
  int _undoEraseCount = 0;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        _initializeGame();
        _hasInitialized = true;
      }
    });
  }

  void _initializeGame() {
    final gameState = context.read<GameState>();

    if (widget.isDailyChallenge && widget.customGame != null) {
      gameState.initDailyChallenge(
        widget.customGame,
        widget.difficulty,
        widget.removeCount,
      );
    } else {
      gameState.initGame(
        widget.difficulty,
        widget.removeCount,
        isContinue: widget.isContinue,
      );
    }

    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigator = Navigator.of(context);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final gameState = context.read<GameState>();
      gameState.incrementSeconds();

      bool isGameComplete = gameState.isBoardComplete();
      bool isGameOverByMistakes = gameState.checkGameOver();

      if ((isGameComplete || isGameOverByMistakes) && !_dialogShown) {
        _dialogShown = true;
        gameState.markGameOverShown();
        _timer?.cancel();
        _showGameOverDialog(gameState);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleUndoErase(VoidCallback action) async {
    _undoEraseCount++;
    if (_undoEraseCount % 3 == 0) {
      await InterstitialAdHelper.showInterstitialAd();
    }
    action();
  }

  Future<void> _handleHint() async {
    final gameState = context.read<GameState>();

    if (RewardedAdHelper.isRewardedAdReady()) {
      await RewardedAdHelper.showRewardedAd(
        onRewardEarned: () {
          gameState.hint();
        },
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad not ready, please try again'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showGameOverDialog(GameState gameState) async {
    if (!mounted) return;

    final isGameWon = gameState.isBoardComplete();
    final canContinue = gameState.canContinue();

    // Record win/loss BEFORE showing dialog (so achievements update)
    if (isGameWon) {
      AppSettings().heavyHaptic();
      await gameState.completeGame();
    } else if (!canContinue) {
      await gameState.recordLoss();
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color:
                        isGameWon ? Colors.green.shade50 : Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isGameWon
                        ? Icons.emoji_events_rounded
                        : Icons.favorite_border,
                    color:
                        isGameWon ? Colors.green.shade500 : Colors.red.shade500,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isGameWon
                      ? '🎉 Congratulations! 🎉'
                      : (canContinue ? 'Game Over!' : 'Final Game Over!'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isGameWon
                      ? 'You solved the puzzle perfectly!'
                      : (canContinue
                          ? 'You\'ve reached the maximum mistakes'
                          : 'No more chances left!'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // Show newly unlocked achievement
                if (isGameWon && gameState.newlyUnlockedAchievementId != null)
                  _AchievementUnlockedBanner(
                    achievementId: gameState.newlyUnlockedAchievementId!,
                    onDone: () => gameState.clearNewlyUnlockedAchievement(),
                  ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:
                        isGameWon ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: isGameWon
                                ? Colors.green.shade600
                                : Colors.red.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Final Score',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isGameWon
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${gameState.score}',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: isGameWon
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _StatPill(
                              icon: Icons.schedule_rounded,
                              label: gameState.formattedTime,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatPill(
                              icon: Icons.error_outline_rounded,
                              label: '${gameState.mistakes} mistakes',
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (!isGameWon && canContinue)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () async {
                            if (RewardedAdHelper.isRewardedAdReady()) {
                              await RewardedAdHelper.showRewardedAd(
                                onRewardEarned: () {
                                  if (Navigator.of(dialogContext).canPop()) {
                                    _dialogShown = false;
                                    gameState.addExtraChance();
                                    Navigator.of(dialogContext).pop();
                                    _startTimer();
                                  }
                                },
                              );
                            } else {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ad not ready, try again'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            _timer?.cancel();
                            _dialogShown = false;
                            gameState.clearGameProgress();
                            Navigator.of(dialogContext).pop();
                            _navigator.pop();
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home_rounded, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Home',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isGameWon
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        _timer?.cancel();
                        _dialogShown = false;
                        gameState.clearGameProgress();
                        Navigator.of(dialogContext).pop();
                        _navigator.pop();
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.home_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Home',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _timer?.cancel();
      },
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFFAFBFC),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _GameHeaderWidget(
                        onBack: () {
                          _timer?.cancel();
                          _navigator.pop();
                        },
                      ),
                      const SizedBox(height: 24),
                      const _BoardDisplayWidget(),
                      const SizedBox(height: 24),
                      _ControlsWidget(
                        onUndoErase: _handleUndoErase,
                        onHint: _handleHint,
                      ),
                      const SizedBox(height: 20),
                      const _NumberPadWidget(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementUnlockedBanner extends StatelessWidget {
  final String achievementId;
  final VoidCallback onDone;

  const _AchievementUnlockedBanner({
    required this.achievementId,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    // Auto-clear after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), onDone);
    });

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade300, Colors.amber.shade500],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: Colors.amber.shade700,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Achievement Unlocked!',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Check your stats',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameHeaderWidget extends StatelessWidget {
  final VoidCallback onBack;

  const _GameHeaderWidget({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        return GameHeader(
          gameState: gameState,
          onBack: onBack,
          onPauseToggle: () {
            gameState.togglePause();
          },
        );
      },
    );
  }
}

class _BoardDisplayWidget extends StatelessWidget {
  const _BoardDisplayWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        return BoardDisplay(gameState: gameState);
      },
    );
  }
}

class _ControlsWidget extends StatelessWidget {
  final Future<void> Function(VoidCallback) onUndoErase;
  final Future<void> Function() onHint;

  const _ControlsWidget({required this.onUndoErase, required this.onHint});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        if (gameState.isPaused) {
          return PauseOverlay(
            onResume: () async {
              if (RewardedAdHelper.isRewardedAdReady()) {
                await RewardedAdHelper.showRewardedAd(
                  onRewardEarned: () {
                    gameState.togglePause();
                  },
                );
              } else {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ad not ready, resuming anyway...'),
                    duration: Duration(seconds: 2),
                  ),
                );
                gameState.togglePause();
              }
            },
          );
        }

        return BottomActions(
          notesMode: gameState.notesMode,
          onUndo: () => onUndoErase(gameState.undo),
          onErase: () => onUndoErase(gameState.erase),
          onNotes: gameState.toggleNotesMode,
          onHint: onHint,
          canUndo: gameState.history.isNotEmpty,
        );
      },
    );
  }
}

class _NumberPadWidget extends StatelessWidget {
  const _NumberPadWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        return NumberPad(
          onTap: gameState.inputNumber,
          isDisabled: gameState.isNumberCompleted,
          board: gameState.game.board,
        );
      },
    );
  }
}
