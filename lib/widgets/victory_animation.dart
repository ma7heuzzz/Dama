import 'package:flutter/material.dart';
import 'dart:math' as math;

class VictoryAnimation extends StatefulWidget {
  final String winnerColor;
  final VoidCallback? onAnimationComplete;
  final bool isWinner;

  const VictoryAnimation({
    Key? key,
    required this.winnerColor,
    this.onAnimationComplete,
    this.isWinner = false,
  }) : super(key: key);

  @override
  State<VictoryAnimation> createState() => _VictoryAnimationState();
}

class _VictoryAnimationState extends State<VictoryAnimation> with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _textController;
  late Animation<double> _textScaleAnimation;
  late Animation<double> _textRotateAnimation;
  
  final List<ConfettiPiece> _confettiPieces = [];
  final int _numberOfPieces = 100;
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar controlador de confete
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    
    // Inicializar controlador de texto
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Animação de escala para o texto
    _textScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
    ]).animate(_textController);
    
    // Animação de rotação para o texto
    _textRotateAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.1, end: 0.1)
            .chain(CurveTween(curve: Curves.elasticInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.1, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
    ]).animate(_textController);
    
    // Gerar peças de confete
    _generateConfettiPieces();
    
    // Iniciar animações
    _confettiController.forward();
    _textController.forward();
    
    // Callback quando a animação terminar
    _confettiController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.onAnimationComplete != null) {
          widget.onAnimationComplete!();
        }
      }
    });
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    _textController.dispose();
    super.dispose();
  }
  
  void _generateConfettiPieces() {
    for (int i = 0; i < _numberOfPieces; i++) {
      _confettiPieces.add(ConfettiPiece(
        color: _getRandomColor(),
        position: Offset(
          _random.nextDouble() * 400 - 200,
          _random.nextDouble() * -300,
        ),
        size: _random.nextDouble() * 10 + 5,
        velocity: Offset(
          _random.nextDouble() * 6 - 3,
          _random.nextDouble() * 3 + 5,
        ),
        rotationSpeed: _random.nextDouble() * 0.2 - 0.1,
        shape: _random.nextBool() ? ConfettiShape.circle : ConfettiShape.square,
      ));
    }
  }
  
  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];
    return colors[_random.nextInt(colors.length)];
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camada de confete
        AnimatedBuilder(
          animation: _confettiController,
          builder: (context, child) {
            return CustomPaint(
              painter: ConfettiPainter(
                confettiPieces: _confettiPieces,
                progress: _confettiController.value,
              ),
              size: Size.infinite,
            );
          },
        ),
        
        // Camada de texto
        Center(
          child: AnimatedBuilder(
            animation: _textController,
            builder: (context, child) {
              return Transform.scale(
                scale: _textScaleAnimation.value,
                child: Transform.rotate(
                  angle: _textRotateAnimation.value,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.isWinner ? 'VITÓRIA!' : 'DERROTA!',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 5,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          widget.winnerColor == 'white' ? 'PEÇAS BRANCAS' : 'PEÇAS PRETAS',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: widget.winnerColor == 'white' ? Colors.white : Colors.grey[800],
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 3,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiPiece> confettiPieces;
  final double progress;
  
  ConfettiPainter({
    required this.confettiPieces,
    required this.progress,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var piece in confettiPieces) {
      // Calcular posição atual com base no progresso
      final currentPosition = Offset(
        piece.position.dx + piece.velocity.dx * progress * size.width / 100,
        piece.position.dy + piece.velocity.dy * progress * size.height / 100 + 
            progress * progress * size.height / 2, // Adicionar aceleração para simular gravidade
      );
      
      // Calcular rotação atual
      final currentRotation = piece.rotationSpeed * progress * 10;
      
      // Desenhar peça de confete
      final paint = Paint()..color = piece.color;
      
      canvas.save();
      canvas.translate(
        size.width / 2 + currentPosition.dx,
        size.height / 2 + currentPosition.dy,
      );
      canvas.rotate(currentRotation);
      
      if (piece.shape == ConfettiShape.circle) {
        canvas.drawCircle(Offset.zero, piece.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size,
          ),
          paint,
        );
      }
      
      canvas.restore();
    }
  }
  
  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class ConfettiPiece {
  final Color color;
  final Offset position;
  final double size;
  final Offset velocity;
  final double rotationSpeed;
  final ConfettiShape shape;
  
  ConfettiPiece({
    required this.color,
    required this.position,
    required this.size,
    required this.velocity,
    required this.rotationSpeed,
    required this.shape,
  });
}

enum ConfettiShape {
  circle,
  square,
}

class Random {
  final math.Random _random = math.Random();
  
  double nextDouble() {
    return _random.nextDouble();
  }
  
  int nextInt(int max) {
    return _random.nextInt(max);
  }
  
  bool nextBool() {
    return _random.nextBool();
  }
}
