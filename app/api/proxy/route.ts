import { NextRequest, NextResponse } from 'next/server';

export const runtime = 'nodejs';

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const limit = searchParams.get('limit') || '100';
  try {
    const res = await fetch(`https://clob.polymarket.com/markets?limit=${limit}&closed=false`, {
      signal: AbortSignal.timeout(15000),
    });
    const data = await res.json();
    return NextResponse.json(data);
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 });
  }
}
