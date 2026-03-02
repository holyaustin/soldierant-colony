'use client';

import { motion, useScroll, useTransform } from 'framer-motion';
import Image from 'next/image';
import { usePrivy } from '@privy-io/react-auth';
import dynamic from 'next/dynamic';
import { useEffect, useState } from 'react';

// Fix: Load window-dependent animations only on the client
const AntAnimations = dynamic(() => import('@/components/AntAnimations'), { 
  ssr: false 
});

export default function HomePage() {
  const { login, authenticated } = usePrivy();
  const { scrollY } = useScroll();
  const y = useTransform(scrollY, [0, 500], [0, 150]);
  const [videoError, setVideoError] = useState(false);

  const handlePlayClick = () => {
    if (!authenticated) {
      login();
    } else {
      window.location.href = '/colony';
    }
  };

  return (
    <div className="relative min-h-screen overflow-hidden bg-ant-black">
      {/* Video Background with Image Fallback */}
      <div className="fixed inset-0 w-full h-full -z-20">
        {!videoError ? (
          <video
            autoPlay
            loop
            muted
            playsInline
            className="absolute w-full h-full object-cover scale-105"
            onError={() => setVideoError(true)}
          >
            <source src="/videos/ant-colony-bg.mp4" type="video/mp4" />
            {/* Fallback for unsupported browsers */}
            <Image
              src="/assets/bg1.gif"
              alt="Background Fallback"
              fill
              className="object-cover"
              priority
            />
          </video>
        ) : (
          <Image
            src="/assets/bg1.gif"
            alt="Background Fallback"
            fill
            className="object-cover"
            priority
          />
        )}
        
        {/* Dark overlay for better text contrast */}
        <div className="absolute inset-0 bg-gradient-to-r from-black/80 via-black/50 to-black/80" />
      </div>

      {/* Background layer with animations */}
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-ant-black/20 to-ant-black/60">
        <AntAnimations />
      </div>

      {/* Main Content Container - No top padding */}
      <div className="relative container mx-auto px-4 sm:px-6 lg:px-8 xl:px-12 h-screen flex items-center">
        <div className="w-full grid grid-cols-1 lg:grid-cols-[40%_60%] gap-8 lg:gap-12 xl:gap-16 items-center">
          
          {/* Left Column - Text Content - 40% on desktop */}
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.8 }}
            className="text-center lg:text-left order-2 lg:order-1 lg:pr-4 xl:pr-8"
          >
            <h1 className="font-display text-4xl sm:text-5xl md:text-6xl lg:text-5xl xl:text-6xl 2xl:text-7xl mb-4 sm:mb-6 font-bold   leading-tight">
              <span className="block text-white">Build Your</span>
              <span className="block bg-gradient-to-r from-ant-gold to-primary bg-clip-text text-transparent">
                Ant Colony
              </span>
            </h1>
            
            <p className="text-base sm:text-lg md:text-xl lg:text-base xl:text-lg text-gray-300 mb-6 sm:mb-8 max-w-2xl mx-auto lg:mx-0 lg:max-w-md xl:max-w-lg">
              Breed unique soldier ants, conquer territories, and earn real rewards
              in the first sustainable Web3 strategy game on Avalanche.
            </p>
            
            {/* CTA Button */}
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={handlePlayClick}
              className="relative w-full sm:w-auto px-8 sm:px-10 lg:px-8 xl:px-12 py-4 sm:py-5 text-xl sm:text-2xl lg:text-xl xl:text-2xl font-bold rounded-xl overflow-hidden group shadow-2xl shadow-primary/20 mb-8 sm:mb-0"
            >
              <span className="absolute inset-0 bg-gradient-to-r from-primary to-ant-gold"></span>
              <span className="relative z-10 flex items-center justify-center gap-3 text-white">
                {!authenticated ? 'Connect to Play' : 'Enter Colony'}
                <motion.span
                  animate={{ x: [0, 10, 0] }}
                  transition={{ duration: 1.5, repeat: Infinity }}
                  className="inline-block"
                >
                  →
                </motion.span>
              </span>
            </motion.button>

            {/* Stats */}
            <div className="mt-8 sm:mt-10 flex flex-wrap justify-center lg:justify-start gap-4 sm:gap-6 lg:gap-4 xl:gap-6 text-xs sm:text-sm font-medium text-gray-400 uppercase tracking-widest">
              <span className="flex items-center gap-2">
                <span className="text-ant-gold text-lg">⚔️</span>
                <span>10K Soldiers</span>
              </span>
              <span className="flex items-center gap-2">
                <span className="text-ant-gold text-lg">🏆</span>
                <span>Tournaments</span>
              </span>
              <span className="flex items-center gap-2">
                <span className="text-ant-gold text-lg">💰</span>
                <span>50M $HNY</span>
              </span>
            </div>
          </motion.div>

          {/* Right Column - Hero Image/Video - 60% on desktop */}
          <motion.div
            style={{ y }}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 1, ease: "easeOut" }}
            className="relative order-1 lg:order-2 h-[300px] sm:h-[400px] md:h-[500px] lg:h-[550px] xl:h-[650px] 2xl:h-[750px] flex justify-center items-center lg:pl-4 xl:pl-8"
          >
            <div className="relative w-full h-full max-w-4xl mx-auto lg:max-w-none">
              <Image
                src="/assets/bg1.gif"
                alt="Soldier Ant Hero"
                fill
                className="object-contain drop-shadow-[0_0_50px_rgba(251,191,36,0.3)] scale-105 lg:scale-110 xl:scale-115"
                priority
                sizes="(max-width: 640px) 100vw, (max-width: 1024px) 80vw, 60vw"
              />
            </div>
          </motion.div>
        </div>
      </div>

      {/* Scroll Indicator - Hidden on mobile */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1 }}
        className="absolute bottom-6 sm:bottom-8 lg:bottom-10 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2 hidden sm:flex"
      >
        <span className="text-[8px] sm:text-[10px] text-ant-gold/40 uppercase tracking-[0.3em]">Scroll</span>
        <div className="w-px h-8 sm:h-10 lg:h-12 bg-gradient-to-b from-ant-gold/50 to-transparent" />
      </motion.div>

      {/* Mobile scroll hint - small dot */}
      <div className="absolute bottom-4 left-1/2 -translate-x-1/2 sm:hidden">
        <div className="w-1 h-1 rounded-full bg-ant-gold/50 animate-pulse" />
      </div>
    </div>
  );
}