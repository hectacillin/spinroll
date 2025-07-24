import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

void main() {
  runApp(const LuckyWheelApp());
}

class LuckyWheelApp extends StatelessWidget {
  const LuckyWheelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lucky Wheel',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      home: const LuckyWheelHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LuckyWheelHomePage extends StatefulWidget {
  const LuckyWheelHomePage({super.key});

  @override
  State<LuckyWheelHomePage> createState() => _LuckyWheelHomePageState();
}

class _LuckyWheelHomePageState extends State<LuckyWheelHomePage>
    with TickerProviderStateMixin {
  late AnimationController _wheelController;
  late Animation<double> _wheelAnimation;
  
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _configNameController = TextEditingController();
  
  List<String> _wheelItems = [];
  List<Map<String, dynamic>> _savedConfigs = [];
  String? _selectedResult;
  bool _isSpinning = false;
  
  final List<Color> _wheelColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _wheelAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _wheelController,
      curve: Curves.decelerate,
    ));
    
    _loadSavedConfigs();
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _itemController.dispose();
    _configNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getStringList('saved_configs') ?? [];
    setState(() {
      _savedConfigs = configsJson
          .map((config) => Map<String, dynamic>.from(json.decode(config)))
          .toList();
    });
  }

  Future<void> _saveCurrentConfig() async {
    if (_wheelItems.isEmpty || _configNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter configuration name and at least one item!');
      return;
    }

    final config = {
      'name': _configNameController.text.trim(),
      'items': _wheelItems,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getStringList('saved_configs') ?? [];
    configsJson.add(json.encode(config));
    await prefs.setStringList('saved_configs', configsJson);

    _configNameController.clear();
    await _loadSavedConfigs();
    _showSnackBar('Configuration saved successfully!');
  }

  Future<void> _loadConfig(Map<String, dynamic> config) async {
    setState(() {
      _wheelItems = List<String>.from(config['items']);
      _selectedResult = null;
    });
    _showSnackBar('Loaded configuration: ${config['name']}');
  }

  Future<void> _deleteConfig(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getStringList('saved_configs') ?? [];
    configsJson.removeAt(index);
    await prefs.setStringList('saved_configs', configsJson);
    await _loadSavedConfigs();
    _showSnackBar('Configuration deleted!');
  }

  void _addItem() {
    if (_itemController.text.trim().isNotEmpty) {
      setState(() {
        _wheelItems.add(_itemController.text.trim());
        _itemController.clear();
        _selectedResult = null;
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _wheelItems.removeAt(index);
      _selectedResult = null;
    });
  }

  void _spinWheel() {
    if (_wheelItems.isEmpty) {
      _showSnackBar('Please add at least one item to spin!');
      return;
    }

    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _selectedResult = null;
    });

    final random = Random();
    final spins = 5 + random.nextDouble() * 5; // 5-10 vòng quay
    
    _wheelController.reset();
    _wheelAnimation = Tween<double>(
      begin: 0,
      end: spins,
    ).animate(CurvedAnimation(
      parent: _wheelController,
      curve: Curves.decelerate,
    ));

    _wheelController.forward().then((_) {
      final angle = (_wheelAnimation.value * 2 * pi) % (2 * pi);
      final pointerAngle = pi; // mũi tên ở góc 6 giờ
      double diff = (pointerAngle - angle) % (2 * pi);
      if (diff < 0) diff += 2 * pi;
      final selectedIndex = (diff / (2 * pi / _wheelItems.length)).floor() % _wheelItems.length;
      setState(() {
        _selectedResult = _wheelItems[selectedIndex];
        _isSpinning = false;
      });
      
      _showResultDialog(_selectedResult!);
    });
  }

  void _showResultDialog(String result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🎉 Result'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.celebration,
                size: 64,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              Text(
                result,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
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

  Widget _buildWheel() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _wheelAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _wheelAnimation.value * 2 * pi,
                child: CustomPaint(
                  size: const Size(280, 280),
                  painter: WheelPainter(_wheelItems, _wheelColors),
                ),
              );
            },
          ),
          // Pointer
          Positioned(
            bottom: 10,
            child: Container(
              width: 0,
              height: 0,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(width: 15, color: Colors.transparent),
                  right: BorderSide(width: 15, color: Colors.transparent),
                  top: BorderSide(width: 30, color: Colors.red),
                ),
              ),
            ),
          ),
          // Center circle
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildWheel(),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isSpinning ? null : _spinWheel,
            icon: _isSpinning 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_isSpinning ? 'Spinning...' : 'SPIN!'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (_selectedResult != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber),
              ),
              child: Column(
                children: [
                  const Text(
                    '🎉 Result:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedResult!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 30),
          _buildInputSection(),
          const SizedBox(height: 20),
          _buildItemsList(),
          const SizedBox(height: 20),
          _buildSavedConfigs(),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildWheel(),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _isSpinning ? null : _spinWheel,
                  icon: _isSpinning 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isSpinning ? 'Spinning...' : 'SPIN!'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_selectedResult != null) ...[
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🎉 Result:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedResult!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildInputSection(),
                  const SizedBox(height: 20),
                  _buildItemsList(),
                  const SizedBox(height: 20),
                  _buildSavedConfigs(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Item',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    decoration: const InputDecoration(
                      hintText: 'Enter item...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Save Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _configNameController,
                    decoration: const InputDecoration(
                      hintText: 'Configuration name...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _saveCurrentConfig,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items List (${_wheelItems.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_wheelItems.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No items yet.\nAdd items to get started!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _wheelItems.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _wheelColors[index % _wheelColors.length],
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(_wheelItems[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeItem(index),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedConfigs() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved Configurations (${_savedConfigs.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_savedConfigs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No saved configurations yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _savedConfigs.length,
                itemBuilder: (context, index) {
                  final config = _savedConfigs[index];
                  final itemCount = (config['items'] as List).length;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.settings, color: Colors.purple),
                      title: Text(config['name']),
                      subtitle: Text('$itemCount items'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.download, color: Colors.green),
                            onPressed: () => _loadConfig(config),
                            tooltip: 'Load configuration',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteConfig(index),
                            tooltip: 'Delete configuration',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lucky Wheel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.deepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _buildTabletLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<String> items;
  final List<Color> colors;

  WheelPainter(this.items, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = 2 * pi / items.length;

    for (int i = 0; i < items.length; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      final startAngle = i * sweepAngle - pi / 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      // Draw text
      final textAngle = startAngle + sweepAngle / 2;
      final textRadius = radius * 0.7;
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);

      final textSpan = TextSpan(
        text: items[i],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black54,
            ),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();

      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + pi / 2);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
