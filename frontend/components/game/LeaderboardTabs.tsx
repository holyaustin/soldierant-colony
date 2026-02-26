'use client';

import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

interface LeaderboardEntry {
  address: string;
  score: number;
  wins: number;
}

export default function LeaderboardTabs() {
  const [activeTab, setActiveTab] = useState<'daily' | 'weekly'>('daily');
  const [data, setData] = useState<LeaderboardEntry[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchLeaderboard = async () => {
      setLoading(true);
      try {
        const res = await fetch(`/api/leaderboard?type=${activeTab}`, {
          next: { tags: ['leaderboard'] },
        });
        const json = await res.json();
        setData(json.data);
      } catch (error) {
        console.error('Failed to fetch leaderboard:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchLeaderboard();
  }, [activeTab]);

  return (
    <div className="w-full max-w-4xl mx-auto">
      <div className="flex gap-4 mb-6">
        {['daily', 'weekly'].map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab as 'daily' | 'weekly')}
            className={`relative px-6 py-3 rounded-lg font-semibold capitalize transition ${
              activeTab === tab
                ? 'text-ant-gold'
                : 'text-gray-400 hover:text-gray-200'
            }`}
          >
            {tab} Tournament
            {activeTab === tab && (
              <motion.div
                layoutId="activeTab"
                className="absolute inset-0 border-2 border-ant-gold rounded-lg -z-10"
                transition={{ type: 'spring', bounce: 0.2, duration: 0.6 }}
              />
            )}
          </button>
        ))}
      </div>

      <div className="bg-ant-black/50 backdrop-blur-sm rounded-xl border border-ant-gold/30 overflow-hidden">
        <div className="grid grid-cols-3 gap-4 p-4 border-b border-ant-gold/30 font-semibold text-ant-gold">
          <div>Rank</div>
          <div>Colony</div>
          <div className="text-right">Score</div>
        </div>

        <AnimatePresence mode="wait">
          {loading ? (
            <motion.div
              key="loading"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="p-8 text-center text-gray-400"
            >
              Loading...
            </motion.div>
          ) : (
            <motion.div
              key={activeTab}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.3 }}
            >
              {data.map((entry, index) => (
                <motion.div
                  key={entry.address}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: index * 0.05 }}
                  className="grid grid-cols-3 gap-4 p-4 hover:bg-ant-gold/5 transition border-b border-ant-gold/10 last:border-0"
                >
                  <div className="flex items-center gap-2">
                    <span className={index < 3 ? 'text-ant-gold font-bold' : ''}>
                      #{index + 1}
                    </span>
                    {index === 0 && <span className="text-2xl">👑</span>}
                  </div>
                  <div className="font-mono">
                    {`${entry.address.slice(0, 6)}...${entry.address.slice(-4)}`}
                  </div>
                  <div className="text-right font-bold">
                    {entry.score.toLocaleString()}
                  </div>
                </motion.div>
              ))}
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}