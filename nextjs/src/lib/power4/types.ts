export interface Candle {
  time: number;
  open: number;
  high: number;
  low: number;
  close: number;
  volume: number;
}

export type Stage = 1 | 2 | 3 | 4;

export interface RelevantPoint {
  index: number;
  price: number;
  type: "high" | "low";
  time: number;
}

export interface StageResult {
  stage: Stage;
  sma20: number;
  sma40: number;
  currentPrice: number;
  priceChange24h: number;
  priceChangePct24h: number;
  lastRelevantHigh: RelevantPoint | null;
  lastRelevantLow: RelevantPoint | null;
  relevantHighs: RelevantPoint[];
  relevantLows: RelevantPoint[];
  distanceToSma20Pct: number;
  sma20Trend: "rising" | "falling" | "flat";
  sma40Trend: "rising" | "falling" | "flat";
  candles: Candle[];
  stageHistory: { index: number; stage: Stage }[];
}

export interface AnalysisResult {
  symbol: string;
  daily: StageResult;
  weekly: StageResult;
  lastUpdated: number;
}
