import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import '../widgets/custom_modal.dart';
import '../widgets/global_overlay.dart';
import 'note_editor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, provider, _) {
        final notes = provider.allNotes;

        if (notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Premium empty state with gradient icon container
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.note_add_sharp,
                      size: 40,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No notes yet',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to create your first note',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return _PremiumNoteCard(note: note);
          },
        );
      },
    );
  }
}

// ─── Premium Note Card ───────────────────────────────────────────────────────

class _PremiumNoteCard extends StatelessWidget {
  final Note note;
  const _PremiumNoteCard({required this.note});

  Future<void> _openEditor(BuildContext context) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            GlobalOverlay(child: NoteEditorScreen(note: note)),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.03, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final title = note.title.isEmpty ? 'Untitled Note' : note.title;
    final result = await CustomConfirmDialog.show(
      context,
      title: 'Delete Note',
      message: 'Are you sure you want to delete "$title"?',
      confirmLabel: 'Delete',
      cancelLabel: 'Keep',
      isDangerous: true,
      confirmIcon: Icons.delete_outline,
    );

    if (result == true && context.mounted) {
      notesProvider.deleteNote(note.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note deleted'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(20, 8, 20, 80),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getContentPreview() => note.getFormattedPreview();

  @override
  Widget build(BuildContext context) {
    final title = note.title.isEmpty ? 'Untitled Note' : note.title;
    final hasMedia = note.mediaPaths.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tappable content area
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _openEditor(context),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 8, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with media badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                                color: Color(0xFF111827),
                                letterSpacing: -0.3,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasMedia) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF8B5CF6,
                                ).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.perm_media_rounded,
                                    size: 11,
                                    color: const Color(
                                      0xFF8B5CF6,
                                    ).withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${note.mediaPaths.length}',
                                    style: TextStyle(
                                      color: const Color(
                                        0xFF8B5CF6,
                                      ).withValues(alpha: 0.7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Content preview
                      const SizedBox(height: 8),
                      Text(
                        _getContentPreview(),
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Date & time footer
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(note.lastEdited),
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '·',
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${note.lastEdited.hour}:${note.lastEdited.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Quick actions — outside InkWell so taps aren't stolen
          Padding(
            padding: const EdgeInsets.only(top: 14, right: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFEF4444),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 17, color: color),
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: color.withValues(alpha: 0.06),
          hoverColor: color.withValues(alpha: 0.12),
          highlightColor: color.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
