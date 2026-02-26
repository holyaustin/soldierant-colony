'use client';

import { PrivyProvider as PrivyAuthProvider } from '@privy-io/react-auth';
import { avalancheFuji, avalanche } from 'viem/chains';

export function PrivyProvider({ children }: { children: React.ReactNode }) {
  return (
    <PrivyAuthProvider
      appId={process.env.NEXT_PUBLIC_PRIVY_APP_ID!}
      config={{
        //loginMethods: ['email', 'google', 'twitter'],
        appearance: {
          theme: 'dark',
          accentColor: '#B8860B',
          logo: '/images/ant-logo.png',
        },
        embeddedWallets: {
          ethereum: {
            createOnLogin: "users-without-wallets" as const,
          },
        },
        defaultChain: avalancheFuji,
        supportedChains: [avalancheFuji, avalanche],
      }}
    >
      {children}
    </PrivyAuthProvider>
  );
}