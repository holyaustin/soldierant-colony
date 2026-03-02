import Link from 'next/link';
import { FaDiscord, FaXTwitter } from 'react-icons/fa6';

export default function Footer() {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="${
        isScrolled 
          ? 'bg-ant-black/90 backdrop-blur-md border-b border-ant-gold/30' 
          : 'bg-transparent'
      }`} border-t border-ant-gold/30 py-8 sm:py-10 lg:py-12">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8 sm:gap-6 lg:gap-8">
          
          {/* Brand Column - Full width on mobile, half on tablet, double on desktop */}
          <div className="sm:col-span-1 lg:col-span-2">
            <h3 className="font-display text-lg sm:text-xl lg:text-2xl text-ant-gold mb-3 sm:mb-4">
              Soldier Ant Colony
            </h3>
            <p className="font-body text-sm sm:text-base text-gray-400 max-w-md">
              Build your empire, breed your army, and conquer the underground.
              A strategy Web3 game on Avalanche.
            </p>
            
            {/* Social Icons - Mobile visible */}
            <div className="flex gap-4 mt-4 sm:hidden">
              <a
                href="https://discord.gg/soldierant"
                target="_blank"
                rel="noopener noreferrer"
                className="text-xl text-gray-400 hover:text-ant-gold transition-colors duration-300"
                aria-label="Discord"
              >
                <FaDiscord />
              </a>
              <a
                href="https://x.com/soldierant"
                target="_blank"
                rel="noopener noreferrer"
                className="text-xl text-gray-400 hover:text-ant-gold transition-colors duration-300"
                aria-label="X (Twitter)"
              >
                <FaXTwitter />
              </a>
            </div>
          </div>

          {/* Game Links */}
          <div>
            <h4 className="font-display text-base sm:text-lg font-semibold mb-3 sm:mb-4 text-white">
              Game
            </h4>
            <ul className="space-y-2 sm:space-y-3">
              <li>
                <Link 
                  href="/leaderboard" 
                  className="font-body text-sm sm:text-base text-gray-400 hover:text-ant-gold transition-colors duration-300"
                >
                  Leaderboard
                </Link>
              </li>
              <li>
                <Link 
                  href="/marketplace" 
                  className="font-body text-sm sm:text-base text-gray-400 hover:text-ant-gold transition-colors duration-300"
                >
                  Marketplace
                </Link>
              </li>
              <li>
                <Link 
                  href="/colony" 
                  className="font-body text-sm sm:text-base text-gray-400 hover:text-ant-gold transition-colors duration-300"
                >
                  My Colony
                </Link>
              </li>
              <li>
                <Link 
                  href="/tournaments" 
                  className="font-body text-sm sm:text-base text-gray-400 hover:text-ant-gold transition-colors duration-300"
                >
                  Tournaments
                </Link>
              </li>
            </ul>
          </div>

          {/* Community Links */}
          <div>
            <h4 className="font-display text-base sm:text-lg font-semibold mb-3 sm:mb-4 text-white">
              Community
            </h4>
            <ul className="space-y-2 sm:space-y-3">
              <li>
                <a
                  href="https://discord.gg/soldierant"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="font-body text-sm sm:text-base text-gray-400 hover:text-ant-gold transition-colors duration-300 flex items-center gap-2"
                >
                  <FaDiscord className="text-base sm:text-lg" />
                  <span>Discord</span>
                </a>
              </li>
              <li>
                <a
                  href="https://x.com/soldierant"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="font-body text-sm sm:text-base text-gray-400 hover:text-ant-gold transition-colors duration-300 flex items-center gap-2"
                >
                  <FaXTwitter className="text-base sm:text-lg" />
                  <span>X (Twitter)</span>
                </a>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="mt-8 sm:mt-10 lg:mt-12 pt-6 sm:pt-8 border-t border-ant-gold/20 flex flex-col sm:flex-row justify-between items-center gap-4">
          <p className="font-body text-xs sm:text-sm text-gray-500 order-2 sm:order-1">
            © {currentYear} Soldier Ant Colony. All rights reserved.
          </p>
          
          {/* Social Icons - Hidden on mobile (shown in brand column), visible on tablet+ */}
          <div className="hidden sm:flex gap-4 order-1 sm:order-2">
            <a
              href="https://discord.gg/soldierant"
              target="_blank"
              rel="noopener noreferrer"
              className="text-lg sm:text-xl text-gray-400 hover:text-ant-gold transition-colors duration-300"
              aria-label="Discord"
            >
              <FaDiscord />
            </a>
            <a
              href="https://x.com/soldierant"
              target="_blank"
              rel="noopener noreferrer"
              className="text-lg sm:text-xl text-gray-400 hover:text-ant-gold transition-colors duration-300"
              aria-label="X (Twitter)"
            >
              <FaXTwitter />
            </a>
          </div>

          {/* Legal Links */}
          <div className="flex gap-4 sm:gap-6 text-xs sm:text-sm text-gray-500 order-3">
            <Link href="/privacy" className="hover:text-ant-gold transition-colors duration-300">
              Privacy
            </Link>
            <Link href="/terms" className="hover:text-ant-gold transition-colors duration-300">
              Terms
            </Link>
          </div>
        </div>
      </div>
    </footer>
  );
}