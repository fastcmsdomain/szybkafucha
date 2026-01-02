"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TasksService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const task_entity_1 = require("./entities/task.entity");
const rating_entity_1 = require("./entities/rating.entity");
const COMMISSION_RATE = 0.17;
let TasksService = class TasksService {
    tasksRepository;
    ratingsRepository;
    constructor(tasksRepository, ratingsRepository) {
        this.tasksRepository = tasksRepository;
        this.ratingsRepository = ratingsRepository;
    }
    async create(clientId, dto) {
        const task = this.tasksRepository.create({
            ...dto,
            clientId,
            scheduledAt: dto.scheduledAt ? new Date(dto.scheduledAt) : null,
        });
        return this.tasksRepository.save(task);
    }
    async findById(id) {
        return this.tasksRepository.findOne({
            where: { id },
            relations: ['client', 'contractor'],
        });
    }
    async findByIdOrFail(id) {
        const task = await this.findById(id);
        if (!task) {
            throw new common_1.NotFoundException(`Task with ID ${id} not found`);
        }
        return task;
    }
    async findByClient(clientId) {
        return this.tasksRepository.find({
            where: { clientId },
            relations: ['contractor'],
            order: { createdAt: 'DESC' },
        });
    }
    async findAvailableForContractor(contractorId, categories, lat, lng, radiusKm = 10) {
        const tasks = await this.tasksRepository.find({
            where: { status: task_entity_1.TaskStatus.CREATED },
            relations: ['client'],
            order: { createdAt: 'DESC' },
        });
        return tasks.filter((task) => {
            if (!categories.includes(task.category)) {
                return false;
            }
            const distance = this.calculateDistance(lat, lng, Number(task.locationLat), Number(task.locationLng));
            return distance <= radiusKm;
        });
    }
    async acceptTask(taskId, contractorId) {
        const task = await this.findByIdOrFail(taskId);
        if (task.status !== task_entity_1.TaskStatus.CREATED) {
            throw new common_1.BadRequestException('Task is no longer available');
        }
        task.contractorId = contractorId;
        task.status = task_entity_1.TaskStatus.ACCEPTED;
        task.acceptedAt = new Date();
        return this.tasksRepository.save(task);
    }
    async startTask(taskId, contractorId) {
        const task = await this.findByIdOrFail(taskId);
        if (task.contractorId !== contractorId) {
            throw new common_1.ForbiddenException('You are not assigned to this task');
        }
        if (task.status !== task_entity_1.TaskStatus.ACCEPTED) {
            throw new common_1.BadRequestException('Task must be accepted before starting');
        }
        task.status = task_entity_1.TaskStatus.IN_PROGRESS;
        task.startedAt = new Date();
        return this.tasksRepository.save(task);
    }
    async completeTask(taskId, contractorId, completionPhotos) {
        const task = await this.findByIdOrFail(taskId);
        if (task.contractorId !== contractorId) {
            throw new common_1.ForbiddenException('You are not assigned to this task');
        }
        if (task.status !== task_entity_1.TaskStatus.IN_PROGRESS) {
            throw new common_1.BadRequestException('Task must be in progress to complete');
        }
        const finalAmount = task.budgetAmount;
        const commissionAmount = Number((Number(finalAmount) * COMMISSION_RATE).toFixed(2));
        task.status = task_entity_1.TaskStatus.COMPLETED;
        task.completedAt = new Date();
        task.finalAmount = finalAmount;
        task.commissionAmount = commissionAmount;
        task.completionPhotos = completionPhotos || null;
        return this.tasksRepository.save(task);
    }
    async confirmTask(taskId, clientId) {
        const task = await this.findByIdOrFail(taskId);
        if (task.clientId !== clientId) {
            throw new common_1.ForbiddenException('You are not the owner of this task');
        }
        if (task.status !== task_entity_1.TaskStatus.COMPLETED) {
            throw new common_1.BadRequestException('Task must be completed first');
        }
        return task;
    }
    async cancelTask(taskId, userId, reason) {
        const task = await this.findByIdOrFail(taskId);
        if (task.clientId === userId) {
            if (task.status !== task_entity_1.TaskStatus.CREATED) {
                throw new common_1.BadRequestException('Cannot cancel task after contractor accepted. Contact support.');
            }
        }
        else if (task.contractorId === userId) {
            if (task.status === task_entity_1.TaskStatus.COMPLETED) {
                throw new common_1.BadRequestException('Cannot cancel completed task');
            }
        }
        else {
            throw new common_1.ForbiddenException('You cannot cancel this task');
        }
        task.status = task_entity_1.TaskStatus.CANCELLED;
        task.cancelledAt = new Date();
        task.cancellationReason = reason || null;
        return this.tasksRepository.save(task);
    }
    async rateTask(taskId, fromUserId, toUserId, dto) {
        const task = await this.findByIdOrFail(taskId);
        if (task.status !== task_entity_1.TaskStatus.COMPLETED) {
            throw new common_1.BadRequestException('Can only rate completed tasks');
        }
        const existingRating = await this.ratingsRepository.findOne({
            where: { taskId, fromUserId },
        });
        if (existingRating) {
            throw new common_1.BadRequestException('You have already rated this task');
        }
        const rating = this.ratingsRepository.create({
            taskId,
            fromUserId,
            toUserId,
            rating: dto.rating,
            comment: dto.comment,
        });
        return this.ratingsRepository.save(rating);
    }
    async addTip(taskId, clientId, tipAmount) {
        const task = await this.findByIdOrFail(taskId);
        if (task.clientId !== clientId) {
            throw new common_1.ForbiddenException('You are not the owner of this task');
        }
        if (task.status !== task_entity_1.TaskStatus.COMPLETED) {
            throw new common_1.BadRequestException('Can only tip completed tasks');
        }
        task.tipAmount = tipAmount;
        return this.tasksRepository.save(task);
    }
    calculateDistance(lat1, lng1, lat2, lng2) {
        const R = 6371;
        const dLat = this.deg2rad(lat2 - lat1);
        const dLng = this.deg2rad(lng2 - lng1);
        const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(this.deg2rad(lat1)) *
                Math.cos(this.deg2rad(lat2)) *
                Math.sin(dLng / 2) *
                Math.sin(dLng / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
    deg2rad(deg) {
        return deg * (Math.PI / 180);
    }
};
exports.TasksService = TasksService;
exports.TasksService = TasksService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(task_entity_1.Task)),
    __param(1, (0, typeorm_1.InjectRepository)(rating_entity_1.Rating)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository])
], TasksService);
//# sourceMappingURL=tasks.service.js.map