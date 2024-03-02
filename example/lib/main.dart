import 'package:flutter/material.dart';
import 'package:teamin_board/teamin_board.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const BoardExampleScreen(),
    );
  }
}

class BoardExampleScreen extends StatefulWidget {
  const BoardExampleScreen({super.key});

  @override
  State<BoardExampleScreen> createState() => _BoardExampleScreenState();
}

class _BoardExampleScreenState extends State<BoardExampleScreen> {
  late final _controller = BoardController(
    onColumnMoved: (from, to) {
      final list = _lists.removeAt(from);
      if (from < to) to--;
      _lists.insert(to, list);
      setState(() {});
    },
    // Uncomment this to test item to column mode.
    // onItemMovedToColumn: (from, toColumn) {
    //   _onItemMoved(from,
    //       ItemBoardPosition(columnIndex: toColumn, columnItemIndex: 0));
    // },
    onItemMoved: (from, to) => _onItemMoved(from, to),
  );

  final _lists = [
    for (var i = 0; i < 10; i++)
      (i, [for (var j = 0; j < _listItems; j++) j + i * _listItems]),
  ];
  static const _listItems = 21;
  static const _shortText = 'Mauris sed nunc a leo rhoncus ornare';
  static const _mediumText =
      'Maecenas eu felis cursus, maximus turpis nec, aliquam et molestie sapien augue';
  static const _largeText =
      'Cras eu lectus gravida, dapibus lorem ut, porttitor velit. Aenean convallis volutpat ligula, vel dignissim augue rhoncus elementum';

  void _onItemMoved(ItemBoardPosition from, ItemBoardPosition to) {
    final item = _lists[from.columnIndex].$2.removeAt(from.columnItemIndex);
    if (from.columnIndex == to.columnIndex &&
        from.columnItemIndex < to.columnItemIndex) {
      _lists[to.columnIndex].$2.insert(to.columnItemIndex - 1, item);
    } else {
      _lists[to.columnIndex].$2.insert(to.columnItemIndex, item);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Board example'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SafeArea(
          top: false,
          child: TeaminBoard(
            controller: _controller,
            boardConfig:
                const BoardConfig(showScrollThresholdDebugOverlay: false),
            start: const SizedBox(width: 8),
            end: const SizedBox(width: 8),
            columns: [
              for (final (key, items) in _lists)
                BoardColumn(
                  key: key,
                  columnDecorationBuilder: (context, column, isHovered) {
                    return Card(
                      elevation: isHovered ? 4 : 0,
                      margin: EdgeInsets.zero,
                      color: Colors.grey[200],
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8) +
                                  const EdgeInsets.all(4),
                              child: Text('Column $key',
                                  style:
                                      Theme.of(context).textTheme.titleSmall),
                            ),
                            Flexible(child: column),
                          ],
                        ),
                      ),
                    );
                  },
                  items: [
                    for (final item in items)
                      ColumnItem(
                        key: item,
                        builder: (context) {
                          return Card(
                            elevation: 0,
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  '$item ${item % 5 == 0 ? _shortText : (item.isOdd ? _largeText : _mediumText)}',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
