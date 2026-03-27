"use client";

import { useState } from "react";
import { AAVEPosition } from "../DeltaNeutralDashboard";
import { MarketIndicators } from "@/lib/indicators";

// Fixed params per token (AAVE V3 mainnet approx)
const TOKEN_PARAMS: Record<string, { liqThreshold: number; supplyAPY: number; borrowAPY: number }> = {
  USDC: { liqThreshold: 0.89, supplyAPY: 4.5,  borrowAPY: 6.2  },
  BTC:  { liqThreshold: 0.82, supplyAPY: 0.4,  borrowAPY: 1.8  },
  ETH:  { liqThreshold: 0.85, supplyAPY: 1.2,  borrowAPY: 2.9  },
};

const TOKENS = ["USDC", "BTC", "ETH"] as const;

function TokenSelect({ label, value, onChange }: { label: string; value: string; onChange: (v: string) => void }) {
  return (
    <div>
      <label className="text-xs text-slate-400 mb-1 block">{label}</label>
      <div className="flex gap-2">
        {TOKENS.map((t) => (
          <button key={t} onClick={() => onChange(t)}
            className={`flex-1 py-2 rounded-xl text-sm font-bold border transition-colors ${
              value === t
                ? t === "USDC" ? "bg-blue-600 border-blue-500 text-white"
                : t === "BTC"  ? "bg-orange-600 border-orange-500 text-white"
                :                "bg-violet-600 border-violet-500 text-white"
                : "bg-slate-800 border-slate-700 text-slate-400 hover:text-white"
            }`}
          >{t}</button>
        ))}
      </div>
    </div>
  );
}

function PriceTag({ label, value, color }: { label: string; value: string; color: string }) {
  return (
    <div className="rounded-lg bg-slate-800 border border-slate-700/50 px-3 py-2">
      <div className="text-[10px] text-slate-500 mb-0.5">{label}</div>
      <div className={`text-sm font-black ${color}`}>{value}</div>
    </div>
  );
}

interface Step {
  icon: string;
  title: string;
  body: string;
  tags?: { label: string; value: string; color: string }[];
  accent: string;
}

function StrategyStep({ step, num }: { step: Step; num: number }) {
  return (
    <div className={`rounded-xl border p-4 ${step.accent}`}>
      <div className="flex items-start gap-3 mb-2">
        <span className="flex-shrink-0 w-6 h-6 rounded-full bg-slate-700 flex items-center justify-center text-xs font-black text-white">{num}</span>
        <div>
          <div className="text-white font-bold text-sm">{step.icon} {step.title}</div>
          <p className="text-slate-300 text-xs mt-1 leading-relaxed">{step.body}</p>
        </div>
      </div>
      {step.tags && step.tags.length > 0 && (
        <div className="flex flex-wrap gap-2 mt-3 ml-9">
          {step.tags.map((t) => (
            <PriceTag key={t.label} label={t.label} value={t.value} color={t.color} />
          ))}
        </div>
      )}
    </div>
  );
}

function fmt(n: number) {
  return n.toLocaleString("en-US", { maximumFractionDigits: 0 });
}

function fmtDec(n: number, d = 4) {
  return n.toFixed(d);
}

function AAVEStrategy({ saved, market }: { saved: AAVEPosition; market: MarketIndicators }) {
  const collateralUSD = saved.collateralAmount;
  const borrowUSD     = saved.borrowAmount;
  const cTok = saved.collateralToken; // BTC | ETH | USDC
  const bTok = saved.borrowToken;
  const cp = TOKEN_PARAMS[cTok];
  const bp = TOKEN_PARAMS[bTok];

  const hf = borrowUSD > 0 ? (collateralUSD * cp.liqThreshold) / borrowUSD : Infinity;
  const netAPY = (collateralUSD * cp.supplyAPY / 100) - (borrowUSD * bp.borrowAPY / 100);

  const btcPrice = market.price;
  const atr   = market.atr;
  const ema20 = market.ema20;
  const ema50 = market.ema50;

  // ── Net directional exposure ─────────────────────────────────────────────
  // Colateral volátil → long en ese token
  // Borrow volátil → short sintético en ese token
  const collateralIsVolatile = cTok !== "USDC";
  const borrowIsVolatile     = bTok !== "USDC";

  // Token principal de cobertura y su exposición en USD
  // Si colateral volátil: exposición larga en ese token
  // Si borrow volátil (y colateral estable): exposición corta en ese token
  const hedgeToken = collateralIsVolatile ? cTok : borrowIsVolatile ? bTok : null;
  const hedgeDirection: "LONG" | "SHORT" | null =
    collateralIsVolatile ? "LONG"   // long en colateral → cubrir con SHORT
    : borrowIsVolatile   ? "SHORT"  // short sintético en borrow → cubrir con LONG
    : null;

  // Tamaño de cobertura en USD (para BTC tenemos precio exacto, para ETH no)
  const hedgeSizeUSD = collateralIsVolatile ? collateralUSD : borrowIsVolatile ? borrowUSD : 0;
  const hedgeSizeBTC = hedgeToken === "BTC" && btcPrice > 0 ? hedgeSizeUSD / btcPrice : 0;

  // Precio de liquidación del colateral (solo relevante si colateral = BTC)
  const liqPriceBTC = cTok === "BTC" && borrowUSD > 0
    ? btcPrice * (borrowUSD / (collateralUSD * cp.liqThreshold))
    : 0;

  // Niveles de precio para BTC (tenemos datos en tiempo real de BTC)
  const shortEntry = Math.max(btcPrice, ema20) * 1.001;
  const shortStop  = shortEntry + atr * 1.5;
  const shortTP1   = shortEntry - atr * 2.5;
  const shortTP2   = shortEntry - atr * 4;

  const longEntry = Math.min(btcPrice, ema20) * 0.999;
  const longStop  = longEntry - atr * 1.5;
  const longTP1   = longEntry + atr * 2.5;

  // ── Caída tolerada hasta liquidación ────────────────────────────────────
  const dropToLiq = isFinite(hf) && hf > 1 ? (((hf - 1) / hf) * 100).toFixed(1) : "—";

  const steps: Step[] = [];

  // ═══════════════════════════════════════════════════════════════════════
  // BAJISTA
  // ═══════════════════════════════════════════════════════════════════════
  if (market.trend === "BAJISTA") {

    // ── Colateral volátil (BTC o ETH) → en riesgo ──
    if (collateralIsVolatile) {
      steps.push({
        icon: "⚠",
        title: `Colateral ${cTok} en riesgo — mercado bajista`,
        body: `Tu colateral ${cTok} vale $${fmt(collateralUSD)}. Si ${cTok} cae un ${dropToLiq}% más, tu posición se liquida.${cTok === "BTC" ? ` Precio de liquidación aprox. $${fmt(liqPriceBTC)}.` : ""}`,
        accent: "bg-orange-900/20 border-orange-500/30",
        tags: [
          { label: "Health Factor", value: hf.toFixed(2), color: hf < 2 ? "text-orange-400" : "text-emerald-400" },
          { label: "Caída máx. tolerable", value: `${dropToLiq}%`, color: "text-white" },
          ...(cTok === "BTC" ? [{ label: "Precio liq. BTC", value: `$${fmt(liqPriceBTC)}`, color: "text-red-400" }] : []),
        ],
      });

      // Sugerir cambiar borrow al mismo token que el colateral
      if (bTok === "USDC") {
        const borrowAPYMatch = TOKEN_PARAMS[cTok].borrowAPY;
        steps.push({
          icon: "💡",
          title: `Cambia el borrow a ${cTok} en lugar de USDC`,
          body: `Si tomas prestado ${cTok} (en vez de USDC), cuando ${cTok} baje tu deuda en USD también baja. Es un short sintético sobre ${cTok} a través del borrow: repagar te costará menos si el precio cae. Además el APY es más barato.`,
          accent: "bg-cyan-900/20 border-cyan-500/30",
          tags: [
            { label: `APY borrow ${cTok}`, value: `${borrowAPYMatch}%`, color: "text-emerald-400" },
            { label: "APY borrow USDC", value: `${TOKEN_PARAMS.USDC.borrowAPY}%`, color: "text-red-400" },
            { label: "Ahorro anual", value: `+$${fmt(borrowUSD * (TOKEN_PARAMS.USDC.borrowAPY - borrowAPYMatch) / 100)}`, color: "text-emerald-400" },
          ],
        });
      }

      // SHORT perpetual en el mismo token que el colateral
      if (cTok === "BTC") {
        steps.push({
          icon: "🛡",
          title: `Abre SHORT BTC/USDC perpetual — cubre los ${fmtDec(hedgeSizeBTC)} BTC`,
          body: `$${fmt(collateralUSD)} en BTC = ~${fmtDec(hedgeSizeBTC)} BTC de exposición larga. Abre un SHORT en Hyperliquid/GMX con ese tamaño. Si BTC cae, la ganancia del SHORT compensa la pérdida de valor del colateral y protege el HF.`,
          accent: "bg-red-900/20 border-red-500/30",
          tags: [
            { label: "Par", value: "BTC/USDC", color: "text-white" },
            { label: "Dirección", value: "SHORT", color: "text-red-400" },
            { label: "Tamaño", value: `${fmtDec(hedgeSizeBTC)} BTC`, color: "text-red-400" },
            { label: "Entrada límite", value: `$${fmt(shortEntry)}`, color: "text-white" },
            { label: "Stop loss", value: `$${fmt(shortStop)}`, color: "text-orange-400" },
            { label: "TP conservador", value: `$${fmt(shortTP1)}`, color: "text-emerald-400" },
            { label: "TP agresivo", value: `$${fmt(shortTP2)}`, color: "text-emerald-400" },
            { label: "Apalancamiento", value: "2–3×", color: "text-slate-300" },
          ],
        });
      } else if (cTok === "ETH") {
        steps.push({
          icon: "🛡",
          title: `Abre SHORT ETH/USDC perpetual — cubre $${fmt(hedgeSizeUSD)} en ETH`,
          body: `Tienes $${fmt(collateralUSD)} en ETH de exposición larga. Abre un SHORT ETH/USDC en Hyperliquid/GMX por un nocional de ~$${fmt(hedgeSizeUSD)}. Si ETH cae, la ganancia del SHORT compensa la pérdida del colateral.`,
          accent: "bg-red-900/20 border-red-500/30",
          tags: [
            { label: "Par", value: "ETH/USDC", color: "text-white" },
            { label: "Dirección", value: "SHORT", color: "text-red-400" },
            { label: "Nocional USD", value: `$${fmt(hedgeSizeUSD)}`, color: "text-red-400" },
            { label: "Apalancamiento", value: "2–3×", color: "text-slate-300" },
            { label: "Stop loss aprox.", value: `+ATR ETH × 1.5`, color: "text-orange-400" },
            { label: "TP aprox.", value: `-ATR ETH × 2.5`, color: "text-emerald-400" },
          ],
        });
      }
    }

    // ── Colateral USDC + Borrow volátil → short sintético ya activo ──
    if (!collateralIsVolatile && borrowIsVolatile) {
      steps.push({
        icon: "✅",
        title: `Posición ideal para bajista — short sintético en ${bTok}`,
        body: `Tienes colateral estable (USDC) y has tomado prestado ${bTok}. Si ${bTok} baja, repagar la deuda te cuesta menos USD — es un short sintético. Mercado bajista favorece exactamente esta estructura.`,
        accent: "bg-emerald-900/20 border-emerald-500/30",
        tags: [
          { label: "HF", value: hf.toFixed(2), color: hf < 2 ? "text-orange-400" : "text-emerald-400" },
          { label: "APY neto", value: `${netAPY >= 0 ? "+" : ""}$${fmt(netAPY)}/año`, color: netAPY >= 0 ? "text-emerald-400" : "text-red-400" },
          { label: "Ahorro si baja 20%", value: `$${fmt(borrowUSD * 0.2)}`, color: "text-emerald-400" },
        ],
      });
    }

    steps.push({
      icon: "📋",
      title: "Monitoreo",
      body: `ADX ${market.adx.toFixed(0)} — tendencia fuerte. Revisa HF cada 4h.${cTok === "BTC" ? ` Si BTC cierra bajo EMA50 = $${fmt(ema50)}, reduce el borrow un 20–30%.` : ""}`,
      accent: "bg-slate-800/40 border-slate-700/30",
      tags: [
        { label: "EMA 20 BTC", value: `$${fmt(ema20)}`, color: "text-sky-400" },
        { label: "EMA 50 BTC", value: `$${fmt(ema50)}`, color: "text-orange-400" },
        { label: "ATR BTC", value: `$${fmt(atr)}`, color: "text-white" },
        { label: "APY neto", value: `${netAPY >= 0 ? "+" : ""}$${fmt(netAPY)}/año`, color: netAPY >= 0 ? "text-emerald-400" : "text-red-400" },
      ],
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ALCISTA
  // ═══════════════════════════════════════════════════════════════════════
  else if (market.trend === "ALCISTA") {

    // Colateral volátil → se aprecia, buena noticia
    if (collateralIsVolatile) {
      steps.push({
        icon: "✅",
        title: `Colateral ${cTok} se aprecia — posición favorecida`,
        body: `Mercado alcista: ${cTok} sube, mejorando tu HF automáticamente. Si ${cTok} sube un 10%, tu HF pasaría a ~${((collateralUSD * 1.1 * cp.liqThreshold) / Math.max(borrowUSD, 1)).toFixed(2)}.`,
        accent: "bg-emerald-900/20 border-emerald-500/30",
        tags: [
          { label: "HF actual", value: hf.toFixed(2), color: "text-emerald-400" },
          { label: `HF si ${cTok} +10%`, value: ((collateralUSD * 1.1 * cp.liqThreshold) / Math.max(borrowUSD, 1)).toFixed(2), color: "text-emerald-400" },
          { label: "APY neto", value: `${netAPY >= 0 ? "+" : ""}$${fmt(netAPY)}/año`, color: netAPY >= 0 ? "text-emerald-400" : "text-red-400" },
        ],
      });

      // Borrow volátil diferente al colateral → riesgo adicional
      if (borrowIsVolatile && bTok !== cTok) {
        steps.push({
          icon: "⚠",
          title: `Borrow en ${bTok} — riesgo si ${bTok} sube`,
          body: `Tomaste prestado ${bTok} y el mercado es alcista. Si ${bTok} sube, tu deuda en USD aumenta y el HF empeora. Considera cambiar el borrow a USDC para eliminar este riesgo.`,
          accent: "bg-orange-900/20 border-orange-500/30",
          tags: [
            { label: "APY borrow USDC (sin riesgo)", value: `${TOKEN_PARAMS.USDC.borrowAPY}%`, color: "text-white" },
            { label: `HF si ${bTok} +20%`, value: ((collateralUSD * cp.liqThreshold) / (borrowUSD * 1.2)).toFixed(2), color: "text-orange-400" },
          ],
        });
      }

      // Cobertura parcial opcional
      const perpToken = cTok;
      if (perpToken === "BTC") {
        steps.push({
          icon: "📈",
          title: "Cobertura parcial opcional — protege beneficios",
          body: `Si quieres asegurar parte de las ganancias sin cerrar AAVE, abre un SHORT BTC del 50% de tu exposición. Actívalo solo si BTC rompe por debajo de EMA20 = $${fmt(ema20)}.`,
          accent: "bg-cyan-900/20 border-cyan-500/30",
          tags: [
            { label: "Par", value: "BTC/USDC", color: "text-white" },
            { label: "SHORT parcial (50%)", value: `${fmtDec(hedgeSizeBTC * 0.5)} BTC`, color: "text-cyan-400" },
            { label: "Activar si BTC <", value: `$${fmt(ema20)}`, color: "text-red-400" },
            { label: "Entrada SHORT", value: `$${fmt(shortEntry)}`, color: "text-white" },
            { label: "Stop SHORT", value: `$${fmt(shortStop)}`, color: "text-orange-400" },
          ],
        });
      } else if (perpToken === "ETH") {
        steps.push({
          icon: "📈",
          title: "Cobertura parcial ETH opcional",
          body: `Si quieres protegerte de un giro bajista sin cerrar AAVE, abre un SHORT ETH/USDC del 50% de tu exposición ($${fmt(hedgeSizeUSD * 0.5)}). Actívalo si ETH muestra debilidad o rompe su EMA20.`,
          accent: "bg-cyan-900/20 border-cyan-500/30",
          tags: [
            { label: "Par", value: "ETH/USDC", color: "text-white" },
            { label: "SHORT parcial (50%)", value: `$${fmt(hedgeSizeUSD * 0.5)}`, color: "text-cyan-400" },
            { label: "Apalancamiento", value: "2–3×", color: "text-slate-300" },
          ],
        });
      }
    }

    // Colateral USDC + Borrow volátil → short sintético en tendencia alcista: peligro
    if (!collateralIsVolatile && borrowIsVolatile) {
      steps.push({
        icon: "⚠",
        title: `Borrow ${bTok} en riesgo — mercado alcista`,
        body: `Tomaste prestado ${bTok} con colateral estable. El mercado es alcista: si ${bTok} sube, tu deuda en USD sube y el HF baja. Considera cerrar el borrow o abrir un LONG ${bTok} perpetual para cubrirte.`,
        accent: "bg-orange-900/20 border-orange-500/30",
        tags: [
          { label: "HF actual", value: hf.toFixed(2), color: hf < 2 ? "text-orange-400" : "text-emerald-400" },
          { label: `HF si ${bTok} +20%`, value: ((collateralUSD * cp.liqThreshold) / (borrowUSD * 1.2)).toFixed(2), color: "text-orange-400" },
        ],
      });

      if (bTok === "BTC") {
        steps.push({
          icon: "🛡",
          title: "Abre LONG BTC/USDC perpetual — cubre el borrow",
          body: `Tu borrow en BTC actúa como un short sintético. Si BTC sube, cubre la deuda con un LONG BTC en Hyperliquid/GMX por el mismo nocional.`,
          accent: "bg-emerald-900/20 border-emerald-500/30",
          tags: [
            { label: "Par", value: "BTC/USDC", color: "text-white" },
            { label: "Dirección", value: "LONG", color: "text-emerald-400" },
            { label: "Tamaño", value: `${fmtDec(hedgeSizeBTC)} BTC`, color: "text-emerald-400" },
            { label: "Entrada límite", value: `$${fmt(longEntry)}`, color: "text-white" },
            { label: "Stop loss", value: `$${fmt(longStop)}`, color: "text-orange-400" },
            { label: "TP", value: `$${fmt(longTP1)}`, color: "text-emerald-400" },
            { label: "Apalancamiento", value: "2–3×", color: "text-slate-300" },
          ],
        });
      } else if (bTok === "ETH") {
        steps.push({
          icon: "🛡",
          title: "Abre LONG ETH/USDC perpetual — cubre el borrow",
          body: `Tu borrow en ETH actúa como un short sintético sobre ETH. Si ETH sube, cubre la deuda con un LONG ETH/USDC de ~$${fmt(hedgeSizeUSD)} nocional.`,
          accent: "bg-emerald-900/20 border-emerald-500/30",
          tags: [
            { label: "Par", value: "ETH/USDC", color: "text-white" },
            { label: "Dirección", value: "LONG", color: "text-emerald-400" },
            { label: "Nocional USD", value: `$${fmt(hedgeSizeUSD)}`, color: "text-emerald-400" },
            { label: "Apalancamiento", value: "2–3×", color: "text-slate-300" },
          ],
        });
      }
    }

    steps.push({
      icon: "📋",
      title: "Monitoreo",
      body: `EMA20 BTC = $${fmt(ema20)} es el soporte clave. Si el precio 1H cierra bajo ese nivel, re-evalúa la posición.`,
      accent: "bg-slate-800/40 border-slate-700/30",
      tags: [
        { label: "Soporte EMA 20 BTC", value: `$${fmt(ema20)}`, color: "text-sky-400" },
        { label: "Soporte EMA 50 BTC", value: `$${fmt(ema50)}`, color: "text-orange-400" },
        { label: "ATR BTC", value: `$${fmt(atr)}`, color: "text-white" },
      ],
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LATERAL
  // ═══════════════════════════════════════════════════════════════════════
  else {
    steps.push({
      icon: "→",
      title: "Mercado lateral — mantener y cobrar APY",
      body: `Sin tendencia clara (ADX ${market.adx.toFixed(0)}). Tu posición AAVE genera $${fmt(Math.abs(netAPY))}/año de APY neto. Mantener es la estrategia óptima.`,
      accent: "bg-yellow-900/20 border-yellow-500/30",
      tags: [
        { label: "APY neto", value: `${netAPY >= 0 ? "+" : ""}$${fmt(netAPY)}/año`, color: netAPY >= 0 ? "text-emerald-400" : "text-red-400" },
        { label: "HF", value: hf.toFixed(2), color: hf < 2 ? "text-orange-400" : "text-emerald-400" },
        ...(cTok === "BTC" ? [{ label: "Precio liq. BTC", value: `$${fmt(liqPriceBTC)}`, color: "text-red-400" }] : []),
      ],
    });

    if (hedgeToken && hedgeDirection === "LONG") {
      const perpToken = hedgeToken;
      steps.push({
        icon: "🔄",
        title: `Cobertura condicional ${perpToken} — si sale del rango`,
        body: `Si ${perpToken === "BTC" ? `BTC sale del rango $${fmt(ema20)}–$${fmt(ema50)}` : `${perpToken} muestra momentum fuerte`}, activa cobertura. Rompe arriba → SHORT 50%. Rompe abajo → SHORT 100%.`,
        accent: "bg-slate-800/40 border-slate-700/30",
        tags: perpToken === "BTC" ? [
          { label: "Rango BTC", value: `$${fmt(ema20)} – $${fmt(ema50)}`, color: "text-yellow-400" },
          { label: "SHORT 50% si sube", value: `${fmtDec(hedgeSizeBTC * 0.5)} BTC @ $${fmt(shortEntry)}`, color: "text-red-400" },
          { label: "SHORT 100% si baja", value: `${fmtDec(hedgeSizeBTC)} BTC @ $${fmt(longEntry)}`, color: "text-orange-400" },
          { label: "Stop loss", value: `ATR × 1.5 = $${fmt(atr * 1.5)}`, color: "text-white" },
        ] : [
          { label: "Par", value: `${perpToken}/USDC`, color: "text-white" },
          { label: "SHORT 50% si sube", value: `$${fmt(hedgeSizeUSD * 0.5)} nocional`, color: "text-red-400" },
          { label: "SHORT 100% si baja", value: `$${fmt(hedgeSizeUSD)} nocional`, color: "text-orange-400" },
        ],
      });
    }
  }

  const trendLabel = market.trend === "ALCISTA" ? "ALCISTA ▲" : market.trend === "BAJISTA" ? "BAJISTA ▼" : "LATERAL →";
  const trendColor = market.trend === "ALCISTA" ? "text-emerald-400" : market.trend === "BAJISTA" ? "text-red-400" : "text-yellow-400";
  const headerBg   = market.trend === "ALCISTA" ? "bg-emerald-900/20 border-emerald-600/30"
    : market.trend === "BAJISTA" ? "bg-red-900/20 border-red-600/30"
    : "bg-yellow-900/20 border-yellow-600/30";

  return (
    <div className="mt-6 flex flex-col gap-4">
      <div className={`rounded-2xl border p-4 flex items-center gap-3 ${headerBg}`}>
        <span className={`text-2xl font-black ${trendColor}`}>{trendLabel}</span>
        <span className="text-slate-400 text-sm">— Plan de acción para tu posición AAVE</span>
      </div>
      {steps.map((s, i) => <StrategyStep key={i} step={s} num={i + 1} />)}
    </div>
  );
}

export default function AAVEModule({ onSave, saved, market }: {
  onSave: (p: AAVEPosition) => void;
  saved: AAVEPosition | null;
  market: MarketIndicators;
}) {
  const [collateralToken, setCollateralToken] = useState<string>("BTC");
  const [collateralUSD, setCollateralUSD] = useState("50000");
  const [borrowToken, setBorrowToken] = useState<string>("USDC");
  const [borrowUSD, setBorrowUSD] = useState("20000");

  const cUSD = parseFloat(collateralUSD) || 0;
  const bUSD = parseFloat(borrowUSD) || 0;
  const cp = TOKEN_PARAMS[collateralToken];
  const bp = TOKEN_PARAMS[borrowToken];

  const healthFactor = bUSD > 0 ? (cUSD * cp.liqThreshold) / bUSD : Infinity;
  const ltv = cUSD > 0 ? (bUSD / cUSD) * 100 : 0;
  const netAPY = (cUSD * cp.supplyAPY / 100) - (bUSD * bp.borrowAPY / 100);
  const liqCollateralValue = bUSD / cp.liqThreshold;
  const distToLiqPct = cUSD > 0 ? ((cUSD - liqCollateralValue) / cUSD) * 100 : 100;

  const hfColor =
    healthFactor < 1.2 ? "text-red-500" :
    healthFactor < 1.5 ? "text-orange-400" :
    healthFactor < 2   ? "text-yellow-400" : "text-emerald-400";

  const handleSave = () => {
    onSave({
      collateralToken, collateralAmount: cUSD, collateralPriceUSD: 1,
      collateralLiqThreshold: cp.liqThreshold, collateralAPY: cp.supplyAPY,
      borrowToken, borrowAmount: bUSD, borrowPriceUSD: 1, borrowAPY: bp.borrowAPY,
    });
  };

  return (
    <div className="flex flex-col gap-5">
      <h2 className="text-lg font-bold text-white">Módulo AAVE</h2>

      <div className="grid md:grid-cols-2 gap-4">
        {/* Collateral */}
        <div className="rounded-2xl bg-slate-900 border border-slate-700/50 p-5 flex flex-col gap-4">
          <h3 className="text-sm font-bold text-emerald-400">Colateral (Supply)</h3>
          <TokenSelect label="Token" value={collateralToken} onChange={setCollateralToken} />
          <div>
            <label className="text-xs text-slate-400 mb-1 block">Total en USD</label>
            <input type="number" value={collateralUSD} onChange={(e) => setCollateralUSD(e.target.value)}
              className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-xl font-bold text-white focus:outline-none focus:border-emerald-500 transition-colors" />
          </div>
          <div className="flex justify-between text-xs text-slate-500">
            <span>Supply APY: <span className="text-emerald-400">{cp.supplyAPY}%</span></span>
            <span>Liq. Threshold: <span className="text-white">{(cp.liqThreshold * 100).toFixed(0)}%</span></span>
          </div>
        </div>

        {/* Borrow */}
        <div className="rounded-2xl bg-slate-900 border border-slate-700/50 p-5 flex flex-col gap-4">
          <h3 className="text-sm font-bold text-red-400">Préstamo (Borrow)</h3>
          <TokenSelect label="Token" value={borrowToken} onChange={setBorrowToken} />
          <div>
            <label className="text-xs text-slate-400 mb-1 block">Total en USD</label>
            <input type="number" value={borrowUSD} onChange={(e) => setBorrowUSD(e.target.value)}
              className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-xl font-bold text-white focus:outline-none focus:border-red-500 transition-colors" />
          </div>
          <div className="flex justify-between text-xs text-slate-500">
            <span>Borrow APY: <span className="text-red-400">{bp.borrowAPY}%</span></span>
            <span>LTV: <span className={`font-bold ${ltv > 75 ? "text-red-400" : ltv > 60 ? "text-orange-400" : "text-white"}`}>{ltv.toFixed(1)}%</span></span>
          </div>
        </div>
      </div>

      {/* Metrics */}
      <div className="rounded-2xl bg-slate-900 border border-slate-700/50 p-5 flex flex-col gap-4">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          <div className="rounded-xl bg-slate-800/60 p-4 text-center">
            <div className="text-slate-400 text-xs mb-2">Health Factor</div>
            <div className={`text-3xl font-black ${hfColor}`}>
              {isFinite(healthFactor) ? healthFactor.toFixed(2) : "∞"}
            </div>
            <div className={`text-xs mt-1 ${hfColor}`}>
              {healthFactor < 1.5 ? "⚠ ALERTA" : healthFactor < 2 ? "Moderado" : "Seguro"}
            </div>
          </div>
          <div className="rounded-xl bg-slate-800/60 p-4 text-center">
            <div className="text-slate-400 text-xs mb-2">APY Neto / año</div>
            <div className={`text-3xl font-black ${netAPY >= 0 ? "text-emerald-400" : "text-red-400"}`}>
              {netAPY >= 0 ? "+" : ""}${Math.abs(netAPY).toFixed(0)}
            </div>
            <div className="text-xs mt-1 text-slate-500">{netAPY >= 0 ? "Ganancia" : "Coste neto"}</div>
          </div>
          <div className="rounded-xl bg-slate-800/60 p-4 text-center">
            <div className="text-slate-400 text-xs mb-2">Caída hasta Liq.</div>
            <div className={`text-3xl font-black ${distToLiqPct < 20 ? "text-red-400" : distToLiqPct < 35 ? "text-orange-400" : "text-emerald-400"}`}>
              -{distToLiqPct.toFixed(1)}%
            </div>
            <div className="text-xs mt-1 text-slate-500">En colateral</div>
          </div>
          <div className="rounded-xl bg-slate-800/60 p-4 text-center">
            <div className="text-slate-400 text-xs mb-2">Colateral libre</div>
            <div className="text-3xl font-black text-white">
              ${Math.max(0, cUSD - liqCollateralValue).toLocaleString("en-US", { maximumFractionDigits: 0 })}
            </div>
            <div className="text-xs mt-1 text-slate-500">Margen de seguridad</div>
          </div>
        </div>

        {healthFactor < 1.5 && healthFactor > 0 && (
          <div className="rounded-xl bg-red-900/30 border border-red-500/40 p-3 text-sm text-red-300 font-medium">
            🚨 ALERTA CRÍTICA: Health Factor {healthFactor.toFixed(2)} — Repaga deuda o añade colateral inmediatamente.
          </div>
        )}

        <button onClick={handleSave}
          className="w-full bg-cyan-600 hover:bg-cyan-500 text-white font-bold py-2.5 rounded-xl text-sm transition-colors">
          Analizar y ver estrategia
        </button>
      </div>

      {/* Inline strategy — appears after saving */}
      {saved && <AAVEStrategy saved={saved} market={market} />}
    </div>
  );
}
