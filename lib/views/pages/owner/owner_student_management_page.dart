import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/app_models.dart';
import '../../../services/localization_service.dart';
import '../../../viewmodels/all_viewmodels.dart';
import 'theme/owner_inspired_theme.dart';
import 'widgets/owner_drawer.dart';

class OwnerStudentManagementPage extends ConsumerStatefulWidget {
  const OwnerStudentManagementPage({super.key});

  void showStudentDetailsModal(
    BuildContext context,
    WidgetRef ref,
    StudentModel student,
    String joined,
  ) {
    _OwnerStudentManagementPageState().showStudentDetailsModal(
      context,
      ref,
      student,
      joined,
    );
  }

  static void showStudentDetails(
    BuildContext context,
    WidgetRef ref,
    StudentModel student,
    String joined,
  ) {
    _OwnerStudentManagementPageState().showStudentDetailsModal(
      context,
      ref,
      student,
      joined,
    );
  }

  @override
  ConsumerState<OwnerStudentManagementPage> createState() =>
      _OwnerStudentManagementPageState();
}

class _OwnerStudentManagementPageState
    extends ConsumerState<OwnerStudentManagementPage> {
  int _selectedFilterIndex = 0; // 0: All, 1: Active, 2: Pending, 3: Inactive / Dues
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, Future<Map<String, dynamic>>> _billingDataCache = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ownerStudentsProvider);
    final isHi = ref.watch(localizationProvider) == 'hi';
    final mess = ref.watch(ownerDashboardProvider).mess;
    final messName = mess?.name ?? 'Mahakal';

    // Partition students
    final activeStudents = state.students
        .where((s) => s.status == 'active' || s.status == 'approved')
        .toList();
    final pendingStudents = state.pending;
    final inactiveStudents = state.students
        .where((s) => s.status != 'active' && s.status != 'approved')
        .toList();

    List<StudentModel> baseList;
    switch (_selectedFilterIndex) {
      case 1:
        baseList = activeStudents;
        break;
      case 2:
        baseList = pendingStudents;
        break;
      case 3:
        baseList = inactiveStudents;
        break;
      case 0:
      default:
        baseList = [...activeStudents, ...pendingStudents];
        break;
    }

    // Apply search filter
    final displayedStudents = _searchQuery.isEmpty
        ? baseList
        : baseList.where((s) {
            return s.name.toLowerCase().contains(_searchQuery) ||
                s.roomNo.toLowerCase().contains(_searchQuery) ||
                s.phone.contains(_searchQuery);
          }).toList();

    return Scaffold(
      backgroundColor: OwnerColors.canvasWarm,
      endDrawer: const OwnerDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context, messName, isHi),
                Expanded(
                  child: state.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: OwnerColors.sageGreen,
                          ),
                        )
                      : RefreshIndicator(
                          color: OwnerColors.sageGreen,
                          backgroundColor: OwnerColors.surfaceLight,
                          onRefresh: () async {
                            ref.invalidate(ownerStudentsProvider);
                          },
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                            children: [
                              _buildHeroMessCodeCard(state),
                              const SizedBox(height: 16),
                              _buildFilterPills(
                                allCount: activeStudents.length + pendingStudents.length,
                                activeCount: activeStudents.length,
                                pendingCount: pendingStudents.length,
                                inactiveCount: inactiveStudents.length,
                                isHi: isHi,
                              ),
                              const SizedBox(height: 14),
                              _buildSearchBar(isHi),
                              const SizedBox(height: 16),
                              if (displayedStudents.isEmpty)
                                _buildEmptyState(isHi)
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: displayedStudents.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (ctx, i) {
                                    return _buildStudentCard(
                                      ctx,
                                      displayedStudents[i],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),

            // Floating Bottom Button: "Invite a student" (Screenshot 4)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _showInviteDialog(context, state.messCode),
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  label: Text(
                    isHi ? 'विद्यार्थी जोड़ें' : 'Invite a student',
                    style: OwnerTypography.bold(size: 15, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OwnerColors.sageGreen,
                    elevation: 4,
                    shadowColor: OwnerColors.sageGreen.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top Header (Screenshot 4) ─────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String messName, bool isHi) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      decoration: const BoxDecoration(
        color: OwnerColors.canvasWarm,
        border: Border(
          bottom: BorderSide(color: OwnerColors.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'REGISTERED DINERS',
                style: OwnerTypography.overline(color: OwnerColors.walnutMuted),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Scaffold.of(context).openEndDrawer(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: OwnerColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: OwnerColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$messName · Settings',
                        style: OwnerTypography.regular(
                          size: 12,
                          color: OwnerColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.settings_outlined,
                        size: 14,
                        color: OwnerColors.walnutMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (Navigator.canPop(context)) ...[
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: OwnerColors.walnutDark,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                isHi ? 'विद्यार्थी' : 'People',
                style: OwnerTypography.editorialSerif(
                  size: 28,
                  weight: FontWeight.w700,
                  color: OwnerColors.walnutDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Hero Mess Code Card (Screenshot 4) ────────────────────────────────────
  Widget _buildHeroMessCodeCard(OwnerStudentsState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OwnerColors.walnutDark,
        borderRadius: BorderRadius.circular(22),
        boxShadow: OwnerShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MESS JOIN CODE',
                style: OwnerTypography.overline(
                  color: OwnerColors.amberGlow,
                ),
              ),
              Row(
                children: [
                  // Copy pill
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: state.messCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Mess code ${state.messCode} copied!'),
                          backgroundColor: OwnerColors.walnutDark,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.copy_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Copy',
                            style: OwnerTypography.bold(
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Refresh pill
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => ref
                        .read(ownerStudentsProvider.notifier)
                        .regenerateCode(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.refresh_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Refresh',
                            style: OwnerTypography.bold(
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            state.messCode.isNotEmpty ? state.messCode : 'MK-4892',
            style: OwnerTypography.editorialSerif(
              size: 32,
              weight: FontWeight.w700,
              color: OwnerColors.amberGlow,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Students use this code in Mezzo to request admission.',
            style: OwnerTypography.regular(
              size: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter Pills Row (Screenshot 4) ───────────────────────────────────────
  Widget _buildFilterPills({
    required int allCount,
    required int activeCount,
    required int pendingCount,
    required int inactiveCount,
    required bool isHi,
  }) {
    final filters = [
      {'label': isHi ? 'सभी' : 'All', 'count': allCount},
      {'label': isHi ? 'सक्रिय' : 'Active', 'count': activeCount},
      {'label': isHi ? 'अनुरोध' : 'Pending', 'count': pendingCount},
      {'label': isHi ? 'निष्क्रिय' : 'Inactive', 'count': inactiveCount},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          final f = filters[index];
          final isPending = index == 2 && pendingCount > 0;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _selectedFilterIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? OwnerColors.walnutDark
                      : OwnerColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? OwnerColors.walnutDark
                        : OwnerColors.borderSubtle,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${f['label']} (${f['count']})',
                      style: OwnerTypography.bold(
                        size: 12,
                        color: isSelected
                            ? OwnerColors.textLight
                            : OwnerColors.textSecondary,
                      ),
                    ),
                    if (isPending && !isSelected) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: OwnerColors.amberGlow,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Search Bar (Screenshot 4) ─────────────────────────────────────────────
  Widget _buildSearchBar(bool isHi) {
    return Container(
      decoration: BoxDecoration(
        color: OwnerColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OwnerColors.borderSubtle),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 18,
            color: OwnerColors.walnutMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: OwnerTypography.regular(
                size: 13,
                color: OwnerColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: isHi
                    ? 'नाम, कमरा या फोन नंबर से खोजें...'
                    : 'Search by name, room, or phone...',
                hintStyle: OwnerTypography.regular(
                  size: 13,
                  color: OwnerColors.walnutMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () => _searchController.clear(),
              child: const Icon(
                Icons.cancel,
                size: 16,
                color: OwnerColors.walnutMuted,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Student Card (Screenshot 4) ───────────────────────────────────────────
  Widget _buildStudentCard(BuildContext context, StudentModel student) {
    final isPending = student.status == 'pending';
    final isActive = student.status == 'active' || student.status == 'approved';

    final joined =
        '${_getMonthName(student.joinDate.month)} ${student.joinDate.day}, ${student.joinDate.year}';

    return GestureDetector(
      onTap: () {
        if (!isPending) {
          showStudentDetailsModal(context, ref, student, joined);
        } else {
          _showAcceptStudentDialog(context, ref, student);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: OwnerColors.surfaceLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: OwnerColors.borderSubtle),
          boxShadow: OwnerShadows.card,
        ),
        child: Row(
          children: [
            // Avatar circle in warm amber
            CircleAvatar(
              radius: 22,
              backgroundColor: OwnerColors.amberGlow.withValues(alpha: 0.18),
              child: Text(
                student.name.isNotEmpty
                    ? student.name[0].toUpperCase()
                    : 'S',
                style: OwnerTypography.editorialSerif(
                  size: 18,
                  weight: FontWeight.w700,
                  color: OwnerColors.walnutDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          student.name,
                          overflow: TextOverflow.ellipsis,
                          style: OwnerTypography.bold(
                            size: 15,
                            color: OwnerColors.textPrimary,
                          ),
                        ),
                      ),
                      if (student.dietaryPreference.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: student.dietaryPreference.toLowerCase() == 'veg'
                                ? OwnerColors.sageLight
                                : OwnerColors.amberLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            student.dietaryPreference.toUpperCase(),
                            style: OwnerTypography.bold(
                              size: 9,
                              color: student.dietaryPreference.toLowerCase() == 'veg'
                                  ? OwnerColors.sageDark
                                  : OwnerColors.amberDark,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Room ${student.roomNo.isNotEmpty ? student.roomNo : 'N/A'} · Joined $joined',
                    style: OwnerTypography.regular(
                      size: 12,
                      color: OwnerColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Status or Quick Action
            if (isPending) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Accept button
                  GestureDetector(
                    onTap: () =>
                        _showAcceptStudentDialog(context, ref, student),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: OwnerColors.sageLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: OwnerColors.sageDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Reject button
                  GestureDetector(
                    onTap: () => ref
                        .read(ownerStudentsProvider.notifier)
                        .reject(student.studentId),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? OwnerColors.sageLight
                      : OwnerColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: OwnerTypography.bold(
                    size: 11,
                    color: isActive
                        ? OwnerColors.sageDark
                        : OwnerColors.walnutMuted,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: OwnerColors.walnutMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState(bool isHi) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: OwnerColors.surfaceWarm,
              shape: BoxShape.circle,
              border: Border.all(color: OwnerColors.borderSubtle),
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 32,
              color: OwnerColors.walnutMuted,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isHi ? 'कोई विद्यार्थी नहीं मिला' : 'No students found',
            style: OwnerTypography.editorialSerif(
              size: 18,
              weight: FontWeight.w700,
              color: OwnerColors.walnutDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isHi
                ? 'नया विद्यार्थी जोड़ने के लिए अपना मेस कोड शेयर करें।'
                : 'Share your mess join code to register diners.',
            textAlign: TextAlign.center,
            style: OwnerTypography.regular(
              size: 12,
              color: OwnerColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Invite Dialog ─────────────────────────────────────────────────────────
  void _showInviteDialog(BuildContext context, String messCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OwnerColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Invite Diners',
          style: OwnerTypography.editorialSerif(
            size: 20,
            weight: FontWeight.w700,
            color: OwnerColors.walnutDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share this code with your students to let them join your mess instantly:',
              style: OwnerTypography.regular(
                size: 13,
                color: OwnerColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: OwnerColors.walnutDark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    messCode.isNotEmpty ? messCode : 'MK-4892',
                    style: OwnerTypography.editorialSerif(
                      size: 26,
                      weight: FontWeight.w700,
                      color: OwnerColors.amberGlow,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: messCode));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Mess code copied!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Done',
              style: OwnerTypography.bold(
                size: 14,
                color: OwnerColors.sageGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Student Details Modal (Screenshot 14) ─────────────────────────────────
  void showStudentDetailsModal(
    BuildContext context,
    WidgetRef ref,
    StudentModel student,
    String joined,
  ) {
    _billingDataCache.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        DateTime selectedMonthDate = DateTime.now();

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: ScaffoldMessenger(
            child: Builder(
              builder: (innerContext) {
                return Scaffold(
                  backgroundColor: Colors.transparent,
                  body: StatefulBuilder(
                    builder: (modalCtx, setModalState) {
                      return Container(
                        decoration: const BoxDecoration(
                          color: OwnerColors.canvasWarm,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(26)),
                        ),
                        child: Column(
                          children: [
                            // Drag Handle
                            Center(
                              child: Container(
                                margin:
                                    const EdgeInsets.only(top: 12, bottom: 8),
                                width: 44,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: OwnerColors.walnutMuted
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Profile Header
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: OwnerColors.amberGlow
                                              .withValues(alpha: 0.18),
                                          child: Text(
                                            student.name.isNotEmpty
                                                ? student.name[0].toUpperCase()
                                                : 'S',
                                            style:
                                                OwnerTypography.editorialSerif(
                                              size: 24,
                                              weight: FontWeight.w700,
                                              color: OwnerColors.walnutDark,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                student.name,
                                                style: OwnerTypography
                                                    .editorialSerif(
                                                  size: 20,
                                                  weight: FontWeight.w700,
                                                  color: OwnerColors.walnutDark,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'ID: ${student.studentId.length > 8 ? student.studentId.substring(0, 8) : student.studentId} • Room ${student.roomNo}',
                                                style: OwnerTypography.regular(
                                                  size: 12,
                                                  color: OwnerColors.textSecondary,
                                                ),
                                              ),
                                              Text(
                                                'Joined: $joined',
                                                style: OwnerTypography.regular(
                                                  size: 12,
                                                  color: OwnerColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Phone Call Button
                                        GestureDetector(
                                          onTap: () async {
                                            final cleanPhone = student.phone.replaceAll(RegExp(r'\D'), '');
                                            final url = Uri.parse('tel:$cleanPhone');
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(url);
                                            } else {
                                              if (innerContext.mounted) {
                                                ScaffoldMessenger.of(innerContext)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Could not launch dialer'),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: OwnerColors.surfaceWarm,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: OwnerColors.borderSubtle),
                                            ),
                                            child: const Icon(
                                              Icons.phone_outlined,
                                              size: 20,
                                              color: OwnerColors.walnutDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // 3 Attendance Summary Cards (Screenshot 14)
                                    _buildAttendanceSummary(
                                      innerContext,
                                      ref,
                                      student,
                                      selectedMonthDate,
                                      (newDate) {
                                        setModalState(() {
                                          selectedMonthDate = newDate;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 24),

                                    // Billing Summary
                                    Text(
                                      'Billing Summary',
                                      style: OwnerTypography.editorialSerif(
                                        size: 18,
                                        weight: FontWeight.w700,
                                        color: OwnerColors.walnutDark,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildBillingSummary(
                                      innerContext,
                                      ref,
                                      student,
                                      selectedMonthDate,
                                    ),
                                    const SizedBox(height: 24),

                                    // Extra Fees Section
                                    _buildExtraFeesSection(
                                      innerContext,
                                      ref,
                                      student,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ─── Attendance Summary & Interactive Calendar (Screenshot 14) ────────────
  Widget _buildAttendanceSummary(
    BuildContext context,
    WidgetRef ref,
    StudentModel student,
    DateTime selectedMonthDate,
    void Function(DateTime) onMonthChanged,
  ) {
    return FutureBuilder<List<MealRecordModel>>(
      future: ref.read(appServiceProvider).getMealRecords(
            student.studentId,
            selectedMonthDate.month,
            selectedMonthDate.year,
            messId: student.messId,
          ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: OwnerColors.sageGreen),
            ),
          );
        }
        final records = snapshot.data!;
        final selfOff = records.where((r) => r.status == 'absent_self').length;
        final ownerOff = records.where((r) => r.status == 'absent_owner').length;

        final selfSlots = records
            .where((r) => r.status == 'absent_self')
            .map((r) => '${r.date.toIso8601String().substring(0, 10)}_${r.mealSlot}')
            .toSet();
        final ownerSlots = records
            .where((r) => r.status == 'absent_owner')
            .map((r) => '${r.date.toIso8601String().substring(0, 10)}_${r.mealSlot}')
            .toSet();

        final uniqueSlots = {...selfSlots, ...ownerSlots};
        final totalOff = uniqueSlots.length;

        final totalOffList = <MealRecordModel>[];
        for (final slotKey in uniqueSlots) {
          try {
            final match = records.firstWhere((r) =>
                (r.status == 'absent_self' || r.status == 'absent_owner') &&
                ('${r.date.toIso8601String().substring(0, 10)}_${r.mealSlot}' ==
                    slotKey));
            totalOffList.add(match);
          } catch (_) {}
        }
        totalOffList.sort((a, b) {
          final d = a.date.compareTo(b.date);
          return d != 0 ? d : a.mealSlot.compareTo(b.mealSlot);
        });

        return Column(
          children: [
            Row(
              children: [
                _buildSummaryCard(
                  context,
                  'Total Meals Off',
                  '$totalOff',
                  const Color(0xFFEF4444),
                  totalOffList,
                  selfSlots: selfSlots,
                  ownerSlots: ownerSlots,
                ),
                const SizedBox(width: 8),
                _buildSummaryCard(
                  context,
                  'Off by Student',
                  '$selfOff',
                  OwnerColors.amberGlow,
                  records.where((r) => r.status == 'absent_self').toList(),
                ),
                const SizedBox(width: 8),
                _buildSummaryCard(
                  context,
                  'Off by Mess',
                  '$ownerOff',
                  OwnerColors.walnutDark,
                  records.where((r) => r.status == 'absent_owner').toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInteractiveCalendar(
              context,
              records,
              selectedMonthDate,
              () {
                onMonthChanged(DateTime(
                  selectedMonthDate.year,
                  selectedMonthDate.month - 1,
                  1,
                ));
              },
              () {
                onMonthChanged(DateTime(
                  selectedMonthDate.year,
                  selectedMonthDate.month + 1,
                  1,
                ));
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    Color accentColor,
    List<MealRecordModel> offRecords, {
    Set<String>? selfSlots,
    Set<String>? ownerSlots,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showOffDetailsDialog(
          context,
          title,
          offRecords,
          selfSlots: selfSlots,
          ownerSlots: ownerSlots,
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: OwnerColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: OwnerColors.borderSubtle, width: 1),
            boxShadow: OwnerShadows.card,
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(color: accentColor),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: OwnerTypography.editorialSerif(
                  size: 24,
                  weight: FontWeight.w700,
                  color: OwnerColors.walnutDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: OwnerTypography.regular(
                  size: 10,
                  color: OwnerColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Details',
                  style: OwnerTypography.bold(
                    size: 9,
                    color: OwnerColors.sageGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
),
);
  }

  Widget _buildInteractiveCalendar(
    BuildContext context,
    List<MealRecordModel> records,
    DateTime selectedMonthDate,
    VoidCallback onPreviousMonth,
    VoidCallback onNextMonth,
  ) {
    final now = selectedMonthDate;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 for Sunday

    final days = <Widget>[];
    const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    for (var w in weekDays) {
      days.add(
        Center(
          child: Text(
            w,
            style: OwnerTypography.bold(
              size: 11,
              color: OwnerColors.walnutMuted,
            ),
          ),
        ),
      );
    }

    for (int i = 0; i < firstWeekday; i++) {
      days.add(const SizedBox());
    }

    for (int i = 1; i <= daysInMonth; i++) {
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${i.toString().padLeft(2, '0')}';
      final dayRecords = records
          .where(
            (r) =>
                '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}' ==
                dateStr,
          )
          .toList();
      final offRecords = dayRecords
          .where((r) => r.status == 'absent_self' || r.status == 'absent_owner')
          .toList();

      final isOff = offRecords.isNotEmpty;

      days.add(
        GestureDetector(
          onTap: isOff
              ? () => _showOffDetailsDialog(
                    context,
                    'Absents on $i ${_getMonthName(now.month)}',
                    offRecords,
                  )
              : null,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: isOff
                  ? BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    )
                  : null,
              alignment: Alignment.center,
              child: Text(
                '$i',
                style: OwnerTypography.regular(
                  size: 13,
                  color: isOff ? Colors.red : OwnerColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OwnerColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OwnerColors.borderSubtle),
        boxShadow: OwnerShadows.card,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: onPreviousMonth,
                icon: const Icon(
                  Icons.chevron_left,
                  color: OwnerColors.walnutDark,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                '${_getMonthName(now.month)} ${now.year}',
                style: OwnerTypography.bold(
                  size: 15,
                  color: OwnerColors.walnutDark,
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(
                  Icons.chevron_right,
                  color: OwnerColors.walnutDark,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: days,
          ),
        ],
      ),
    );
  }

  void _showOffDetailsDialog(
    BuildContext context,
    String title,
    List<MealRecordModel> offRecords, {
    Set<String>? selfSlots,
    Set<String>? ownerSlots,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OwnerColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          title,
          style: OwnerTypography.bold(size: 16, color: OwnerColors.walnutDark),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: offRecords.isEmpty
              ? Text(
                  'No records found.',
                  style: OwnerTypography.regular(
                    size: 13,
                    color: OwnerColors.walnutMuted,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: offRecords.length,
                  itemBuilder: (ctx, i) {
                    final r = offRecords[i];
                    final date = r.date;
                    final slotKey =
                        '${r.date.toIso8601String().substring(0, 10)}_${r.mealSlot}';
                    final capSlot =
                        '${r.mealSlot[0].toUpperCase()}${r.mealSlot.substring(1)}';
                    String label;
                    if (selfSlots != null &&
                        ownerSlots != null &&
                        selfSlots.contains(slotKey) &&
                        ownerSlots.contains(slotKey)) {
                      label = 'Student + Mess Both Off';
                    } else if (selfSlots != null && selfSlots.contains(slotKey)) {
                      label = 'Student Cancelled';
                    } else if (ownerSlots != null &&
                        ownerSlots.contains(slotKey)) {
                      label = 'Mess Closed';
                    } else {
                      label = r.status == 'absent_self'
                          ? 'Student Cancelled'
                          : 'Mess Closed';
                    }

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.event_busy,
                        color: Colors.red,
                        size: 20,
                      ),
                      title: Text(
                        '${date.day} ${_getMonthName(date.month)} ${date.year}',
                        style: OwnerTypography.bold(size: 13),
                      ),
                      subtitle: Text(
                        '$capSlot ($label)',
                        style: OwnerTypography.regular(
                          size: 11,
                          color: label.contains('Both')
                              ? Colors.red
                              : OwnerColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: OwnerTypography.bold(
                size: 13,
                color: OwnerColors.sageGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Billing Summary (Screenshot 14) ───────────────────────────────────────
  Future<Map<String, dynamic>> _fetchBillingData(
    WidgetRef ref,
    StudentModel student,
    DateTime selectedMonthDate,
  ) async {
    final service = ref.read(appServiceProvider);
    final now = selectedMonthDate;

    BillModel? bill;
    try {
      bill = await service.getBill(student.studentId, now.month, now.year);
    } catch (e) {
      debugPrint('[BillingData] getBill error: $e');
    }

    final mess = await service.getMessById(student.messId);
    if (mess == null) throw Exception("Mess not found");

    MealPlanModel? plan;
    if (student.assignedPlanId != null && student.assignedPlanId!.isNotEmpty) {
      try {
        plan = await service.getMealPlanById(student.messId, student.assignedPlanId!);
      } catch (e) {
        debugPrint('[BillingData] getMealPlanById error: $e');
      }
    }

    List<MealRecordModel> records = [];
    try {
      records = await service.getMealRecords(
        student.studentId,
        now.month,
        now.year,
        messId: student.messId,
      );
    } catch (e) {
      debugPrint('[BillingData] getMealRecords error: $e');
    }

    double previousDues = 0.0;
    try {
      previousDues = await service.getPreviousUnpaidDues(
        student.studentId,
        now.month,
        now.year,
        messId: student.messId,
      );
    } catch (e) {
      debugPrint('[BillingData] getPreviousUnpaidDues error: $e');
    }

    List<ExtraFeeModel> extraFees = [];
    try {
      extraFees = await service.getExtraFees(student.messId, student.studentId);
    } catch (e) {
      debugPrint('[BillingData] getExtraFees error: $e');
    }

    List<LeaveModel> leaves = [];
    try {
      leaves = await service.getStudentLeaves(
        student.studentId,
        messId: student.messId,
      );
    } catch (e) {
      debugPrint('[BillingData] getStudentLeaves error: $e');
    }

    CarryForwardResult carryForward = const CarryForwardResult();
    try {
      carryForward = await calculateCarryForwardCredit(
        studentId: student.studentId,
        currentMonth: now.month,
        currentYear: now.year,
        service: service,
        mess: mess,
        plan: plan,
      );
    } catch (e) {
      debugPrint('[BillingData] calculateCarryForwardCredit error: $e');
    }

    return {
      'bill': bill,
      'mess': mess,
      'plan': plan,
      'records': records,
      'previousDues': previousDues,
      'extraFees': extraFees,
      'leaves': leaves,
      'carryForward': carryForward,
      'month': now.month,
      'year': now.year,
    };
  }

  Widget _buildBillingSummary(
    BuildContext context,
    WidgetRef ref,
    StudentModel student,
    DateTime selectedMonthDate,
  ) {
    String? localCompensationChoice;
    bool? localIsPaidOverride;
    final cacheKey =
        '${student.studentId}_${selectedMonthDate.year}_${selectedMonthDate.month}';

    return FutureBuilder<Map<String, dynamic>>(
      future: _billingDataCache.putIfAbsent(
        cacheKey,
        () => _fetchBillingData(ref, student, selectedMonthDate),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading billing',
              style: OwnerTypography.regular(size: 12, color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: CircularProgressIndicator(color: OwnerColors.sageGreen),
            ),
          );
        }

        final data = snapshot.data!;
        final BillModel? savedBill = data['bill'];
        final MessModel mess = data['mess'];
        final MealPlanModel? plan = data['plan'];
        final List<MealRecordModel> records = data['records'];
        final List<ExtraFeeModel> extraFees =
            (data['extraFees'] as List<ExtraFeeModel>?) ?? const [];
        final List<LeaveModel> leaves =
            (data['leaves'] as List<LeaveModel>?) ?? const [];
        final CarryForwardResult carryForward =
            data['carryForward'] as CarryForwardResult? ??
                const CarryForwardResult();

        // Calculate live current month skips directly from latest records
        final liveSkips = calculateCurrentMonthSkipsSummary(
          records: records,
          leaves: leaves,
          student: student,
          mess: mess,
          plan: plan,
          month: data['month'],
          year: data['year'],
        );

        return StatefulBuilder(
          builder: (context, setLocalState) {
            final effectiveCompensationChoice = localCompensationChoice ??
                ((savedBill?.daysToExtend ?? 0) > 0 ? 'extend' : 'rebate');

            final generatedBill = generateAdvancedBill(
              student: student,
              mess: mess,
              plan: plan,
              month: data['month'],
              year: data['year'],
              records: records,
              previousDues: data['previousDues'],
              compensationChoice: effectiveCompensationChoice,
              extraFees: extraFees,
              leaves: leaves,
              carryForwardResult: carryForward,
              carryForwardCredit: carryForward.amount,
              carryForwardItems: carryForward.items,
            );

            // Always reflect real-time attendance skips dynamically even on saved bills
            final bill = savedBill != null
                ? savedBill.copyWith(
                    currentMonthSkipsCount: liveSkips.count,
                    currentMonthSkipsAmount: liveSkips.amount,
                  )
                : generatedBill;

            bool localIsPaid = localIsPaidOverride ?? bill.isPaid;
            final int effectiveCurrentSkips = bill.currentMonthSkipsCount;
            final double effectiveCurrentAmount = bill.currentMonthSkipsAmount;
            final int priorValidSkips = bill.validSkipsRewarded;
            final int allowedMeals =
                plan != null ? plan.mealsIncludedPerDay : mess.mealsIncludedPerDay;

            final int potentialCurrentExtendDays =
                (allowedMeals > 0) ? (effectiveCurrentSkips ~/ allowedMeals) : 0;
            final int extendDays = bill.daysToExtend > 0
                ? bill.daysToExtend
                : potentialCurrentExtendDays;

            final int displaySkipsCount =
                priorValidSkips > 0 ? priorValidSkips : effectiveCurrentSkips;

            final int coveredSkips = bill.daysToExtend * allowedMeals;
            final int remainderSkips = bill.currentMonthSkipsCount > coveredSkips
                ? (bill.currentMonthSkipsCount - coveredSkips)
                : 0;
            final double ratePerSkip = bill.currentMonthSkipsCount > 0
                ? (bill.currentMonthSkipsAmount / bill.currentMonthSkipsCount)
                : 0.0;
            final int remainderAmount = (remainderSkips * ratePerSkip).round();

            final int potentialCoveredSkips = potentialCurrentExtendDays * allowedMeals;
            final int potentialRemainderSkips = displaySkipsCount > potentialCoveredSkips
                ? (displaySkipsCount - potentialCoveredSkips)
                : 0;
            final double potentialRatePerSkip = displaySkipsCount > 0
                ? (effectiveCurrentAmount / displaySkipsCount)
                : 0.0;
            final int potentialRemainderAmount =
                (potentialRemainderSkips * potentialRatePerSkip).round();

            final int bYear = data['year'];
            final int bMonth = data['month'];
            final DateTime defaultMonthEnd = DateTime(bYear, bMonth + 1, 0);
            final DateTime baseEndDate = (student.subscriptionEndDate != null &&
                    student.subscriptionEndDate!.isAfter(DateTime(bYear, bMonth, 1)))
                ? student.subscriptionEndDate!
                : defaultMonthEnd;

            String extendDateString = '';
            if (extendDays > 0) {
              DateTime newEndDate =
                  baseEndDate.add(Duration(days: extendDays));
              const abbr = [
                'Jan',
                'Feb',
                'Mar',
                'Apr',
                'May',
                'Jun',
                'Jul',
                'Aug',
                'Sep',
                'Oct',
                'Nov',
                'Dec'
              ];
              String monthStr = (newEndDate.month >= 1 && newEndDate.month <= 12)
                  ? abbr[newEndDate.month - 1]
                  : '';
              extendDateString = "${newEndDate.day} $monthStr ${newEndDate.year}";
            } else if (student.subscriptionEndDate != null) {
              const abbr = [
                'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
              ];
              extendDateString =
                  "${student.subscriptionEndDate!.day} ${abbr[student.subscriptionEndDate!.month - 1]} ${student.subscriptionEndDate!.year}";
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OwnerColors.surfaceLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: OwnerColors.borderSubtle),
                boxShadow: OwnerShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bill.daysToExtend > 0) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF5EC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCCE0C8)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.event_available_rounded,
                            size: 16,
                            color: Color(0xFF3F653E),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📅 Month extended by ${bill.daysToExtend} days • Active validity till $extendDateString',
                                  style: OwnerTypography.bold(
                                    size: 11.5,
                                    color: const Color(0xFF2B3B2C),
                                  ),
                                ),
                                if (remainderSkips > 0) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '$coveredSkips of ${bill.currentMonthSkipsCount} skips converted to +${bill.daysToExtend} days. Remaining $remainderSkips skips (₹$remainderAmount) will credit next month.',
                                    style: OwnerTypography.regular(
                                      size: 10.5,
                                      color: const Color(0xFF3F653E),
                                    ),
                                  ),
                                ] else if (bill.currentMonthSkipsCount > 0) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'All ${bill.currentMonthSkipsCount} skips converted to +${bill.daysToExtend} days validity.',
                                    style: OwnerTypography.regular(
                                      size: 10.5,
                                      color: const Color(0xFF3F653E),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (bill.currentMonthSkipsCount > 0) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2EBE0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBDD4BA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: Color(0xFF2B3B2C),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '💡 ${bill.currentMonthSkipsCount} skips in ${_getMonthName(data['month'])} (₹${bill.currentMonthSkipsAmount.toInt()} saved) logged. Will be credited to next month\'s bill.',
                              style: OwnerTypography.bold(
                                size: 11.5,
                                color: const Color(0xFF2B3B2C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (bill.carryForwardCredit > 0) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF5EC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCCE0C8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: Color(0xFF3F653E),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Includes ₹${bill.carryForwardCredit.toInt()} credit carried forward from previous month\'s skips.',
                              style: OwnerTypography.bold(
                                size: 11.5,
                                color: const Color(0xFF2B3B2C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!bill.isPaid) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_outlined,
                          size: 15,
                          color: OwnerColors.walnutMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Skip Compensation',
                          style: OwnerTypography.bold(
                            size: 13,
                            color: OwnerColors.walnutDark,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: displaySkipsCount > 0
                                ? OwnerColors.amberLight
                                : OwnerColors.sageLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            displaySkipsCount > 0
                                ? '$displaySkipsCount meals skipped'
                                : 'No skips',
                            style: OwnerTypography.bold(
                              size: 10,
                              color: displaySkipsCount > 0
                                  ? OwnerColors.amberDark
                                  : OwnerColors.sageDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: OwnerColors.surfaceWarm,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: OwnerColors.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reduce Fees (Rebate)',
                                  style: OwnerTypography.bold(size: 13),
                                ),
                                Text(
                                  priorValidSkips > 0
                                      ? (bill.totalDeductions > 0
                                          ? 'Deduct ₹${bill.totalDeductions.toStringAsFixed(0)} from bill'
                                          : 'No deduction (0 skips)')
                                      : (effectiveCurrentSkips > 0
                                          ? '₹${effectiveCurrentAmount.toStringAsFixed(0)} will credit in next month\'s bill'
                                          : 'No deduction (0 skips)'),
                                  style: OwnerTypography.regular(
                                    size: 11,
                                    color: OwnerColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            value: 'rebate',
                            groupValue: effectiveCompensationChoice,
                            activeColor: OwnerColors.sageGreen,
                            onChanged: (val) => setLocalState(
                                () => localCompensationChoice = val),
                          ),
                          const Divider(
                              height: 1, color: OwnerColors.borderSubtle),
                          RadioListTile<String>(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Extend Validity',
                                  style: OwnerTypography.bold(size: 13),
                                ),
                                Text(
                                  extendDays > 0
                                      ? (potentialRemainderSkips > 0
                                          ? 'Extend to $extendDateString (+$extendDays days for $potentialCoveredSkips skips) & remaining $potentialRemainderSkips skips (₹$potentialRemainderAmount) credit next month'
                                          : 'Extend to $extendDateString (+$extendDays days for $displaySkipsCount skips)')
                                      : (effectiveCurrentSkips > 0
                                          ? '1 day added every $allowedMeals skips'
                                          : 'No extension (0 skips)'),
                                  style: OwnerTypography.regular(
                                    size: 11,
                                    color: OwnerColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            value: 'extend',
                            groupValue: effectiveCompensationChoice,
                            activeColor: OwnerColors.sageGreen,
                            onChanged: (val) => setLocalState(
                                () => localCompensationChoice = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Numbers row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Basic Fee',
                              style: OwnerTypography.regular(
                                size: 11,
                                color: OwnerColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '₹${bill.baseFee.toStringAsFixed(0)}',
                              style: OwnerTypography.editorialSerif(
                                size: 18,
                                weight: FontWeight.w700,
                                color: OwnerColors.walnutDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deductions',
                              style: OwnerTypography.regular(
                                size: 11,
                                color: OwnerColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '-₹${(bill.totalDeductions + bill.proratedDiscount).toStringAsFixed(0)}',
                              style: OwnerTypography.editorialSerif(
                                size: 18,
                                weight: FontWeight.w700,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Final Payable',
                              style: OwnerTypography.regular(
                                size: 11,
                                color: OwnerColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '₹${bill.finalPayable.toStringAsFixed(0)}',
                              style: OwnerTypography.editorialSerif(
                                size: 18,
                                weight: FontWeight.w700,
                                color: OwnerColors.walnutDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Paid Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localIsPaid ? 'Status: Paid' : 'Mark as Paid',
                        style: OwnerTypography.bold(
                          size: 13,
                          color: localIsPaid
                              ? OwnerColors.sageGreen
                              : OwnerColors.walnutDark,
                        ),
                      ),
                      Switch(
                        value: localIsPaid,
                        activeThumbColor: OwnerColors.sageGreen,
                        onChanged: (value) async {
                          setLocalState(() => localIsPaidOverride = value);
                          final int targetExtendDays =
                              effectiveCompensationChoice == 'extend' ? extendDays : 0;
                          final updatedBill = BillModel(
                            billId: bill.billId,
                            studentId: bill.studentId,
                            messId: bill.messId,
                            month: bill.month,
                            year: bill.year,
                            baseFee: bill.baseFee,
                            proratedDiscount: bill.proratedDiscount,
                            totalDeductions: bill.totalDeductions,
                            extraMealsAddon: bill.extraMealsAddon,
                            guestAddons: bill.guestAddons,
                            extraFeesAddon: bill.extraFeesAddon,
                            finalPayable: bill.finalPayable,
                            excessCreditGenerated: bill.excessCreditGenerated,
                            previousDues: bill.previousDues,
                            isPaid: value,
                            autoSettled: bill.autoSettled,
                            validSkipsRewarded: bill.validSkipsRewarded,
                            daysToExtend: targetExtendDays,
                            planId: bill.planId,
                            planName: bill.planName,
                            deductions: bill.deductions,
                            platformFee: bill.platformFee,
                            carryForwardCredit: bill.carryForwardCredit,
                            normalSkipsCount: bill.normalSkipsCount,
                            normalSkipsDeduction: bill.normalSkipsDeduction,
                            specialSkipsCount: bill.specialSkipsCount,
                            specialSkipsDeduction: bill.specialSkipsDeduction,
                            currentMonthSkipsCount: bill.currentMonthSkipsCount,
                            currentMonthSkipsAmount: bill.currentMonthSkipsAmount,
                          );

                          try {
                            await ref
                                .read(ownerStudentsProvider.notifier)
                                .toggleBillPaymentStatus(
                                  student,
                                  updatedBill,
                                  value,
                                  extendDays: targetExtendDays,
                                );
                            _billingDataCache.remove(cacheKey);
                            data['bill'] = updatedBill.copyWith(isPaid: value);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value
                                        ? 'Bill marked as paid!'
                                        : 'Bill marked as unpaid!',
                                  ),
                                  backgroundColor: value
                                      ? OwnerColors.sageGreen
                                      : OwnerColors.walnutDark,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setLocalState(() => localIsPaidOverride = !value);
                              _billingDataCache.remove(cacheKey);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update payment status: $e'),
                                  backgroundColor: const Color(0xFFC62828),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // View Detailed Breakdown button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showDetailedBreakdown(context, bill, allowedMeals),
                      icon: const Icon(
                        Icons.receipt_long,
                        size: 16,
                        color: OwnerColors.walnutDark,
                      ),
                      label: Text(
                        'View Detailed Breakdown',
                        style: OwnerTypography.bold(
                          size: 13,
                          color: OwnerColors.walnutDark,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: OwnerColors.borderSubtle),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // WhatsApp Reminder button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final cleanPhone =
                            student.phone.replaceAll(RegExp(r'\D'), '');
                        final message =
                            "Hi ${student.name}, your Mess bill of ₹${bill.finalPayable.toStringAsFixed(0)} is pending. Please pay at your earliest convenience.";
                        final url = Uri.parse(
                          "https://wa.me/91$cleanPhone?text=${Uri.encodeComponent(message)}",
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not launch WhatsApp'),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Color(0xFF25D366),
                        size: 16,
                      ),
                      label: Text(
                        'Send WhatsApp Reminder',
                        style: OwnerTypography.bold(
                          size: 13,
                          color: OwnerColors.walnutDark,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: OwnerColors.borderSubtle),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDetailedBreakdown(BuildContext context, BillModel bill, [int allowedMeals = 3]) {
    showModalBottomSheet(
      context: context,
      backgroundColor: OwnerColors.surfaceLight,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bill Breakdown',
                    style: OwnerTypography.editorialSerif(
                      size: 22,
                      weight: FontWeight.w700,
                      color: OwnerColors.walnutDark,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildBillRow('Basic Fee', '₹${bill.baseFee.toStringAsFixed(0)}'),
              if (bill.proratedDiscount > 0)
                _buildBillRow(
                  'Mid-Month Joining Discount',
                  '-₹${bill.proratedDiscount.toStringAsFixed(0)}',
                  color: Colors.green,
                ),
              if (bill.specialSkipsCount > 0)
                _buildBillRow(
                  '✨ Special Feast Skips (${bill.specialSkipsCount} meals)',
                  '-₹${bill.specialSkipsDeduction.toStringAsFixed(0)}',
                  color: Colors.green,
                ),
              if (bill.normalSkipsCount > 0)
                _buildBillRow(
                  'Regular Meal Skips (${bill.normalSkipsCount} meals)',
                  '-₹${bill.normalSkipsDeduction.toStringAsFixed(0)}',
                  color: Colors.green,
                )
              else if (bill.totalDeductions > 0 && bill.specialSkipsCount == 0)
                _buildBillRow(
                  'Valid Skipped Meals Refunds',
                  '-₹${bill.totalDeductions.toStringAsFixed(0)}',
                  color: Colors.green,
                ),
              if (bill.carryForwardCredit > 0 && bill.normalSkipsCount == 0 && bill.specialSkipsCount == 0)
                _buildBillRow(
                  'Previous Month Skips Credit',
                  '-₹${bill.carryForwardCredit.toStringAsFixed(0)}',
                  color: Colors.green,
                ),
              if (bill.currentMonthSkipsCount > 0) ...[
                () {
                  final effMeals = allowedMeals > 0 ? allowedMeals : 3;
                  final coveredSkips = bill.daysToExtend * effMeals;
                  final remainderSkips = bill.currentMonthSkipsCount > coveredSkips
                      ? (bill.currentMonthSkipsCount - coveredSkips)
                      : 0;
                  final ratePerSkip = bill.currentMonthSkipsCount > 0
                      ? (bill.currentMonthSkipsAmount / bill.currentMonthSkipsCount)
                      : 0.0;
                  final remainderAmount = (remainderSkips * ratePerSkip).round();

                  return _buildBillRow(
                    'Current Month Skips Logged (${bill.currentMonthSkipsCount})',
                    bill.daysToExtend > 0
                        ? (remainderSkips > 0
                            ? '+${bill.daysToExtend}d & ₹$remainderAmount (Next Month)'
                            : '+${bill.daysToExtend} Days Extended')
                        : '₹${bill.currentMonthSkipsAmount.toStringAsFixed(0)} (Credited Next Month)',
                    color: const Color(0xFF2B3B2C),
                  );
                }(),
              ],
              if (bill.extraMealsAddon > 0)
                _buildBillRow(
                  'Extra Meals Consumed',
                  '+₹${bill.extraMealsAddon.toStringAsFixed(0)}',
                  color: Colors.red,
                ),
              if (bill.guestAddons > 0)
                _buildBillRow(
                  'Guest Meals',
                  '+₹${bill.guestAddons.toStringAsFixed(0)}',
                  color: Colors.red,
                ),
              if (bill.extraFeesAddon > 0)
                _buildBillRow(
                  'Extra Fees / Miscellaneous',
                  '+₹${bill.extraFeesAddon.toStringAsFixed(0)}',
                  color: Colors.red,
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: OwnerColors.borderSubtle),
              ),
              _buildBillRow(
                'Final Payable',
                '₹${bill.finalPayable.toStringAsFixed(0)}',
                isBold: true,
                size: 18,
              ),
              const SizedBox(height: 20),
              Text(
                'Itemized Details',
                style: OwnerTypography.bold(
                  size: 16,
                  color: OwnerColors.walnutDark,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: bill.deductions.isEmpty
                    ? Center(
                        child: Text(
                          "No itemized details this month.",
                          style: OwnerTypography.regular(
                            size: 12,
                            color: OwnerColors.walnutMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: bill.deductions.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 16,
                          color: OwnerColors.borderSubtle,
                        ),
                        itemBuilder: (context, index) {
                          final item = bill.deductions[index];
                          final isDeduction = item.amount < 0;
                          final typeStr =
                              item.type.replaceAll('_', ' ').toUpperCase();
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.date.day}/${item.date.month} - ${item.mealSlot}',
                                      style: OwnerTypography.bold(
                                        size: 13,
                                        color: OwnerColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      typeStr,
                                      style: OwnerTypography.regular(
                                        size: 11,
                                        color: OwnerColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isDeduction ? '' : '+'}₹${item.amount.abs().toStringAsFixed(0)}',
                                style: OwnerTypography.bold(
                                  size: 14,
                                  color: isDeduction
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBillRow(
    String label,
    String amount, {
    bool isBold = false,
    Color color = OwnerColors.textPrimary,
    double size = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: isBold
                  ? OwnerTypography.bold(
                      size: size,
                      color: OwnerColors.textPrimary,
                    )
                  : OwnerTypography.regular(
                      size: size,
                      color: OwnerColors.textSecondary,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            textAlign: TextAlign.end,
            style: OwnerTypography.bold(size: size, color: color),
          ),
        ],
      ),
    );
  }

  // ─── Extra Fees Section & Dialog ──────────────────────────────────────────
  Widget _buildExtraFeesSection(
    BuildContext context,
    WidgetRef ref,
    StudentModel student,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Extra Fees & Add-ons',
              style: OwnerTypography.editorialSerif(
                size: 18,
                weight: FontWeight.w700,
                color: OwnerColors.walnutDark,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddExtraFeeDialog(context, ref, student),
              icon: const Icon(Icons.add, size: 15, color: Colors.white),
              label: Text(
                'Add Fee',
                style: OwnerTypography.bold(size: 12, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: OwnerColors.sageGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<ExtraFeeModel>>(
          stream: ref
              .read(appServiceProvider)
              .streamExtraFees(student.messId, student.studentId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(color: OwnerColors.sageGreen),
                ),
              );
            }

            final fees = snapshot.data ?? [];
            if (fees.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: OwnerColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: OwnerColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: OwnerColors.walnutMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No extra fees or penalty charges for this student.',
                        style: OwnerTypography.regular(
                          size: 12,
                          color: OwnerColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: fees.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final fee = fees[index];
                final expenseDateStr =
                    '${fee.originalDate.day}/${fee.originalDate.month}/${fee.originalDate.year}';
                final targetMonthName = _getMonthName(fee.targetBillingMonth);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: OwnerColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: OwnerColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: OwnerColors.amberLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: OwnerColors.amberDark,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fee.note.isNotEmpty ? fee.note : 'Extra Fee',
                              style: OwnerTypography.bold(
                                size: 13,
                                color: OwnerColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Date: $expenseDateStr • Target: $targetMonthName ${fee.targetBillingYear}',
                              style: OwnerTypography.regular(
                                size: 11,
                                color: OwnerColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+₹${fee.amount.toStringAsFixed(0)}',
                        style: OwnerTypography.bold(
                          size: 14,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: OwnerColors.walnutMuted,
                        ),
                        tooltip: 'Delete Fee',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: OwnerColors.surfaceLight,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                              title: Text(
                                'Delete Extra Fee?',
                                style: OwnerTypography.bold(size: 16),
                              ),
                              content: Text(
                                'Are you sure you want to remove "+₹${fee.amount.toStringAsFixed(0)} (${fee.note})"?',
                                style: OwnerTypography.regular(size: 13),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await ref
                                .read(appServiceProvider)
                                .deleteExtraFee(student.messId, fee.feeId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Extra fee deleted successfully!')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showAddExtraFeeDialog(
    BuildContext context,
    WidgetRef ref,
    StudentModel student,
  ) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    DateTime expenseDate = DateTime.now();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: OwnerColors.surfaceLight,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Add Extra Fee',
              style: OwnerTypography.editorialSerif(
                size: 20,
                weight: FontWeight.w700,
                color: OwnerColors.walnutDark,
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense Date',
                      style: OwnerTypography.bold(size: 12),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: expenseDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                        );
                        if (picked != null) {
                          setDialogState(() => expenseDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: OwnerColors.borderSubtle),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 15,
                              color: OwnerColors.walnutMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${expenseDate.day}/${expenseDate.month}/${expenseDate.year}',
                              style: OwnerTypography.regular(size: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Amount (₹) *',
                      style: OwnerTypography.bold(size: 12),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter amount';
                        }
                        final numVal = double.tryParse(val.trim());
                        if (numVal == null || numVal <= 0) {
                          return 'Enter a positive amount (> 0)';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g. 150',
                        prefixText: '₹ ',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: OwnerColors.borderSubtle),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Description / Reason *',
                      style: OwnerTypography.bold(size: 12),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: noteCtrl,
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Enter a description'
                          : null,
                      decoration: InputDecoration(
                        hintText: 'e.g. Late snack, Room guest, Crockery damage',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: OwnerColors.borderSubtle),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: OwnerColors.surfaceWarm,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '💡 Carry-Forward: If the bill for this date has already been paid, this fee will roll over to the next unpaid month.',
                        style: OwnerTypography.regular(
                          size: 11,
                          color: OwnerColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);

                        try {
                          final parsedAmount =
                              double.parse(amountCtrl.text.trim());
                          final appService = ref.read(appServiceProvider);

                          int targetMonth = expenseDate.month;
                          int targetYear = expenseDate.year;

                          BillModel? bill;
                          try {
                            bill = await appService.getBill(
                              student.studentId,
                              expenseDate.month,
                              expenseDate.year,
                            );
                          } catch (e) {
                            debugPrint('[ExtraFee] getBill error: $e');
                          }

                          if (bill != null && bill.isPaid) {
                            targetMonth =
                                expenseDate.month == 12 ? 1 : expenseDate.month + 1;
                            targetYear = expenseDate.month == 12
                                ? expenseDate.year + 1
                                : expenseDate.year;
                          }

                          final fee = ExtraFeeModel(
                            feeId: 'fee_${DateTime.now().millisecondsSinceEpoch}',
                            studentId: student.studentId,
                            messId: student.messId,
                            originalDate: expenseDate,
                            targetBillingMonth: targetMonth,
                            targetBillingYear: targetYear,
                            amount: parsedAmount,
                            note: noteCtrl.text.trim(),
                          );

                          await appService.addExtraFee(fee);

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Extra fee ₹${parsedAmount.toStringAsFixed(0)} added! Target: ${_getMonthName(targetMonth)} $targetYear'),
                                backgroundColor: OwnerColors.sageGreen,
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error adding fee: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: OwnerColors.sageGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Add Fee'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Approve Member Dialog ────────────────────────────────────────────────
  void _showAcceptStudentDialog(
      BuildContext context, WidgetRef ref, StudentModel student) async {
    final mess = ref.read(ownerSettingsProvider).mess;
    if (mess == null) {
      ref.read(ownerStudentsProvider.notifier).accept(student.studentId);
      return;
    }

    final plans = await ref.read(appServiceProvider).getMealPlans(mess.messId);
    String? selectedPlanId = student.assignedPlanId;
    if (selectedPlanId == null && plans.isNotEmpty) {
      selectedPlanId = plans.first.planId;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: OwnerColors.surfaceLight,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Approve Member',
              style: OwnerTypography.editorialSerif(
                size: 20,
                weight: FontWeight.w700,
                color: OwnerColors.walnutDark,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: OwnerTypography.bold(
                    size: 16,
                    color: OwnerColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Room: ${student.roomNo}  •  ${student.phone}',
                  style: OwnerTypography.regular(
                    size: 12,
                    color: OwnerColors.textSecondary,
                  ),
                ),
                if (student.dietaryPreference.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Diet: ${student.dietaryPreference.toUpperCase()}',
                    style: OwnerTypography.bold(
                      size: 11,
                      color: OwnerColors.sageGreen,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(color: OwnerColors.borderSubtle),
                const SizedBox(height: 10),
                Text(
                  'Assign Meal Plan:',
                  style: OwnerTypography.bold(
                    size: 13,
                    color: OwnerColors.walnutDark,
                  ),
                ),
                const SizedBox(height: 8),
                if (plans.isEmpty)
                  Text(
                    'Default Mess Plan (₹${mess.monthlyFee.toInt()}/mo, ${mess.mealsIncludedPerDay} meals)',
                    style: OwnerTypography.regular(
                      size: 12,
                      color: OwnerColors.textSecondary,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: OwnerColors.surfaceWarm,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: OwnerColors.borderSubtle),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: selectedPlanId,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Default Mess Plan (₹${mess.monthlyFee.toInt()})',
                              style: OwnerTypography.regular(size: 13),
                            ),
                          ),
                          ...plans.map((p) => DropdownMenuItem<String?>(
                                value: p.planId,
                                child: Text(
                                  '${p.name} (₹${p.monthlyFee.toInt()})',
                                  style: OwnerTypography.regular(size: 13),
                                ),
                              )),
                        ],
                        onChanged: (val) {
                          setDialogState(() => selectedPlanId = val);
                        },
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: OwnerColors.sageGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(ownerStudentsProvider.notifier)
                      .accept(student.studentId, selectedPlanId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${student.name} approved successfully!'),
                        backgroundColor: OwnerColors.sageGreen,
                      ),
                    );
                  }
                },
                child: const Text('Confirm & Accept'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month >= 1 && month <= 12) return monthNames[month];
    return '';
  }
}
