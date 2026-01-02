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
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const config_1 = require("@nestjs/config");
const users_service_1 = require("../users/users.service");
const user_entity_1 = require("../users/entities/user.entity");
const otpStore = new Map();
const OTP_CONFIG = {
    LENGTH: 6,
    EXPIRES_IN_MINUTES: 5,
};
let AuthService = class AuthService {
    usersService;
    jwtService;
    configService;
    constructor(usersService, jwtService, configService) {
        this.usersService = usersService;
        this.jwtService = jwtService;
        this.configService = configService;
    }
    generateToken(user) {
        const payload = {
            sub: user.id,
            type: user.type,
        };
        return {
            accessToken: this.jwtService.sign(payload),
            user: {
                id: user.id,
                type: user.type,
                name: user.name,
                email: user.email,
                phone: user.phone,
                avatarUrl: user.avatarUrl,
                status: user.status,
            },
        };
    }
    async requestPhoneOtp(phone) {
        const normalizedPhone = this.normalizePhone(phone);
        const code = this.generateOtp();
        const expiresAt = new Date(Date.now() + OTP_CONFIG.EXPIRES_IN_MINUTES * 60 * 1000);
        otpStore.set(normalizedPhone, { code, expiresAt });
        console.log(`[DEV] OTP for ${normalizedPhone}: ${code}`);
        return {
            message: 'OTP sent successfully',
            expiresIn: OTP_CONFIG.EXPIRES_IN_MINUTES * 60,
        };
    }
    async verifyPhoneOtp(phone, code, userType) {
        const normalizedPhone = this.normalizePhone(phone);
        const storedOtp = otpStore.get(normalizedPhone);
        if (!storedOtp) {
            throw new common_1.BadRequestException('OTP not found. Please request a new one.');
        }
        if (new Date() > storedOtp.expiresAt) {
            otpStore.delete(normalizedPhone);
            throw new common_1.BadRequestException('OTP expired. Please request a new one.');
        }
        if (storedOtp.code !== code) {
            throw new common_1.BadRequestException('Invalid OTP code.');
        }
        otpStore.delete(normalizedPhone);
        let user = await this.usersService.findByPhone(normalizedPhone);
        let isNewUser = false;
        if (!user) {
            isNewUser = true;
            user = await this.usersService.create({
                phone: normalizedPhone,
                type: userType || user_entity_1.UserType.CLIENT,
                status: user_entity_1.UserStatus.ACTIVE,
            });
        }
        const token = this.generateToken(user);
        return { ...token, isNewUser };
    }
    async authenticateWithGoogle(googleId, email, name, avatarUrl, userType) {
        let user = await this.usersService.findByGoogleId(googleId);
        let isNewUser = false;
        if (!user) {
            user = await this.usersService.findByEmail(email);
            if (user) {
                user = await this.usersService.update(user.id, { googleId });
            }
            else {
                isNewUser = true;
                user = await this.usersService.create({
                    googleId,
                    email,
                    name,
                    avatarUrl,
                    type: userType || user_entity_1.UserType.CLIENT,
                    status: user_entity_1.UserStatus.ACTIVE,
                });
            }
        }
        const token = this.generateToken(user);
        return { ...token, isNewUser };
    }
    async authenticateWithApple(appleId, email, name, userType) {
        let user = await this.usersService.findByAppleId(appleId);
        let isNewUser = false;
        if (!user) {
            if (email) {
                user = await this.usersService.findByEmail(email);
                if (user) {
                    user = await this.usersService.update(user.id, { appleId });
                }
            }
            if (!user) {
                isNewUser = true;
                user = await this.usersService.create({
                    appleId,
                    email,
                    name,
                    type: userType || user_entity_1.UserType.CLIENT,
                    status: user_entity_1.UserStatus.ACTIVE,
                });
            }
        }
        const token = this.generateToken(user);
        return { ...token, isNewUser };
    }
    generateOtp() {
        return Math.floor(100000 + Math.random() * 900000).toString();
    }
    normalizePhone(phone) {
        let normalized = phone.replace(/[^\d+]/g, '');
        if (!normalized.startsWith('+')) {
            if (normalized.length === 9) {
                normalized = `+48${normalized}`;
            }
        }
        return normalized;
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [users_service_1.UsersService,
        jwt_1.JwtService,
        config_1.ConfigService])
], AuthService);
//# sourceMappingURL=auth.service.js.map