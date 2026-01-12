/**
 * Realtime Gateway Unit Tests
 * Tests for WebSocket gateway functionality
 */
import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { Socket, Server } from 'socket.io';
import { RealtimeGateway, ServerEvent, ClientEvent } from './realtime.gateway';
import { RealtimeService } from './realtime.service';
import { TaskStatus } from '../tasks/entities/task.entity';

describe('RealtimeGateway', () => {
  let gateway: RealtimeGateway;
  let realtimeService: jest.Mocked<RealtimeService>;
  let jwtService: jest.Mocked<JwtService>;
  let mockServer: jest.Mocked<Server>;

  const mockSocket = (overrides = {}): jest.Mocked<Socket> =>
    ({
      id: 'socket-123',
      data: {},
      handshake: {
        query: {},
        headers: {},
        auth: {},
      },
      emit: jest.fn(),
      disconnect: jest.fn(),
      join: jest.fn(),
      leave: jest.fn(),
      ...overrides,
    } as unknown as jest.Mocked<Socket>);

  beforeEach(async () => {
    const mockRealtimeService = {
      registerConnection: jest.fn(),
      removeConnection: jest.fn(),
      joinTaskRoom: jest.fn(),
      leaveTaskRoom: jest.fn(),
      updateLocation: jest.fn(),
      saveMessage: jest.fn(),
      markMessagesRead: jest.fn(),
      isUserAuthorizedForTask: jest.fn(),
      getSocketForUser: jest.fn(),
      getActiveConnectionsCount: jest.fn(),
    };

    const mockJwtService = {
      verify: jest.fn(),
    };

    mockServer = {
      emit: jest.fn(),
      to: jest.fn().mockReturnThis(),
      sockets: {
        adapter: {
          rooms: new Map(),
        },
      },
    } as unknown as jest.Mocked<Server>;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RealtimeGateway,
        { provide: RealtimeService, useValue: mockRealtimeService },
        { provide: JwtService, useValue: mockJwtService },
      ],
    }).compile();

    gateway = module.get<RealtimeGateway>(RealtimeGateway);
    realtimeService = module.get(RealtimeService);
    jwtService = module.get(JwtService);

    // Inject mock server
    (gateway as any).server = mockServer;
  });

  describe('afterInit', () => {
    it('should log initialization', () => {
      const logSpy = jest.spyOn((gateway as any).logger, 'log');

      gateway.afterInit(mockServer);

      expect(logSpy).toHaveBeenCalledWith('WebSocket Gateway initialized');
    });
  });

  describe('handleConnection', () => {
    it('should authenticate and register valid connection', async () => {
      const socket = mockSocket({
        handshake: {
          query: { token: 'valid-token' },
          headers: {},
          auth: {},
        },
      });

      jwtService.verify.mockReturnValue({ sub: 'user-123', type: 'client' });

      await gateway.handleConnection(socket);

      expect(jwtService.verify).toHaveBeenCalledWith('valid-token');
      expect(realtimeService.registerConnection).toHaveBeenCalledWith(
        'socket-123',
        'user-123',
        'client',
      );
      expect(socket.data.userId).toBe('user-123');
      expect(socket.data.userType).toBe('client');
      expect(mockServer.emit).toHaveBeenCalledWith(ServerEvent.USER_ONLINE, {
        userId: 'user-123',
        userType: 'client',
      });
    });

    it('should disconnect when no token provided', async () => {
      const socket = mockSocket();

      await gateway.handleConnection(socket);

      expect(socket.emit).toHaveBeenCalledWith(ServerEvent.ERROR, {
        message: 'Authentication required',
      });
      expect(socket.disconnect).toHaveBeenCalled();
      expect(realtimeService.registerConnection).not.toHaveBeenCalled();
    });

    it('should disconnect on invalid token', async () => {
      const socket = mockSocket({
        handshake: {
          query: { token: 'invalid-token' },
          headers: {},
          auth: {},
        },
      });

      jwtService.verify.mockImplementation(() => {
        throw new Error('Invalid token');
      });

      await gateway.handleConnection(socket);

      expect(socket.emit).toHaveBeenCalledWith(ServerEvent.ERROR, {
        message: 'Invalid authentication token',
      });
      expect(socket.disconnect).toHaveBeenCalled();
    });

    it('should extract token from auth header', async () => {
      const socket = mockSocket({
        handshake: {
          query: {},
          headers: { authorization: 'Bearer header-token' },
          auth: {},
        },
      });

      jwtService.verify.mockReturnValue({ sub: 'user-123', type: 'contractor' });

      await gateway.handleConnection(socket);

      expect(jwtService.verify).toHaveBeenCalledWith('header-token');
    });

    it('should extract token from auth object', async () => {
      const socket = mockSocket({
        handshake: {
          query: {},
          headers: {},
          auth: { token: 'auth-object-token' },
        },
      });

      jwtService.verify.mockReturnValue({ sub: 'user-123', type: 'client' });

      await gateway.handleConnection(socket);

      expect(jwtService.verify).toHaveBeenCalledWith('auth-object-token');
    });

    it('should default userType to client when not specified', async () => {
      const socket = mockSocket({
        handshake: {
          query: { token: 'valid-token' },
          headers: {},
          auth: {},
        },
      });

      jwtService.verify.mockReturnValue({ sub: 'user-123' }); // No type

      await gateway.handleConnection(socket);

      expect(realtimeService.registerConnection).toHaveBeenCalledWith(
        'socket-123',
        'user-123',
        'client',
      );
    });
  });

  describe('handleDisconnect', () => {
    it('should remove connection and emit offline event', () => {
      const socket = mockSocket();
      socket.data.userId = 'user-123';
      socket.data.userType = 'contractor';

      gateway.handleDisconnect(socket);

      expect(realtimeService.removeConnection).toHaveBeenCalledWith('socket-123');
      expect(mockServer.emit).toHaveBeenCalledWith(ServerEvent.USER_OFFLINE, {
        userId: 'user-123',
        userType: 'contractor',
      });
    });

    it('should not emit offline event when no userId', () => {
      const socket = mockSocket();

      gateway.handleDisconnect(socket);

      expect(realtimeService.removeConnection).not.toHaveBeenCalled();
      expect(mockServer.emit).not.toHaveBeenCalled();
    });
  });

  describe('handleLocationUpdate', () => {
    it('should update location for contractor', async () => {
      const socket = mockSocket();
      socket.data.userId = 'contractor-123';
      socket.data.userType = 'contractor';

      await gateway.handleLocationUpdate(socket, {
        latitude: 52.2297,
        longitude: 21.0122,
      });

      expect(realtimeService.updateLocation).toHaveBeenCalledWith({
        userId: 'contractor-123',
        latitude: 52.2297,
        longitude: 21.0122,
        timestamp: expect.any(Date),
      });
      expect(mockServer.emit).toHaveBeenCalledWith(
        ServerEvent.LOCATION_UPDATE,
        expect.objectContaining({
          userId: 'contractor-123',
          latitude: 52.2297,
          longitude: 21.0122,
        }),
      );
    });

    it('should reject location update from client', async () => {
      const socket = mockSocket();
      socket.data.userId = 'client-123';
      socket.data.userType = 'client';

      await gateway.handleLocationUpdate(socket, {
        latitude: 52.2297,
        longitude: 21.0122,
      });

      expect(socket.emit).toHaveBeenCalledWith(ServerEvent.ERROR, {
        message: 'Only contractors can update location',
      });
      expect(realtimeService.updateLocation).not.toHaveBeenCalled();
    });
  });

  describe('handleTaskJoin', () => {
    it('should join task room when authorized', async () => {
      const socket = mockSocket();
      socket.data.userId = 'user-123';

      realtimeService.isUserAuthorizedForTask.mockResolvedValue(true);

      const result = await gateway.handleTaskJoin(socket, { taskId: 'task-123' });

      expect(result.success).toBe(true);
      expect(socket.join).toHaveBeenCalledWith('task:task-123');
      expect(realtimeService.joinTaskRoom).toHaveBeenCalledWith('socket-123', 'task-123');
    });

    it('should reject unauthorized task join', async () => {
      const socket = mockSocket();
      socket.data.userId = 'user-123';

      realtimeService.isUserAuthorizedForTask.mockResolvedValue(false);

      const result = await gateway.handleTaskJoin(socket, { taskId: 'task-123' });

      expect(result.success).toBe(false);
      expect(result.error).toBe('Not authorized for this task');
      expect(socket.join).not.toHaveBeenCalled();
    });
  });

  describe('handleTaskLeave', () => {
    it('should leave task room', () => {
      const socket = mockSocket();
      socket.data.userId = 'user-123';

      const result = gateway.handleTaskLeave(socket, { taskId: 'task-123' });

      expect(result.success).toBe(true);
      expect(socket.leave).toHaveBeenCalledWith('task:task-123');
      expect(realtimeService.leaveTaskRoom).toHaveBeenCalledWith('socket-123', 'task-123');
    });
  });

  describe('handleMessageSend', () => {
    it('should save and broadcast message when authorized', async () => {
      const socket = mockSocket();
      socket.data.userId = 'user-123';

      realtimeService.isUserAuthorizedForTask.mockResolvedValue(true);
      realtimeService.saveMessage.mockResolvedValue({
        id: 'message-123',
        taskId: 'task-123',
        senderId: 'user-123',
        content: 'Hello',
        readAt: null,
        createdAt: new Date(),
        task: null as any,
        sender: null as any,
      });

      const result = await gateway.handleMessageSend(socket, {
        taskId: 'task-123',
        content: 'Hello',
      });

      expect(result.success).toBe(true);
      expect(result.messageId).toBe('message-123');
      expect(realtimeService.saveMessage).toHaveBeenCalledWith({
        taskId: 'task-123',
        senderId: 'user-123',
        content: 'Hello',
        createdAt: expect.any(Date),
      });
      expect(mockServer.to).toHaveBeenCalledWith('task:task-123');
      expect(mockServer.emit).toHaveBeenCalledWith(
        ServerEvent.MESSAGE_NEW,
        expect.objectContaining({
          id: 'message-123',
          taskId: 'task-123',
          senderId: 'user-123',
          content: 'Hello',
        }),
      );
    });

    it('should reject unauthorized message send', async () => {
      const socket = mockSocket();
      socket.data.userId = 'user-123';

      realtimeService.isUserAuthorizedForTask.mockResolvedValue(false);

      const result = await gateway.handleMessageSend(socket, {
        taskId: 'task-123',
        content: 'Hello',
      });

      expect(result.success).toBe(false);
      expect(result.error).toBe('Not authorized for this task');
      expect(realtimeService.saveMessage).not.toHaveBeenCalled();
    });
  });

  describe('handleMessageRead', () => {
    it('should mark messages as read and broadcast', async () => {
      const socket = mockSocket();
      socket.data.userId = 'user-123';

      const result = await gateway.handleMessageRead(socket, { taskId: 'task-123' });

      expect(result.success).toBe(true);
      expect(realtimeService.markMessagesRead).toHaveBeenCalledWith('task-123', 'user-123');
      expect(mockServer.to).toHaveBeenCalledWith('task:task-123');
      expect(mockServer.emit).toHaveBeenCalledWith(
        ServerEvent.MESSAGE_READ,
        expect.objectContaining({
          taskId: 'task-123',
          readBy: 'user-123',
          readAt: expect.any(Date),
        }),
      );
    });
  });

  describe('broadcastTaskStatus', () => {
    it('should broadcast task status to room', () => {
      gateway.broadcastTaskStatus('task-123', TaskStatus.IN_PROGRESS, 'contractor-123');

      expect(mockServer.to).toHaveBeenCalledWith('task:task-123');
      expect(mockServer.emit).toHaveBeenCalledWith(
        ServerEvent.TASK_STATUS,
        expect.objectContaining({
          taskId: 'task-123',
          status: TaskStatus.IN_PROGRESS,
          updatedBy: 'contractor-123',
          updatedAt: expect.any(Date),
        }),
      );
    });
  });

  describe('sendToUser', () => {
    it('should send event to specific user', () => {
      realtimeService.getSocketForUser.mockReturnValue('socket-456');

      const result = gateway.sendToUser('user-123', 'custom:event', { data: 'test' });

      expect(result).toBe(true);
      expect(mockServer.to).toHaveBeenCalledWith('socket-456');
      expect(mockServer.emit).toHaveBeenCalledWith('custom:event', { data: 'test' });
    });

    it('should return false when user not connected', () => {
      realtimeService.getSocketForUser.mockReturnValue(undefined);

      const result = gateway.sendToUser('offline-user', 'custom:event', { data: 'test' });

      expect(result).toBe(false);
    });
  });

  describe('getStats', () => {
    it('should return connection statistics', () => {
      realtimeService.getActiveConnectionsCount.mockReturnValue(10);
      (mockServer.sockets.adapter.rooms as Map<string, Set<string>>).set('room1', new Set());
      (mockServer.sockets.adapter.rooms as Map<string, Set<string>>).set('room2', new Set());
      (mockServer.sockets.adapter.rooms as Map<string, Set<string>>).set('room3', new Set());

      const stats = gateway.getStats();

      expect(stats.connections).toBe(10);
      expect(stats.rooms).toBe(3);
    });
  });
});

describe('RealtimeService', () => {
  let service: RealtimeService;
  let taskRepository: jest.Mocked<any>;
  let messageRepository: jest.Mocked<any>;
  let contractorProfileRepository: jest.Mocked<any>;
  let userRepository: jest.Mocked<any>;

  beforeEach(async () => {
    taskRepository = {
      findOne: jest.fn(),
    };

    messageRepository = {
      save: jest.fn(),
      find: jest.fn(),
      createQueryBuilder: jest.fn(() => ({
        update: jest.fn().mockReturnThis(),
        set: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        execute: jest.fn().mockResolvedValue({ affected: 1 }),
      })),
    };

    contractorProfileRepository = {
      update: jest.fn(),
    };

    userRepository = {
      findOne: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RealtimeService,
        { provide: 'TaskRepository', useValue: taskRepository },
        { provide: 'MessageRepository', useValue: messageRepository },
        { provide: 'ContractorProfileRepository', useValue: contractorProfileRepository },
        { provide: 'UserRepository', useValue: userRepository },
      ],
    })
      .overrideProvider(RealtimeService)
      .useFactory({
        factory: () => {
          const srv = new RealtimeService(
            taskRepository,
            messageRepository,
            contractorProfileRepository,
            userRepository,
          );
          return srv;
        },
      })
      .compile();

    service = module.get<RealtimeService>(RealtimeService);
  });

  describe('connection management', () => {
    it('should register and track connections', () => {
      service.registerConnection('socket-1', 'user-1', 'client');
      service.registerConnection('socket-2', 'user-2', 'contractor');

      expect(service.getActiveConnectionsCount()).toBe(2);
      expect(service.isUserOnline('user-1')).toBe(true);
      expect(service.isUserOnline('user-2')).toBe(true);
      expect(service.isUserOnline('user-3')).toBe(false);
    });

    it('should remove connections properly', () => {
      service.registerConnection('socket-1', 'user-1', 'client');
      service.removeConnection('socket-1');

      expect(service.getActiveConnectionsCount()).toBe(0);
      expect(service.isUserOnline('user-1')).toBe(false);
    });

    it('should return socket ID for user', () => {
      service.registerConnection('socket-abc', 'user-123', 'contractor');

      expect(service.getSocketForUser('user-123')).toBe('socket-abc');
      expect(service.getSocketForUser('unknown')).toBeUndefined();
    });

    it('should return connection info', () => {
      service.registerConnection('socket-1', 'user-1', 'contractor');

      const info = service.getConnectionInfo('socket-1');

      expect(info).toBeDefined();
      expect(info?.userId).toBe('user-1');
      expect(info?.userType).toBe('contractor');
      expect(info?.connectedAt).toBeInstanceOf(Date);
    });
  });

  describe('task rooms', () => {
    it('should join and leave task rooms', () => {
      service.joinTaskRoom('socket-1', 'task-123');
      service.joinTaskRoom('socket-2', 'task-123');

      expect(service.getTaskRoomSockets('task-123')).toHaveLength(2);

      service.leaveTaskRoom('socket-1', 'task-123');
      expect(service.getTaskRoomSockets('task-123')).toHaveLength(1);
    });

    it('should return empty array for non-existent room', () => {
      expect(service.getTaskRoomSockets('nonexistent')).toEqual([]);
    });

    it('should clean up empty rooms', () => {
      service.joinTaskRoom('socket-1', 'task-123');
      service.leaveTaskRoom('socket-1', 'task-123');

      expect(service.getTaskRoomSockets('task-123')).toEqual([]);
    });

    it('should remove user from all rooms on disconnect', () => {
      service.registerConnection('socket-1', 'user-1', 'client');
      service.joinTaskRoom('socket-1', 'task-1');
      service.joinTaskRoom('socket-1', 'task-2');

      service.removeConnection('socket-1');

      expect(service.getTaskRoomSockets('task-1')).toEqual([]);
      expect(service.getTaskRoomSockets('task-2')).toEqual([]);
    });
  });

  describe('contractor tracking', () => {
    it('should track online contractors', () => {
      service.registerConnection('socket-1', 'client-1', 'client');
      service.registerConnection('socket-2', 'contractor-1', 'contractor');
      service.registerConnection('socket-3', 'contractor-2', 'contractor');

      const onlineContractors = service.getOnlineContractors();

      expect(onlineContractors).toHaveLength(2);
      expect(onlineContractors).toContain('contractor-1');
      expect(onlineContractors).toContain('contractor-2');
    });

    it('should update contractor location', async () => {
      await service.updateLocation({
        userId: 'contractor-1',
        latitude: 52.2297,
        longitude: 21.0122,
        timestamp: new Date(),
      });

      expect(contractorProfileRepository.update).toHaveBeenCalledWith(
        'contractor-1',
        expect.objectContaining({
          lastLocationLat: 52.2297,
          lastLocationLng: 21.0122,
        }),
      );

      const location = service.getContractorLocation('contractor-1');
      expect(location).toBeDefined();
      expect(location?.latitude).toBe(52.2297);
    });
  });

  describe('task authorization', () => {
    it('should authorize client for their task', async () => {
      taskRepository.findOne.mockResolvedValue({
        clientId: 'client-123',
        contractorId: 'contractor-123',
      });

      const isAuthorized = await service.isUserAuthorizedForTask('client-123', 'task-123');

      expect(isAuthorized).toBe(true);
    });

    it('should authorize contractor for assigned task', async () => {
      taskRepository.findOne.mockResolvedValue({
        clientId: 'client-123',
        contractorId: 'contractor-123',
      });

      const isAuthorized = await service.isUserAuthorizedForTask('contractor-123', 'task-123');

      expect(isAuthorized).toBe(true);
    });

    it('should reject unauthorized user', async () => {
      taskRepository.findOne.mockResolvedValue({
        clientId: 'client-123',
        contractorId: 'contractor-123',
      });

      const isAuthorized = await service.isUserAuthorizedForTask('random-user', 'task-123');

      expect(isAuthorized).toBe(false);
    });

    it('should return false for non-existent task', async () => {
      taskRepository.findOne.mockResolvedValue(null);

      const isAuthorized = await service.isUserAuthorizedForTask('user-123', 'nonexistent');

      expect(isAuthorized).toBe(false);
    });
  });

  describe('messages', () => {
    it('should save chat message', async () => {
      const savedMessage = {
        id: 'message-123',
        taskId: 'task-123',
        senderId: 'user-123',
        content: 'Hello',
        createdAt: new Date(),
      };
      messageRepository.save.mockResolvedValue(savedMessage);

      const result = await service.saveMessage({
        taskId: 'task-123',
        senderId: 'user-123',
        content: 'Hello',
        createdAt: new Date(),
      });

      expect(result.id).toBe('message-123');
      expect(messageRepository.save).toHaveBeenCalled();
    });

    it('should get task messages', async () => {
      const messages = [
        { id: 'msg-1', content: 'Hello' },
        { id: 'msg-2', content: 'Hi' },
      ];
      messageRepository.find.mockResolvedValue(messages);

      const result = await service.getTaskMessages('task-123', 50);

      expect(result).toHaveLength(2);
      expect(messageRepository.find).toHaveBeenCalledWith({
        where: { taskId: 'task-123' },
        order: { createdAt: 'DESC' },
        take: 50,
        relations: ['sender'],
      });
    });

    it('should mark messages as read', async () => {
      await service.markMessagesRead('task-123', 'user-123');

      expect(messageRepository.createQueryBuilder).toHaveBeenCalled();
    });
  });
});
