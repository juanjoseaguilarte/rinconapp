"use client";

import { useState } from "react";
import { LPPosition } from "../DeltaNeutralDashboard";
import { MarketIndicators } from "@/lib/indicators";

function calcIL(initialPrice: number, currentPrice: number): number {
  const r = currentPrice / initialPrice;
  return (2 * Math.sqrt(r)) / (1 + r) - 1;
}

function calcAPR(fees24h: number, tvl: number): number {
  return tvl > 0 ? (fees24h * 365 / tvl) * 100 : 0;
}

function Field({ label, value, onChange, type = "number", placeholder = "" }: {
  label: string; value: string; onChange: (v: string) => void;
  type?: string; placeholder?: string;
}) {
  return (
    <div>
      <label className="text-xs text-slate-400 mb-1 block">{label}</label>
      <input
        type={type} value={value} onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-cyan-500 transition-colors"
      />
    </div>
  );
}

function ResultCard({ label, value, color, sub }: { label: string; value: string; color?: string; sub?: string }) {
  return (
    <div className="rounded-xl bg-slate-800/60 p-3">
      <div className="text-slate-400 text-xs mb-1">{label}</div>
      <div className={`font-bold ${color ?? "text-white"}`}>{value}</div>
      {sub && <div className="text-xs text-slate-500 mt-0.5">{sub}</div>}
    </div>
  );
}

export default function LiquidityPoolModule({ onSave, saved, market }: {
  onSave: (p: LPPosition) => void;
  saved: LPPosition | null;
  market: MarketIndicators;
}) {
  const [f, setF] = useState({
    tokenA: "BTC", tokenB: "USDC",
    tvl: "100000", fees24h: "500", fees7d: "3200",
    priceA: String(market.price.toFixed(0)), priceB: "1",
    initialPriceA: String(market.price.toFixed(0)), initialPriceB: "1",
    rangeMin: String((market.price * 0.8).toFixed(0)),
    rangeMax: String((market.price * 1.2).toFixed(0)),
    positionUSD: "10000",
  });

  const set = (k: string) => (v: string) => setF((prev) => ({ ...prev, [k]: v }));
  const n = (k: string) => parseFloat(f[k as keyof typeof f]) || 0;

  const tvl = n("tvl"), fees24h = n("fees24h"), fees7d = n("fees7d");
  const priceA = n("priceA"), initialPriceA = n("initialPriceA");
  const positionUSD = n("positionUSD");

  const apr = calcAPR(fees24h, tvl);
  const ilCurrent = calcIL(initialPriceA, priceA) * 100;
  const il10up = calcIL(initialPriceA, initialPriceA * 1.1) * 100;
  const il10dn = calcIL(initialPriceA, initialPriceA * 0.9) * 100;
  const il20up = calcIL(initialPriceA, initialPriceA * 1.2) * 100;
  const il20dn = calcIL(initialPriceA, initialPriceA * 0.8) * 100;
  const il30up = calcIL(initialPriceA, initialPriceA * 1.3) * 100;
  const il30dn = calcIL(initialPriceA, initialPriceA * 0.7) * 100;

  const ilUSD = (ilCurrent / 100) * positionUSD;
  const dailyFeeShare = tvl > 0 ? (positionUSD / tvl) * fees24h : 0;
  const feesVsIL = ilUSD !== 0 ? Math.abs(dailyFeeShare * 30 / ilUSD) : Infinity;

  const rangeMin = n("rangeMin"), rangeMax = n("rangeMax");
  const inRange = priceA >= rangeMin && priceA <= rangeMax;

  let recommendation = "";
  let recColor = "text-white";
  if (!inRange) {
    recommendation = "CERRAR — Precio fuera del rango. Rebalancear posición.";
    recColor = "text-red-400";
  } else if (feesVsIL < 1) {
    recommendation = "CERRAR — IL supera el 50% de fees proyectadas a 30 días.";
    recColor = "text-orange-400";
  } else if (apr > 20 && inRange) {
    recommendation = "MANTENER — APR elevado, precio en rango. Estrategia favorable.";
    recColor = "text-emerald-400";
  } else {
    recommendation = "REBALANCEAR — Ajustar rango al precio actual para maximizar fees.";
    recColor = "text-yellow-400";
  }

  const handleSave = () => {
    onSave({
      tokenA: f.tokenA, tokenB: f.tokenB,
      tvl, fees24h, fees7d,
      priceA, priceB: n("priceB"),
      initialPriceA: n("initialPriceA"), initialPriceB: n("initialPriceB"),
      rangeMin, rangeMax, positionUSD,
    });
  };

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-bold text-white">Módulo Liquidity Pool</h2>
        {saved && <span className="text-xs text-cyan-400 border border-cyan-500/30 bg-cyan-500/10 px-2 py-1 rounded-lg">✓ Guardado en Estrategia</span>}
      </div>

      {/* Form */}
      <div className="rounded-2xl bg-slate-900 border border-slate-700/50 p-5">
        <h3 className="text-sm font-bold text-slate-300 mb-4">Datos de la Posición</h3>
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          <Field label="Token A" value={f.tokenA} onChange={set("tokenA")} type="text" />
          <Field label="Token B" value={f.tokenB} onChange={set("tokenB")} type="text" />
          <Field label="TVL del Pool (USD)" value={f.tvl} onChange={set("tvl")} />
          <Field label="Fees 24h (USD)" value={f.fees24h} onChange={set("fees24h")} />
          <Field label="Fees 7d (USD)" value={f.fees7d} onChange={set("fees7d")} />
          <Field label="Precio actual Token A (USD)" value={f.priceA} onChange={set("priceA")} />
          <Field label="Precio entrada Token A (USD)" value={f.initialPriceA} onChange={set("initialPriceA")} />
          <Field label="Rango mínimo" value={f.rangeMin} onChange={set("rangeMin")} />
          <Field label="Rango máximo" value={f.rangeMax} onChange={set("rangeMax")} />
          <Field label="Tamaño posición (USD)" value={f.positionUSD} onChange={set("positionUSD")} />
        </div>
      </div>

      {/* Results */}
      <div className="rounded-2xl bg-slate-900 border border-slate-700/50 p-5">
        <h3 className="text-sm font-bold text-slate-300 mb-4">Análisis</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-4">
          <ResultCard label="APR por Fees" value={`${apr.toFixed(2)}%`}
            color={apr > 20 ? "text-emerald-400" : apr > 10 ? "text-yellow-400" : "text-red-400"} />
          <ResultCard label="IL Actual" value={`${ilCurrent.toFixed(2)}%`}
            color={ilCurrent < -5 ? "text-red-400" : "text-slate-300"}
            sub={`-$${Math.abs(ilUSD).toFixed(2)}`} />
          <ResultCard label="Precio en Rango" value={inRange ? "✓ Sí" : "✗ No"}
            color={inRange ? "text-emerald-400" : "text-red-400"}
            sub={`$${rangeMin.toLocaleString()} – $${rangeMax.toLocaleString()}`} />
          <ResultCard label="Fees vs IL (30d)" value={isFinite(feesVsIL) ? `${feesVsIL.toFixed(1)}x` : "∞"}
            color={feesVsIL >= 1 ? "text-emerald-400" : "text-red-400"}
            sub={feesVsIL >= 1 ? "Fees cubren IL" : "IL supera fees"} />
        </div>

        {/* IL projections */}
        <div className="mb-4">
          <div className="text-xs text-slate-400 mb-2 font-medium">IL Proyectado por movimiento de precio</div>
          <div className="grid grid-cols-3 md:grid-cols-6 gap-2">
            {[
              { label: "+30%", val: il30up }, { label: "+20%", val: il20up }, { label: "+10%", val: il10up },
              { label: "-10%", val: il10dn }, { label: "-20%", val: il20dn }, { label: "-30%", val: il30dn },
            ].map(({ label, val }) => (
              <div key={label} className="rounded-lg bg-slate-800/60 p-2 text-center">
                <div className="text-slate-400 text-[10px]">{label}</div>
                <div className={`font-bold text-sm ${val < -5 ? "text-red-400" : "text-slate-300"}`}>
                  {val.toFixed(2)}%
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Recommendation */}
        <div className={`rounded-xl p-3 border text-sm ${
          recColor === "text-emerald-400" ? "bg-emerald-900/20 border-emerald-500/20" :
          recColor === "text-red-400" ? "bg-red-900/20 border-red-500/20" :
          recColor === "text-orange-400" ? "bg-orange-900/20 border-orange-500/20" :
          "bg-yellow-900/20 border-yellow-500/20"
        }`}>
          <span className="font-bold text-slate-300">Recomendación: </span>
          <span className={recColor}>{recommendation}</span>
        </div>

        <button onClick={handleSave}
          className="mt-4 w-full bg-cyan-600 hover:bg-cyan-500 text-white font-bold py-2 rounded-xl text-sm transition-colors">
          Guardar posición en Estrategia
        </button>
      </div>
    </div>
  );
}
