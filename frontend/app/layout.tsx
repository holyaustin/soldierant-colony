import type { Metadata } from 'next';
import { Inter, Cinzel } from 'next/font/google';
import { Providers } from '@/components/providers/PrivyProvider'; // Updated import
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import './globals.css';

const inter = Inter({ subsets: ['latin'], variable: '--font-body' });
const cinzel = Cinzel({ subsets: ['latin'], variable: '--font-display' });

export const metadata: Metadata = {
  title: 'Soldier Ant Colony',
  description: 'Build your empire, rule the underground',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.variable} ${cinzel.variable} font-body bg-ant-black text-white`}>
        <Providers> {/* Use the wrapper that includes WagmiProvider */}
          <Header />
          <main className="min-h-screen pt-20">{children}</main>
          <Footer />
        </Providers>
      </body>
    </html>
  );
}