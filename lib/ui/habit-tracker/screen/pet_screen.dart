import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:purewill/ui/habit-tracker/screen/home_screen.dart';
import 'package:sensors_plus/sensors_plus.dart';

class PetScreen extends StatefulWidget {
  const PetScreen({super.key});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> {
  final Random random = Random();

  // ================= AUDIO =================
  AudioPlayer? _audioPlayer;
  final bool _isWeb = kIsWeb;

  final List<String> _normalSounds = [
    'voice_pack/cat-1.wav',
    'voice_pack/cat-2.wav',
    'voice_pack/cat-3.wav',
  ];

  final Map<String, String> _specialSounds = {
    'Hurt': 'voice_pack/cat-grapped.wav',
    'Happy': 'voice_pack/cat-pur.wav',
    'Sad': 'voice_pack/cat-sad.wav',
    'Shake': 'voice_pack/cat-shake.wav',
  };

  // ================= WORLD =================
  double catX = 0;
  double cameraX = 0;
  double screenWidth = 0;
  double screenHeight = 0;
  double worldWidth = 0;

  bool moveRight = true;

  // ================= GYROSCOPE =================
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _gyroX = 0;
  bool _gyroEnabled = true;
  double _gyroSensitivity = 0.5;
  double _targetCameraX = 0;
  String _lastGyroAction = "";
  
  // ================= HOLD SYSTEM =================
  bool isHoldingCat = false;
  double holdOffsetY = 0;

  // ================= CAMERA DRAG =================
  bool isDragging = false;
  double dragStartX = 0;
  double cameraStartX = 0;

  // ================= ANIMATION =================
  int currentFrame = 0;
  List<String> frames = [];
  String currentAction = "Idle";

  final Map<String, int> actionMap = {
    "Idle": 10,
    "Walk": 10,
    "Run": 8,
    "Slide": 10,
    "Hurt": 10,
    "Dead": 10,
    "Jump": 8,
    "Fall": 8,
  };

  final List<String> randomActions = ["Idle", "Walk", "Run"];

  // ================= STATE =================
  bool isDead = false;
  int hunger = 100;
  int mood = 100;

  // ================= TIMER =================
  late Timer gameLoop;
  late Timer actionTimer;
  late Timer soundTimer;

  @override
  void initState() {
    super.initState();
    loadFrames("Idle");
    _initAudio();
    _initGyroscope();

    gameLoop = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (!mounted) return;

      setState(() {
        if (!isDead && frames.isNotEmpty) {
          currentFrame = (currentFrame + 1) % frames.length;

          // GERAK (disable saat dipegang)
          if (!isHoldingCat) {
            if (currentAction == "Walk") {
              catX += moveRight ? 3 : -3;
            } else if (currentAction == "Run") {
              catX += moveRight ? 6 : -6;
            } else if (currentAction == "Slide") {
              catX += moveRight ? 8 : -8;
            }
          }

          // GYROSCOPE CONTROL - Gerakkan kucing dengan animasi slide
          if (_gyroEnabled && !isDragging && !isHoldingCat && !isDead) {
            // BALIKAN arah gyro (miring kanan = ke kanan)
            double gyroMove = -(_gyroX * _gyroSensitivity * 10);
            
            if (gyroMove.abs() > 0.5) {
              // Aktifkan animasi slide saat gyro bergerak
              if (_lastGyroAction != "Slide") {
                loadFrames("Slide");
                _lastGyroAction = "Slide";
                _playRandomShortSound();
              }
              
              catX += gyroMove;
              
              // Ubah arah berdasarkan gerakan gyro
              if (gyroMove > 0) {
                moveRight = true;
              } else if (gyroMove < 0) {
                moveRight = false;
              }
            } else {
              // Kembali ke idle atau walk saat gyro berhenti
              if (_lastGyroAction == "Slide" && currentAction == "Slide") {
                if (!isDead && mounted) {
                  loadFrames("Idle");
                  _lastGyroAction = "";
                }
              }
            }
            
            // Batasi posisi
            catX = catX.clamp(0, worldWidth - 200);
            
            // Update target kamera
            _targetCameraX = catX - screenWidth / 2 + 100;
          }

          // BATAS
          if (catX >= worldWidth - 200) {
            catX = worldWidth - 200;
            moveRight = false;
            if (!isHoldingCat && currentAction != "Slide") _playRandomShortSound();
          } else if (catX <= 0) {
            catX = 0;
            moveRight = true;
            if (!isHoldingCat && currentAction != "Slide") _playRandomShortSound();
          }

          // CAMERA FOLLOW
          if (!isDragging) {
            if (_gyroEnabled && !isHoldingCat) {
              cameraX += (_targetCameraX - cameraX) * 0.15;
            } else {
              double target = catX - screenWidth / 2 + 100;
              cameraX += (target - cameraX) * 0.1;
            }
          }

          cameraX = cameraX.clamp(0, worldWidth - screenWidth);

          // GRAVITY sederhana
          if (!isHoldingCat) {
            holdOffsetY = max(0, holdOffsetY - 10);
          }

          // STATUS TURUN
          if (currentFrame % 10 == 0 && currentAction != "Slide") {
            hunger = max(0, hunger - 1);
            mood = max(0, mood - 1);
          } else if (currentFrame % 15 == 0 && currentAction == "Slide") {
            hunger = max(0, hunger - 2);
            mood = max(0, mood - 1);
          }

          // KONDISI
          if (hunger <= 0 && !isDead) {
            isDead = true;
            loadFrames("Dead");
            _playSpecialSound("Sad");
            actionTimer.cancel();
            soundTimer.cancel();
          } else if (hunger < 30 &&
              currentAction != "Hurt" &&
              currentAction != "Dead" &&
              !isDead &&
              currentAction != "Slide") {
            loadFrames("Hurt");
            _playSpecialSound("Hurt");
          } else if (hunger >= 30 &&
              currentAction == "Hurt" &&
              !isDead) {
            loadFrames("Idle");
          }
        }
      });
    });

    actionTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!isDead && !isHoldingCat && _lastGyroAction != "Slide") {
        changeRandomAction();
      }
    });

    soundTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!isDead) _playRandomSound();
    });
  }

  // ================= GYROSCOPE INIT =================
  void _initGyroscope() {
    if (_isWeb) {
      _gyroEnabled = false;
      return;
    }
    
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        // BALIKAN arah dengan negatif (miring kanan = positif)
        _gyroX = -event.x.clamp(-2, 2).toDouble();
        
        // Deadzone
        if (_gyroX.abs() < 0.1) {
          _gyroX = 0;
        }
      },
      onError: (error) {
        debugPrint("Gyroscope error: $error");
        _gyroEnabled = false;
      },
    );
  }

  void _toggleGyro() {
    setState(() {
      _gyroEnabled = !_gyroEnabled;
      if (_gyroEnabled) {
        _showSnackBar("🎮 Gyro ON - Tilt phone to make cat slide!");
        if (!isDead && mounted) {
          loadFrames("Idle");
          _lastGyroAction = "";
        }
      } else {
        _showSnackBar("Gyro OFF");
        if (!isDead && mounted && currentAction == "Slide") {
          loadFrames("Idle");
          _lastGyroAction = "";
        }
      }
    });
  }

  void _changeGyroSensitivity() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Gyro Sensitivity"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Higher sensitivity = faster slide movement:"),
            const SizedBox(height: 20),
            StatefulBuilder(
              builder: (context, setStateDialog) {
                return Column(
                  children: [
                    Slider(
                      value: _gyroSensitivity,
                      min: 0.1,
                      max: 2.0,
                      divisions: 19,
                      label: _gyroSensitivity.toStringAsFixed(1),
                      onChanged: (value) {
                        setStateDialog(() {
                          _gyroSensitivity = value;
                        });
                        setState(() {
                          _gyroSensitivity = value;
                        });
                      },
                    ),
                    Text(
                      "Speed: ${(_gyroSensitivity * 10).toStringAsFixed(0)} pts/sec",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ================= AUDIO =================
  void _initAudio() {
    _audioPlayer = AudioPlayer();
    _audioPlayer?.setVolume(0.8);
    if (_isWeb) {
      _audioPlayer?.setPlayerMode(PlayerMode.mediaPlayer);
    }
  }

  Future<void> _playRandomSound() async {
    if (_audioPlayer == null || isDead) return;

    if (random.nextInt(100) < 30 && _lastGyroAction != "Slide") {
      final sound = _normalSounds[random.nextInt(_normalSounds.length)];
      await _audioPlayer!.play(AssetSource(sound));
    }
  }

  Future<void> _playRandomShortSound() async {
    if (_audioPlayer == null || isDead) return;
    if (_lastGyroAction != "Slide") {
      final sound = _normalSounds[random.nextInt(_normalSounds.length)];
      await _audioPlayer!.play(AssetSource(sound));
    }
  }

  Future<void> _playSpecialSound(String type) async {
    if (_audioPlayer == null) return;
    final sound = _specialSounds[type];
    if (sound != null) {
      await _audioPlayer!.play(AssetSource(sound));
    }
  }

  // ================= LOGIC =================
  void loadFrames(String action) {
    if (actionMap.containsKey(action)) {
      frames = List.generate(
        actionMap[action]!,
        (i) => 'assets/cat/${action}_${i + 1}.png',
      );
      currentFrame = 0;
      currentAction = action;
    }
  }

  void changeRandomAction() {
    final action = randomActions[random.nextInt(randomActions.length)];
    loadFrames(action);

    if (action == "Walk" || action == "Run") {
      _playRandomShortSound();
    }
  }

  void feedCat() {
    if (isDead) return;
    setState(() {
      hunger = min(100, hunger + 20);
      mood = min(100, mood + 15);
      _playSpecialSound("Happy");
    });
  }

  void playWithCat() {
    if (isDead) return;
    setState(() {
      mood = min(100, mood + 25);
      hunger = max(0, hunger - 5);
      _playSpecialSound("Happy");
    });
  }

  void resetGame() {
    setState(() {
      hunger = 100;
      mood = 100;
      isDead = false;
      catX = worldWidth / 2;
      moveRight = true;
      holdOffsetY = 0;
      isHoldingCat = false;
      _lastGyroAction = "";
      loadFrames("Idle");

      if (!actionTimer.isActive) {
        actionTimer = Timer.periodic(const Duration(seconds: 4), (_) {
          if (!isDead) changeRandomAction();
        });
      }

      if (!soundTimer.isActive) {
        soundTimer = Timer.periodic(const Duration(seconds: 12), (_) {
          if (!isDead) _playRandomSound();
        });
      }
    });
  }

  void goToHomeScreen() async {
    gameLoop.cancel();
    actionTimer.cancel();
    soundTimer.cancel();
    await _accelerometerSubscription?.cancel();
    await _audioPlayer?.stop();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final size = MediaQuery.of(context).size;
    screenWidth = size.width;
    screenHeight = size.height;

    worldWidth = screenWidth * 2;

    if (catX == 0) {
      catX = worldWidth / 2;
    }
  }

  @override
  void dispose() {
    gameLoop.cancel();
    actionTimer.cancel();
    soundTimer.cancel();
    _accelerometerSubscription?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double catBottom = screenHeight * 0.20;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          if (!isDead && _lastGyroAction != "Slide") {
            _playRandomShortSound();
          }
        },
        onHorizontalDragStart: (details) {
          if (!isHoldingCat) {
            isDragging = true;
            dragStartX = details.globalPosition.dx;
            cameraStartX = cameraX;
          }
        },
        onHorizontalDragUpdate: (details) {
          if (isDragging && !isHoldingCat) {
            double delta = details.globalPosition.dx - dragStartX;
            setState(() {
              cameraX = (cameraStartX - delta)
                  .clamp(0, worldWidth - screenWidth);
            });
          }
        },
        onHorizontalDragEnd: (_) {
          Future.delayed(const Duration(seconds: 1), () {
            if (!isHoldingCat) {
              isDragging = false;
            }
          });
        },
        onDoubleTap: () {
          setState(() {
            cameraX = catX - screenWidth / 2 + 100;
          });
        },
        child: Stack(
          children: [
            // ================= BACKGROUND =================
            Positioned(
              left: -cameraX,
              top: 0,
              child: Image.asset(
                'assets/images/cat/room.jpg',
                width: worldWidth,
                height: screenHeight,
                fit: BoxFit.cover,
              ),
            ),

            // ================= SLIDE TRAIL EFFECT =================
            if (currentAction == "Slide" && _gyroEnabled)
              Positioned(
                bottom: catBottom + holdOffsetY - 10,
                left: catX - cameraX - 20,
                child: AnimatedOpacity(
                  opacity: 0.5,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 240,
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),

            // ================= SHADOW =================
            if (!isHoldingCat && holdOffsetY == 0 && currentAction != "Slide")
              Positioned(
                bottom: catBottom - 10,
                left: catX - cameraX + 40,
                child: Container(
                  width: 120,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),

            // ================= CAT (DRAGGABLE) =================
            Positioned(
              bottom: catBottom + holdOffsetY,
              left: catX - cameraX,
              child: GestureDetector(
                onPanStart: (_) {
                  if (isDead) return;
                  setState(() {
                    isHoldingCat = true;
                    loadFrames("Jump");
                    _playSpecialSound("Happy");
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    catX += details.delta.dx;
                    holdOffsetY -= details.delta.dy;

                    catX = catX.clamp(0, worldWidth - 200);
                    holdOffsetY = holdOffsetY.clamp(0, 200);
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    isHoldingCat = false;
                    loadFrames("Fall");
                    _playSpecialSound("Hurt");
                  });

                  Future.delayed(const Duration(milliseconds: 600), () {
                    if (!isDead && mounted && !isHoldingCat && _lastGyroAction != "Slide") {
                      setState(() {
                        loadFrames("Idle");
                      });
                    }
                  });
                },
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(100.0)
                    ..scale(moveRight ? 1.0 : -1.0, 1.0)
                    ..translate(-100.0),
                  child: Image.asset(
                    frames.isNotEmpty ? frames[currentFrame] : '',
                    width: 200,
                    height: 200,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),

            // ================= BACK BUTTON =================
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: goToHomeScreen,
                  tooltip: 'Back to Home',
                ),
              ),
            ),

            // ================= GYRO CONTROL BUTTON =================
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _gyroEnabled ? Icons.sensors : Icons.sensors_off,
                        color: _gyroEnabled ? Colors.green : Colors.red,
                      ),
                      onPressed: _toggleGyro,
                      tooltip: _gyroEnabled ? 'Disable Gyro' : 'Enable Gyro',
                    ),
                    IconButton(
                      icon: const Icon(Icons.speed, color: Colors.white),
                      onPressed: _changeGyroSensitivity,
                      tooltip: 'Slide Sensitivity',
                    ),
                  ],
                ),
              ),
            ),

            // ================= RESURRECT BUTTON =================
            if (isDead)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton(
                    onPressed: resetGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Resurrect Cat"),
                  ),
                ),
              ),

            // ================= UI (Hunger & Mood) =================
            Positioned(
              top: 40,
              left: 80,
              right: 80,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.restaurant, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Hunger: $hunger",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: hunger / 100,
                    backgroundColor: Colors.grey[800],
                    color: hunger < 30 ? Colors.red : Colors.green,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.emoji_emotions, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Mood: $mood",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: mood / 100,
                    backgroundColor: Colors.grey[800],
                    color: mood < 30 ? Colors.orange : Colors.blue,
                  ),
                ],
              ),
            ),

            // ================= ACTION BUTTONS =================
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: feedCat,
                    icon: const Icon(Icons.restaurant, size: 18),
                    label: const Text("Feed"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: playWithCat,
                    icon: const Icon(Icons.cake, size: 18),
                    label: const Text("Play"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: resetGame,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("Reset"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ================= HINT TEXT =================
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _gyroEnabled 
                        ? "🎮 TILT PHONE to slide! • Drag cat to lift • Double tap focus"
                        : "👉 Tap cat & drag • Drag bg for camera • Double tap focus",
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
              ),
            ),

            // ================= GYRO ACTIVE INDICATOR =================
            if (_gyroEnabled && !isHoldingCat && !isDead)
              Positioned(
                top: 100,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: currentAction == "Slide" 
                        ? Colors.orange.withOpacity(0.9)
                        : Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentAction == "Slide" 
                            ? Icons.speed
                            : Icons.sensors,
                        color: Colors.white, 
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentAction == "Slide" 
                            ? "SLIDING!"
                            : "Gyro: ${(_gyroX * _gyroSensitivity).toStringAsFixed(1)}",
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),

            // ================= DRAG INDICATOR =================
            if (isHoldingCat)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "🐱 Release to drop the cat!",
                      style: TextStyle(color: Colors.white, fontSize: 12),
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
