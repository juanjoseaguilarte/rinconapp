"use client";

import { MarketIndicators } from "@/lib/indicators";
import { LPPosition, AAVEPosition, PerpPosition } from "../DeltaNeutralDashboard";

// ── helpers ──────────────────────────────────────────────────────────────────
function calcIL(initialPrice: number, currentPrice: number): number {
  if (initialPrice === 0) return 0;
  const r = currentPrice / initialPrice;
  return (2 * Math.sqrt(r)) / (1 + r) - 1;
}

function fmt(n: number, decimals = 0) {
  return n.toLocaleString("en-US", { maximumFractionDigits: decimals, minimumFractionDigits: decimals });
}

function fmtUSD(n: number) { return `$${fmt(Math.abs(n))}`; }
function fmtBTC(n: number) { return `${n.toFixed(4)} BTC`; }

// ── sub-components ────────────────────────────────────────────────────────────
function KPI({ label, value, color, sub }: { label: string; value: string; color?: string; sub?: string }) {
  return (
    <div className="rounded-xl bg-slate-900 border border-slate-700/50 p-4">
      <div className="text-slate-400 text-xs mb-1">{label}</div>
      <div className={`text-2xl font-black ${color ?? "text-white"}`}>{value}</div>
      {sub && <div className={`text-xs mt-1 ${color ?? "text-slate-500"}`}>{sub}</div>}
    </div>
  );
}

function ScoreBar({ score }: { score: number }) {
  const color = score < 30 ? "bg-emerald-500" : score < 60 ? "bg-yellow-500" : score < 80 ? "bg-orange-500" : "bg-red-500";
  const label = score < 30 ? "BAJO" : score < 60 ? "MODERADO" : score < 80 ? "ALTO" : "CRÍTICO";
  const textColor = score < 30 ? "text-emerald-400" : score < 60 ? "text-yellow-400" : score < 80 ? "text-orange-400" : "text-red-400";
  return (
    <div>
      <div className="flex justify-between mb-2">
        <span className="text-sm text-slate-400">Score de Riesgo Global</span>
        <span className={`text-sm font-black ${textColor}`}>{score}/100 — {label}</span>
      </div>
      <div className="h-3 rounded-full bg-slate-700 overflow-hidden">
        <div className={`h-full rounded-full transition-all duration-500 ${color}`} style={{ width: `${score}%` }} />
      </div>
    </div>
  );
}

interface Step {
  num: number;
  title: string;
  detail: string;
  badge: string;
  badgeColor: string;
  prices?: { label: string; value: string; color: string }[];
}

function ActionStep({ step }: { step: Step }) {
  return (
    <div className="flex gap-4">
      <div className="flex-shrink-0 w-8 h-8 rounded-full bg-slate-700 flex items-center justify-center text-sm font-black text-white">
        {step.num}
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-1 flex-wrap">
          <span className="text-white font-bold text-sm">{step.title}</span>
          <span className={`text-[10px] font-black uppercase tracking-wider px-2 py-0.5 rounded-full border ${step.badgeColor}`}>
            {step.badge}
          </span>
        </div>
        <p className="text-slate-400 text-xs leading-relaxed mb-2">{step.detail}</p>
        {step.prices && step.prices.length > 0 && (
          <div className="flex flex-wrap gap-2">
            {step.prices.map((p) => (
              <div key={p.label} className="rounded-lg bg-slate-800 border border-slate-700/50 px-3 py-1.5">
                <div className="text-[10px] text-slate-500 mb-0.5">{p.label}</div>
                <div className={`text-sm font-black ${p.color}`}>{p.value}</div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

// ── main ──────────────────────────────────────────────────────────────────────
export default function StrategyDashboard({ market, lp, aave, perp }: {
  market: MarketIndicators;
  lp: LPPosition | null;
  aave: AAVEPosition | null;
  perp: PerpPosition | null;
}) {
  const hasPositions = lp || aave || perp;

  // ── AAVE metrics (amounts are USD since the module stores cUSD/bUSD directly) ──
  const collateralUSD = aave ? aave.collateralAmount : 0;
  const borrowUSD     = aave ? aave.borrowAmount : 0;
  const aaveNetAPY    = aave
    ? (collateralUSD * aave.collateralAPY / 100) - (borrowUSD * aave.borrowAPY / 100)
    : 0;
  const aaveMonthlyPnL = aaveNetAPY / 12;
  const aaveHF = aave && borrowUSD > 0
    ? (collateralUSD * aave.collateralLiqThreshold) / borrowUSD
    : Infinity;

  // BTC exposure from AAVE: only if collateralToken is BTC (or ETH approximated)
  const isBTCCollateral = aave?.collateralToken === "BTC";
  const isETHCollateral = aave?.collateralToken === "ETH";
  const btcPrice = market.price;
  // Approximate ETH/BTC ratio — if ETH we treat it as directional (not stable)
  const aaveBTCExposure = isBTCCollateral
    ? collateralUSD / btcPrice
    : isETHCollateral
    ? collateralUSD / btcPrice * 0.06  // rough ETH/BTC ratio approximation
    : 0;

  // ── Perp metrics ──
  const perpPnL = perp
    ? perp.side === "LONG"
      ? (market.price - perp.entryPrice) * perp.size
      : (perp.entryPrice - market.price) * perp.size
    : 0;
  const perpDelta = perp
    ? (perp.side === "LONG" ? perp.size : -perp.size)
    : 0;

  // ── LP metrics ──
  const lpFees30d = lp ? (lp.positionUSD / lp.tvl) * lp.fees24h * 30 : 0;
  const lpIL      = lp ? calcIL(lp.initialPriceA, lp.priceA) * lp.positionUSD : 0;
  const lpPnL     = lpFees30d + lpIL;

  // ── Net delta & total PnL ──
  const netDelta  = aaveBTCExposure + perpDelta;
  const isNeutral = Math.abs(netDelta) < 0.05;
  const totalPnL30d = lpPnL + aaveMonthlyPnL + perpPnL;

  // ── Risk score ──
  let riskScore = 0;
  if (aave) {
    if (aaveHF < 1.2) riskScore += 45;
    else if (aaveHF < 1.5) riskScore += 28;
    else if (aaveHF < 2)   riskScore += 12;
  }
  if (!isNeutral) riskScore += Math.min(30, Math.abs(netDelta) * 15);
  if (lp && lpIL < 0 && Math.abs(lpIL) > lpFees30d) riskScore += 10;
  if (market.trend !== "LATERAL") riskScore += 5;
  if (perp && perp.leverage > 5) riskScore += 10;
  riskScore = Math.min(100, Math.round(riskScore));

  // ── Price levels for action plan ──
  const atr    = market.atr;
  const ema20  = market.ema20;
  const ema50  = market.ema50;
  const ema200 = market.ema200;

  // SHORT entry: just above current price or EMA20 (nearest resistance)
  const shortEntry    = Math.max(btcPrice, ema20) * 1.001;
  const shortStop     = shortEntry + atr * 1.5;
  const shortTP       = shortEntry - atr * 2.5;
  const shortLiqGuard = shortEntry - atr * 4;  // aggressive TP to derisked

  // LONG entry: just below current price or EMA20 (nearest support)
  const longEntry = Math.min(btcPrice, ema20) * 0.999;
  const longStop  = longEntry - atr * 1.5;
  const longTP    = longEntry + atr * 2.5;

  // Hedge size needed to reach delta neutral
  const hedgeSizeBTC = Math.abs(netDelta);
  const hedgeSide: "SHORT" | "LONG" = netDelta > 0 ? "SHORT" : "LONG";

  // ── Build step-by-step action plan ──
  const steps: Step[] = [];
  let stepNum = 1;

  // STEP: AAVE health check
  if (aave) {
    if (aaveHF < 1.5) {
      steps.push({
        num: stepNum++,
        title: "Reducir riesgo AAVE — URGENTE",
        badge: "URGENTE",
        badgeColor: "text-red-300 border-red-500/50 bg-red-500/10",
        detail: `Health Factor en ${aaveHF.toFixed(2)} — peligro de liquidación. Repaga al menos $${fmt(borrowUSD * 0.2)} de borrow (${aave.borrowToken}) o añade $${fmt(borrowUSD * 0.25)} más de colateral (${aave.collateralToken}).`,
        prices: [
          { label: "HF actual", value: aaveHF.toFixed(2), color: "text-red-400" },
          { label: "Repagar para HF 2.0", value: fmtUSD(borrowUSD - (collateralUSD * aave.collateralLiqThreshold) / 2), color: "text-orange-400" },
          { label: "Colateral añadir HF 2.0", value: fmtUSD((borrowUSD * 2 / aave.collateralLiqThreshold) - collateralUSD), color: "text-yellow-400" },
        ],
      });
    } else if (aaveHF < 2) {
      steps.push({
        num: stepNum++,
        title: "Monitorear Health Factor AAVE",
        badge: "ATENCIÓN",
        badgeColor: "text-yellow-300 border-yellow-500/50 bg-yellow-500/10",
        detail: `HF en ${aaveHF.toFixed(2)}. Si BTC cae >${(((aaveHF - 1) / aaveHF) * 100).toFixed(0)}% el colateral podría liquidarse. Considera reducir borrow o añadir buffer.`,
        prices: [
          { label: "HF actual", value: aaveHF.toFixed(2), color: "text-yellow-400" },
          { label: "Precio liq. BTC", value: fmtUSD(btcPrice * (borrowUSD / (collateralUSD * aave.collateralLiqThreshold))), color: "text-red-400" },
        ],
      });
    }
  }

  // STEP: delta hedge
  if (!isNeutral && aave) {
    const entry = hedgeSide === "SHORT" ? shortEntry : longEntry;
    const stop  = hedgeSide === "SHORT" ? shortStop  : longStop;
    const tp    = hedgeSide === "SHORT" ? shortTP    : longTP;

    steps.push({
      num: stepNum++,
      title: `Abrir ${hedgeSide} perpetual — Cobertura delta`,
      badge: hedgeSide === "SHORT" ? "SHORT" : "LONG",
      badgeColor: hedgeSide === "SHORT"
        ? "text-red-300 border-red-500/50 bg-red-500/10"
        : "text-emerald-300 border-emerald-500/50 bg-emerald-500/10",
      detail: `Delta neto = ${netDelta > 0 ? "+" : ""}${netDelta.toFixed(4)} BTC. Para neutralizarlo: abre un ${hedgeSide} de ${fmtBTC(hedgeSizeBTC)} en perpetuos (ej. Hyperliquid o GMX). Usa 2-3x de apalancamiento para minimizar margen requerido.`,
      prices: [
        { label: "Entrada límite", value: fmtUSD(entry), color: hedgeSide === "SHORT" ? "text-red-400" : "text-emerald-400" },
        { label: "Stop loss", value: fmtUSD(stop), color: "text-orange-400" },
        { label: "Take profit / rebalanceo", value: fmtUSD(tp), color: "text-cyan-400" },
        { label: "Tamaño", value: fmtBTC(hedgeSizeBTC), color: "text-white" },
        { label: "Nocional USD", value: fmtUSD(hedgeSizeBTC * btcPrice), color: "text-white" },
      ],
    });
  } else if (perp && !isNeutral) {
    steps.push({
      num: stepNum++,
      title: "Ajustar tamaño del perpetual",
      badge: "AJUSTAR",
      badgeColor: "text-orange-300 border-orange-500/50 bg-orange-500/10",
      detail: `Delta neto = ${netDelta > 0 ? "+" : ""}${netDelta.toFixed(4)} BTC. Modifica el size del perpetual en ${Math.abs(netDelta).toFixed(4)} BTC ${netDelta > 0 ? "añadiendo SHORT" : "reduciendo SHORT / añadiendo LONG"}.`,
      prices: [
        { label: "Delta a cubrir", value: fmtBTC(Math.abs(netDelta)), color: "text-orange-400" },
      ],
    });
  }

  // STEP: market-context specific
  if (market.trend === "BAJISTA" && (isBTCCollateral || isETHCollateral)) {
    const breakdownLevel = Math.min(ema50, ema200) - atr * 0.5;
    steps.push({
      num: stepNum++,
      title: `Protección bajista — si BTC rompe soporte`,
      badge: "CONDICIONAL",
      badgeColor: "text-orange-300 border-orange-500/50 bg-orange-500/10",
      detail: `Mercado BAJISTA con colateral volátil (${aave?.collateralToken}). Si BTC cierra 1H por debajo de $${fmt(breakdownLevel)}, refuerza el SHORT en ${hedgeSizeBTC.toFixed(4)} BTC adicionales o reduce colateral.`,
      prices: [
        { label: "Nivel de ruptura bajista", value: fmtUSD(breakdownLevel), color: "text-red-400" },
        { label: "EMA 50", value: fmtUSD(ema50), color: "text-orange-400" },
        { label: "EMA 200", value: fmtUSD(ema200), color: "text-violet-400" },
        { label: "SHORT adicional si rompe", value: fmtBTC(hedgeSizeBTC), color: "text-red-400" },
        { label: "Stop del adicional", value: fmtUSD(breakdownLevel - atr), color: "text-slate-400" },
      ],
    });
  }

  if (market.trend === "ALCISTA" && (isBTCCollateral || isETHCollateral)) {
    const breakoutLevel = Math.max(ema20, btcPrice) + atr * 0.3;
    steps.push({
      num: stepNum++,
      title: "Aprovechar tendencia alcista — gestión del SHORT",
      badge: "OPORTUNIDAD",
      badgeColor: "text-emerald-300 border-emerald-500/50 bg-emerald-500/10",
      detail: `Mercado ALCISTA: el colateral ${aave?.collateralToken} sube, mejorando el HF. Si BTC supera $${fmt(breakoutLevel)}, considera mover el stop del SHORT a breakeven para no limitar la ganancia de colateral.`,
      prices: [
        { label: "Nivel de breakout", value: fmtUSD(breakoutLevel), color: "text-emerald-400" },
        { label: "Mover stop a", value: fmtUSD(shortEntry * 1.002), color: "text-cyan-400" },
        { label: "TP parcial (50%)", value: fmtUSD(btcPrice - atr * 1.5), color: "text-emerald-400" },
      ],
    });
  }

  // STEP: LP management
  if (lp) {
    const inRange = lp.priceA >= lp.rangeMin && lp.priceA <= lp.rangeMax;
    if (!inRange) {
      steps.push({
        num: stepNum++,
        title: "Rebalancear Liquidity Pool",
        badge: "FUERA DE RANGO",
        badgeColor: "text-red-300 border-red-500/50 bg-red-500/10",
        detail: `Precio $${fmt(lp.priceA)} fuera del rango [$${fmt(lp.rangeMin)} – $${fmt(lp.rangeMax)}]. Retira la posición y vuelve a entrar centrada en $${fmt(lp.priceA)} con un ±20% de rango.`,
        prices: [
          { label: "Nuevo rango mín.", value: fmtUSD(lp.priceA * 0.8), color: "text-white" },
          { label: "Nuevo rango máx.", value: fmtUSD(lp.priceA * 1.2), color: "text-white" },
        ],
      });
    }
  }

  // STEP: monitoring
  steps.push({
    num: stepNum++,
    title: "Monitoreo periódico",
    badge: "RUTINA",
    badgeColor: "text-slate-300 border-slate-600 bg-slate-700/30",
    detail: `Revisa HF cada 4h si el mercado es volátil (ATR = $${fmt(atr)}). Ajusta cobertura si delta neto supera ±0.1 BTC. Registra fees LP semanalmente.`,
    prices: [
      { label: "ATR actual", value: fmtUSD(atr), color: "text-white" },
      { label: "EMA 20", value: fmtUSD(ema20), color: "text-sky-400" },
      { label: "EMA 50", value: fmtUSD(ema50), color: "text-orange-400" },
      { label: "EMA 200", value: fmtUSD(ema200), color: "text-violet-400" },
    ],
  });

  if (!hasPositions) {
    return (
      <div className="flex flex-col items-center justify-center py-20 gap-4 text-center">
        <div className="text-6xl">🧱</div>
        <h2 className="text-xl font-bold text-white">Dashboard vacío</h2>
        <p className="text-slate-400 max-w-sm">
          Configura al menos una posición en los módulos LP, AAVE o Perpetuals para ver el plan de acción.
        </p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      <h2 className="text-lg font-bold text-white">Estrategia Combinada — Plan de Acción</h2>

      {/* KPIs */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        <KPI
          label="PnL Estimado (30d)"
          value={`${totalPnL30d >= 0 ? "+" : ""}${fmtUSD(totalPnL30d)}`}
          color={totalPnL30d >= 0 ? "text-emerald-400" : "text-red-400"}
        />
        <KPI
          label="Delta Neto"
          value={`${netDelta > 0 ? "+" : ""}${netDelta.toFixed(4)} BTC`}
          color={isNeutral ? "text-emerald-400" : "text-orange-400"}
          sub={isNeutral ? "✓ NEUTRAL" : "⚠ EXPUESTO"}
        />
        <KPI
          label="Health Factor AAVE"
          value={aave ? (isFinite(aaveHF) ? aaveHF.toFixed(2) : "∞") : "—"}
          color={!aave ? "text-slate-500" : aaveHF < 1.5 ? "text-red-400" : aaveHF < 2 ? "text-yellow-400" : "text-emerald-400"}
          sub={aave ? (aaveHF < 1.5 ? "🚨 ALERTA" : aaveHF < 2 ? "Moderado" : "Seguro") : undefined}
        />
        <KPI
          label="Tendencia BTC"
          value={market.trend}
          color={market.trend === "ALCISTA" ? "text-emerald-400" : market.trend === "BAJISTA" ? "text-red-400" : "text-yellow-400"}
          sub={`RSI ${market.rsi.toFixed(0)} · ADX ${market.adx.toFixed(0)}`}
        />
      </div>

      {/* Risk score */}
      <div className="rounded-2xl bg-slate-900 border border-slate-700/50 p-5">
        <ScoreBar score={riskScore} />
      </div>

      {/* Action plan */}
      <div className="rounded-2xl bg-slate-900 border border-slate-700/50 p-5">
        <h3 className="text-sm font-bold text-slate-300 mb-5 uppercase tracking-wider">
          Pasos a seguir
        </h3>
        <div className="flex flex-col gap-6">
          {steps.map((s) => <ActionStep key={s.num} step={s} />)}
        </div>
      </div>

      {/* Position summaries */}
      <div className="grid md:grid-cols-3 gap-4">
        {lp && (
          <div className="rounded-2xl bg-slate-900 border border-slate-700/50 p-4">
            <div className="text-xs font-bold text-cyan-400 mb-3 uppercase tracking-wider">Liquidity Pool</div>
            <div className="flex flex-col gap-2 text-sm">
              <div className="flex justify-between"><span className="text-slate-400">Par</span><span className="text-white font-bold">{lp.tokenA}/{lp.tokenB}</span></div>
              <div className="flex justify-between"><span className="text-slate-400">Fees 30d</span><span className="text-emerald-400 font-bold">+${lpFees30d.toFixed(0)}</span></div>
              <div className="flex justify-between"><span className="text-slate-400">IL actual</span><span className={`font-bold ${lpIL < 0 ? "text-red-400" : "text-white"}`}>${lpIL.toFixed(0)}</span></div>
              <div className="flex justify-between border-t border-slate-700 pt-2"><span className="text-slate-400">PnL neto</span><span className={`font-bold ${lpPnL >= 0 ? "text-emerald-400" : "text-red-400"}`}>{lpPnL >= 0 ? "+" : ""}${lpPnL.toFixed(0)}</span></div>
            </div>
          </div>
        )}
        {aave && (
          <div className="rounded-2xl bg-slate-900 border border-slate-700/50 p-4">
            <div className="text-xs font-bold text-cyan-400 mb-3 uppercase tracking-wider">AAVE</div>
            <div className="flex flex-col gap-2 text-sm">
              <div className="flex justify-between"><span className="text-slate-400">Colateral</span><span className="text-white font-bold">${fmt(collateralUSD)} {aave.collateralToken}</span></div>
              <div className="flex justify-between"><span className="text-slate-400">Borrow</span><span className="text-white font-bold">${fmt(borrowUSD)} {aave.borrowToken}</span></div>
              <div className="flex justify-between"><span className="text-slate-400">APY neto</span><span className={`font-bold ${aaveNetAPY >= 0 ? "text-emerald-400" : "text-red-400"}`}>{aaveNetAPY >= 0 ? "+" : ""}${aaveNetAPY.toFixed(0)}/año</span></div>
              <div className="flex justify-between border-t border-slate-700 pt-2"><span className="text-slate-400">HF</span><span className={`font-bold ${aaveHF < 1.5 ? "text-red-400" : aaveHF < 2 ? "text-yellow-400" : "text-emerald-400"}`}>{isFinite(aaveHF) ? aaveHF.toFixed(2) : "∞"}</span></div>
            </div>
          </div>
        )}
        {perp && (
          <div className="rounded-2xl bg-slate-900 border border-slate-700/50 p-4">
            <div className="text-xs font-bold text-cyan-400 mb-3 uppercase tracking-wider">Perpetual</div>
            <div className="flex flex-col gap-2 text-sm">
              <div className="flex justify-between"><span className="text-slate-400">Exchange</span><span className="text-white font-bold">{perp.exchange}</span></div>
              <div className="flex justify-between"><span className="text-slate-400">Posición</span><span className={`font-bold ${perp.side === "LONG" ? "text-emerald-400" : "text-red-400"}`}>{perp.side} {perp.size} BTC × {perp.leverage}x</span></div>
              <div className="flex justify-between"><span className="text-slate-400">Entrada</span><span className="text-white font-bold">${fmt(perp.entryPrice)}</span></div>
              <div className="flex justify-between border-t border-slate-700 pt-2"><span className="text-slate-400">PnL no real.</span><span className={`font-bold ${perpPnL >= 0 ? "text-emerald-400" : "text-red-400"}`}>{perpPnL >= 0 ? "+" : ""}${perpPnL.toFixed(0)}</span></div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
