import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Users'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.accent));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No users yet.',
                  style: TextStyle(color: AppTheme.textSecondary)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final name = data['name'] as String? ?? 'Unknown';
              final email = data['email'] as String? ?? '';
              final isAdmin = data['isAdmin'] as bool? ?? false;
              final uid = docs[i].id;
              final initials = name.isNotEmpty
                  ? name.trim().split(' ')
                      .map((w) => w[0].toUpperCase()).take(2).join()
                  : '?';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? AppTheme.accent
                            : AppTheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(initials,
                            style: TextStyle(
                              color: isAdmin
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            )),
                      ),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700)),
                          Text(email,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ),

                    // Admin toggle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppTheme.accent.withOpacity(0.3)),
                            ),
                            child: const Text('ADMIN',
                                style: TextStyle(
                                    color: AppTheme.accent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800)),
                          ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _toggleAdmin(context, uid, isAdmin, name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isAdmin
                                  ? AppTheme.error.withOpacity(0.1)
                                  : AppTheme.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isAdmin
                                    ? AppTheme.error.withOpacity(0.3)
                                    : AppTheme.accent.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              isAdmin ? 'Remove Admin' : 'Make Admin',
                              style: TextStyle(
                                color: isAdmin
                                    ? AppTheme.error
                                    : AppTheme.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _toggleAdmin(
      BuildContext context, String uid, bool isAdmin, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isAdmin ? 'Remove admin?' : 'Make admin?',
          style: const TextStyle(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          isAdmin
              ? 'Remove admin privileges from $name?'
              : 'Grant admin privileges to $name?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({'isAdmin': !isAdmin});
            },
            child: Text(
              isAdmin ? 'Remove' : 'Grant',
              style: TextStyle(
                  color: isAdmin ? AppTheme.error : AppTheme.accent,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
