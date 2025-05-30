import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Rwanda'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCountryOverview(),
              const SizedBox(height: 24),
              _buildQuickFacts(context),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Geography',
                content:
                    'Rwanda is located in East Africa, bordered by Uganda to the north, Tanzania to the east, Burundi to the south, and the Democratic Republic of the Congo to the west. Despite being one of Africa\'s smallest countries, Rwanda features diverse landscapes, from mountains and volcanoes in the northwest to savanna in the east, with numerous lakes throughout the country.\n\nKnown as "The Land of a Thousand Hills," Rwanda\'s terrain is characterized by rolling hills and mountains, with elevations ranging from about 950m to 4,507m at Mount Karisimbi, the highest peak.',
                imageUrl: 'https://images.unsplash.com/photo-1579532042755-a9f15439d04b',
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Culture',
                content:
                    'Rwandan culture is rich and diverse, with traditions passed down through generations. Dance and music play important roles in ceremonies and celebrations, with the intore dance being particularly famous.\n\nRwandan society values community and collective responsibility, exemplified by practices like Umuganda (community work) and Gacaca (community justice).\n\nTraditional crafts include basket weaving (particularly the agaseke peace basket), pottery, woodcarving, and beadwork. These crafts not only preserve cultural heritage but also provide income for many artisans.',
                imageUrl: 'https://images.unsplash.com/photo-1591567462181-88b13c0f19cf',
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Wildlife',
                content:
                    'Rwanda is home to remarkable biodiversity, with its most famous residents being the endangered mountain gorillas in Volcanoes National Park. About one-third of the world\'s remaining mountain gorilla population lives in the Virunga Mountains.\n\nAkagera National Park hosts classic African savanna wildlife, including elephants, lions, leopards, giraffes, zebras, and numerous antelope species.\n\nNyungwe Forest National Park shelters 13 primate species, including chimpanzees and colobus monkeys, along with hundreds of bird species and over 1,000 plant varieties.',
                imageUrl: 'https://images.unsplash.com/photo-1564760055775-d63b17a55c44',
              ),
              const SizedBox(height: 24),
              _buildAboutApp(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: 'https://images.unsplash.com/photo-1580287917731-a0e92dd3bf9f',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Rwanda',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Rwanda is a landlocked country in East Africa known for its breathtaking landscapes, remarkable wildlife, and resilient people. Often called "The Land of a Thousand Hills," Rwanda has transformed itself into one of Africa\'s most stable and progressive nations.',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildQuickFacts(BuildContext context) {
    final facts = [
      {'icon': Icons.location_on, 'label': 'Capital', 'value': 'Kigali'},
      {'icon': Icons.people, 'label': 'Population', 'value': '13.2 million'},
      {'icon': Icons.language, 'label': 'Languages', 'value': 'Kinyarwanda, English, French, Swahili'},
      {'icon': Icons.attach_money, 'label': 'Currency', 'value': 'Rwandan Franc (RWF)'},
      {'icon': Icons.square_foot, 'label': 'Area', 'value': '26,338 km²'},
      {'icon': Icons.calendar_today, 'label': 'Independence', 'value': 'July 1, 1962'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Facts',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: facts.map((fact) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Icon(
                        fact['icon'] as IconData,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${fact['label']}: ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          fact['value'] as String,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required String imageUrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildAboutApp(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About This App',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Rwanda Fun Facts is designed to help you discover and learn interesting information about Rwanda. Browse through our collection of facts, or ask questions to learn more about this beautiful country.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This app uses Google\'s Gemini AI to generate informative responses to your questions about Rwanda.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Developed by Initiative Tech Solutions Ltd.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  label: const Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
