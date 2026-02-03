Claude’s Plan
Implementation Plan: Multi-Contractor Application System
Overview
Transform the current "first-come-first-served" task acceptance into a marketplace application system where:

Multiple contractors can apply to tasks
Client sees list of applicants with profiles
Client selects preferred contractor
Payment hold triggered after selection
Current Flow:


Client creates task → TOP 5 notified → First to click "accept" gets task → Client confirms → Payment
New Flow:


Client creates task → TOP 5 notified → Contractors apply → Client sees list → Client selects → Payment → Work
Key Decisions
1. Application Limits
Max 10 applications per task (prevents overwhelming clients)
No limit per contractor (encourages engagement)
2. Timeouts & Re-notification Strategy
Tiered approach:

0-5 min: Initial TOP 5 contractors notified
5 min + <3 apps: Notify NEXT 5 contractors
15 min + <3 apps: Expand radius 1.5x, notify NEXT 10
30 min + <2 apps: Expand radius 2x, notify ALL online
3. Pricing
Phase 1 (MVP): Use client's budget (no bidding)
Phase 2: Allow contractors to propose prices
TaskApplication entity includes optional proposedPrice field for future
4. Status Flow Changes
Old: CREATED → ACCEPTED → CONFIRMED → IN_PROGRESS → PENDING_COMPLETE → COMPLETED

New: CREATED → (applications) → CONFIRMED → IN_PROGRESS → PENDING_COMPLETE → COMPLETED

Key Change: Skip ACCEPTED status entirely. Client selects from applications → directly to CONFIRMED.

5. Backward Compatibility
Keep /tasks/:id/accept for 2 releases:

If task has <3 applications: Auto-create application + auto-select (instant)
If task has ≥3 applications: Create pending application, notify client
Return deprecation warning
After 2 releases: Return 410 Gone
Database Schema
New Entity: TaskApplication

@Entity('task_applications')
export class TaskApplication {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column('uuid')
  taskId: string;

  @ManyToOne(() => Task, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'taskId' })
  task: Task;

  @Column('uuid')
  contractorId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'contractorId' })
  contractor: User;

  @Column({
    type: 'enum',
    enum: ApplicationStatus,
    default: ApplicationStatus.PENDING,
  })
  status: ApplicationStatus;

  // Optional: For future bidding feature
  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  proposedPrice: number | null;

  // Optional: Contractor's message to client
  @Column({ type: 'text', nullable: true })
  message: string | null;

  // Optional: Estimated time (minutes)
  @Column({ type: 'int', nullable: true })
  estimatedMinutes: number | null;

  @CreateDateColumn()
  appliedAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  selectedAt: Date | null;

  @Column({ type: 'timestamp', nullable: true })
  rejectedAt: Date | null;

  // Applications expire after 1 hour
  @Column({ type: 'timestamp', nullable: true })
  expiresAt: Date | null;
}

export enum ApplicationStatus {
  PENDING = 'pending',
  SELECTED = 'selected',
  REJECTED = 'rejected',
  WITHDRAWN = 'withdrawn',
  EXPIRED = 'expired',
}
Indexes:

(taskId, contractorId) - UNIQUE constraint (prevent duplicate applications)
(taskId, status) - Fast fetch of pending applications
(contractorId, status) - Contractor's active applications
(expiresAt) - Cleanup cron jobs
API Endpoints
1. POST /tasks/:id/apply
Contractor applies to task

Auth: JWT (contractor only)

Request Body:


{
  "message": "string (optional, max 500 chars)",
  "estimatedMinutes": "number (optional)"
}
Business Logic:

Verify task exists and status = CREATED
Verify contractor hasn't already applied (UNIQUE constraint)
Check application count < 10
Create TaskApplication with expiresAt = now + 1 hour
WebSocket → Client: task:application_received
Push notification to client
Response:


{
  "success": true,
  "applicationId": "uuid",
  "message": "Aplikacja wysłana pomyślnie"
}
Errors:

404: Task not found
400: Task not available for applications
409: Already applied to this task
400: Application limit (10) reached
2. GET /tasks/:id/applications
Client views list of applicants

Auth: JWT (must be task owner)

Query Parameters:


?status=pending (default)
&sortBy=score (default) | rating | appliedAt | distance
Response:


{
  "applications": [
    {
      "id": "uuid",
      "contractor": {
        "id": "uuid",
        "name": "Jan Kowalski",
        "avatarUrl": "https://...",
        "rating": 4.8,
        "completedTasks": 45,
        "isVerified": true
      },
      "status": "pending",
      "message": "Mogę to zrobić w 30 minut!",
      "appliedAt": "2026-02-03T10:00:00Z",
      "distance": 2.5,
      "eta": 15,
      "score": 0.85
    }
  ],
  "total": 5
}
Business Logic:

Fetch all applications with status filter
Join with ContractorProfile and User
Calculate distance and score for each
Sort by specified field
Enrich with contractor details
3. PUT /tasks/:id/select-application/:applicationId
Client selects contractor from applicants

Auth: JWT (must be task owner)

Request Body:


{
  "paymentMethod": "cash" | "card"
}
Business Logic (ATOMIC TRANSACTION):

Begin transaction
Verify task.status = CREATED
Verify application exists and status = PENDING
Update selected application:
status = SELECTED
selectedAt = now
Update all other applications:
status = REJECTED
rejectedAt = now
Update task:
contractorId = selected contractor
status = CONFIRMED
confirmedAt = now
Commit transaction
WebSocket → Selected contractor: task:application_selected
WebSocket → Rejected contractors: task:application_rejected
Push notifications to all
Response:


{
  "success": true,
  "task": { /* updated task with contractor */ }
}
Errors:

403: Not task owner
400: Task not in CREATED status
404: Application not found
409: Task already assigned
4. DELETE /tasks/:id/applications/:applicationId
Contractor withdraws application

Auth: JWT (must be application owner)

Business Logic:

Verify application exists
Verify contractor is owner
Update status = WITHDRAWN
WebSocket → Client: task:application_withdrawn
Response:


{
  "success": true,
  "message": "Aplikacja wycofana"
}
5. PUT /tasks/:id/accept (DEPRECATED)
Legacy endpoint for backward compatibility

Phase 1 Behavior:


if (taskApplications.length < 3) {
  // Auto-create application and auto-select
  const app = await createApplication(taskId, contractorId);
  await selectApplication(app.id);
  return { legacy: true, accepted: true };
} else {
  // Just create pending application
  const app = await createApplication(taskId, contractorId);
  return {
    deprecated: true,
    message: "Use POST /tasks/:id/apply instead",
    applicationId: app.id
  };
}
Phase 2 (after 2 releases): Return 410 Gone

WebSocket Events
task:application_received
Sent to: Client (task owner)


{
  "event": "task:application_received",
  "data": {
    "taskId": "uuid",
    "application": {
      "id": "uuid",
      "contractor": { /* full profile */ },
      "appliedAt": "2026-02-03T10:00:00Z",
      "distance": 2.5,
      "eta": 15
    },
    "totalApplications": 3
  }
}
task:application_selected
Sent to: Selected contractor


{
  "event": "task:application_selected",
  "data": {
    "taskId": "uuid",
    "task": { /* full task details */ },
    "message": "Gratulacje! Klient wybrał Cię do wykonania zlecenia."
  }
}
task:application_rejected
Sent to: Rejected contractors


{
  "event": "task:application_rejected",
  "data": {
    "taskId": "uuid",
    "message": "Klient wybrał innego wykonawcę."
  }
}
task:application_withdrawn
Sent to: Client (task owner)


{
  "event": "task:application_withdrawn",
  "data": {
    "taskId": "uuid",
    "applicationId": "uuid",
    "totalApplications": 2
  }
}
Backend Implementation Steps
Phase 1: Database & Entity (Day 1)
Files to create:

backend/src/tasks/entities/task-application.entity.ts
backend/src/tasks/dto/create-application.dto.ts
backend/src/tasks/dto/application-response.dto.ts
Files to modify:

backend/src/tasks/tasks.module.ts - Register TaskApplication entity
backend/src/app.module.ts - Add to TypeORM entities array
Implementation:


// tasks.module.ts
import { TaskApplication } from './entities/task-application.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Task, Rating, TaskApplication, ContractorProfile]),
    // ...
  ],
})
Phase 2: Service Methods (Day 2-3)
File: backend/src/tasks/tasks.service.ts

New methods to add:


// 1. Contractor applies to task
async applyToTask(
  taskId: string,
  contractorId: string,
  dto: CreateApplicationDto
): Promise<TaskApplication>

// 2. Client fetches applicants
async getApplicationsForTask(
  taskId: string,
  clientId: string,
  status?: ApplicationStatus
): Promise<EnrichedApplication[]>

// 3. Client selects contractor (TRANSACTION)
async selectApplication(
  taskId: string,
  applicationId: string,
  clientId: string,
  paymentMethod: string
): Promise<Task>

// 4. Contractor withdraws
async withdrawApplication(
  applicationId: string,
  contractorId: string
): Promise<void>

// 5. Cleanup expired applications (CRON)
async cleanupExpiredApplications(): Promise<number>

// 6. Re-notify contractors for low-interest tasks
async reNotifyContractorsForLowInterestTasks(): Promise<void>
Modify existing methods:


// acceptTask() - Add deprecation logic
async acceptTask(taskId: string, contractorId: string): Promise<Task> {
  this.logger.warn('DEPRECATED: /accept endpoint used, use /apply instead');

  const applicationCount = await this.getApplicationCount(taskId);

  if (applicationCount < 3) {
    // Auto-create and auto-select (backward compat)
    const app = await this.applyToTask(taskId, contractorId, {});
    return await this.selectApplication(taskId, app.id, task.clientId, 'cash');
  } else {
    // Just create pending application
    await this.applyToTask(taskId, contractorId, {});
    throw new BadRequestException('Task has multiple applicants, use /apply');
  }
}

// notifyAvailableContractors() - Update to mention applications
async notifyAvailableContractors(task: Task): Promise<void> {
  // ... existing logic ...

  this.realtimeGateway.sendToUser(
    ranked.contractorId,
    'task:new_available',
    {
      task: notification.task,
      message: 'Nowe zlecenie w Twojej okolicy! Aplikuj szybko.',
      score: ranked.score,
      distance: ranked.distance,
    },
  );
}
Phase 3: Controller Endpoints (Day 3-4)
File: backend/src/tasks/tasks.controller.ts

New endpoints:


@Post(':id/apply')
@UseGuards(JwtAuthGuard)
async applyToTask(
  @Param('id') taskId: string,
  @GetUser() user: User,
  @Body() dto: CreateApplicationDto,
): Promise<ApplicationResponse>

@Get(':id/applications')
@UseGuards(JwtAuthGuard)
async getApplications(
  @Param('id') taskId: string,
  @GetUser() user: User,
  @Query('status') status?: ApplicationStatus,
  @Query('sortBy') sortBy?: string,
): Promise<ApplicationsListResponse>

@Put(':id/select-application/:applicationId')
@UseGuards(JwtAuthGuard)
async selectApplication(
  @Param('id') taskId: string,
  @Param('applicationId') applicationId: string,
  @GetUser() user: User,
  @Body() dto: SelectApplicationDto,
): Promise<TaskResponse>

@Delete(':id/applications/:applicationId')
@UseGuards(JwtAuthGuard)
async withdrawApplication(
  @Param('applicationId') applicationId: string,
  @GetUser() user: User,
): Promise<SuccessResponse>
Modify existing:


@Put(':id/accept')
@UseGuards(JwtAuthGuard)
async acceptTask(
  @Param('id') taskId: string,
  @GetUser() user: User,
): Promise<DeprecatedAcceptResponse> {
  // ... existing logic with deprecation warning ...
}
Phase 4: WebSocket Integration (Day 4)
File: backend/src/realtime/realtime.gateway.ts

Add server events:


export enum ServerEvent {
  // ... existing ...
  TASK_APPLICATION_RECEIVED = 'task:application_received',
  TASK_APPLICATION_SELECTED = 'task:application_selected',
  TASK_APPLICATION_REJECTED = 'task:application_rejected',
  TASK_APPLICATION_WITHDRAWN = 'task:application_withdrawn',
}
New methods:


broadcastApplicationReceived(
  clientId: string,
  application: EnrichedApplication,
  totalApplications: number,
): void {
  this.sendToUser(clientId, ServerEvent.TASK_APPLICATION_RECEIVED, {
    taskId: application.taskId,
    application,
    totalApplications,
  });
}

notifyApplicationSelected(
  contractorId: string,
  task: Task,
): void {
  this.sendToUser(contractorId, ServerEvent.TASK_APPLICATION_SELECTED, {
    taskId: task.id,
    task,
    message: 'Gratulacje! Klient wybrał Cię do wykonania zlecenia.',
  });
}

notifyApplicationsRejected(
  contractorIds: string[],
  taskId: string,
): void {
  contractorIds.forEach(id => {
    this.sendToUser(id, ServerEvent.TASK_APPLICATION_REJECTED, {
      taskId,
      message: 'Klient wybrał innego wykonawcę.',
    });
  });
}
Phase 5: Scheduled Jobs (Day 5)
New file: backend/src/tasks/tasks.scheduler.ts


@Injectable()
export class TasksScheduler {
  constructor(private readonly tasksService: TasksService) {}

  // Every 5 minutes: Clean up expired applications
  @Cron('*/5 * * * *')
  async cleanupExpiredApplications() {
    const count = await this.tasksService.cleanupExpiredApplications();
    this.logger.log(`Cleaned up ${count} expired applications`);
  }

  // Every 2 minutes: Re-notify for low-interest tasks
  @Cron('*/2 * * * *')
  async reNotifyLowInterestTasks() {
    await this.tasksService.reNotifyContractorsForLowInterestTasks();
  }
}
Phase 6: Testing (Day 6-7)
Test files to create/modify:

backend/src/tasks/tasks.service.spec.ts - Unit tests
backend/test/tasks-applications.e2e-spec.ts - E2E tests
Test scenarios:

Unit Tests:

✅ Create application successfully
✅ Prevent duplicate applications (UNIQUE constraint)
✅ Enforce 10 application limit
✅ Select application updates task and applications atomically
✅ Reject other applications when selecting one
✅ Withdraw application marks as withdrawn
✅ Cleanup expired applications
E2E Tests:

✅ Full flow: Apply → Client views → Client selects → Contractor notified
✅ Race condition: Two contractors apply simultaneously
✅ Race condition: Client selects while contractor withdraws
✅ Legacy /accept endpoint backward compatibility
✅ WebSocket notifications delivered correctly
Mobile App Implementation
Phase 1: Models & Services (Day 1-2)
New files:

mobile/lib/core/models/task_application.dart

class TaskApplication {
  final String id;
  final String taskId;
  final Contractor contractor;
  final ApplicationStatus status;
  final String? message;
  final int? estimatedMinutes;
  final DateTime appliedAt;
  final double distance;
  final int eta;
  final double score;
}

enum ApplicationStatus {
  pending, selected, rejected, withdrawn, expired
}
mobile/lib/core/models/applicant.dart

class Applicant {
  final String applicationId;
  final Contractor contractor;
  final double distance;
  final int eta;
  final double score;
  final String? message;
  final DateTime appliedAt;
}
Modify: mobile/lib/core/services/task_service.dart


class TaskService {
  // New methods
  Future<TaskApplication> applyToTask(String taskId, {String? message}) async {
    final response = await _dio.post('/tasks/$taskId/apply', data: {
      if (message != null) 'message': message,
    });
    return TaskApplication.fromJson(response.data);
  }

  Future<List<Applicant>> getApplications(String taskId) async {
    final response = await _dio.get('/tasks/$taskId/applications');
    return (response.data['applications'] as List)
        .map((json) => Applicant.fromJson(json))
        .toList();
  }

  Future<Task> selectApplication(
    String taskId,
    String applicationId,
    String paymentMethod,
  ) async {
    final response = await _dio.put(
      '/tasks/$taskId/select-application/$applicationId',
      data: {'paymentMethod': paymentMethod},
    );
    return Task.fromJson(response.data['task']);
  }

  Future<void> withdrawApplication(String taskId, String applicationId) async {
    await _dio.delete('/tasks/$taskId/applications/$applicationId');
  }
}
Phase 2: Client Side UI (Day 3-5)
NEW: applicants_list_screen.dart
File: mobile/lib/features/client/screens/applicants_list_screen.dart

Full screen structure:


class ApplicantsListScreen extends ConsumerStatefulWidget {
  final String taskId;

  @override
  State<ApplicantsListScreen> createState() => _ApplicantsListScreenState();
}

class _ApplicantsListScreenState extends ConsumerState<ApplicantsListScreen> {
  List<Applicant> _applicants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplications();
    _listenToWebSocket();
  }

  void _listenToWebSocket() {
    // Listen for task:application_received
    ref.listen(taskApplicationUpdatesProvider, (previous, next) {
      if (next.taskId == widget.taskId) {
        _loadApplications(); // Refresh list
      }
    });
  }

  Future<void> _loadApplications() async {
    final apps = await ref.read(taskServiceProvider).getApplications(widget.taskId);
    setState(() {
      _applicants = apps;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wybierz wykonawcę (${_applicants.length})'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _applicants.isEmpty
              ? _buildEmptyState()
              : _buildApplicantsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Szukamy wykonawcy...', style: TextStyle(fontSize: 20)),
          SizedBox(height: 8),
          Text('Poczekaj, aż wykonawcy się zgłoszą'),
        ],
      ),
    );
  }

  Widget _buildApplicantsList() {
    return ListView.builder(
      itemCount: _applicants.length,
      itemBuilder: (context, index) {
        final applicant = _applicants[index];
        return ApplicantCard(
          applicant: applicant,
          onSelect: () => _handleSelect(applicant),
        );
      },
    );
  }

  Future<void> _handleSelect(Applicant applicant) async {
    // Show payment popup
    final paymentMethod = await _showPaymentPopup();
    if (paymentMethod == null) return;

    // Select application
    setState(() => _isLoading = true);
    try {
      await ref.read(taskServiceProvider).selectApplication(
        widget.taskId,
        applicant.applicationId,
        paymentMethod,
      );

      // Navigate to task tracking
      context.go(Routes.clientTask(widget.taskId));
    } catch (e) {
      _showError(e.toString());
    }
  }
}
NEW Widget: mobile/lib/features/client/widgets/applicant_card.dart


class ApplicantCard extends StatelessWidget {
  final Applicant applicant;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(applicant.contractor.avatarUrl),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant.contractor.name,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          Text('${applicant.contractor.rating}'),
                          SizedBox(width: 8),
                          Text('${applicant.contractor.completedTasks} zleceń'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16),
                Text('${applicant.distance.toStringAsFixed(1)} km'),
                SizedBox(width: 16),
                Icon(Icons.access_time, size: 16),
                Text('${applicant.eta} min'),
              ],
            ),
            if (applicant.message != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(applicant.message!),
              ),
            ],
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: onSelect,
              child: Text('WYBIERZ'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
MODIFY: task_tracking_screen.dart
Changes:

Remove confirm/reject contractor buttons (lines 659-719)
Add applicants button for CREATED status
Listen to application updates

// Add at line 470 (after cancel button)
if (_status == TrackingStatus.searching)
  _buildViewApplicantsButton(),

// New method
Widget _buildViewApplicantsButton() {
  return StreamBuilder<int>(
    stream: _getApplicationCountStream(),
    builder: (context, snapshot) {
      final count = snapshot.data ?? 0;

      if (count == 0) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Szukamy wykonawcy...'),
            ],
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () => context.push(Routes.clientApplicants(_taskId)),
          icon: Icon(Icons.people),
          label: Text('Zobacz aplikacje ($count)'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 48),
          ),
        ),
      );
    },
  );
}

Stream<int> _getApplicationCountStream() {
  // Listen to WebSocket for application updates
  return ref.watch(taskApplicationCountProvider(_taskId)).stream;
}
Phase 3: Contractor Side UI (Day 6-7)
MODIFY: task_alert_screen.dart
Changes:

Line 486: Change button text


// OLD
child: Text('PRZYJMIJ ZLECENIE'),

// NEW
child: Text('APLIKUJ NA ZLECENIE'),
Lines 501-520: Update accept handler


Future<void> _handleApply() async {
  setState(() => _isLoading = true);

  try {
    await ref.read(taskServiceProvider).applyToTask(_task.id);

    if (!mounted) return;

    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Aplikacja wysłana!'),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 3),
      ),
    );

    // Go back to home (not to active task)
    context.go(Routes.contractorHome);

  } catch (e) {
    _showError(e.toString());
  } finally {
    setState(() => _isLoading = false);
  }
}
NEW: application_status_screen.dart
File: mobile/lib/features/contractor/screens/application_status_screen.dart

Shows contractor's pending applications:


class ApplicationStatusScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(contractorApplicationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Moje aplikacje')),
      body: applications.isEmpty
          ? Center(child: Text('Nie masz aktywnych aplikacji'))
          : ListView.builder(
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final app = applications[index];
                return _ApplicationCard(application: app);
              },
            ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final TaskApplication application;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(application.task.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aplikowano: ${_formatTime(application.appliedAt)}'),
            Text('Status: Oczekuje na wybór klienta'),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => _withdrawApplication(context),
        ),
      ),
    );
  }
}
WebSocket listener (in provider):


// When application selected → Navigate to active task
ref.listen(taskApplicationSelectedProvider, (previous, next) {
  if (next != null) {
    context.go(Routes.contractorTask(next.taskId));
  }
});

// When application rejected → Show toast
ref.listen(taskApplicationRejectedProvider, (previous, next) {
  if (next != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Klient wybrał innego wykonawcę')),
    );
  }
});
MODIFY: active_task_screen.dart
Changes:

Remove "Oczekuje" step from progress (line 336)

// OLD
const steps = ['Oczekuje', 'Potwierdzone', 'W trakcie', 'Zakończono'];

// NEW
const steps = ['Potwierdzone', 'W trakcie', 'Zakończono'];
Remove accepted status handling (lines 512-570)

// DELETE lines 512-570 (waiting for client confirmation state)
// Task only appears in ActiveTaskScreen when status = confirmed
Update button logic (line 630)

// Start from confirmed immediately
if (widget.task.status == ContractorTaskStatus.confirmed) {
  buttonText = 'Rozpocznij';
  onPressed = _startTask;
}
Risk Mitigation
1. Race Condition: Multiple Contractors Apply Simultaneously
Risk: Database integrity violation

Solution:

UNIQUE constraint on (taskId, contractorId)
Catch PostgreSQL error code 23505
Return user-friendly message: "Już aplikowałeś na to zlecenie"
2. Race Condition: Client Selects During Contractor Withdrawal
Risk: Selected application doesn't exist

Solution:

Use database transaction with row lock
Check application.status = PENDING before selecting
If failed: Return 409 Conflict
3. WebSocket Message Loss
Risk: Client doesn't see new applications

Solutions:

Persist all events in event_log table
Push notification backup for offline clients
Fetch missed events on reconnect using lastEventId
4. Application Expires While Client Reviewing
Risk: Client tries to select expired application

Solution:

1-hour expiration window
Show countdown timer in UI
Extend expiration when client opens applicants screen
Check expiresAt before selection
5. Payment Failure After Selection
Risk: Contractor notified but payment didn't process

Solution:

Create payment intent BEFORE database transaction
Only commit transaction if payment succeeds
Rollback on payment failure
Retry mechanism with idempotency key
6. No Contractors Apply
Risk: Task sits unfulfilled

Solution:

Tiered re-notification (see Decision 2)
Suggest budget increase after 30 min
Admin alert after 2 hours
Auto-cancel + refund after 24 hours
Testing Strategy
Unit Tests (Day 6)
File: backend/src/tasks/tasks.service.spec.ts

Scenarios:

✅ applyToTask() creates application successfully
✅ Duplicate application throws 409
✅ Application limit (10) enforced
✅ selectApplication() updates task + applications atomically
✅ Other applications rejected when one selected
✅ withdrawApplication() marks as withdrawn
✅ Expired applications cleaned up
✅ Re-notification triggers for low-interest tasks
Target: 90%+ coverage on new code

Integration Tests (Day 6-7)
File: backend/test/tasks-applications.e2e-spec.ts

Full flow tests:

Create task → 5 contractors notified
3 contractors apply
Client fetches applications
Client selects contractor
Selected contractor receives notification
Other contractors receive rejection
Task status = CONFIRMED
Race condition tests:

Two contractors apply at exact same time (use Promise.all)
Client selects while contractor withdraws
Application expires during selection
Backward compatibility:

/accept endpoint with <3 applications auto-assigns
/accept endpoint with ≥3 applications creates pending
Mobile Widget Tests (Day 7)
Files:

test/features/client/screens/applicants_list_screen_test.dart
test/features/contractor/screens/task_alert_screen_test.dart
Scenarios:

Empty state shows "Szukamy wykonawcy..."
Applicant cards render correctly
Select button triggers payment popup
WebSocket updates add new applicants
Apply button sends correct API call
Manual QA Checklist (Day 7)
Client Flow:

 Create task → See "Szukamy wykonawcy..." screen
 First application arrives → Button appears
 Click "Zobacz aplikacje" → See list
 Applicant cards show all details correctly
 Click "Wybierz" → Payment popup appears
 Select payment → Task confirmed
 WebSocket updates in real-time
Contractor Flow:

 See new task notification
 Click "Aplikuj" → Success message
 Navigate back to home
 Application appears in "Moje aplikacje"
 Get selected → Navigate to active task
 Get rejected → See toast notification
Edge Cases:

 Apply to same task twice → Error
 10 applications reached → Error
 Application expires → Can't be selected
 Client offline → Push notification received
 Network error during selection → Proper error handling
Success Metrics
Must Have (MVP):

✅ Contractors can apply to tasks
✅ Clients see list of applicants
✅ Clients can select from list
✅ Real-time WebSocket notifications work
✅ No data loss or race conditions
✅ 90%+ test coverage on new code
✅ Zero breaking changes for mobile app v1.0
Should Have:

✅ Application expiration after 1 hour
✅ Tiered re-notification for low interest
✅ <500ms API response time
✅ Graceful degradation when WebSocket fails
Nice to Have (Phase 2):

⭕ Contractor bidding (custom prices)
⭕ Application analytics dashboard
⭕ A/B testing for notification timing
⭕ Machine learning for ranking
Rollout Plan
Week 1: Backend Implementation
Days 1-2: Database + Entity + DTOs
Days 3-4: Service methods + Controllers
Day 5: WebSocket + Cron jobs
Days 6-7: Testing
Week 2: Mobile Implementation
Days 1-2: Models + Services
Days 3-5: Client UI
Days 6-7: Contractor UI + Testing
Week 3: Integration & QA
Days 1-2: Integration testing
Days 3-4: Manual QA + Bug fixes
Day 5: Performance testing
Days 6-7: Deployment preparation
Week 4: Staged Rollout
Day 1: Deploy to staging
Days 2-3: Beta testing with 10 users
Days 4-5: Fix issues, deploy to prod (10% rollout)
Day 6: Monitor, increase to 50%
Day 7: Full rollout to 100%
Critical Files Summary
Backend (Must Modify/Create)
backend/src/tasks/entities/task-application.entity.ts - NEW
backend/src/tasks/tasks.service.ts - MODIFY (add 6 methods)
backend/src/tasks/tasks.controller.ts - MODIFY (add 4 endpoints)
backend/src/realtime/realtime.gateway.ts - MODIFY (add 3 event methods)
backend/src/tasks/tasks.module.ts - MODIFY (register entity)
backend/src/app.module.ts - MODIFY (add entity to TypeORM)
backend/src/tasks/dto/create-application.dto.ts - NEW
backend/src/tasks/tasks.service.spec.ts - MODIFY (add tests)
backend/test/tasks-applications.e2e-spec.ts - NEW
Mobile (Must Modify/Create)
mobile/lib/features/client/screens/applicants_list_screen.dart - NEW
mobile/lib/features/client/widgets/applicant_card.dart - NEW
mobile/lib/features/client/screens/task_tracking_screen.dart - MODIFY
mobile/lib/features/contractor/screens/task_alert_screen.dart - MODIFY
mobile/lib/features/contractor/screens/application_status_screen.dart - NEW
mobile/lib/features/contractor/screens/active_task_screen.dart - MODIFY
mobile/lib/core/models/task_application.dart - NEW
mobile/lib/core/models/applicant.dart - NEW
mobile/lib/core/services/task_service.dart - MODIFY
Verification & Testing
End-to-End Test Scenario
Setup:

Start backend: cd backend && npm run start:dev
Start PostgreSQL: docker-compose up -d postgres
Seed database: cd backend && npm run seed
Start mobile app: cd mobile && flutter run
Test Flow:

Client creates task (mobile)

Login as client (+48111111111)
Create new task in "paczki" category
Verify WebSocket notification sent to contractors
Verify "Szukamy wykonawcy..." screen shows
Contractors apply (3 different devices/emulators)

Login as contractor 1 (+48222222221)
See task notification
Click "Aplikuj" → Success message
Repeat for contractors 2 and 3
Client sees applicants

Return to client app
See "Zobacz aplikacje (3)" button
Click → See list of 3 applicants
Verify all details (rating, distance, etc.)
Client selects contractor

Click "Wybierz" on contractor 2
Payment popup appears
Select "Gotówka"
Task status → CONFIRMED
Notifications received

Contractor 2: "Gratulacje! Klient wybrał Cię" → Navigate to ActiveTaskScreen
Contractors 1 & 3: "Klient wybrał innego wykonawcę" → Toast
Continue normal flow

Contractor 2: Click "Rozpocznij" → IN_PROGRESS
Client: See map with contractor location
Complete task → Rating → COMPLETED
Expected Results:

✅ All WebSocket messages received
✅ No errors in logs
✅ Database consistent (applications updated, task assigned)
✅ UI responsive and smooth
Documentation Requirements
After implementation:

Update currentupdate.md with all changes
Create docs/task-summaries/contractor-applications-2026-02-XX.md with:
Full implementation details
Code examples
Test results
API documentation
Update tasks/CONTRACTOR_MATCHING.md with new flow
Update CLAUDE.md if needed (new conventions)
Approved for Implementation
Estimated Timeline: 3 weeks
Risk Level: Medium (significant architectural change)
Backward Compatibility: Yes (legacy endpoint for 2 releases)
Breaking Changes: None

Ready to implement? ✅