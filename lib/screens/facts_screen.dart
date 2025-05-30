import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rwandafunfacts/models/fact.dart';
import 'package:rwandafunfacts/screens/ask_screen.dart';

class FactsScreen extends StatefulWidget {
  const FactsScreen({super.key});

  @override
  State<FactsScreen> createState() => _FactsScreenState();
}

class _FactsScreenState extends State<FactsScreen> {
  // Fact categories
  final List<String> _categories = [
    'All',
    'History',
    'Wildlife',
    'Culture',
    'Geography',
    'Tourism',
    'Food',
  ];

  String _selectedCategory = 'All';

  // Example facts (in a real app, this might come from a service or database)
  final List<RwandaFact> _allFacts = [
    RwandaFact(
      title: 'Land of a Thousand Hills',
      content: 'Rwanda is known as the Land of a Thousand Hills due to its beautiful mountainous terrain.',
      imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
      timestamp: DateTime(2023, 1, 1),
    ),
    RwandaFact(
      title: 'Mountain Gorillas',
      content: 'Rwanda is home to one-third of the world’s remaining mountain gorillas.',
      imageUrl: 'https://images.unsplash.com/photo-1464983953574-0892a716854b',
      timestamp: DateTime(2023, 2, 1),
    ),
    RwandaFact(
      title: 'Kigali',
      content: 'Kigali, the capital of Rwanda, is considered one of the cleanest cities in Africa.',
      imageUrl: 'https://images.unsplash.com/photo-1502086223501-7ea6ecd79368',
      timestamp: DateTime(2023, 3, 1),
    ),
    RwandaFact(
      title: 'Umuganda',
      content: 'Rwanda has a monthly community service day called Umuganda, where citizens clean and improve their neighborhoods.',
      imageUrl: null,
      timestamp: DateTime(2023, 4, 1),
    ),
    RwandaFact(
      title: 'Lake Kivu',
      content: 'Lake Kivu is one of Africa’s Great Lakes and a popular destination for tourists in Rwanda.',
      imageUrl: 'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429',
      timestamp: DateTime(2023, 5, 1),
    ),
  ];

  List<RwandaFact> get _facts {
    if (_selectedCategory == 'All') return _allFacts;
    // Example: filter by keyword in title for demo purposes
    return _allFacts.where((fact) => fact.title.toLowerCase().contains(_selectedCategory.toLowerCase())).toList();
  }

  Widget _buildFactCard(RwandaFact fact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fact.imageUrl != null)
            CachedNetworkImage(
              imageUrl: fact.imageUrl!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => const SizedBox(
                height: 180,
                child: Center(child: Icon(Icons.broken_image)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fact.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  fact.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: 	${fact.timestamp.toLocal().toString().split(' ')[0]}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rwanda Facts'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0, bottom: 16.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _facts.length,
        itemBuilder: (context, index) {
          final fact = _facts[index];
          return _buildFactCard(fact);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to AskScreen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AskScreen(),
            ),
          );
        },
        tooltip: 'Ask about Rwanda',
        child: const Icon(Icons.search),
      ),
    );
  }
}
