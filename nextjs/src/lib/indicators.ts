import { Candle } from "./power4/types";

// ── EMA ──────────────────────────────────────────────────────────────────────
export function calcEMA(data: number[], period: number): number[] {
  const k = 2 / (period + 1);
  const ema: number[] = [];
  let sum = 0;
  for (let i = 0; i < period; i++) sum += data[i];
  ema[period - 1] = sum / period;
  for (let i = period; i < data.length; i++) {
    ema[i] = data[i] * k + ema[i - 1] * (1 - k);
  }
  return ema;
}

// ── RSI ──────────────────────────────────────────────────────────────────────
export function calcRSI(closes: number[], period = 14): number[] {
  const rsi: number[] = new Array(closes.length).fill(NaN);
  if (closes.length < period + 1) return rsi;

  let avgGain = 0, avgLoss = 0;
  for (let i = 1; i <= period; i++) {
    const diff = closes[i] - closes[i - 1];
    if (diff > 0) avgGain += diff; else avgLoss -= diff;
  }
  avgGain /= period;
  avgLoss /= period;
  rsi[period] = avgLoss === 0 ? 100 : 100 - 100 / (1 + avgGain / avgLoss);

  for (let i = period + 1; i < closes.length; i++) {
    const diff = closes[i] - closes[i - 1];
    const gain = diff > 0 ? diff : 0;
    const loss = diff < 0 ? -diff : 0;
    avgGain = (avgGain * (period - 1) + gain) / period;
    avgLoss = (avgLoss * (period - 1) + loss) / period;
    rsi[i] = avgLoss === 0 ? 100 : 100 - 100 / (1 + avgGain / avgLoss);
  }
  return rsi;
}

// ── MACD ─────────────────────────────────────────────────────────────────────
export function calcMACD(closes: number[], fast = 12, slow = 26, signal = 9) {
  const ema12 = calcEMA(closes, fast);
  const ema26 = calcEMA(closes, slow);
  const macdLine = closes.map((_, i) =>
    ema12[i] !== undefined && ema26[i] !== undefined ? ema12[i] - ema26[i] : NaN
  );
  const validMacd = macdLine.filter((v) => !isNaN(v));
  const signalRaw = calcEMA(validMacd, signal);
  const signalLine: number[] = new Array(closes.length).fill(NaN);
  let si = 0;
  for (let i = 0; i < closes.length; i++) {
    if (!isNaN(macdLine[i])) { signalLine[i] = signalRaw[si++] ?? NaN; }
  }
  const histogram = macdLine.map((v, i) =>
    !isNaN(v) && !isNaN(signalLine[i]) ? v - signalLine[i] : NaN
  );
  return { macdLine, signalLine, histogram };
}

// ── ATR ──────────────────────────────────────────────────────────────────────
export function calcATR(candles: Candle[], period = 14): number[] {
  const tr: number[] = [0];
  for (let i = 1; i < candles.length; i++) {
    const { high, low } = candles[i];
    const prevClose = candles[i - 1].close;
    tr.push(Math.max(high - low, Math.abs(high - prevClose), Math.abs(low - prevClose)));
  }
  const atr: number[] = new Array(candles.length).fill(NaN);
  let sum = 0;
  for (let i = 1; i <= period; i++) sum += tr[i];
  atr[period] = sum / period;
  for (let i = period + 1; i < candles.length; i++) {
    atr[i] = (atr[i - 1] * (period - 1) + tr[i]) / period;
  }
  return atr;
}

// ── ADX ──────────────────────────────────────────────────────────────────────
export function calcADX(candles: Candle[], period = 14): number[] {
  const adx: number[] = new Array(candles.length).fill(NaN);
  if (candles.length < period * 2) return adx;

  const plusDM: number[] = [0], minusDM: number[] = [], trArr: number[] = [0];
  for (let i = 1; i < candles.length; i++) {
    const upMove = candles[i].high - candles[i - 1].high;
    const downMove = candles[i - 1].low - candles[i].low;
    plusDM.push(upMove > downMove && upMove > 0 ? upMove : 0);
    minusDM.push(downMove > upMove && downMove > 0 ? downMove : 0);
    const { high, low } = candles[i];
    const pc = candles[i - 1].close;
    trArr.push(Math.max(high - low, Math.abs(high - pc), Math.abs(low - pc)));
  }
  minusDM.unshift(0);

  const smoothPlus = calcEMA(plusDM, period);
  const smoothMinus = calcEMA(minusDM, period);
  const smoothTR = calcEMA(trArr, period);

  const dx: number[] = candles.map((_, i) => {
    if (!smoothTR[i] || smoothTR[i] === 0) return NaN;
    const pdi = (smoothPlus[i] / smoothTR[i]) * 100;
    const mdi = (smoothMinus[i] / smoothTR[i]) * 100;
    const sum2 = pdi + mdi;
    return sum2 === 0 ? 0 : (Math.abs(pdi - mdi) / sum2) * 100;
  });

  const adxSmooth = calcEMA(dx.filter((v) => !isNaN(v)), period);
  let si = 0;
  for (let i = 0; i < candles.length; i++) {
    if (!isNaN(dx[i])) adx[i] = adxSmooth[si++] ?? NaN;
  }
  return adx;
}

// ── Market Classification ─────────────────────────────────────────────────────
export type MarketTrend = "ALCISTA" | "BAJISTA" | "LATERAL";

export interface MarketIndicators {
  trend: MarketTrend;
  ema20: number;
  ema50: number;
  ema200: number;
  rsi: number;
  macd: number;
  macdSignal: number;
  macdHistogram: number;
  atr: number;
  adx: number;
  price: number;
}

export function analyzeMarket(candles: Candle[]): MarketIndicators {
  const closes = candles.map((c) => c.close);
  const last = candles.length - 1;

  const ema20Arr = calcEMA(closes, 20);
  const ema50Arr = calcEMA(closes, 50);
  const ema200Arr = calcEMA(closes, 200);
  const rsiArr = calcRSI(closes);
  const { macdLine, signalLine, histogram } = calcMACD(closes);
  const atrArr = calcATR(candles);
  const adxArr = calcADX(candles);

  const price = closes[last];
  const ema20 = ema20Arr[last] ?? NaN;
  const ema50 = ema50Arr[last] ?? NaN;
  const ema200 = ema200Arr[last] ?? NaN;
  const rsi = rsiArr[last] ?? NaN;
  const macd = macdLine[last] ?? NaN;
  const macdSignal = signalLine[last] ?? NaN;
  const macdHistogram = histogram[last] ?? NaN;
  const atr = atrArr[last] ?? NaN;
  const adx = adxArr[last] ?? NaN;

  let bullPoints = 0, bearPoints = 0;
  if (price > ema20) bullPoints++; else bearPoints++;
  if (price > ema50) bullPoints++; else bearPoints++;
  if (price > ema200) bullPoints++; else bearPoints++;
  if (!isNaN(ema20) && !isNaN(ema50) && ema20 > ema50) bullPoints++; else bearPoints++;
  if (!isNaN(ema50) && !isNaN(ema200) && ema50 > ema200) bullPoints++; else bearPoints++;
  if (!isNaN(rsi) && rsi > 50) bullPoints++; else bearPoints++;
  if (!isNaN(macdHistogram) && macdHistogram > 0) bullPoints++; else bearPoints++;

  let trend: MarketTrend;
  const diff = bullPoints - bearPoints;
  if (diff >= 3) trend = "ALCISTA";
  else if (diff <= -3) trend = "BAJISTA";
  else trend = "LATERAL";

  return { trend, ema20, ema50, ema200, rsi, macd, macdSignal, macdHistogram, atr, adx, price };
}
