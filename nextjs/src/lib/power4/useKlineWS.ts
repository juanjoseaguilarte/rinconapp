"use client";

import { useEffect, useRef, useCallback } from "react";
import { Candle } from "./types";

interface KlineEvent {
  t: number;   // open time
  o: string;   // open
  h: string;   // high
  l: string;   // low
  c: string;   // close (current price)
  v: string;   // volume
  x: boolean;  // is candle closed
}

type OnKline = (candles: Candle[]) => void;

export function useKlineWS(
  binanceSymbol: string,
  interval: string,
  candlesRef: React.MutableRefObject<Candle[]>,
  onUpdate: OnKline
) {
  const wsRef = useRef<WebSocket | null>(null);
  const retryRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const throttleRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pendingRef = useRef<Candle[] | null>(null);
  const onUpdateRef = useRef(onUpdate);
  onUpdateRef.current = onUpdate;

  const flush = useCallback(() => {
    if (pendingRef.current) {
      onUpdateRef.current(pendingRef.current);
      pendingRef.current = null;
    }
    throttleRef.current = null;
  }, []);

  useEffect(() => {
    let alive = true;

    function connect() {
      const symbol = binanceSymbol.toLowerCase();
      const ws = new WebSocket(
        `wss://stream.binance.com:9443/ws/${symbol}@kline_${interval}`
      );
      wsRef.current = ws;

      ws.onmessage = (e) => {
        if (!alive) return;
        try {
          const msg = JSON.parse(e.data);
          const k: KlineEvent = msg.k;
          const candles = candlesRef.current;
          if (!candles.length) return;

          // Update or append the current (last) candle with live data
          const updatedCandle: Candle = {
            time: k.t,
            open: parseFloat(k.o),
            high: parseFloat(k.h),
            low: parseFloat(k.l),
            close: parseFloat(k.c),
            volume: parseFloat(k.v),
          };

          let updated: Candle[];
          const last = candles[candles.length - 1];

          if (last.time === k.t) {
            // Same candle — update in place
            updated = [...candles.slice(0, -1), updatedCandle];
          } else if (k.x) {
            // New closed candle — append and drop oldest to keep size stable
            updated = [...candles.slice(1), updatedCandle];
          } else {
            // New forming candle
            updated = [...candles, updatedCandle];
          }

          candlesRef.current = updated;

          // Throttle recalculation to max once per 500ms
          pendingRef.current = updated;
          if (!throttleRef.current) {
            throttleRef.current = setTimeout(flush, 500);
          }
        } catch {
          // ignore malformed frames
        }
      };

      ws.onclose = () => {
        if (!alive) return;
        retryRef.current = setTimeout(connect, 3000);
      };

      ws.onerror = () => ws.close();
    }

    connect();

    return () => {
      alive = false;
      if (retryRef.current) clearTimeout(retryRef.current);
      if (throttleRef.current) clearTimeout(throttleRef.current);
      wsRef.current?.close();
    };
  }, [binanceSymbol, interval, candlesRef, flush]);
}
