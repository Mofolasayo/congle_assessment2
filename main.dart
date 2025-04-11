import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(e, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

class Dock<T> extends StatefulWidget {
  const Dock({super.key, this.items = const [], required this.builder});
  final List<T> items;
  final Widget Function(T) builder;
  @override
  State<Dock<T>> createState() => _DockState<T>();
}

class _DockState<T> extends State<Dock<T>> with TickerProviderStateMixin {
  late final List<T> _items = widget.items.toList();

  int? _draggedItemIndex;
  double? _dragPosition;

  final Map<int, GlobalKey> _keys = {};
  final Map<int, Offset> _itemPositions = {};
  final Map<int, AnimationController> _animationControllers = {};
  final Map<int, Animation<Offset>> _animations = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _items.length; i++) {
      _keys[i] = GlobalKey();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordInitialPositions();
    });
  }

  @override
  void dispose() {
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _recordInitialPositions() {
    for (int i = 0; i < _items.length; i++) {
      _updateItemPosition(i);
    }
  }

  void _updateItemPosition(int index) {
    final key = _keys[index];
    if (key?.currentContext != null) {
      final RenderBox box =
          key?.currentContext!.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero);
      _itemPositions[index] = position;
    }
  }

  // Handle the start of a drag operation
  void _onDragStart(int index, DragStartDetails details) {
    setState(() {
      _draggedItemIndex = index;
      _dragPosition = details.globalPosition.dx;
      _recordInitialPositions();
    });
  }

  // Handles drag updates
  void _onDragUpdate(DragUpdateDetails details) {
    if (_draggedItemIndex == null) return;

    setState(() {
      _dragPosition = details.globalPosition.dx;

      int newIndex = _draggedItemIndex!;

      for (int i = 0; i < _items.length; i++) {
        if (i == _draggedItemIndex) continue;

        final itemPosition = _itemPositions[i];
        if (itemPosition != null) {
          final itemCenter = itemPosition.dx + _getItemWidth(i) / 2;

          if (_draggedItemIndex! < i && _dragPosition! > itemCenter) {
            newIndex = i;
          } else if (_draggedItemIndex! > i && _dragPosition! < itemCenter) {
            newIndex = i;
          }
        }
      }

      if (newIndex != _draggedItemIndex) {
        final item = _items.removeAt(_draggedItemIndex!);
        _items.insert(newIndex, item);

        _draggedItemIndex = newIndex;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _recordInitialPositions();
        });
      }
    });
  }

  // Handles the end of a drag operation
  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _draggedItemIndex = null;
      _dragPosition = null;
    });
  }

  double _getItemWidth(int index) {
    final key = _keys[index];
    if (key?.currentContext != null) {
      final RenderBox box =
          key?.currentContext!.findRenderObject() as RenderBox;
      return box.size.width;
    }
    return 64;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(mainAxisSize: MainAxisSize.min, children: _buildDockItems()),
    );
  }

  List<Widget> _buildDockItems() {
    return List.generate(_items.length, (index) {
      final item = _items[index];
      final isBeingDragged = _draggedItemIndex == index;

      // Builds the dock item with a scaled effect when dragged
      Widget dockItem = SizedBox(
        key: _keys[index],
        child: Transform.scale(
          scale: isBeingDragged ? 1.1 : 1.0,
          child: Opacity(
            opacity: isBeingDragged ? 0.8 : 1.0,
            child: widget.builder(item),
          ),
        ),
      );

      return GestureDetector(
        onPanStart: (details) => _onDragStart(index, details),
        onPanUpdate: (details) => _onDragUpdate(details),
        onPanEnd: (details) => _onDragEnd(details),
        child: dockItem,
      );
    });
  }
}
