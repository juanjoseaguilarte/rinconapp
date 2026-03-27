import { NextRequest, NextResponse } from "next/server";

const LIMITS: Record<string, number> = {
  "1m": 100,
  "5m": 100,
  "15m": 100,
  "1h": 150,
  "4h": 150,
  "6h": 150,
  "1d": 200,
  "1w": 150,
  "1M": 100,
};

export async function GET(req: NextRequest) {
  const { searchParams } = req.nextUrl;
  const symbol = searchParams.get("symbol");
  const interval = searchParams.get("interval") ?? "1d";

  if (!symbol) return NextResponse.json({ error: "Missing symbol" }, { status: 400 });

  const limit = LIMITS[interval] ?? 150;
  const url = `https://api.binance.com/api/v3/klines?symbol=${symbol}&interval=${interval}&limit=${limit}`;

  try {
    const res = await fetch(url, { next: { revalidate: 60 } });
    if (!res.ok) throw new Error(`Binance ${res.status}`);
    const data = await res.json();
    return NextResponse.json(data);
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 502 });
  }
}
