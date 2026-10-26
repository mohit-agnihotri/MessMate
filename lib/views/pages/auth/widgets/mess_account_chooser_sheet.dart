import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Redesigned Executive Account Selector Sheet.
/// Matches the dark luxury Obsidian aesthetic for seamless account switching.
class MessAccountChooserSheet extends ConsumerWidget {
  final Function(String uid) onAccountSelected;
  final VoidCallback onAddAnotherAccount;

  const MessAccountChooserSheet({
    super.key,
    required this.onAccountSelected,
    required this.onAddAnotherAccount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1B1713),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF382F25), width: 1.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Drag Handle
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Green App Cutlery Emblem
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.restaurant_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title: Choose an account
            Text(
              'Choose an account',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFAF7F2),
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle: to continue to Mezzo
            Text(
              'to continue to Mezzo',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF9E9287),
              ),
            ),
            const SizedBox(height: 22),

            // Accounts List Card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF14110E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2E261E)),
              ),
              child: Column(
                children: [
                  if (currentUser != null) ...[
                    _buildAccountTile(
                      name: currentUser.displayName?.isNotEmpty == true
                          ? currentUser.displayName!
                          : 'Active Account',
                      email: currentUser.email ?? 'No email',
                      avatarUrl: currentUser.photoURL,
                      onTap: () {
                        Navigator.pop(context);
                        onAccountSelected(currentUser.uid);
                      },
                    ),
                    const Divider(color: Color(0xFF241C16), height: 1),
                  ],

                  // Add another account row
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onAddAnotherAccount();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF241D17),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF382F25)),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 18,
                              color: Color(0xFFFAF7F2),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Add another account',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFAF7F2),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: Color(0xFF7A7067),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile({
    required String name,
    required String email,
    required String? avatarUrl,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: const Color(0xFF382B1C),
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF59E0B),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFAF7F2),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF9E9287),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: Color(0xFF22C55E),
            ),
          ],
        ),
      ),
    );
  }
}
