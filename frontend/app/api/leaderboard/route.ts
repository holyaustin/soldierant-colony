import { NextRequest, NextResponse } from 'next/server';
import clientPromise from '@/lib/mongodb';
import { revalidateTag } from 'next/cache';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const type = searchParams.get('type') || 'daily';
    
    const client = await clientPromise;
    const db = client.db('soldier-ant');
    
    const leaderboard = await db
      .collection(type === 'daily' ? 'dailyLeaderboard' : 'weeklyLeaderboard')
      .find({})
      .sort({ score: -1 })
      .limit(100)
      .toArray();
    
    return NextResponse.json({ success: true, data: leaderboard });
  } catch (error) {
    return NextResponse.json(
      { success: false, error: 'Failed to fetch leaderboard' },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { type, address, score } = body;
    
    const client = await clientPromise;
    const db = client.db('soldier-ant');
    
    await db.collection(type === 'daily' ? 'dailyLeaderboard' : 'weeklyLeaderboard').updateOne(
      { address },
      { $set: { address, score, updatedAt: new Date() } },
      { upsert: true }
    );
    
    // Revalidate the cache
    revalidateTag('leaderboard');
    
    return NextResponse.json({ success: true });
  } catch (error) {
    return NextResponse.json(
      { success: false, error: 'Failed to update leaderboard' },
      { status: 500 }
    );
  }
}