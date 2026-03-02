'use client';

import { motion, useScroll, useTransform, AnimatePresence } from 'framer-motion';
import Image from 'next/image';
import { usePrivy } from '@privy-io/react-auth';
import dynamic from 'next/dynamic';
import { useState, useEffect } from 'react';

// Load window-dependent animations only on the client
const AntAnimations = dynamic(() => import('@/components/AntAnimations'), { 
  ssr: false 
});

// Game features for the slider
const gameFeatures = [
  {
    id: 1,
    title: "Breed Unique Ants",
    description: "Combine genetic traits to create legendary soldier ants with unique abilities",
    icon: "🥚",
    color: "from-amber-400 to-yellow-600"
  },
  {
    id: 2,
    title: "Conquer Territories",
    description: "Battle for control of valuable land and resources across the underground",
    icon: "⚔️",
    color: "from-red-400 to-orange-600"
  },
  {
    id: 3,
    title: "Earn Real Rewards",
    description: "Win tournaments and claim AVAX prizes in our sustainable economy",
    icon: "💰",
    color: "from-emerald-400 to-teal-600"
  },
  {
    id: 4,
    title: "Join a Colony",
    description: "Team up with other players in guilds to dominate the leaderboards",
    icon: "🐜",
    color: "from-purple-400 to-indigo-600"
  },
  {
    id: 5,
    title: "Daily Tournaments",
    description: "Compete in rookie to champion tiers with prizes up to 500 AVAX",
    icon: "🏆",
    color: "from-blue-400 to-cyan-600"
  }
];

export default function HomePage() {
  const { login, authenticated } = usePrivy();
  const { scrollY } = useScroll();
  const y = useTransform(scrollY, [0, 500], [0, -50]);
  const opacity = useTransform(scrollY, [0, 300], [1, 0.8]);
  
  const [videoError, setVideoError] = useState(false);
  const [currentFeature, setCurrentFeature] = useState(0);
  const [direction, setDirection] = useState(1);
  const [mounted, setMounted] = useState(false);

  // Handle client-side only mounting
  useEffect(() => {
    setMounted(true);
  }, []);

  // Auto-sliding effect
  useEffect(() => {
    if (!mounted) return;
    const timer = setInterval(() => {
      setDirection(1);
      setCurrentFeature((prev) => (prev + 1) % gameFeatures.length);
    }, 4000);
    return () => clearInterval(timer);
  }, [mounted]);

  const handlePlayClick = () => {
    if (!authenticated) {
      login();
    } else {
      window.location.href = '/colony';
    }
  };

  // Variants for slider animation
  const slideVariants = {
    enter: (direction: number) => ({
      x: direction > 0 ? 100 : -100,
      opacity: 0
    }),
    center: {
      x: 0,
      opacity: 1
    },
    exit: (direction: number) => ({
      x: direction < 0 ? 100 : -100,
      opacity: 0
    })
  };

  // Don't render until mounted to prevent hydration mismatch
  if (!mounted) {
    return (
      <div className="relative min-h-screen overflow-hidden bg-ant-black">
        <div className="absolute inset-0 bg-gradient-to-r from-black/90 via-black/70 to-black/90" />
      </div>
    );
  }

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
          </video>
        ) : null}
        
        {/* Always show fallback image for consistency */}
        <div className="absolute inset-0">
          <Image
            src="/assets/bg1.gif"
            alt="Background"
            fill
            className="object-cover"
            priority
          />
        </div>
        
        {/* Enhanced gradient overlay for better text contrast */}
        <div className="absolute inset-0 bg-gradient-to-r from-black/90 via-black/70 to-black/90" />
        <div className="absolute inset-0 bg-gradient-to-t from-ant-black via-transparent to-transparent" />
      </div>

      {/* Background animations */}
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-ant-black/20 to-ant-black/60">
        <AntAnimations />
      </div>

      {/* Main Content Container - Centered and full height */}
      <div className="relative container mx-auto px-4 sm:px-6 lg:px-8 xl:px-12 h-screen flex items-center justify-center">
        <motion.div 
          style={{ y, opacity }}
          className="w-full max-w-4xl mx-auto text-center"
        >
          {/* Animated title with staggered children */}
          <motion.div
            initial="hidden"
            animate="visible"
            variants={{
              hidden: { opacity: 0 },
              visible: {
                opacity: 1,
                transition: { staggerChildren: 0.2 }
              }
            }}
          >
            {/* Colony name with glow effect */}
            <motion.div
              variants={{
                hidden: { y: 20, opacity: 0 },
                visible: { y: 0, opacity: 1 }
              }}
              className="mb-1"
            >
              <span className="inline-block px-4 py-2 rounded-full bg-ant-gold/10 border border-ant-gold/30 text-ant-gold text-sm font-semibold tracking-wider mb-2">
                🐜 WELCOME TO THE COLONY
              </span>
            </motion.div>

            {/* Main headline */}
            <motion.h1
              variants={{
                hidden: { y: 30, opacity: 0 },
                visible: { y: 0, opacity: 1 }
              }}
              className="font-display text-5xl sm:text-6xl md:text-7xl lg:text-8xl xl:text-9xl font-black mb-2 leading-[1.1]"
            >
              <span className="block text-white">Build Your</span>
              <span className="block bg-gradient-to-r from-ant-gold via-amber-400 to-primary bg-clip-text text-transparent">
                Ant Empire
              </span>
            </motion.h1>

            {/* Animated feature slider */}
            <motion.div
              variants={{
                hidden: { opacity: 0 },
                visible: { opacity: 1 }
              }}
              className="relative h-32 sm:h-28 md:h-24 mb-4 overflow-hidden"
            >
              <AnimatePresence mode="wait" custom={direction}>
                <motion.div
                  key={currentFeature}
                  custom={direction}
                  variants={slideVariants}
                  initial="enter"
                  animate="center"
                  exit="exit"
                  transition={{ duration: 0.5, type: "spring", stiffness: 100 }}
                  className="absolute inset-0 flex flex-col items-center justify-center"
                >
                  <div className={`inline-flex items-center gap-3 px-6 py-3 rounded-2xl bg-gradient-to-r ${gameFeatures[currentFeature].color} bg-opacity-10 backdrop-blur-sm border border-white/10`}>
                    <span className="text-3xl">{gameFeatures[currentFeature].icon}</span>
                    <span className="text-xl font-bold text-white">{gameFeatures[currentFeature].title}</span>
                  </div>
                  <p className="text-base sm:text-lg text-gray-300 max-w-2xl mx-auto mt-3">
                    {gameFeatures[currentFeature].description}
                  </p>
                </motion.div>
              </AnimatePresence>
            </motion.div>

            {/* Feature dots indicator */}
            <motion.div
              variants={{
                hidden: { opacity: 0 },
                visible: { opacity: 1 }
              }}
              className="flex justify-center gap-2 mb-8"
            >
              {gameFeatures.map((_, index) => (
                <button
                  key={index}
                  onClick={() => {
                    setDirection(index > currentFeature ? 1 : -1);
                    setCurrentFeature(index);
                  }}
                  className={`w-2 h-2 rounded-full transition-all duration-300 ${
                    index === currentFeature 
                      ? 'w-8 bg-ant-gold' 
                      : 'bg-gray-600 hover:bg-gray-400'
                  }`}
                  aria-label={`Go to feature ${index + 1}`}
                />
              ))}
            </motion.div>

            {/* CTA Button */}
            <motion.div
              variants={{
                hidden: { y: 20, opacity: 0 },
                visible: { y: 0, opacity: 1 }
              }}
            >
              <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={handlePlayClick}
                className="relative px-12 py-5 text-2xl font-bold rounded-xl overflow-hidden group shadow-2xl shadow-primary/20 mb-6"
              >
                <span className="absolute inset-0 bg-gradient-to-r from-primary via-ant-gold to-primary bg-[length:200%] group-hover:animate-shimmer"></span>
                <span className="relative z-10 flex items-center justify-center gap-3 text-white">
                  {!authenticated ? 'Start Your Colony' : 'Return to Colony'}
                  <motion.span
                    animate={{ x: [0, 10, 0] }}
                    transition={{ duration: 1.5, repeat: Infinity }}
                    className="inline-block"
                  >
                    →
                  </motion.span>
                </span>
              </motion.button>
            </motion.div>

            {/* Trust badges / stats */}
            <motion.div
              variants={{
                hidden: { opacity: 0 },
                visible: { opacity: 1 }
              }}
              className="flex flex-wrap justify-center gap-6 sm:gap-8 text-sm font-medium text-gray-400"
            >
              <div className="flex items-center gap-2">
                <span className="text-ant-gold text-xl">✓</span>
                <span>50M $HNY Supply</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-ant-gold text-xl">✓</span>
                <span>10K+ Players</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-ant-gold text-xl">✓</span>
                <span>Audited Contracts</span>
              </div>
            </motion.div>
          </motion.div>
        </motion.div>
      </div>

      {/* Scroll Indicator */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 2 }}
        className="absolute bottom-8 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2"
      >
        <span className="text-xs text-ant-gold/40 uppercase tracking-[0.3em]">Discover</span>
        <motion.div
          animate={{ y: [0, 10, 0] }}
          transition={{ duration: 1.5, repeat: Infinity }}
          className="w-px h-12 bg-gradient-to-b from-ant-gold/50 to-transparent"
        />
      </motion.div>

      {/* Add shimmer animation to global styles */}
      <style jsx global>{`
        @keyframes shimmer {
          0% { background-position: -200% 0; }
          100% { background-position: 200% 0; }
        }
        .animate-shimmer {
          animation: shimmer 3s infinite;
        }
      `}</style>
    </div>
  );
}