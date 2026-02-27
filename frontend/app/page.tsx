'use client';

import { motion, useScroll, useTransform } from 'framer-motion';
import Image from 'next/image';
import { usePrivy } from '@privy-io/react-auth';
import dynamic from 'next/dynamic';

// Fix: Load window-dependent animations only on the client
const AntAnimations = dynamic(() => import('@/components/AntAnimations'), { 
  ssr: false 
});

export default function HomePage() {
  const { login, authenticated } = usePrivy();
  const { scrollY } = useScroll();
  const y = useTransform(scrollY, [0, 500], [0, 150]);

  const handlePlayClick = () => {
    if (!authenticated) {
      login();
    } else {
      window.location.href = '/colony';
    }
  };

  return (
    <div className="relative min-h-screen overflow-hidden bg-ant-black">
      {/* Background layer */}
      <div className="absolute inset-0 bg-gradient-to-b from-ant-black via-ant-black/95 to-primary/20">
        <AntAnimations />
      </div>

      {/* Hero content */}
      <div className="relative container mx-auto px-4 pt-4 pb-20 z-10">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.8 }}
          >
            <h1 className="font-display text-5xl md:text-7xl mb-6">
              <span className="block text-white">Build Your</span>
              <span className="block bg-gradient-to-r from-ant-gold to-primary bg-clip-text text-transparent">
                Ant Colony
              </span>
            </h1>
            <p className="text-xl text-gray-400 mb-8 max-w-lg">
              Breed unique soldier ants, conquer territories, and earn real rewards
              in the first sustainable Web3 strategy game on Avalanche.
            </p>
            
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={handlePlayClick}
              className="relative px-12 py-5 text-2xl font-bold rounded-xl overflow-hidden group shadow-2xl shadow-primary/20"
            >
              <span className="absolute inset-0 bg-gradient-to-r from-primary to-ant-gold"></span>
              <span className="relative z-10 flex items-center gap-3 text-white">
                {!authenticated ? 'Connect to Play' : 'Enter Colony'}
                <motion.span
                  animate={{ x: [0, 10, 0] }}
                  transition={{ duration: 1.5, repeat: Infinity }}
                >
                  →
                </motion.span>
              </span>
            </motion.button>

            <div className="mt-12 flex gap-8 text-sm font-medium text-gray-500 uppercase tracking-widest">
              <span className="flex items-center gap-2">⚔️ 10K Soldiers</span>
              <span className="flex items-center gap-2">🏆 Tournaments</span>
            </div>
          </motion.div>

          <motion.div
            style={{ y }}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 1, ease: "easeOut" }}
            className="relative h-[450px] md:h-[600px] flex justify-center items-center"
          >
            <div className="relative w-full h-full">
               <Image
                src="/images/ant.jpg"
                alt="Soldier Ant Hero"
                fill
                className="object-contain drop-shadow-[0_0_50px_rgba(251,191,36,0.2)]"
                priority
              />
            </div>
          </motion.div>
        </div>
      </div>

      {/* Scroll Indicator */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1 }}
        className="absolute bottom-10 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2"
      >
        <span className="text-[10px] text-ant-gold/40 uppercase tracking-[0.3em]">Scroll</span>
        <div className="w-px h-12 bg-gradient-to-b from-ant-gold/50 to-transparent" />
      </motion.div>
    </div>
  );
}
