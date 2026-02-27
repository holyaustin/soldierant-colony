'use client';

import { PrivyProvider as PrivyAuthProvider } from '@privy-io/react-auth';
import { WagmiProvider } from 'wagmi';
import { avalancheFuji, avalanche } from 'viem/chains';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http, createConfig } from 'wagmi';

// Create a Wagmi config
const wagmiConfig = createConfig({
  chains: [avalancheFuji, avalanche],
  transports: {
    [avalancheFuji.id]: http(),
    [avalanche.id]: http(),
  },
});

// Create a React Query client
const queryClient = new QueryClient();

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        <PrivyAuthProvider
          appId={process.env.NEXT_PUBLIC_PRIVY_APP_ID!}
          config={{
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
      </QueryClientProvider>
    </WagmiProvider>
  );
}
