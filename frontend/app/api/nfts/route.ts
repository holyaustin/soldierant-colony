import { NextRequest, NextResponse } from 'next/server';
import { pinata } from '@/lib/pinata';

export async function GET() {
  try {
    // Fetch NFTs from Pinata (you'll need to adapt this based on your data structure)
    const files = await pinata.files.public.list();
    
    // Transform to NFT format with gateway URLs
    const nfts = await Promise.all(
      files.map(async (file) => {
        const url = await pinata.gateways.public.convert(file.cid);
        return {
          id: file.id,
          cid: file.cid,
          name: file.name,
          size: file.size,
          url,
        };
      })
    );
    
    return NextResponse.json({ success: true, data: nfts });
  } catch (error) {
    return NextResponse.json(
      { success: false, error: 'Failed to fetch NFTs' },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const file = formData.get('file') as File;
    const metadata = formData.get('metadata') as string;
    
    if (!file || !metadata) {
      return NextResponse.json(
        { success: false, error: 'Missing file or metadata' },
        { status: 400 }
      );
    }

    // Upload file to Pinata
    const upload = await pinata.upload.public.file(file);
    
    // Store metadata (you might want to store this in MongoDB as well)
    const metadataObj = JSON.parse(metadata);
    
    return NextResponse.json({
      success: true,
      data: {
        id: upload.id,
        cid: upload.cid,
        ...metadataObj,
      },
    });
  } catch (error) {
    return NextResponse.json(
      { success: false, error: 'Failed to upload NFT' },
      { status: 500 }
    );
  }
}