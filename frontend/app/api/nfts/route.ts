import { NextRequest, NextResponse } from 'next/server';
import { pinata } from '@/lib/pinata';

// Define types for Pinata V3 responses based on the latest SDK
interface PinataFileResponse {
  id: string;
  name: string;
  cid: string;
  size: number;
  mime_type: string;
  created_at: string;
  metadata?: {
    name?: string;
    keyvalues?: Record<string, string>; // Strict string record
  };
}

interface PinataListResponse {
  files: PinataFileResponse[];
  next_page_token?: string;
}

export async function GET() {
  try {
    // Cast through 'unknown' to bridge the SDK's internal type mismatch
    const response = (await pinata.files.public.list()) as unknown as PinataListResponse;
    const files = response.files || [];
    
    const nfts = await Promise.all(
      files.map(async (file) => {
        const url = await pinata.gateways.public.convert(file.cid);
        return {
          id: file.id,
          cid: file.cid,
          name: file.name,
          size: file.size,
          url,
          traits: file.metadata?.keyvalues || {},
          createdAt: file.created_at,
        };
      })
    );
    
    return NextResponse.json({ success: true, data: nfts });
  } catch (error) {
    console.error('Pinata fetch error:', error);
    return NextResponse.json({ success: false, error: 'Fetch failed' }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const file = formData.get('file') as File;
    const metadataString = formData.get('metadata') as string;
    
    if (!file || !metadataString) {
      return NextResponse.json({ success: false, error: 'Missing data' }, { status: 400 });
    }

    const metadata = JSON.parse(metadataString);
    
    /**
     * FIX: Pinata V3 requires Record<string, string>. 
     * We MUST cast numbers (like power level) to strings using String().
     */
    const keyvalues: Record<string, string> = {};
    if (metadata.attributes && Array.isArray(metadata.attributes)) {
      metadata.attributes.forEach((attr: { trait_type: string; value: any }) => {
        keyvalues[attr.trait_type] = String(attr.value);
      });
    }
    
    const upload = (await pinata.upload.public.file(file, {
      metadata: {
        name: metadata.name || file.name,
        keyvalues: keyvalues // Now correctly typed as Record<string, string>
      }
    })) as unknown as PinataFileResponse;
    
    const url = await pinata.gateways.public.convert(upload.cid);
    
    return NextResponse.json({
      success: true,
      data: { id: upload.id, cid: upload.cid, url, ...metadata },
    });
  } catch (error) {
    console.error('Upload error:', error);
    return NextResponse.json({ success: false, error: 'Upload failed' }, { status: 500 });
  }
}

export async function DELETE(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    
    if (!id) {
      return NextResponse.json(
        { success: false, error: 'Missing file ID' },
        { status: 400 }
      );
    }

    // FIX: Wrap 'id' in an array [id] to satisfy string[] requirement
    await pinata.files.public.delete([id]);
    
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Pinata delete error:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to delete file' },
      { status: 500 }
    );
  }
}

