'use client';

import { useState, useEffect } from 'react';
import Image from 'next/image';
import { motion, AnimatePresence } from 'framer-motion';

interface NFT {
  id: string;
  cid: string;
  name: string;
  url: string;
  metadata?: {
    attributes?: Array<{ trait_type: string; value: string | number }>;
  };
}

export default function MarketplaceGrid() {
  const [nfts, setNfts] = useState<NFT[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedNft, setSelectedNft] = useState<NFT | null>(null);

  useEffect(() => {
    const fetchNFTs = async () => {
      try {
        const res = await fetch('/api/nfts');
        const json = await res.json();
        setNfts(json.data);
      } catch (error) {
        console.error('Failed to fetch NFTs:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchNFTs();
  }, []);

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-6">
        <AnimatePresence>
          {nfts.map((nft, index) => (
            <motion.div
              key={nft.id}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              transition={{ delay: index * 0.1 }}
              whileHover={{ y: -10 }}
              className="group cursor-pointer"
              onClick={() => setSelectedNft(nft)}
            >
              <div className="relative aspect-square rounded-lg overflow-hidden border-2 border-ant-gold/30 group-hover:border-ant-gold transition">
                <Image
                  src={nft.url}
                  alt={nft.name}
                  fill
                  className="object-cover group-hover:scale-110 transition duration-500"
                  sizes="(max-width: 768px) 100vw, (max-width: 1200px) 33vw, 25vw"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-ant-black via-transparent to-transparent opacity-0 group-hover:opacity-100 transition" />
              </div>
              <div className="mt-3">
                <h3 className="font-semibold text-ant-gold">{nft.name}</h3>
                <p className="text-sm text-gray-400">
                  {nft.metadata?.attributes?.find(a => a.trait_type === 'Class')?.value || 'Soldier'} Ant
                </p>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      {/* NFT Detail Modal */}
      <AnimatePresence>
        {selectedNft && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-ant-black/90 backdrop-blur-sm"
            onClick={() => setSelectedNft(null)}
          >
            <motion.div
              initial={{ scale: 0.9 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0.9 }}
              className="relative max-w-2xl w-full bg-gradient-to-b from-ant-black to-primary/20 rounded-2xl border-2 border-ant-gold p-6"
              onClick={(e) => e.stopPropagation()}
            >
              <button
                onClick={() => setSelectedNft(null)}
                className="absolute top-4 right-4 text-2xl text-gray-400 hover:text-white"
              >
                ✕
              </button>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="relative aspect-square rounded-lg overflow-hidden">
                  <Image
                    src={selectedNft.url}
                    alt={selectedNft.name}
                    fill
                    className="object-cover"
                  />
                </div>
                
                <div>
                  <h2 className="font-display text-2xl text-ant-gold mb-2">
                    {selectedNft.name}
                  </h2>
                  
                  <div className="space-y-3 mt-4">
                    {selectedNft.metadata?.attributes?.map((attr, i) => (
                      <div key={i} className="flex justify-between border-b border-ant-gold/20 pb-2">
                        <span className="text-gray-400">{attr.trait_type}</span>
                        <span className="font-semibold">{attr.value}</span>
                      </div>
                    ))}
                  </div>
                  
                  <button className="w-full mt-6 px-6 py-3 rounded-lg bg-gradient-to-r from-primary to-ant-gold text-white font-semibold hover:shadow-lg hover:shadow-ant-gold/20 transition">
                    Acquire Ant
                  </button>
                </div>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}