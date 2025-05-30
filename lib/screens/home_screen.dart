import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Rwanda Fun Facts'),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: 'https://images.unsplash.com/photo-1564760055775-d63b17a55c44',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 60,
                    child: AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          'Discover the Pearl of Africa',
                          textStyle: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          speed: const Duration(milliseconds: 100),
                        ),
                        TypewriterAnimatedText(
                          'Land of a Thousand Hills',
                          textStyle: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          speed: const Duration(milliseconds: 100),
                        ),
                        TypewriterAnimatedText(
                          'Home to Mountain Gorillas',
                          textStyle: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          speed: const Duration(milliseconds: 100),
                        ),
                      ],
                      repeatForever: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to Rwanda Fun Facts!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Explore fascinating facts about Rwanda, its culture, history, wildlife, and more. Use the navigation bar below to discover interesting facts or ask your own questions about Rwanda.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  _buildFeatureCard(
                    context,
                    Icons.menu_book,
                    'Browse Facts',
                    'Explore our collection of interesting Rwanda facts',
                    () {
                      // Navigate to Facts screen
                      DefaultTabController.of(context)?.animateTo(1);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    context,
                    Icons.question_answer,
                    'Ask Questions',
                    'Wonder about Rwanda? Ask our AI for detailed answers',
                    () {
                      // Navigate to Ask screen
                      DefaultTabController.of(context)?.animateTo(2);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    context,
                    Icons.info,
                    'About Rwanda',
                    'Learn more about this beautiful East African country',
                    () {
                      // Navigate to About screen
                      DefaultTabController.of(context)?.animateTo(3);
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildFactOfTheDay(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFactOfTheDay(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primary,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fact of the Day',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white54),
            const SizedBox(height: 8),
            const Text(
              'Rwanda is one of the cleanest countries in Africa, with a nationwide ban on plastic bags since 2008. Every last Saturday of each month, citizens participate in community service called "Umuganda" to clean and improve public spaces.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
