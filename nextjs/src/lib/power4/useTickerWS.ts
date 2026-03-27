"use client";

import { useEffect, useRef, useState } from "react";

export interface TickerData {
  price: number;
  change24hPct: number;
  updatedAt: Date;
}

export function useTickerWS(binanceSymbol: string): TickerData | null {
  const [data, setData] = useState<TickerData | null>(null);
  const wsRef = useRef<WebSocket | null>(null);
  const retryRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    let alive = true;

    function connect() {
      const symbol = binanceSymbol.toLowerCase();
      const ws = new WebSocket(
        `wss://stream.binance.com:9443/ws/${symbol}@miniTicker`
      );
      wsRef.current = ws;

      ws.onmessage = (e) => {
        if (!alive) return;
        try {
          const d = JSON.parse(e.data);
          const price = parseFloat(d.c);
          const open = parseFloat(d.o);
          const change24hPct = ((price - open) / open) * 100;
          setData({ price, change24hPct, updatedAt: new Date() });
        } catch {
          // ignore malformed frames
        }
      };

      ws.onclose = () => {
        if (!alive) return;
        // Reconnect after 3s on unexpected close
        retryRef.current = setTimeout(connect, 3000);
      };

      ws.onerror = () => ws.close();
    }

    connect();

    return () => {
      alive = false;
      if (retryRef.current) clearTimeout(retryRef.current);
      wsRef.current?.close();
    };
  }, [binanceSymbol]);

  return data;
}
