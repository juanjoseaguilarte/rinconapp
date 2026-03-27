"use client";

import { useState } from "react";
import { MarketIndicators } from "@/lib/indicators";
import AppNav from "@/app/components/AppNav";
import MarketModule from "./modules/MarketModule";
import LiquidityPoolModule from "./modules/LiquidityPoolModule";
import AAVEModule from "./modules/AAVEModule";

const TABS = [
  { id: "market", label: "Mercado" },
  { id: "lp", label: "Liquidity Pool" },
  { id: "aave", label: "AAVE" },
] as const;

type Tab = (typeof TABS)[number]["id"];

export interface LPPosition {
  tokenA: string; tokenB: string;
  tvl: number; fees24h: number; fees7d: number;
  priceA: number; priceB: number;
  initialPriceA: number; initialPriceB: number;
  rangeMin: number; rangeMax: number;
  positionUSD: number;
}

export interface AAVEPosition {
  collateralToken: string; collateralAmount: number; collateralPriceUSD: number;
  collateralLiqThreshold: number; collateralAPY: number;
  borrowToken: string; borrowAmount: number; borrowPriceUSD: number; borrowAPY: number;
}

export default function DeltaNeutralDashboard({ initialMarket }: { initialMarket: MarketIndicators }) {
  const [activeTab, setActiveTab] = useState<Tab>("market");
  const [lpPosition, setLpPosition] = useState<LPPosition | null>(null);
  const [aavePosition, setAavePosition] = useState<AAVEPosition | null>(null);

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100">
      <AppNav />

      {/* Trend banner */}
      <div className={`border-b ${
        initialMarket.trend === "ALCISTA" ? "bg-emerald-900/30 border-emerald-700/40" :
        initialMarket.trend === "BAJISTA" ? "bg-red-900/30 border-red-700/40" :
        "bg-slate-800/40 border-slate-700/40"
      }`}>
        <div className="max-w-5xl mx-auto px-4 py-2 flex items-center justify-between flex-wrap gap-2">
          <div className="flex items-center gap-3">
            <span className={`text-xs font-black uppercase tracking-widest px-3 py-1 rounded-full border ${
              initialMarket.trend === "ALCISTA" ? "text-emerald-300 border-emerald-500/50 bg-emerald-500/10" :
              initialMarket.trend === "BAJISTA" ? "text-red-300 border-red-500/50 bg-red-500/10" :
              "text-yellow-300 border-yellow-500/50 bg-yellow-500/10"
            }`}>
              {initialMarket.trend === "ALCISTA" ? "▲" : initialMarket.trend === "BAJISTA" ? "▼" : "→"} BTC {initialMarket.trend}
            </span>
            <span className="text-slate-400 text-xs">
              RSI <span className="text-white font-bold">{initialMarket.rsi.toFixed(1)}</span>
              &nbsp;·&nbsp; ADX <span className="text-white font-bold">{initialMarket.adx.toFixed(1)}</span>
              &nbsp;·&nbsp; ATR <span className="text-white font-bold">${initialMarket.atr.toFixed(0)}</span>
            </span>
          </div>
          <span className="text-slate-400 text-xs font-mono">
            ${initialMarket.price.toLocaleString("en-US", { maximumFractionDigits: 0 })}
          </span>
        </div>
      </div>

      {/* Tab bar */}
      <div className="border-b border-slate-800 bg-slate-900/60 sticky top-0 z-10">
        <div className="max-w-5xl mx-auto px-4 flex gap-1 pt-2 overflow-x-auto">
          {TABS.map(({ id, label }) => (
            <button
              key={id}
              onClick={() => setActiveTab(id)}
              className={`px-4 py-2 text-sm font-semibold rounded-t-lg border-b-2 whitespace-nowrap transition-colors ${
                activeTab === id
                  ? "border-cyan-400 text-cyan-300 bg-slate-800"
                  : "border-transparent text-slate-500 hover:text-slate-300"
              }`}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      <div className="max-w-5xl mx-auto px-4 py-6">
        {activeTab === "market" && <MarketModule initialMarket={initialMarket} />}
        {activeTab === "lp" && <LiquidityPoolModule onSave={setLpPosition} saved={lpPosition} market={initialMarket} />}
        {activeTab === "aave" && <AAVEModule onSave={setAavePosition} saved={aavePosition} market={initialMarket} />}
      </div>
    </div>
  );
}
