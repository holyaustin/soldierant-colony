import Link from 'next/link';
import { FaDiscord, FaXTwitter } from 'react-icons/fa6';

export default function Footer() {
  return (
    <footer className="bg-ant-black/95 border-t border-ant-gold/30 py-8">
      <div className="container mx-auto px-4">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          <div className="col-span-1 md:col-span-2">
            <h3 className="font-display text-xl text-ant-gold mb-4">Soldier Ant Colony</h3>
            <p className="text-gray-400 text-sm">
              Build your empire, breed your army, and conquer the underground.
              A strategy Web3 game on Avalanche.
            </p>
          </div>
          
          <div>
            <h4 className="font-semibold mb-3">Game</h4>
            <ul className="space-y-2 text-sm text-gray-400">
              <li><Link href="/leaderboard" className="hover:text-ant-gold">Leaderboard</Link></li>
              <li><Link href="/marketplace" className="hover:text-ant-gold">Marketplace</Link></li>
              <li><Link href="/colony" className="hover:text-ant-gold">My Colony</Link></li>
            </ul>
          </div>
          
          <div>
            <h4 className="font-semibold mb-3">Community</h4>
            <div className="flex gap-4">
              <a
                href="https://discord.gg/soldierant"
                target="_blank"
                rel="noopener noreferrer"
                className="text-2xl text-gray-400 hover:text-ant-gold transition"
              >
                <FaDiscord />
              </a>
              <a
                href="https://x.com/soldierant"
                target="_blank"
                rel="noopener noreferrer"
                className="text-2xl text-gray-400 hover:text-ant-gold transition"
              >
                <FaXTwitter />
              </a>
            </div>
          </div>
        </div>
        
        <div className="mt-8 pt-6 border-t border-ant-gold/20 text-center text-sm text-gray-500">
          © 2026 Soldier Ant Colony. All rights reserved.
        </div>
      </div>
    </footer>
  );
}