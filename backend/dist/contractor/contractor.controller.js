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
exports.ContractorController = void 0;
const common_1 = require("@nestjs/common");
const contractor_service_1 = require("./contractor.service");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const update_contractor_profile_dto_1 = require("./dto/update-contractor-profile.dto");
const update_location_dto_1 = require("./dto/update-location.dto");
let ContractorController = class ContractorController {
    contractorService;
    constructor(contractorService) {
        this.contractorService = contractorService;
    }
    async getProfile(req) {
        let profile = await this.contractorService.findByUserId(req.user.id);
        if (!profile) {
            profile = await this.contractorService.create(req.user.id);
        }
        return profile;
    }
    async updateProfile(req, dto) {
        await this.contractorService.findByUserId(req.user.id) ||
            await this.contractorService.create(req.user.id);
        return this.contractorService.update(req.user.id, dto);
    }
    async setAvailability(req, isOnline) {
        return this.contractorService.setAvailability(req.user.id, isOnline);
    }
    async updateLocation(req, dto) {
        return this.contractorService.updateLocation(req.user.id, dto);
    }
    async submitKycId(req, documentUrl) {
        return this.contractorService.submitKycId(req.user.id, documentUrl);
    }
    async submitKycSelfie(req, selfieUrl) {
        return this.contractorService.submitKycSelfie(req.user.id, selfieUrl);
    }
    async submitKycBank(req, iban, accountHolder) {
        return this.contractorService.submitKycBank(req.user.id, iban, accountHolder);
    }
};
exports.ContractorController = ContractorController;
__decorate([
    (0, common_1.Get)('profile'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ContractorController.prototype, "getProfile", null);
__decorate([
    (0, common_1.Put)('profile'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, update_contractor_profile_dto_1.UpdateContractorProfileDto]),
    __metadata("design:returntype", Promise)
], ContractorController.prototype, "updateProfile", null);
__decorate([
    (0, common_1.Put)('availability'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)('isOnline')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Boolean]),
    __metadata("design:returntype", Promise)
], ContractorController.prototype, "setAvailability", null);
__decorate([
    (0, common_1.Put)('location'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, update_location_dto_1.UpdateLocationDto]),
    __metadata("design:returntype", Promise)
], ContractorController.prototype, "updateLocation", null);
__decorate([
    (0, common_1.Post)('kyc/id'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)('documentUrl')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], ContractorController.prototype, "submitKycId", null);
__decorate([
    (0, common_1.Post)('kyc/selfie'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)('selfieUrl')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], ContractorController.prototype, "submitKycSelfie", null);
__decorate([
    (0, common_1.Post)('kyc/bank'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)('iban')),
    __param(2, (0, common_1.Body)('accountHolder')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], ContractorController.prototype, "submitKycBank", null);
exports.ContractorController = ContractorController = __decorate([
    (0, common_1.Controller)('contractor'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [contractor_service_1.ContractorService])
], ContractorController);
//# sourceMappingURL=contractor.controller.js.map