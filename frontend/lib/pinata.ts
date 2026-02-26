import { PinataSDK } from 'pinata';

if (!process.env.PINATA_JWT) {
  throw new Error('PINATA_JWT is not defined');
}

if (!process.env.NEXT_PUBLIC_PINATA_GATEWAY) {
  throw new Error('NEXT_PUBLIC_PINATA_GATEWAY is not defined');
}

export const pinata = new PinataSDK({
  pinataJwt: process.env.PINATA_JWT,
  pinataGateway: process.env.NEXT_PUBLIC_PINATA_GATEWAY,
});

export interface NFTMetadata {
  name: string;
  description: string;
  image: string;
  attributes: Array<{
    trait_type: string;
    value: string | number;
  }>;
}