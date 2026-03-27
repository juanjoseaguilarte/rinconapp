import { Candle } from "./types";

const BINANCE_BASE = "https://api.binance.com/api/v3";

type Interval = "1d" | "1w";

export async function fetchCandles(
  symbol: string,
  interval: Interval,
  limit = 200
): Promise<Candle[]> {
  const url = `${BINANCE_BASE}/klines?symbol=${symbol}&interval=${interval}&limit=${limit}`;
  const res = await fetch(url, { next: { revalidate: 300 } });
  if (!res.ok) throw new Error(`Binance API error: ${res.status}`);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const data: any[][] = await res.json();
  return data.map((k) => ({
    time: k[0],
    open: parseFloat(k[1]),
    high: parseFloat(k[2]),
    low: parseFloat(k[3]),
    close: parseFloat(k[4]),
    volume: parseFloat(k[5]),
  }));
}
