'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { usePrivy } from '@privy-io/react-auth';
import { useAccount, useBalance, useNetwork } from 'wagmi';
import { motion } from 'framer-motion';

export default function Header() {
  const [isScrolled, setIsScrolled] = useState(false);
  const { login, logout, authenticated, ready } = usePrivy();
  const { address } = useAccount();
  const { chain } = useNetwork();
  const { data: balance } = useBalance({ address });

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 50);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

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
      <div className="container mx-auto px-4 py-4 flex items-center justify-between">
        <Link href="/" className="flex items-center gap-2">
          <div className="relative w-10 h-10">
            <Image
              src="/images/ant-icon.svg"
              alt="Soldier Ant"
              fill
              className="object-contain"
              priority
            />
          </div>
          <span className="font-display text-xl font-bold bg-gradient-to-r from-ant-gold to-primary bg-clip-text text-transparent">
            SOLDIER ANT
          </span>
        </Link>

        <nav className="hidden md:flex items-center gap-8">
          <Link href="/leaderboard" className="hover:text-ant-gold transition">
            Leaderboard
          </Link>
          <Link href="/marketplace" className="hover:text-ant-gold transition">
            Marketplace
          </Link>
        </nav>

        <div className="flex items-center gap-4">
          {authenticated && address && (
            <div className="hidden md:flex items-center gap-2 px-3 py-1 rounded-full bg-ant-gold/10 border border-ant-gold/30">
              <span className="text-sm text-ant-gold">
                {balance ? `${parseFloat(balance.formatted).toFixed(4)} AVAX` : '0 AVAX'}
              </span>
              <span className="w-1 h-1 rounded-full bg-ant-gold"></span>
              <span className="text-xs text-ant-gold/70">
                {chain?.name === 'Avalanche Fuji' ? 'Fuji' : chain?.name}
              </span>
            </div>
          )}

          {!authenticated ? (
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={login}
              className="px-6 py-2 rounded-lg bg-gradient-to-r from-primary to-ant-gold text-white font-semibold shadow-lg hover:shadow-ant-gold/20 transition"
            >
              Connect Colony
            </motion.button>
          ) : (
            <div className="relative group">
              <button className="w-10 h-10 rounded-full bg-gradient-to-r from-primary to-ant-gold flex items-center justify-center">
                <span className="text-white font-bold">
                  {address?.slice(0, 2)}...
                </span>
              </button>
              <div className="absolute right-0 mt-2 w-48 py-2 bg-ant-black/95 backdrop-blur-md rounded-lg border border-ant-gold/30 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition">
                <button
                  onClick={logout}
                  className="w-full px-4 py-2 text-left hover:bg-ant-gold/10 text-red-400"
                >
                  Disconnect
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </motion.header>
  );
}