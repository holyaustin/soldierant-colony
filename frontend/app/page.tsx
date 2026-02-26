'use client';

import { motion, useScroll, useTransform } from 'framer-motion';
import Image from 'next/image';
import Link from 'next/link';
import { usePrivy } from '@privy-io/react-auth';

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
    <div className="relative min-h-screen overflow-hidden">
      {/* Animated background with ant trail effect */}
      <div className="absolute inset-0 bg-gradient-to-b from-ant-black via-ant-black/95 to-primary/20">
        <div className="absolute inset-0 opacity-30">
          {[...Array(20)].map((_, i) => (
            <motion.div
              key={i}
              className="absolute w-1 h-1 bg-ant-gold rounded-full ant-trail"
              initial={{
                x: Math.random() * window.innerWidth,
                y: Math.random() * window.innerHeight,
              }}
              animate={{
                x: [null, Math.random() * 100 - 50],
                y: [null, Math.random() * 100 - 50],
              }}
              transition={{
                duration: 10 + Math.random() * 20,
                repeat: Infinity,
                repeatType: 'reverse',
              }}
            />
          ))}
        </div>
      </div>

      {/* Hero content */}
      <div className="relative container mx-auto px-4 pt-32 pb-20">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.8 }}
          >
            <h1 className="font-display text-5xl md:text-7xl mb-6">
              <span className="block text-white">Build Your</span>
              <span className="block bg-gradient-to-r from-ant-gold to-primary bg-clip-text text-transparent">
                Ant Empire
              </span>
            </h1>
            <p className="text-xl text-gray-300 mb-8">
              Breed unique soldier ants, conquer territories, and earn real rewards
              in the first sustainable Web3 strategy game on Avalanche.
            </p>
            
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={handlePlayClick}
              className="relative px-12 py-5 text-2xl font-bold rounded-lg overflow-hidden group"
            >
              <span className="absolute inset-0 bg-gradient-to-r from-primary to-ant-gold opacity-80 group-hover:opacity-100 transition"></span>
              <span className="absolute inset-0 bg-[url('/images/ant-pattern.png')] opacity-20 group-hover:animate-march"></span>
              <span className="relative z-10 flex items-center gap-3">
                {!authenticated ? 'Connect to Play' : 'Enter Colony'}
                <motion.span
                  animate={{ x: [0, 10, 0] }}
                  transition={{ duration: 1.5, repeat: Infinity }}
                >
                  →
                </motion.span>
              </span>
            </motion.button>

            <div className="mt-8 flex gap-6 text-sm text-gray-400">
              <span>⚔️ 10K+ Soldiers</span>
              <span>🏆 Daily Tournaments</span>
              <span>💰 50M $HNY Supply</span>
            </div>
          </motion.div>

          <motion.div
            style={{ y }}
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="relative h-[500px]"
          >
            <Image
              src="/images/soldier-ant-hero.png"
              alt="Soldier Ant"
              fill
              className="object-contain"
              priority
              sizes="(max-width: 768px) 100vw, 50vw"
            />
            
            {/* Floating ants around hero */}
            <motion.div
              animate={{ rotate: 360 }}
              transition={{ duration: 20, repeat: Infinity, ease: 'linear' }}
              className="absolute inset-0"
            >
              {[...Array(5)].map((_, i) => (
                <motion.div
                  key={i}
                  className="absolute w-8 h-8"
                  style={{
                    top: `${Math.sin(i * 72) * 180 + 50}%`,
                    left: `${Math.cos(i * 72) * 180 + 50}%`,
                  }}
                >
                  <Image
                    src="/images/ant-icon.svg"
                    alt=""
                    width={32}
                    height={32}
                    className="opacity-50"
                  />
                </motion.div>
              ))}
            </motion.div>
          </motion.div>
        </div>

        {/* Animated scroll indicator */}
        <motion.div
          animate={{ y: [0, 10, 0] }}
          transition={{ duration: 1.5, repeat: Infinity }}
          className="absolute bottom-10 left-1/2 transform -translate-x-1/2"
        >
          <div className="w-6 h-10 border-2 border-ant-gold/50 rounded-full flex justify-center">
            <div className="w-1 h-2 bg-ant-gold rounded-full mt-2"></div>
          </div>
        </motion.div>
      </div>
    </div>
  );
}