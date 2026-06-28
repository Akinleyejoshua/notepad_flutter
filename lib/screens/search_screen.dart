import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/note_provider.dart';
import 'note_editor_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Premium search input
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: (value) {
                Provider.of<NotesProvider>(context, listen: false)
                    .setSearchQuery(value);
                setState(() {}); // Refresh to show/hide clear button
              },
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF111111),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search your notes...',
                hintStyle: const TextStyle(
                  color: Color(0xFFBBBBBB),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(Icons.search_rounded,
                      color: Color(0xFF9CA3AF), size: 22),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          Provider.of<NotesProvider>(context, listen: false)
                              .setSearchQuery('');
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE5E7EB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Color(0xFF6B7280), size: 14),
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ),

        // Search results
        Expanded(
          child: Consumer<NotesProvider>(
            builder: (context, provider, _) {
              final results = provider.filteredNotes;

              // Initial state — no query yet
              if (_searchController.text.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.search_rounded,
                            size: 30, color: Colors.grey.shade300),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Type to search your notes',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // No results
              if (results.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.search_off_rounded,
                            size: 30, color: Color(0xFFFCA5A5)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No matching notes found',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Results list
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final note = results[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => NoteEditorScreen(note: note)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          child: Row(
                            children: [
                              // Accent dot
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF111111),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note.title.isEmpty
                                          ? 'Untitled Note'
                                          : note.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Color(0xFF111111),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${note.lastEdited.hour}:${note.lastEdited.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}