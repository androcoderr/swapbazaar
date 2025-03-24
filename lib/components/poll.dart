import 'package:flutter/material.dart';

class SimplePollWidget extends StatefulWidget {
  final String question;
  final List<String> options;

  const SimplePollWidget({
    Key? key,
    required this.question,
    required this.options,
  }) : super(key: key);

  @override
  _SimplePollWidgetState createState() => _SimplePollWidgetState();
}

class _SimplePollWidgetState extends State<SimplePollWidget> {
  late String _selectedOption; // Varsayılan olarak ilk seçenek seçilecek
  final Map<String, int> _votes = {};

  @override
  void initState() {
    super.initState();
    for (var option in widget.options) {
      _votes[option] = 0;
    }
    _selectedOption = widget.options.first; // İlk seçeneği varsayılan olarak ayarla
  }

  void _submitVote() {
    setState(() {
      _votes[_selectedOption] = (_votes[_selectedOption] ?? 0) + 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You selected: $_selectedOption'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  double _getPercentage(String option) {
    final totalVotes = _votes.values.fold<int>(0, (a, b) => a + b);
    if (totalVotes == 0) return 0.0;
    return (_votes[option]! / totalVotes) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.question,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: widget.options.map((option) {
                final percentage = _getPercentage(option);
                return RadioListTile<String>(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(option, style: const TextStyle(fontSize: 16)),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  value: option,
                  groupValue: _selectedOption,
                  onChanged: (value) {
                    setState(() {
                      _selectedOption = value!;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _submitVote,
                icon: const Icon(Icons.send),
                label: const Text('Submit'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
