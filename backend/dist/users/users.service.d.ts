import { Repository } from 'typeorm';
import { User, UserStatus } from './entities/user.entity';
export declare class UsersService {
    private readonly usersRepository;
    constructor(usersRepository: Repository<User>);
    findById(id: string): Promise<User | null>;
    findByIdOrFail(id: string): Promise<User>;
    findByPhone(phone: string): Promise<User | null>;
    findByEmail(email: string): Promise<User | null>;
    findByGoogleId(googleId: string): Promise<User | null>;
    findByAppleId(appleId: string): Promise<User | null>;
    create(data: Partial<User>): Promise<User>;
    update(id: string, data: Partial<User>): Promise<User>;
    updateStatus(id: string, status: UserStatus): Promise<User>;
    updateFcmToken(id: string, fcmToken: string): Promise<User>;
    activate(id: string): Promise<User>;
}
