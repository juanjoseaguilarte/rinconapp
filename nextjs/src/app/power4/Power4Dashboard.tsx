"use client";

import { StageResult, Candle } from "@/lib/power4/types";
import { detectStage } from "@/lib/power4/analysis";
import { useTickerWS } from "@/lib/power4/useTickerWS";
import { useKlineWS } from "@/lib/power4/useKlineWS";
import { useState, useEffect, useCallback, useRef } from "react";
import { InitialAsset } from "./page";
import AppNav from "@/app/components/AppNav";

// ─── Constants ───────────────────────────────────────────────────────────────

const TIMEFRAMES = ["1m", "5m", "15m", "1h", "4h", "6h", "1d", "1w", "1M"] as const;
type TF = (typeof TIMEFRAMES)[number];

const STAGE_INFO = {
  1: {
    label: "Etapa 1 — Acumulación",
    description: "El precio corta la MMS20 arriba y abajo mientras ésta se aplana tras una caída. Zona de indecisión.",
    color: "text-yellow-400",
    bg: "bg-yellow-400/10",
    border: "border-yellow-400/30",
    dot: "bg-yellow-400",
  },
  2: {
    label: "Etapa 2 — Alcista",
    description: "MMS20 y MMS40 suben paralelas (vías del tren). El precio por encima de ambas. Tendencia alcista confirmada.",
    color: "text-emerald-400",
    bg: "bg-emerald-400/10",
    border: "border-emerald-400/30",
    dot: "bg-emerald-400",
  },
  3: {
    label: "Etapa 3 — Distribución",
    description: "El precio corta la MMS20 con volatilidad tras perder el primer mínimo relevante creciente.",
    color: "text-orange-400",
    bg: "bg-orange-400/10",
    border: "border-orange-400/30",
    dot: "bg-orange-400",
  },
  4: {
    label: "Etapa 4 — Bajista",
    description: "MMS20 y MMS40 bajan paralelas. El precio por debajo de ambas. Tendencia bajista confirmada.",
    color: "text-red-400",
    bg: "bg-red-400/10",
    border: "border-red-400/30",
    dot: "bg-red-400",
  },
} as const;

// ─── Helpers ─────────────────────────────────────────────────────────────────

function formatPrice(price: number) {
  if (price > 1000) return price.toLocaleString("en-US", { maximumFractionDigits: 0 });
  if (price > 1) return price.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  return price.toLocaleString("en-US", { minimumFractionDigits: 4, maximumFractionDigits: 6 });
}

function formatPct(pct: number) {
  return (pct >= 0 ? "+" : "") + pct.toFixed(2) + "%";
}

async function fetchAndAnalyze(binanceSymbol: string, interval: TF): Promise<StageResult> {
  const res = await fetch(`/api/candles?symbol=${binanceSymbol}&interval=${interval}`);
  if (!res.ok) throw new Error("API error");
  const raw: unknown[][] = await res.json();
  const candles: Candle[] = raw.map((k) => ({
    time: k[0] as number,
    open: parseFloat(k[1] as string),
    high: parseFloat(k[2] as string),
    low: parseFloat(k[3] as string),
    close: parseFloat(k[4] as string),
    volume: parseFloat(k[5] as string),
  }));
  return detectStage(candles);
}

// ─── Sub-components ──────────────────────────────────────────────────────────

function TrendBadge({ trend }: { trend: "rising" | "falling" | "flat" }) {
  if (trend === "rising") return <span className="text-emerald-400 text-xs font-medium">↑ Subiendo</span>;
  if (trend === "falling") return <span className="text-red-400 text-xs font-medium">↓ Bajando</span>;
  return <span className="text-slate-400 text-xs font-medium">→ Plana</span>;
}

function StageBadge({ stage }: { stage: keyof typeof STAGE_INFO }) {
  const info = STAGE_INFO[stage];
  return (
    <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-sm font-bold ${info.color} ${info.bg} border ${info.border}`}>
      <span className={`w-2 h-2 rounded-full ${info.dot} animate-pulse`} />
      Etapa {stage}
    </span>
  );
}

function StagePanel({ result, tf }: { result: StageResult; tf: TF }) {
  const info = STAGE_INFO[result.stage];
  const isNearSma = Math.abs(result.distanceToSma20Pct) <= 4;
  const distanceColor = result.distanceToSma20Pct > 0
    ? isNearSma ? "text-emerald-400" : "text-orange-400"
    : isNearSma ? "text-red-400" : "text-orange-400";

  const formatDate = (time: number) => {
    const d = new Date(time);
    // For small timeframes show time, for larger show date
    if (["1m", "5m", "15m", "1h", "4h", "6h"].includes(tf)) {
      return d.toLocaleString("es-ES", { day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit" });
    }
    return d.toLocaleDateString("es-ES", { day: "2-digit", month: "short", year: "numeric" });
  };

  return (
    <div className={`rounded-2xl border p-5 ${info.bg} ${info.border} flex flex-col gap-4`}>
      {/* Stage header */}
      <div className="flex items-center justify-between flex-wrap gap-2">
        <StageBadge stage={result.stage} />
        <span className={`text-xs font-medium ${info.color}`}>
          {result.sma20Trend === result.sma40Trend && result.sma20Trend !== "flat"
            ? result.sma20Trend === "rising" ? "✓ Vías alcistas" : "✓ Vías bajistas"
            : "⚠ Sin vías"}
        </span>
      </div>

      <p className={`text-sm ${info.color} leading-snug`}>{info.description}</p>

      {/* SMAs */}
      <div className="grid grid-cols-2 gap-3">
        <div className="rounded-xl bg-slate-800/60 p-3">
          <div className="text-slate-400 text-xs mb-1">MMS20</div>
          <div className="text-white font-bold text-sm">${formatPrice(result.sma20)}</div>
          <TrendBadge trend={result.sma20Trend} />
        </div>
        <div className="rounded-xl bg-slate-800/60 p-3">
          <div className="text-slate-400 text-xs mb-1">MMS40</div>
          <div className="text-white font-bold text-sm">${formatPrice(result.sma40)}</div>
          <TrendBadge trend={result.sma40Trend} />
        </div>
      </div>

      {/* Distance + Relevant levels */}
      <div className="grid grid-cols-3 gap-3">
        <div className="rounded-xl bg-slate-800/60 p-3">
          <div className="text-slate-400 text-xs mb-1">Dist. MMS20</div>
          <div className={`font-bold text-sm ${distanceColor}`}>{formatPct(result.distanceToSma20Pct)}</div>
          <div className="text-xs text-slate-500">{isNearSma ? "Cerca" : "Lejos"}</div>
        </div>
        {result.lastRelevantHigh && (
          <div className="rounded-xl bg-slate-800/60 p-3">
            <div className="text-slate-400 text-xs mb-1">Máx. Relev.</div>
            <div className="text-emerald-400 font-bold text-sm">${formatPrice(result.lastRelevantHigh.price)}</div>
            <div className="text-xs text-slate-500">{formatDate(result.lastRelevantHigh.time)}</div>
          </div>
        )}
        {result.lastRelevantLow && (
          <div className="rounded-xl bg-slate-800/60 p-3">
            <div className="text-slate-400 text-xs mb-1">Mín. Relev.</div>
            <div className="text-red-400 font-bold text-sm">${formatPrice(result.lastRelevantLow.price)}</div>
            <div className="text-xs text-slate-500">{formatDate(result.lastRelevantLow.time)}</div>
          </div>
        )}
      </div>

      {/* Pattern alert */}
      {(result.stage === 2 || result.stage === 4) && (
        <div className={`rounded-xl p-3 text-xs border ${
          result.stage === 2
            ? "bg-emerald-900/30 border-emerald-500/20 text-emerald-300"
            : "bg-red-900/30 border-red-500/20 text-red-300"
        }`}>
          {result.stage === 2 ? (
            <><span className="font-bold">PC1 activo:</span> Espera retroceso de 3-5 máximos decrecientes hacia MMS20. Entrada 0.3% sobre el último máx. decreciente. SL 1% bajo el mínimo de la vela de entrada.</>
          ) : (
            <><span className="font-bold">PV1 activo:</span> Espera rebote de 3-5 mínimos crecientes hacia MMS20. Entrada 0.3% bajo el último mín. creciente. SL 1% sobre el máximo más alto entre entrada y vela previa.</>
          )}
        </div>
      )}
    </div>
  );
}

function LoadingSkeleton() {
  return (
    <div className="rounded-2xl border border-slate-700/30 bg-slate-800/20 p-5 flex flex-col gap-4 animate-pulse">
      <div className="flex justify-between">
        <div className="h-7 w-28 rounded-full bg-slate-700/50" />
        <div className="h-4 w-20 rounded bg-slate-700/50" />
      </div>
      <div className="h-10 rounded bg-slate-700/30" />
      <div className="grid grid-cols-2 gap-3">
        <div className="h-16 rounded-xl bg-slate-700/30" />
        <div className="h-16 rounded-xl bg-slate-700/30" />
      </div>
      <div className="grid grid-cols-3 gap-3">
        <div className="h-16 rounded-xl bg-slate-700/30" />
        <div className="h-16 rounded-xl bg-slate-700/30" />
        <div className="h-16 rounded-xl bg-slate-700/30" />
      </div>
    </div>
  );
}

// ─── Asset Card ───────────────────────────────────────────────────────────────

type TfStages = Partial<Record<TF, keyof typeof STAGE_INFO>>;

function AssetCard({ asset }: { asset: InitialAsset }) {
  const [selectedTf, setSelectedTf] = useState<TF>("1d");
  const [result, setResult] = useState<StageResult>(asset.initial1d);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [tfStages, setTfStages] = useState<TfStages>({ "1d": asset.initial1d.stage as keyof typeof STAGE_INFO });

  // Candles for the selected timeframe — updated live by WS
  const candlesRef = useRef<Candle[]>(asset.initial1d.candles);
  const selectedTfRef = useRef<TF>("1d");

  // Real-time price (24h change) via miniTicker WS
  const ticker = useTickerWS(asset.binanceSymbol);
  const liveChangePct = ticker?.change24hPct ?? asset.initial1d.priceChangePct24h;
  const priceUp = liveChangePct >= 0;

  // Real-time kline WS → recalculates ALL indicators on every tick
  useKlineWS(asset.binanceSymbol, selectedTf, candlesRef, useCallback((updatedCandles: Candle[]) => {
    try {
      const newResult = detectStage(updatedCandles);
      setResult(newResult);
      setTfStages((prev) => ({
        ...prev,
        [selectedTfRef.current]: newResult.stage as keyof typeof STAGE_INFO,
      }));
    } catch { /* not enough candles yet */ }
  }, []));

  // Load candles for a timeframe (HTTP fetch), then WS takes over
  const loadTf = useCallback(async (tf: TF) => {
    selectedTfRef.current = tf;
    setSelectedTf(tf);
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`/api/candles?symbol=${asset.binanceSymbol}&interval=${tf}`);
      if (!res.ok) throw new Error("API error");
      const raw: unknown[][] = await res.json();
      const candles: Candle[] = raw.map((k) => ({
        time: k[0] as number,
        open: parseFloat(k[1] as string),
        high: parseFloat(k[2] as string),
        low: parseFloat(k[3] as string),
        close: parseFloat(k[4] as string),
        volume: parseFloat(k[5] as string),
      }));
      candlesRef.current = candles;
      const data = detectStage(candles);
      setResult(data);
      setTfStages((prev) => ({ ...prev, [tf]: data.stage as keyof typeof STAGE_INFO }));
    } catch {
      setError("Error al cargar datos");
    } finally {
      setLoading(false);
    }
  }, [asset.binanceSymbol]);

  // Load all other timeframes in background (for badges summary)
  useEffect(() => {
    TIMEFRAMES.filter((tf) => tf !== "1d").forEach(async (tf) => {
      try {
        const res = await fetch(`/api/candles?symbol=${asset.binanceSymbol}&interval=${tf}`);
        if (!res.ok) return;
        const raw: unknown[][] = await res.json();
        const candles: Candle[] = raw.map((k) => ({
          time: k[0] as number,
          open: parseFloat(k[1] as string),
          high: parseFloat(k[2] as string),
          low: parseFloat(k[3] as string),
          close: parseFloat(k[4] as string),
          volume: parseFloat(k[5] as string),
        }));
        const data = detectStage(candles);
        setTfStages((prev) => ({ ...prev, [tf]: data.stage as keyof typeof STAGE_INFO }));
      } catch { /* silent */ }
    });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [asset.binanceSymbol]);

  const livePrice = result.currentPrice;

  return (
    <div className="rounded-2xl bg-slate-900 border border-slate-700/50 overflow-hidden">
      {/* Price header */}
      <div className="p-5 pb-4 border-b border-slate-700/50">
        <div className="flex items-start justify-between gap-3">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <h2 className="text-xl font-bold text-white">{asset.name}</h2>
              {ticker && (
                <span className="flex items-center gap-1 text-[10px] text-emerald-400 font-medium">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                  LIVE
                </span>
              )}
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-3xl font-black text-white tabular-nums">${formatPrice(livePrice)}</span>
              <span className={`text-base font-bold ${priceUp ? "text-emerald-400" : "text-red-400"}`}>
                {formatPct(liveChangePct)}
              </span>
            </div>
            {ticker && (
              <div className="text-[10px] text-slate-500 mt-0.5 font-mono tabular-nums">
                {ticker.updatedAt.toLocaleTimeString("es-ES")}
              </div>
            )}
          </div>
          <StageBadge stage={result.stage} />
        </div>

        {/* Timeframe selector */}
        <div className="flex flex-wrap gap-1.5 mt-4">
          {TIMEFRAMES.map((tf) => {
            const tfStage = tfStages[tf];
            const info = tfStage ? STAGE_INFO[tfStage] : null;
            const isSelected = selectedTf === tf;
            return (
              <button
                key={tf}
                onClick={() => loadTf(tf)}
                disabled={loading}
                className={`flex flex-col items-center px-2.5 pt-1.5 pb-1 rounded-xl text-xs font-bold transition-all min-w-[36px] border ${
                  isSelected
                    ? `${STAGE_INFO[result.stage].bg} ${STAGE_INFO[result.stage].color} ${STAGE_INFO[result.stage].border}`
                    : "bg-slate-800 text-slate-300 border-slate-700 hover:border-slate-500 hover:text-slate-100"
                } ${loading && !isSelected ? "opacity-40 cursor-not-allowed" : "cursor-pointer"}`}
              >
                <span>{tf}</span>
                <span className={`text-[10px] font-black mt-0.5 ${
                  tfStage ? info!.color : "text-slate-600"
                }`}>
                  {tfStage ? `E${tfStage}` : "·"}
                </span>
              </button>
            );
          })}
          {loading && (
            <span className="self-center text-xs text-slate-500 ml-1 animate-pulse">Cargando...</span>
          )}
        </div>
      </div>

      {/* Stage panel */}
      <div className="p-4">
        {error ? (
          <div className="rounded-xl bg-red-900/20 border border-red-500/20 text-red-400 text-sm p-4 text-center">
            {error}
          </div>
        ) : loading ? (
          <LoadingSkeleton />
        ) : (
          <StagePanel result={result} tf={selectedTf} />
        )}
      </div>
    </div>
  );
}

// ─── Dashboard ────────────────────────────────────────────────────────────────

function Header() {
  const [time, setTime] = useState(() => new Date());
  const [legendOpen, setLegendOpen] = useState(false);

  useEffect(() => {
    const id = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(id);
  }, []);

  return (
    <div className="border-b border-slate-800 bg-slate-900/80 backdrop-blur sticky top-0 z-20">
      <div className="max-w-3xl mx-auto px-4 py-4 flex items-center justify-between">
        <h1 className="text-xl font-black text-white tracking-tight">
          Power 4 <span className="text-slate-400 font-normal text-base">Crypto Scanner</span>
        </h1>

        <div className="flex items-center gap-3">
          {/* Legend button */}
          <div className="relative">
            <button
              onClick={() => setLegendOpen((v) => !v)}
              className={`w-8 h-8 rounded-full text-sm font-black border transition-all ${
                legendOpen
                  ? "bg-slate-200 text-slate-900 border-slate-200"
                  : "bg-slate-800 text-slate-300 border-slate-600 hover:border-slate-400 hover:text-white"
              }`}
            >
              C
            </button>

            {legendOpen && (
              <>
                {/* Backdrop */}
                <div
                  className="fixed inset-0 z-10"
                  onClick={() => setLegendOpen(false)}
                />
                {/* Dropdown */}
                <div className="absolute right-0 top-10 z-20 w-[min(360px,90vw)] rounded-2xl bg-slate-900 border border-slate-700 shadow-2xl shadow-black/60 overflow-hidden">
                  <div className="px-4 py-3 border-b border-slate-700/60 flex items-center justify-between">
                    <span className="text-xs font-bold text-slate-300 uppercase tracking-wider">
                      Ciclo de Vida — Power 4
                    </span>
                    <button
                      onClick={() => setLegendOpen(false)}
                      className="text-slate-500 hover:text-slate-200 text-lg leading-none"
                    >
                      ×
                    </button>
                  </div>
                  <div className="p-4 grid grid-cols-2 gap-2">
                    {([1, 2, 3, 4] as const).map((s) => {
                      const info = STAGE_INFO[s];
                      return (
                        <div key={s} className={`rounded-xl p-3 border text-xs ${info.bg} ${info.border}`}>
                          <div className={`font-bold mb-1 ${info.color}`}>Etapa {s}</div>
                          <div className="text-slate-400 leading-snug">{info.description}</div>
                        </div>
                      );
                    })}
                  </div>
                  <p className="text-xs text-slate-500 px-4 pb-4 leading-relaxed">
                    Alineación óptima: mismo marco temporal en E2 (PC1) o E4 (PV1) en semanal y diario.
                    Distancia a MMS20 mayor al 4% aumenta el riesgo de fallo.
                  </p>
                </div>
              </>
            )}
          </div>

          {/* Clock */}
          <div className="text-right">
            <div className="text-xs text-slate-500">Hora actual</div>
            <div className="text-xs text-slate-400 font-mono tabular-nums">
              {time.toLocaleTimeString("es-ES")}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function Power4Dashboard({ assets }: { assets: InitialAsset[] }) {
  return (
    <div className="min-h-screen bg-slate-950 text-slate-100">
      <AppNav />
      <Header />
      <div className="max-w-3xl mx-auto px-4 py-6 flex flex-col gap-5">
        {assets.map((a) => <AssetCard key={a.binanceSymbol} asset={a} />)}
        <p className="text-center text-xs text-slate-600 pb-4">
          Datos de Binance · Solo fines educativos, no es asesoría financiera
        </p>
      </div>
    </div>
  );
}
