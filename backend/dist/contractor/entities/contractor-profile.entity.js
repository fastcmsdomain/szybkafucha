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
Object.defineProperty(exports, "__esModule", { value: true });
exports.ContractorProfile = exports.TaskCategory = exports.KycStatus = void 0;
const typeorm_1 = require("typeorm");
const user_entity_1 = require("../../users/entities/user.entity");
var KycStatus;
(function (KycStatus) {
    KycStatus["PENDING"] = "pending";
    KycStatus["VERIFIED"] = "verified";
    KycStatus["REJECTED"] = "rejected";
})(KycStatus || (exports.KycStatus = KycStatus = {}));
var TaskCategory;
(function (TaskCategory) {
    TaskCategory["PACZKI"] = "paczki";
    TaskCategory["ZAKUPY"] = "zakupy";
    TaskCategory["KOLEJKI"] = "kolejki";
    TaskCategory["MONTAZ"] = "montaz";
    TaskCategory["PRZEPROWADZKI"] = "przeprowadzki";
    TaskCategory["SPRZATANIE"] = "sprzatanie";
})(TaskCategory || (exports.TaskCategory = TaskCategory = {}));
let ContractorProfile = class ContractorProfile {
    userId;
    user;
    bio;
    categories;
    serviceRadiusKm;
    kycStatus;
    kycIdVerified;
    kycSelfieVerified;
    kycBankVerified;
    stripeAccountId;
    ratingAvg;
    ratingCount;
    completedTasksCount;
    isOnline;
    lastLocationLat;
    lastLocationLng;
    lastLocationAt;
    createdAt;
    updatedAt;
};
exports.ContractorProfile = ContractorProfile;
__decorate([
    (0, typeorm_1.PrimaryColumn)('uuid'),
    __metadata("design:type", String)
], ContractorProfile.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.OneToOne)(() => user_entity_1.User),
    (0, typeorm_1.JoinColumn)({ name: 'userId' }),
    __metadata("design:type", user_entity_1.User)
], ContractorProfile.prototype, "user", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", Object)
], ContractorProfile.prototype, "bio", void 0);
__decorate([
    (0, typeorm_1.Column)('simple-array', { default: '' }),
    __metadata("design:type", Array)
], ContractorProfile.prototype, "categories", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'int', default: 10 }),
    __metadata("design:type", Number)
], ContractorProfile.prototype, "serviceRadiusKm", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: KycStatus,
        default: KycStatus.PENDING,
    }),
    __metadata("design:type", String)
], ContractorProfile.prototype, "kycStatus", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'boolean', default: false }),
    __metadata("design:type", Boolean)
], ContractorProfile.prototype, "kycIdVerified", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'boolean', default: false }),
    __metadata("design:type", Boolean)
], ContractorProfile.prototype, "kycSelfieVerified", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'boolean', default: false }),
    __metadata("design:type", Boolean)
], ContractorProfile.prototype, "kycBankVerified", void 0);
__decorate([
    (0, typeorm_1.Column)({ length: 255, nullable: true }),
    __metadata("design:type", Object)
], ContractorProfile.prototype, "stripeAccountId", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'decimal', precision: 3, scale: 2, default: 0 }),
    __metadata("design:type", Number)
], ContractorProfile.prototype, "ratingAvg", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'int', default: 0 }),
    __metadata("design:type", Number)
], ContractorProfile.prototype, "ratingCount", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'int', default: 0 }),
    __metadata("design:type", Number)
], ContractorProfile.prototype, "completedTasksCount", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'boolean', default: false }),
    __metadata("design:type", Boolean)
], ContractorProfile.prototype, "isOnline", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'decimal', precision: 10, scale: 7, nullable: true }),
    __metadata("design:type", Object)
], ContractorProfile.prototype, "lastLocationLat", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'decimal', precision: 10, scale: 7, nullable: true }),
    __metadata("design:type", Object)
], ContractorProfile.prototype, "lastLocationLng", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'timestamp', nullable: true }),
    __metadata("design:type", Object)
], ContractorProfile.prototype, "lastLocationAt", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], ContractorProfile.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)(),
    __metadata("design:type", Date)
], ContractorProfile.prototype, "updatedAt", void 0);
exports.ContractorProfile = ContractorProfile = __decorate([
    (0, typeorm_1.Entity)('contractor_profiles')
], ContractorProfile);
//# sourceMappingURL=contractor-profile.entity.js.map