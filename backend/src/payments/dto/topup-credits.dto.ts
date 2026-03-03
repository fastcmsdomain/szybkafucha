import { IsNumber, Min } from 'class-validator';

export class TopupCreditsDto {
  @IsNumber()
  @Min(20, { message: 'Minimalna kwota doładowania to 20 zł' })
  amount: number;
}
