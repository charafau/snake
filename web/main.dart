import 'dart:collection';
import 'dart:html';

import 'dart:math';

CanvasElement canvas;
CanvasRenderingContext2D ctx;
Keyboard keyboard = Keyboard();

const int CELL_SIZE = 20;
bool isRunning = true;

int _rightEdgeX;
int _bottomEdgeY;

const String backgroundColor = '#649568';
const String snakeColor = '#000000';
const String fruitColor = '#ff0000';

void _drawCell(Point point, String color) {
  ctx
    ..fillStyle = color
    ..strokeStyle = backgroundColor;

  final int x = point.x * CELL_SIZE;
  final int y = point.y * CELL_SIZE;

  ctx
    ..fillRect(x, y, CELL_SIZE, CELL_SIZE)
    ..strokeRect(x, y, CELL_SIZE, CELL_SIZE);
}

void main() {
  canvas = querySelector('#game');
  ctx = canvas.getContext('2d');

  _rightEdgeX = canvas.width ~/ CELL_SIZE;
  _bottomEdgeY = canvas.height ~/ CELL_SIZE;

  Game()..run();
}

class Game {
  final int gameSpeed = 40;
  double _lastTimeStamp = 0;

  final rand = Random();
  Point _fruitPosition;
  int _score = 0;

  Snake _snake;

  Game() {
    init();
  }

  void _generateFruit() {
    _fruitPosition =
        Point(rand.nextInt(_rightEdgeX), rand.nextInt(_bottomEdgeY));
  }

  void init() {
    _snake = Snake(initialSize: 6);
    _generateFruit();
  }

  void _drawFruit() {
    _drawCell(_fruitPosition, fruitColor);
  }

  void _drawScore() {
    ctx.font = '16px serif';
    ctx.fillText('Score: $_score', 24, 24);
  }

  void clear() {
    ctx
      ..fillStyle = backgroundColor
      ..fillRect(0, 0, canvas.width, canvas.height);
  }

  Future<void> run() async {
    update(await window.animationFrame);
  }

  void _die() {
    ctx.font = '48px serif';
    ctx.fillText('💀', canvas.width / 2 - 24, canvas.height / 2);
  }

  void update(double delta) {
    final diff = delta - _lastTimeStamp;

    if (diff > gameSpeed) {
      _lastTimeStamp = delta;
      clear();

      _drawFruit();

      if (_snake.head.x == _fruitPosition.x &&
          _snake.head.y == _fruitPosition.y) {
        _snake.shouldRemoveLast = false;
        _generateFruit();
        _score++;
      }

      if (!_snake.isDead) {
        _snake.update();
      } else {
        _die();
      }
      _drawScore();
    }

    run();
  }
}

class Snake {
  final Point _right = Point(1, 0);
  final Point _left = Point(-1, 0);
  final Point _up = Point(0, -1);
  final Point _down = Point(0, 1);

  Point _currentDirection;
  bool shouldRemoveLast = true;
  bool _isDead = false;

  bool get isDead => _isDead;

  List<Point> _body;

  Snake({int initialSize = 6}) {
    _currentDirection = _right;
    _body = <Point>[];
    for (var i = 0; i < initialSize; i++) {
      _body.add(Point(5 - i, 5));
    }
  }

  void update() {
    _checkInput();
    _move();
    _draw();
    _checkIfBiteSelf();
  }

  void _checkIfBiteSelf() {
    _body.skip(1).forEach((part) {
      if (part.x == head.x && part.y == head.y) {
        _isDead = true;
      }
    });
  }

  void _draw() {
    _body.forEach((e) {
      _drawCell(e, snakeColor);
    });
  }

  Point get head => _body.first;

  void _grow() {
    if ((head + _currentDirection).x >= _rightEdgeX) {
      _body.insert(0, Point(0, head.y));
    } else if ((head + _currentDirection).y >= _bottomEdgeY) {
      _body.insert(0, Point(head.x, 0));
    } else if ((head + _currentDirection).y < 0) {
      _body.insert(0, Point(head.x, _bottomEdgeY));
    } else if ((head + _currentDirection).x < 0) {
      _body.insert(0, Point(_rightEdgeX, head.y));
    } else {
      _body.insert(0, head + _currentDirection);
    }
  }

  void _move() {
    _grow();

    if (shouldRemoveLast) {
      _body.removeLast();
    } else {
      shouldRemoveLast = true;
    }
  }

  void _checkInput() {
    if (keyboard.isPressed(KeyCode.LEFT) && _currentDirection != _right) {
      _currentDirection = _left;
    }
    if (keyboard.isPressed(KeyCode.RIGHT) && _currentDirection != _left) {
      _currentDirection = _right;
    }
    if (keyboard.isPressed(KeyCode.UP) && _currentDirection != _down) {
      _currentDirection = _up;
    }
    if (keyboard.isPressed(KeyCode.DOWN) && _currentDirection != _up) {
      _currentDirection = _down;
    }
  }
}

class Keyboard {
  final HashMap<int, num> _keys = HashMap<int, num>();

  Keyboard() {
    window.onKeyDown.listen(
        (event) => _keys.putIfAbsent(event.keyCode, () => event.timeStamp));

    window.onKeyUp.listen((event) => _keys.remove(event.keyCode));
  }

  bool isPressed(int keyCode) => _keys.containsKey(keyCode);
}
