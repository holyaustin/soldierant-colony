import { Suspense } from 'react';
import LeaderboardTabs from '@/components/game/LeaderboardTabs';

export const dynamic = 'force-dynamic';
export const revalidate = 60; // Revalidate every minute

export default function LeaderboardPage() {
  return (
    <div className="min-h-screen py-20">
      <div className="container mx-auto px-4">
        <h1 className="font-display text-4xl md:text-5xl text-center mb-12">
          <span className="bg-gradient-to-r from-ant-gold to-primary bg-clip-text text-transparent">
            Tournament Leaderboard
          </span>
        </h1>
        
        <Suspense fallback={<div>Loading...</div>}>
          <LeaderboardTabs />
        </Suspense>
      </div>
    </div>
  );
}