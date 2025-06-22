// Flutter Prompt Picker Screen with filtering and randomizer

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class PromptPickerScreen extends StatefulWidget {
  const PromptPickerScreen({super.key});

  @override
  State<PromptPickerScreen> createState() => _PromptPickerScreenState();
}

class _PromptPickerScreenState extends State<PromptPickerScreen> {
  String? selectedTheme;
  final List<String> themes = [
    "All", "Childhood", "Family", "Love Life", "Career & Hustle",
    "Travel", "Food & Cooking", "Culture & Identity", "Milestones",
    "Sports & Play", "Life Lessons", "Friendship", "Dreams & Goals",
    "Holidays & Traditions", "Pets & Animals", "Faith & Beliefs",
    "Technology & Change", "Regrets & Forgiveness"
  ];

  Stream<QuerySnapshot> getPromptStream() {
    final collection = FirebaseFirestore.instance.collection('prompts');
    if (selectedTheme != null && selectedTheme != 'All') {
      return collection.where('theme', isEqualTo: selectedTheme).snapshots();
    }
    return collection.limit(100).snapshots();
  }

  void pickRandomPrompt(List<DocumentSnapshot> prompts) {
    final rand = Random();
    final randomPrompt = prompts[rand.nextInt(prompts.length)].data() as Map<String, dynamic>;
    Navigator.pushNamed(context, '/record', arguments: randomPrompt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Prompt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Pick Random',
            onPressed: () async {
              final snapshot = await FirebaseFirestore.instance.collection('prompts').get();
              if (snapshot.docs.isNotEmpty) {
                pickRandomPrompt(snapshot.docs);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedTheme ?? 'All',
              isExpanded: true,
              items: themes.map((theme) => DropdownMenuItem(
                value: theme,
                child: Text(theme),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  selectedTheme = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getPromptStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No prompts available'));
                }

                final prompts = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: prompts.length,
                  itemBuilder: (context, index) {
                    final prompt = prompts[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(prompt['prompt_text'] ?? 'Untitled'),
                      subtitle: Text(prompt['theme'] ?? 'No theme'),
                      onTap: () {
                        Navigator.pushNamed(context, '/record', arguments: prompt);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
