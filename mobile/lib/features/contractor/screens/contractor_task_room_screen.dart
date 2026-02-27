import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/api_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/providers/websocket_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_chat_badge.dart';
import '../../client/models/task_category.dart';

/// Screen showing task room details for a contractor who applied.
/// Shows full task info, chat button, and resign button.
class ContractorTaskRoomScreen extends ConsumerStatefulWidget {
  final String taskId;

  const ContractorTaskRoomScreen({super.key, required this.taskId});

  @override
  ConsumerState<ContractorTaskRoomScreen> createState() =>
      _ContractorTaskRoomScreenState();
}

class _ContractorTaskRoomScreenState
    extends ConsumerState<ContractorTaskRoomScreen> {
  Map<String, dynamic>? _taskData;
  bool _isLoading = true;
  bool _isResigning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTaskDetails();
  }

  Future<void> _loadTaskDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final response =
          await api.get<Map<String, dynamic>>('/tasks/${widget.taskId}');
      if (mounted) {
        setState(() {
          _taskData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Nie udało się załadować zlecenia';
        });
      }
    }
  }

  Future<void> _resignFromRoom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rezygnujesz?'),
        content: const Text(
          'Czy na pewno chcesz zrezygnować z tego zlecenia? '
          'Twoje miejsce w pokoju zostanie zwolnione.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nie'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Tak, rezygnuję'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isResigning = true);

    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/tasks/${widget.taskId}/apply');

      if (mounted) {
        // Refresh the active tasks list
        ref.read(contractorActiveTasksProvider.notifier).refresh();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zrezygnowano z pokoju')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    }
  }

  void _openChat() {
    final currentUser = ref.read(currentUserProvider);
    final clientId = _taskData?['client']?['id'] as String? ??
        _taskData?['clientId'] as String? ??
        '';
    final clientName =
        _taskData?['client']?['name'] as String? ?? 'Zleceniodawca';
    final clientAvatar = _taskData?['client']?['avatarUrl'] as String?;
    final description = _taskData?['description'] as String? ?? 'Czat';

    context.push(
      Routes.contractorTaskChatRoute(widget.taskId),
      extra: {
        'otherUserId': clientId,
        'taskTitle': description,
        'otherUserName': clientName,
        'otherUserAvatarUrl': clientAvatar,
        'currentUserId': currentUser?.id ?? '',
        'currentUserName': currentUser?.name ?? 'Ty',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for kick/reject events — navigate back if this task is affected
    ref.listen<AsyncValue<Map<String, dynamic>>>(
      applicationResultProvider,
      (previous, next) {
        next.whenData((event) {
          final status = event['status']?.toString().toLowerCase();
          final taskId = event['taskId']?.toString();
          if (taskId == widget.taskId &&
              (status == 'kicked' || status == 'rejected')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(status == 'kicked'
                      ? 'Zostałeś zwolniony z tego pokoju'
                      : 'Twoje zgłoszenie zostało odrzucone'),
                  backgroundColor: AppColors.error,
                ),
              );
              context.pop();
            }
          }
        });
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokój zlecenia'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: AppTypography.bodyMedium),
                      SizedBox(height: AppSpacing.paddingMD),
                      ElevatedButton(
                        onPressed: _loadTaskDetails,
                        child: const Text('Spróbuj ponownie'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
      bottomNavigationBar: _taskData != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildContent() {
    if (_taskData == null) return const SizedBox.shrink();

    final categoryStr = _taskData!['category'] as String? ?? 'paczki';
    final category = TaskCategory.values.firstWhere(
      (c) => c.name == categoryStr,
      orElse: () => TaskCategory.paczki,
    );
    final categoryData = TaskCategoryData.fromCategory(category);

    final description = _taskData!['description'] as String? ?? '';
    final address = _taskData!['address'] as String? ?? '';
    final budget = _parseNum(_taskData!['budgetAmount']);
    final budgetStr = budget != null ? '${budget.toStringAsFixed(0)} zł' : 'Do ustalenia';
    final clientName =
        _taskData!['client']?['name'] as String? ?? 'Zleceniodawca';
    final clientAvatar = _taskData!['client']?['avatarUrl'] as String?;
    final estimatedHours = _parseNum(_taskData!['estimatedDurationHours']);
    final createdAt = _taskData!['createdAt'] as String?;
    final imageUrls = _taskData!['imageUrls'] as List<dynamic>?;

    return RefreshIndicator(
      onRefresh: _loadTaskDetails,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room status banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: AppRadius.radiusMD,
                border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.meeting_room_outlined,
                      color: AppColors.info, size: 24),
                  SizedBox(width: AppSpacing.gapMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jesteś w pokoju',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                        Text(
                          'Porozmawiaj z szefem przez czat, aby ustalić szczegóły.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.space6),

            // Category + budget header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.paddingMD),
                  decoration: BoxDecoration(
                    color: categoryData.color.withValues(alpha: 0.1),
                    borderRadius: AppRadius.radiusLG,
                  ),
                  child: Icon(
                    categoryData.icon,
                    color: categoryData.color,
                    size: 32,
                  ),
                ),
                SizedBox(width: AppSpacing.gapMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryData.name,
                        style: AppTypography.h4.copyWith(
                          color: categoryData.color,
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          _formatDate(DateTime.parse(createdAt)),
                          style: AppTypography.caption
                              .copyWith(color: AppColors.gray500),
                        ),
                    ],
                  ),
                ),
                Text(
                  budgetStr,
                  style: AppTypography.h3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.space6),

            // Description
            Text(
              'Opis zlecenia',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.gray500),
            ),
            SizedBox(height: AppSpacing.gapSM),
            Text(
              description,
              style: AppTypography.bodyMedium,
            ),
            SizedBox(height: AppSpacing.space6),

            // Address
            Text(
              'Lokalizacja',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.gray500),
            ),
            SizedBox(height: AppSpacing.gapSM),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 18, color: AppColors.gray600),
                SizedBox(width: AppSpacing.gapSM),
                Expanded(
                  child: Text(address, style: AppTypography.bodyMedium),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.space6),

            // Estimated duration
            if (estimatedHours != null) ...[
              Text(
                'Szacowany czas',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.gray500),
              ),
              SizedBox(height: AppSpacing.gapSM),
              Row(
                children: [
                  Icon(Icons.schedule, size: 18, color: AppColors.gray600),
                  SizedBox(width: AppSpacing.gapSM),
                  Text(
                    '${estimatedHours!.toStringAsFixed(1)} godz.',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.space6),
            ],

            // Client info
            Text(
              'Zleceniodawca',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.gray500),
            ),
            SizedBox(height: AppSpacing.gapSM),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.gray200,
                  backgroundImage: clientAvatar != null
                      ? NetworkImage(clientAvatar)
                      : null,
                  child: clientAvatar == null
                      ? Text(
                          clientName.isNotEmpty ? clientName[0] : '?',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.gray600,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: AppSpacing.gapMD),
                Text(
                  clientName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            // Images
            if (imageUrls != null && imageUrls.isNotEmpty) ...[
              SizedBox(height: AppSpacing.space6),
              Text(
                'Zdjęcia',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.gray500),
              ),
              SizedBox(height: AppSpacing.gapSM),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(width: AppSpacing.gapSM),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: AppRadius.radiusMD,
                      child: Image.network(
                        imageUrls[index] as String,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 120,
                          height: 120,
                          color: AppColors.gray200,
                          child: Icon(Icons.broken_image,
                              color: AppColors.gray400),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Fee info
            SizedBox(height: AppSpacing.space6),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.paddingSM),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: AppRadius.radiusMD,
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.gray500),
                  SizedBox(width: AppSpacing.gapSM),
                  Expanded(
                    child: Text(
                      'Opłata 10 zł zostanie pobrana tylko gdy szef Cię wybierze.',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.gray600),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.space6),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.paddingMD,
        AppSpacing.paddingSM,
        AppSpacing.paddingMD,
        AppSpacing.paddingMD + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.gray200)),
      ),
      child: Row(
        children: [
          // Resign button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isResigning ? null : _resignFromRoom,
              icon: _isResigning
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Icon(Icons.exit_to_app, size: 18),
              label: const Text('Rezygnuję'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                padding:
                    EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.paddingSM),
          // Chat button
          Expanded(
            child: SFChatBadge(
              taskId: widget.taskId,
              child: ElevatedButton.icon(
                onPressed: _openChat,
                icon: Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Czat z szefem'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  padding:
                      EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Safely parse dynamic value to double (handles String and num)
  static double? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return 'Dzisiaj, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Wczoraj';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dni temu';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
