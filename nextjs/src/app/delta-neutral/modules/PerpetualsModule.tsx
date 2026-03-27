"use client";

import { useState } from "react";
import { PerpPosition, AAVEPosition } from "../DeltaNeutralDashboard";
import { MarketIndicators } from "@/lib/indicators";

function Field({ label, value, onChange, type = "number", placeholder = "" }: {
  label: string; value: string; onChange: (v: string) => void; type?: string; placeholder?: string;
}) {
  return (
    <div>
      <label className="text-xs text-slate-400 mb-1 block">{label}</label>
      <input type={type} value={value} onChange={(e) => onChange(e.target.value)} placeholder={placeholder}
        className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-cyan-500 transition-colors" />
    </div>
  );
}

const EXCHANGES = ["Hyperliquid", "GMX", "dYdX", "Bybit", "Binance Futures", "Otro"];

export default function PerpetualsModule({ onSave, saved, aave, market }: {
  onSave: (p: PerpPosition) => void;
  saved: PerpPosition | null;
  aave: AAVEPosition | null;
  market: MarketIndicators;
}) {
  const [f, setF] = useState({
    exchange: "Hyperliquid", pair: "BTC/USDC",
    size: "1", entryPrice: String(market.price.toFixed(0)),
    leverage: "5", side: "SHORT" as "LONG" | "SHORT",
  });
  const set = (k: string) => (v: string) => setF((prev) => ({ ...prev, [k]: v }));
  const n = (k: string) => parseFloat(f[k as keyof typeof f]) || 0;

  const size = n("size");
  const entryPrice = n("entryPrice");
  const leverage = n("leverage");
  const currentPrice = market.price;

  const notionalUSD = size * entryPrice;
  const margin = notionalUSD / leverage;
  const pnl = f.side === "LONG"
    ? (currentPrice - entryPrice) * size
    : (entryPrice - currentPrice) * size;
  const pnlPct = entryPrice > 0 ? (pnl / (size * entryPrice)) * 100 : 0;
  const liquidationPrice = f.side === "LONG"
    ? entryPrice * (1 - 1 / leverage * 0.9)
    : entryPrice * (1 + 1 / leverage * 0.9);

  // Suggest hedge from AAVE exposure
  const aaveExposure = aave ? aave.collateralAmount : 0;
  const aaveBorrowIsVolatile = aave && !["USDC", "USDT", "DAI"].includes(aave.borrowToken.toUpperCase());
  const suggestedHedge = aaveExposure;
  const deltaNet = f.side === "LONG" ? aaveExposure - size : aaveExposure + size;
  const isNeutral = Math.abs(deltaNet) < 0.05;

  // Hedge suggestion
  let hedgeSuggestion = "";
  let hedgeColor = "text-white";
  if (market.trend === "BAJISTA" && aaveBorrowIsVolatile) {
    hedgeSuggestion = `Mercado BAJISTA + AAVE borrow en ${aave?.borrowToken}: si ${aave?.borrowToken} rompe resistencia, abrir LONG de cobertura. Tamaño sugerido: ${suggestedHedge.toFixed(4)} ${aave?.borrowToken}.`;
    hedgeColor = "text-cyan-400";
  } else if (market.trend === "ALCISTA" && aave) {
    hedgeSuggestion = `Mercado ALCISTA + colateral ${aave.collateralToken}: si BTC rompe soporte, abrir SHORT de cobertura. Tamaño sugerido: ${aave.collateralAmount.toFixed(4)} ${aave.collateralToken}.`;
    hedgeColor = "text-cyan-400";
  } else if (!aave) {
    hedgeSuggestion = "Configura tu posición AAVE primero para calcular el tamaño de cobertura óptimo.";
    hedgeColor = "text-slate-400";
  } else {
    hedgeSuggestion = "Posición AAVE estable. Monitorear mercado para ajustar cobertura.";
    hedgeColor = "text-yellow-400";
  }

  const handleSave = () => {
    onSave({ exchange: f.exchange, pair: f.pair, size, entryPrice, leverage, side: f.side });
  };

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-bold text-white">Módulo Perpetuals — Cobertura</h2>
        {saved && <span className="text-xs text-cyan-400 border border-cyan-500/30 bg-cyan-500/10 px-2 py-1 rounded-lg">✓ Guardado en Estrategia</span>}
      </div>

      {/* AAVE exposure summary */}
      {aave && (
        <div className="rounded-xl bg-slate-800/40 border border-slate-700/40 p-4 text-sm">
          <span className="text-slate-400">Exposición AAVE detectada: </span>
          <span className="text-white font-bold">{aave.collateralAmount} {aave.collateralToken}</span>
          <span className="text-slate-400"> · Borrow: </span>
          <span className="text-white font-bold">{aave.borrowAmount} {aave.borrowToken}</span>
          <span className="text-slate-400 ml-2">→ Cobertura sugerida: </span>
          <span className="text-cyan-400 font-bold">{suggestedHedge.toFixed(4)} {aave.collateralToken}</span>
        </div>
      )}

      {/* Form */}
      <div className="rounded-2xl bg-slate-900 border border-slate-700/50 p-5">
        <h3 className="text-sm font-bold text-slate-300 mb-4">Posición en Perpetuals</h3>
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          <div>
            <label className="text-xs text-slate-400 mb-1 block">Exchange</label>
            <select value={f.exchange} onChange={(e) => setF((p) => ({ ...p, exchange: e.target.value }))}
              className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-cyan-500">
              {EXCHANGES.map((e) => <option key={e}>{e}</option>)}
            </select>
          </div>
          <Field label="Par" value={f.pair} onChange={set("pair")} type="text" />
          <Field label="Tamaño (BTC)" value={f.size} onChange={set("size")} />
          <Field label="Precio entrada" value={f.entryPrice} onChange={set("entryPrice")} />
          <Field label="Apalancamiento" value={f.leverage} onChange={set("leverage")} />
          <div>
            <label className="text-xs text-slate-400 mb-1 block">Dirección</label>
            <div className="flex gap-2">
              {(["LONG", "SHORT"] as const).map((s) => (
                <button key={s} onClick={() => setF((p) => ({ ...p, side: s }))}
                  className={`flex-1 py-2 rounded-lg text-sm font-bold border transition-colors ${
                    f.side === s
                      ? s === "LONG" ? "bg-emerald-600 border-emerald-500 text-white" : "bg-red-600 border-red-500 text-white"
                      : "bg-slate-800 border-slate-700 text-slate-400 hover:text-white"
                  }`}>{s}</button>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Results */}
      <div className="rounded-2xl bg-slate-900 border border-slate-700/50 p-5">
        <h3 className="text-sm font-bold text-slate-300 mb-4">Métricas de la Posición</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-4">
          <div className="rounded-xl bg-slate-800/60 p-3">
            <div className="text-slate-400 text-xs mb-1">Nocional</div>
            <div className="text-white font-bold">${notionalUSD.toLocaleString("en-US", { maximumFractionDigits: 0 })}</div>
          </div>
          <div className="rounded-xl bg-slate-800/60 p-3">
            <div className="text-slate-400 text-xs mb-1">Margen requerido</div>
            <div className="text-white font-bold">${margin.toLocaleString("en-US", { maximumFractionDigits: 0 })}</div>
          </div>
          <div className="rounded-xl bg-slate-800/60 p-3">
            <div className="text-slate-400 text-xs mb-1">PnL no realizado</div>
            <div className={`font-bold ${pnl >= 0 ? "text-emerald-400" : "text-red-400"}`}>
              {pnl >= 0 ? "+" : ""}${pnl.toFixed(0)} ({pnlPct.toFixed(2)}%)
            </div>
          </div>
          <div className="rounded-xl bg-slate-800/60 p-3">
            <div className="text-slate-400 text-xs mb-1">Precio liquidación</div>
            <div className="text-red-400 font-bold">${liquidationPrice.toFixed(0)}</div>
          </div>
        </div>

        {/* Delta Net */}
        {aave && (
          <div className={`rounded-xl p-3 border mb-4 ${
            isNeutral ? "bg-emerald-900/20 border-emerald-500/20" : "bg-orange-900/20 border-orange-500/20"
          }`}>
            <div className="text-slate-300 text-sm font-bold mb-1">Delta Neto de la Estrategia</div>
            <div className="flex items-center gap-3 flex-wrap">
              <span className="text-slate-400 text-sm">AAVE spot: <span className="text-white font-bold">+{aaveExposure.toFixed(4)} BTC</span></span>
              <span className="text-slate-500">+</span>
              <span className="text-slate-400 text-sm">Perpetual {f.side}: <span className="text-white font-bold">{f.side === "SHORT" ? "-" : "+"}{size.toFixed(4)} BTC</span></span>
              <span className="text-slate-500">=</span>
              <span className={`font-black text-lg ${isNeutral ? "text-emerald-400" : "text-orange-400"}`}>
                {deltaNet > 0 ? "+" : ""}{deltaNet.toFixed(4)} BTC
              </span>
              <span className={`text-xs font-bold ${isNeutral ? "text-emerald-400" : "text-orange-400"}`}>
                {isNeutral ? "✓ DELTA NEUTRAL" : "⚠ AJUSTAR COBERTURA"}
              </span>
            </div>
          </div>
        )}

        {/* Hedge suggestion */}
        <div className={`rounded-xl p-3 border text-sm ${
          hedgeColor === "text-cyan-400" ? "bg-cyan-900/20 border-cyan-500/20" :
          hedgeColor === "text-yellow-400" ? "bg-yellow-900/20 border-yellow-500/20" :
          "bg-slate-800/40 border-slate-700/30"
        }`}>
          <span className="font-bold text-slate-300">Cobertura ({market.trend}): </span>
          <span className={hedgeColor}>{hedgeSuggestion}</span>
        </div>

        <button onClick={handleSave}
          className="mt-4 w-full bg-cyan-600 hover:bg-cyan-500 text-white font-bold py-2 rounded-xl text-sm transition-colors">
          Guardar posición en Estrategia
        </button>
      </div>
    </div>
  );
}
