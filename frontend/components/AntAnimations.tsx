'use client';

import { motion } from 'framer-motion';
import { useEffect, useState } from 'react';
import Image from 'next/image';

export default function AntAnimations() {
  const [dims, setDims] = useState({ w: 0, h: 0 });

  useEffect(() => {
    setDims({ w: window.innerWidth, h: window.innerHeight });
    const handleResize = () => setDims({ w: window.innerWidth, h: window.innerHeight });
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  if (dims.w === 0) return null;

  return (
    <div className="fixed inset-0 pointer-events-none overflow-hidden z-0">
      {/* 1. Full Screen Video Background */}
      <div className="absolute inset-0 z-0">
        <video
          autoPlay
          loop
          muted
          playsInline
          poster="/images/soil-texture.png" // Fallback from your provided image
          className="absolute inset-0 w-full h-full object-cover opacity-40 grayscale-[0.5]"
        >
          <source src="/images/SoldierAntLong.mkv" type="video/mp4" />
          Your browser does not support the video tag.
        </video>
        {/* Dark overlay to ensure text readability */}
        <div className="absolute inset-0 bg-black/50" />
      </div>

      {/* 2. Scurrying Soldier Ants (Layered over video) */}
      {[...Array(15)].map((_, i) => {
        const startX = Math.random() * dims.w;
        const startY = Math.random() * dims.h;
        const endX = Math.random() * dims.w;
        const endY = Math.random() * dims.h;
        
        // Calculate rotation so ants face the direction they move
        const angle = Math.atan2(endY - startY, endX - startX) * (180 / Math.PI) + 90;

        return (
          <motion.div
            key={`scurry-${i}`}
            className="absolute z-10 w-6 h-6 md:w-8 md:h-8"
            initial={{ x: startX, y: startY, rotate: angle, opacity: 0 }}
            animate={{ 
              x: [startX, endX], 
              y: [startY, endY],
              opacity: [0, 0.2, 0.2, 0] 
            }}
            transition={{ 
              duration: 20 + Math.random() * 20, 
              repeat: Infinity, 
              ease: "linear" 
            }}
          >
            <Image 
              src="/images/ant-icon.svg" 
              alt="Scurrying Ant" 
              width={32} 
              height={32} 
              className="brightness-0 opacity-80"
            />
          </motion.div>
        );
      })}

      {/* 3. Floating Guardian Ring in Center */}
      <div className="absolute inset-0 flex items-center justify-center z-20">
        <motion.div
          animate={{ rotate: 360 }}
          transition={{ duration: 80, repeat: Infinity, ease: 'linear' }}
          className="relative w-[300px] h-[300px] md:w-[600px] md:h-[600px]"
        >
          {[...Array(6)].map((_, i) => (
            <motion.div
              key={`guardian-${i}`}
              className="absolute w-8 h-8 md:w-12 md:h-12 opacity-10"
              style={{
                top: `${50 + 42 * Math.sin((i * 2 * Math.PI) / 6)}%`,
                left: `${50 + 42 * Math.cos((i * 2 * Math.PI) / 6)}%`,
                transform: `rotate(${i * 60}deg)`
              }}
            >
              <Image 
                src="/images/ant-icon.svg" 
                alt="Guardian" 
                width={48} 
                height={48} 
                className="brightness-200"
              />
            </motion.div>
          ))}
        </motion.div>
      </div>
    </div>
  );
}
