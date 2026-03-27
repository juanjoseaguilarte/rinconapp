import { Candle, Stage, RelevantPoint, StageResult } from "./types";

const RELEVANT_NEIGHBORS = 3;

export function calcSMA(candles: Candle[], period: number, endIndex: number): number {
  if (endIndex < period - 1) return NaN;
  let sum = 0;
  for (let i = endIndex - period + 1; i <= endIndex; i++) {
    sum += candles[i].close;
  }
  return sum / period;
}

export function findRelevantHighs(candles: Candle[], n = RELEVANT_NEIGHBORS): RelevantPoint[] {
  const result: RelevantPoint[] = [];
  for (let i = n; i < candles.length - n; i++) {
    const h = candles[i].high;
    let isRelevant = true;
    for (let j = i - n; j < i; j++) {
      if (candles[j].high >= h) { isRelevant = false; break; }
    }
    if (!isRelevant) continue;
    for (let j = i + 1; j <= i + n; j++) {
      if (candles[j].high >= h) { isRelevant = false; break; }
    }
    if (isRelevant) {
      result.push({ index: i, price: h, type: "high", time: candles[i].time });
    }
  }
  return result;
}

export function findRelevantLows(candles: Candle[], n = RELEVANT_NEIGHBORS): RelevantPoint[] {
  const result: RelevantPoint[] = [];
  for (let i = n; i < candles.length - n; i++) {
    const l = candles[i].low;
    let isRelevant = true;
    for (let j = i - n; j < i; j++) {
      if (candles[j].low <= l) { isRelevant = false; break; }
    }
    if (!isRelevant) continue;
    for (let j = i + 1; j <= i + n; j++) {
      if (candles[j].low <= l) { isRelevant = false; break; }
    }
    if (isRelevant) {
      result.push({ index: i, price: l, type: "low", time: candles[i].time });
    }
  }
  return result;
}

function getTrend(candles: Candle[], period: number, lookback = 5): "rising" | "falling" | "flat" {
  const last = candles.length - 1;
  if (last < period - 1 + lookback) return "flat";
  const current = calcSMA(candles, period, last);
  const prev = calcSMA(candles, period, last - lookback);
  const pct = (current - prev) / prev;
  if (pct > 0.005) return "rising";
  if (pct < -0.005) return "falling";
  return "flat";
}

export function detectStage(candles: Candle[]): StageResult {
  if (candles.length < 50) {
    throw new Error("Not enough candles");
  }

  const allHighs = findRelevantHighs(candles);
  const allLows = findRelevantLows(candles);

  // Walk through candles applying stage machine
  // We start detecting from index 40 (enough for sma40)
  let currentStage: Stage = 1;
  const stageHistory: { index: number; stage: Stage }[] = [];

  // Bootstrap: determine initial stage from first 40 candles
  const initSma20 = calcSMA(candles, 20, 39);
  const initSma40 = calcSMA(candles, 40, 39);
  if (initSma20 > initSma40) {
    currentStage = 2;
  } else {
    currentStage = 4;
  }

  for (let i = 40; i < candles.length; i++) {
    const close = candles[i].close;

    // Relevant highs and lows known up to i (excluding last n for "confirmed")
    const knownHighs = allHighs.filter((p) => p.index <= i - RELEVANT_NEIGHBORS);
    const knownLows = allLows.filter((p) => p.index <= i - RELEVANT_NEIGHBORS);

    const lastRH = knownHighs[knownHighs.length - 1] ?? null;
    const lastRL = knownLows[knownLows.length - 1] ?? null;

    const prevStage = currentStage;

    if (currentStage === 1 || currentStage === 4) {
      // Transition to Stage 2: close above last relevant high
      if (lastRH && close > lastRH.price) {
        currentStage = 2;
      }
    } else if (currentStage === 2) {
      // Transition to Stage 3: close below last relevant low
      if (lastRL && close < lastRL.price) {
        currentStage = 3;
      }
    } else if (currentStage === 3 || currentStage === 1) {
      // Transition to Stage 4: close below last relevant low (base of stage 3)
      if (lastRL && close < lastRL.price) {
        currentStage = 4;
      }
    }

    // Stage 4 → Stage 1: close above last relevant high
    if (prevStage === 4 && lastRH && close > lastRH.price) {
      currentStage = 1;
    }

    if (currentStage !== prevStage) {
      stageHistory.push({ index: i, stage: currentStage });
    }
  }

  const last = candles.length - 1;
  const sma20 = calcSMA(candles, 20, last);
  const sma40 = calcSMA(candles, 40, last);
  const currentPrice = candles[last].close;
  const prevPrice = candles[last - 1]?.close ?? currentPrice;
  const priceChange24h = currentPrice - prevPrice;
  const priceChangePct24h = (priceChange24h / prevPrice) * 100;
  const distanceToSma20Pct = ((currentPrice - sma20) / sma20) * 100;

  const finalHighs = allHighs.filter((p) => p.index <= last - RELEVANT_NEIGHBORS);
  const finalLows = allLows.filter((p) => p.index <= last - RELEVANT_NEIGHBORS);

  return {
    stage: currentStage,
    sma20,
    sma40,
    currentPrice,
    priceChange24h,
    priceChangePct24h,
    lastRelevantHigh: finalHighs[finalHighs.length - 1] ?? null,
    lastRelevantLow: finalLows[finalLows.length - 1] ?? null,
    relevantHighs: finalHighs.slice(-10),
    relevantLows: finalLows.slice(-10),
    distanceToSma20Pct,
    sma20Trend: getTrend(candles, 20),
    sma40Trend: getTrend(candles, 40),
    candles,
    stageHistory,
  };
}
