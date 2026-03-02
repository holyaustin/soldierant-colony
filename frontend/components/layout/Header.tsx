'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { usePrivy } from '@privy-io/react-auth';
import { useAccount, useBalance } from 'wagmi'; 
import { motion } from 'framer-motion';

export default function Header() {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const { login, logout, authenticated, ready } = usePrivy();
  
  // In wagmi v2, chain info comes from useAccount
  const { address, chain } = useAccount();
  const { data: balance } = useBalance({ address });

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 50);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Helper function to get network display name
  const getNetworkName = () => {
    if (!chain) return '';
    
    if (chain.id === 43113) return 'Fuji';
    if (chain.id === 43114) return 'Avalanche';
    return chain.name;
  };

  // Don't render until Privy is ready to avoid hydration issues
  if (!ready) {
    return (
      <header className="fixed top-0 w-full z-50 bg-ant-black/90 backdrop-blur-md border-b border-ant-gold/30">
        <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="relative w-8 sm:w-10 h-8 sm:h-10">
              <div className="w-8 sm:w-10 h-8 sm:h-10 bg-ant-gold/20 rounded-full animate-pulse" />
            </div>
            <span className="font-display text-lg sm:text-xl font-bold bg-gradient-to-r from-ant-gold to-primary bg-clip-text text-transparent">
              SOLDIER ANT
            </span>
          </div>
        </div>
      </header>
    );
  }

  return (
    <motion.header
      initial={{ y: -100 }}
      animate={{ y: 0 }}
      className={`fixed top-0 w-full z-50 transition-all duration-300 ${
        isScrolled 
          ? 'bg-ant-black/90 backdrop-blur-md border-b border-ant-gold/30' 
          : 'bg-transparent'
      }`}
    >
      <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-3 sm:py-4">
        <div className="flex items-center justify-between">
          {/* Logo and Brand */}
          <Link href="/" className="flex items-center gap-2 group">
            <div className="relative w-8 sm:w-10 h-8 sm:h-10 transition-transform group-hover:scale-110 duration-300">
              <Image
                src="/images/logo2.jpg"
                alt="Soldier Ant"
                fill
                className="object-contain"
                priority
                sizes="(max-width: 640px) 32px, 40px"
              />
            </div>
            <span className="font-display text-xl sm:text-2xl font-black bg-gradient-to-r from-ant-gold to-primary bg-clip-text text-transparent">
              SOLDIER ANT COLONY
            </span>
          </Link>

          {/* Desktop Navigation */}
          <nav className="hidden md:flex items-center gap-6 lg:gap-8">
            <Link href="/leaderboard" className="font-body text-sm lg:text-base text-gray-300 hover:text-ant-gold transition-colors duration-300">
              Leaderboard
            </Link>
            <Link href="/marketplace" className="font-body text-sm lg:text-base text-gray-300 hover:text-ant-gold transition-colors duration-300">
              Marketplace
            </Link>
            <Link href="/colony" className="font-body text-sm lg:text-base text-gray-300 hover:text-ant-gold transition-colors duration-300">
              My Colony
            </Link>
          </nav>

          {/* Wallet Info and Auth */}
          <div className="flex items-center gap-2 sm:gap-4">
            {authenticated && address && (
              <div className="hidden md:flex items-center gap-2 px-2 sm:px-3 py-1 rounded-full bg-ant-gold/10 border border-ant-gold/30">
                <span className="text-xs sm:text-sm text-ant-gold font-mono">
                  {balance ? `${parseFloat(balance.formatted).toFixed(2)} AVAX` : '0 AVAX'}
                </span>
                <span className="w-1 h-1 rounded-full bg-ant-gold"></span>
                <span className="text-xs text-ant-gold/70">
                  {getNetworkName()}
                </span>
              </div>
            )}

            {!authenticated ? (
              <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={login}
                className="px-4 sm:px-6 py-1.5 sm:py-2 rounded-lg bg-gradient-to-r from-primary to-ant-gold text-white font-semibold text-sm sm:text-base shadow-lg hover:shadow-ant-gold/20 transition-all duration-300"
              >
                <span className="hidden sm:inline">Connect Colony</span>
                <span className="sm:hidden">Connect</span>
              </motion.button>
            ) : (
              <div className="relative group">
                <button className="w-8 sm:w-10 h-8 sm:h-10 rounded-full bg-gradient-to-r from-primary to-ant-gold flex items-center justify-center hover:shadow-lg hover:shadow-ant-gold/20 transition-all duration-300">
                  <span className="text-white font-bold text-xs sm:text-sm">
                    {address?.slice(0, 2)}
                  </span>
                </button>
                <div className="absolute right-0 mt-2 w-40 sm:w-48 py-2 bg-ant-black/95 backdrop-blur-md rounded-lg border border-ant-gold/30 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200">
                  <div className="px-3 sm:px-4 py-2 border-b border-ant-gold/20">
                    <p className="text-xs text-gray-400">Connected as</p>
                    <p className="text-xs sm:text-sm font-mono">{`${address?.slice(0, 4)}...${address?.slice(-4)}`}</p>
                  </div>
                  <button
                    onClick={logout}
                    className="w-full px-3 sm:px-4 py-2 text-left text-xs sm:text-sm hover:bg-ant-gold/10 text-red-400 transition"
                  >
                    Disconnect
                  </button>
                </div>
              </div>
            )}

            {/* Mobile Menu Button */}
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="md:hidden flex flex-col gap-1.5 p-2"
            >
              <span className={`w-6 h-0.5 bg-ant-gold transition-all duration-300 ${mobileMenuOpen ? 'rotate-45 translate-y-2' : ''}`} />
              <span className={`w-6 h-0.5 bg-ant-gold transition-all duration-300 ${mobileMenuOpen ? 'opacity-0' : ''}`} />
              <span className={`w-6 h-0.5 bg-ant-gold transition-all duration-300 ${mobileMenuOpen ? '-rotate-45 -translate-y-2' : ''}`} />
            </button>
          </div>
        </div>

        {/* Mobile Menu */}
        <motion.div
          initial={false}
          animate={mobileMenuOpen ? { height: 'auto', opacity: 1 } : { height: 0, opacity: 0 }}
          transition={{ duration: 0.3 }}
          className="md:hidden overflow-hidden"
        >
          <div className="pt-4 pb-2 space-y-3">
            <Link 
              href="/leaderboard" 
              className="block font-body text-base text-gray-300 hover:text-ant-gold py-2"
              onClick={() => setMobileMenuOpen(false)}
            >
              Leaderboard
            </Link>
            <Link 
              href="/marketplace" 
              className="block font-body text-base text-gray-300 hover:text-ant-gold py-2"
              onClick={() => setMobileMenuOpen(false)}
            >
              Marketplace
            </Link>
            <Link 
              href="/colony" 
              className="block font-body text-base text-gray-300 hover:text-ant-gold py-2"
              onClick={() => setMobileMenuOpen(false)}
            >
              My Colony
            </Link>
            
            {authenticated && address && (
              <div className="flex items-center gap-2 py-2">
                <span className="text-sm text-ant-gold">
                  {balance ? `${parseFloat(balance.formatted).toFixed(2)} AVAX` : '0 AVAX'}
                </span>
                <span className="w-1 h-1 rounded-full bg-ant-gold"></span>
                <span className="text-xs text-ant-gold/70">
                  {getNetworkName()}
                </span>
              </div>
            )}
          </div>
        </motion.div>
      </div>
    </motion.header>
  );
}