import { Suspense } from 'react';
import MarketplaceGrid from '@/components/game/MarketplaceGrid';

export const dynamic = 'force-dynamic';

export default function MarketplacePage() {
  return (
    <div className="min-h-screen py-20">
      <div className="container mx-auto px-4">
        <h1 className="font-display text-4xl md:text-5xl text-center mb-4">
          <span className="bg-gradient-to-r from-ant-gold to-primary bg-clip-text text-transparent">
            Ant Marketplace
          </span>
        </h1>
        <p className="text-center text-gray-400 mb-12">
          Collect and trade unique soldier ants with verifiable genetics
        </p>
        
        <Suspense fallback={<div>Loading marketplace...</div>}>
          <MarketplaceGrid />
        </Suspense>
      </div>
    </div>
  );
}