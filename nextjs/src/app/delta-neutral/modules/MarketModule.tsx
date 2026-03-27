"use client";

import { useEffect, useRef, useState, useCallback } from "react";
import { MarketIndicators, analyzeMarket } from "@/lib/indicators";
import { fetchCandles } from "@/lib/power4/api";
import { Candle } from "@/lib/power4/types";
import { createChart, IChartApi, CandlestickSeries, LineSeries, ColorType } from "lightweight-charts";

function Stat({ label, value, sub, color }: { label: string; value: string; sub?: string; color?: string }) {
  return (
    <div className="rounded-xl bg-slate-800/60 p-3">
      <div className="text-slate-400 text-xs mb-1">{label}</div>
      <div className={`font-bold ${color ?? "text-white"}`}>{value}</div>
      {sub && <div className="text-xs text-slate-500 mt-0.5">{sub}</div>}
    </div>
  );
}

function PriceChart({ candles, ema20, ema50, ema200 }: {
  candles: Candle[];
  ema20: number[]; ema50: number[]; ema200: number[];
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const chartRef = useRef<IChartApi | null>(null);

  useEffect(() => {
    if (!containerRef.current || candles.length === 0) return;
    const chart = createChart(containerRef.current, {
      layout: { background: { type: ColorType.Solid, color: "#0f172a" }, textColor: "#94a3b8" },
      grid: { vertLines: { color: "#1e293b" }, horzLines: { color: "#1e293b" } },
      crosshair: { mode: 1 },
      rightPriceScale: { borderColor: "#334155" },
      timeScale: { borderColor: "#334155", timeVisible: true },
      width: containerRef.current.clientWidth,
      height: 320,
    });
    chartRef.current = chart;

    const candleSeries = chart.addSeries(CandlestickSeries, {
      upColor: "#34d399", downColor: "#f87171",
      borderUpColor: "#34d399", borderDownColor: "#f87171",
      wickUpColor: "#34d399", wickDownColor: "#f87171",
    });
    candleSeries.setData(candles.map((c) => ({
      time: Math.floor(c.time / 1000) as unknown as import("lightweight-charts").Time,
      open: c.open, high: c.high, low: c.low, close: c.close,
    })));

    const colors = ["#38bdf8", "#fb923c", "#a78bfa"];
    [[ema20, "EMA20"], [ema50, "EMA50"], [ema200, "EMA200"]].forEach(([arr, name], idx) => {
      const s = chart.addSeries(LineSeries, { color: colors[idx], lineWidth: 1, title: name as string });
      s.setData(
        (arr as number[])
          .map((v, i) => ({ time: Math.floor(candles[i].time / 1000) as unknown as import("lightweight-charts").Time, value: v }))
          .filter((d) => !isNaN(d.value))
      );
    });

    chart.timeScale().fitContent();
    const ro = new ResizeObserver(() => {
      if (containerRef.current) chart.applyOptions({ width: containerRef.current.clientWidth });
    });
    ro.observe(containerRef.current);
    return () => { chart.remove(); ro.disconnect(); };
  }, [candles, ema20, ema50, ema200]);

  return <div ref={containerRef} className="rounded-xl overflow-hidden" />;
}

export default function MarketModule({ initialMarket }: { initialMarket: MarketIndicators }) {
  const [market, setMarket] = useState(initialMarket);
  const [candles, setCandles] = useState<Candle[]>([]);
  const [ema20, setEma20] = useState<number[]>([]);
  const [ema50, setEma50] = useState<number[]>([]);
  const [ema200, setEma200] = useState<number[]>([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    try {
      const c = await fetchCandles("BTCUSDT", "1h", 220);
      setCandles(c);
      const closes = c.map((x) => x.close);
      const { calcEMA, calcRSI, calcMACD, calcATR, calcADX, analyzeMarket: am } = await import("@/lib/indicators");
      setEma20(calcEMA(closes, 20));
      setEma50(calcEMA(closes, 50));
      setEma200(calcEMA(closes, 200));
      setMarket(am(c));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const trendColor =
    market.trend === "ALCISTA" ? "text-emerald-400" :
    market.trend === "BAJISTA" ? "text-red-400" : "text-yellow-400";

  return (
    <div className="flex flex-col gap-5">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-bold text-white">Módulo de Mercado — BTC/USDT 1H</h2>
        <button onClick={load} className="text-xs text-slate-400 hover:text-white border border-slate-700 rounded-lg px-3 py-1">
          ↻ Actualizar
        </button>
      </div>

      {/* Trend badge */}
      <div className={`rounded-2xl p-4 border flex items-center gap-4 ${
        market.trend === "ALCISTA" ? "bg-emerald-900/20 border-emerald-600/30" :
        market.trend === "BAJISTA" ? "bg-red-900/20 border-red-600/30" :
        "bg-yellow-900/20 border-yellow-600/30"
      }`}>
        <span className={`text-4xl font-black ${trendColor}`}>
          {market.trend === "ALCISTA" ? "▲" : market.trend === "BAJISTA" ? "▼" : "→"}
        </span>
        <div>
          <div className={`text-2xl font-black ${trendColor}`}>{market.trend}</div>
          <div className="text-slate-400 text-sm">
            {market.trend === "ALCISTA" && "EMAs alcistas · RSI > 50 · MACD positivo"}
            {market.trend === "BAJISTA" && "EMAs bajistas · RSI < 50 · MACD negativo"}
            {market.trend === "LATERAL" && "Precio sin tendencia clara · ADX bajo"}
          </div>
        </div>
        <div className="ml-auto text-right">
          <div className="text-3xl font-black text-white tabular-nums">
            ${market.price.toLocaleString("en-US", { maximumFractionDigits: 0 })}
          </div>
          <div className="text-slate-400 text-xs">Precio actual</div>
        </div>
      </div>

      {/* Indicators grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        <Stat label="EMA 20" value={`$${market.ema20.toLocaleString("en-US", { maximumFractionDigits: 0 })}`}
          color={market.price > market.ema20 ? "text-emerald-400" : "text-red-400"} />
        <Stat label="EMA 50" value={`$${market.ema50.toLocaleString("en-US", { maximumFractionDigits: 0 })}`}
          color={market.price > market.ema50 ? "text-emerald-400" : "text-red-400"} />
        <Stat label="EMA 200" value={`$${market.ema200.toLocaleString("en-US", { maximumFractionDigits: 0 })}`}
          color={market.price > market.ema200 ? "text-emerald-400" : "text-red-400"} />
        <Stat label="RSI (14)" value={market.rsi.toFixed(1)}
          color={market.rsi > 70 ? "text-red-400" : market.rsi < 30 ? "text-emerald-400" : "text-white"}
          sub={market.rsi > 70 ? "Sobrecomprado" : market.rsi < 30 ? "Sobrevendido" : "Neutral"} />
        <Stat label="MACD" value={market.macd.toFixed(1)}
          color={market.macd > 0 ? "text-emerald-400" : "text-red-400"}
          sub={`Signal: ${market.macdSignal.toFixed(1)}`} />
        <Stat label="Histograma MACD" value={market.macdHistogram.toFixed(1)}
          color={market.macdHistogram > 0 ? "text-emerald-400" : "text-red-400"} />
        <Stat label="ATR (14)" value={`$${market.atr.toFixed(0)}`} sub="Volatilidad media" />
        <Stat label="ADX (14)" value={market.adx.toFixed(1)}
          sub={market.adx > 25 ? "Tendencia fuerte" : "Tendencia débil"}
          color={market.adx > 25 ? "text-cyan-400" : "text-slate-400"} />
      </div>

      {/* Chart */}
      {loading ? (
        <div className="rounded-xl bg-slate-800/40 h-80 flex items-center justify-center text-slate-500 animate-pulse">
          Cargando gráfico...
        </div>
      ) : (
        <PriceChart candles={candles} ema20={ema20} ema50={ema50} ema200={ema200} />
      )}
    </div>
  );
}
