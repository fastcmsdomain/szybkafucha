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
exports.ContractorService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const contractor_profile_entity_1 = require("./entities/contractor-profile.entity");
let ContractorService = class ContractorService {
    contractorRepository;
    constructor(contractorRepository) {
        this.contractorRepository = contractorRepository;
    }
    async findByUserId(userId) {
        return this.contractorRepository.findOne({
            where: { userId },
            relations: ['user'],
        });
    }
    async findByUserIdOrFail(userId) {
        const profile = await this.findByUserId(userId);
        if (!profile) {
            throw new common_1.NotFoundException('Contractor profile not found');
        }
        return profile;
    }
    async create(userId) {
        const existing = await this.findByUserId(userId);
        if (existing) {
            return existing;
        }
        const profile = this.contractorRepository.create({
            userId,
            categories: [],
        });
        return this.contractorRepository.save(profile);
    }
    async update(userId, dto) {
        const profile = await this.findByUserIdOrFail(userId);
        if (dto.bio !== undefined) {
            profile.bio = dto.bio;
        }
        if (dto.categories !== undefined) {
            profile.categories = dto.categories;
        }
        if (dto.serviceRadiusKm !== undefined) {
            profile.serviceRadiusKm = dto.serviceRadiusKm;
        }
        return this.contractorRepository.save(profile);
    }
    async setAvailability(userId, isOnline) {
        const profile = await this.findByUserIdOrFail(userId);
        if (isOnline && profile.kycStatus !== contractor_profile_entity_1.KycStatus.VERIFIED) {
            throw new common_1.BadRequestException('Complete KYC verification before going online');
        }
        profile.isOnline = isOnline;
        return this.contractorRepository.save(profile);
    }
    async updateLocation(userId, location) {
        const profile = await this.findByUserIdOrFail(userId);
        profile.lastLocationLat = location.lat;
        profile.lastLocationLng = location.lng;
        profile.lastLocationAt = new Date();
        return this.contractorRepository.save(profile);
    }
    async submitKycId(userId, documentUrl) {
        const profile = await this.findByUserIdOrFail(userId);
        profile.kycIdVerified = true;
        await this.updateKycStatus(profile);
        return this.contractorRepository.save(profile);
    }
    async submitKycSelfie(userId, selfieUrl) {
        const profile = await this.findByUserIdOrFail(userId);
        profile.kycSelfieVerified = true;
        await this.updateKycStatus(profile);
        return this.contractorRepository.save(profile);
    }
    async submitKycBank(userId, iban, accountHolder) {
        const profile = await this.findByUserIdOrFail(userId);
        if (!this.validateIban(iban)) {
            throw new common_1.BadRequestException('Invalid IBAN format');
        }
        profile.kycBankVerified = true;
        await this.updateKycStatus(profile);
        return this.contractorRepository.save(profile);
    }
    async updateRating(userId, newRating) {
        const profile = await this.findByUserIdOrFail(userId);
        const totalRatings = profile.ratingCount * Number(profile.ratingAvg) + newRating;
        profile.ratingCount += 1;
        profile.ratingAvg = Number((totalRatings / profile.ratingCount).toFixed(2));
        return this.contractorRepository.save(profile);
    }
    async incrementCompletedTasks(userId) {
        const profile = await this.findByUserIdOrFail(userId);
        profile.completedTasksCount += 1;
        return this.contractorRepository.save(profile);
    }
    async updateKycStatus(profile) {
        if (profile.kycIdVerified &&
            profile.kycSelfieVerified &&
            profile.kycBankVerified) {
            profile.kycStatus = contractor_profile_entity_1.KycStatus.VERIFIED;
        }
    }
    validateIban(iban) {
        const cleanIban = iban.replace(/\s/g, '').toUpperCase();
        if (cleanIban.length < 15 || cleanIban.length > 34) {
            return false;
        }
        const ibanRegex = /^[A-Z]{2}[0-9]{2}[A-Z0-9]+$/;
        return ibanRegex.test(cleanIban);
    }
};
exports.ContractorService = ContractorService;
exports.ContractorService = ContractorService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(contractor_profile_entity_1.ContractorProfile)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], ContractorService);
//# sourceMappingURL=contractor.service.js.map