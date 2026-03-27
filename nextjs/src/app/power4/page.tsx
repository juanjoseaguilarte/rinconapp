import { fetchCandles } from "@/lib/power4/api";
import { detectStage } from "@/lib/power4/analysis";
import { StageResult } from "@/lib/power4/types";
import Power4Dashboard from "./Power4Dashboard";

export interface InitialAsset {
  name: string;
  binanceSymbol: string;
  initial1d: StageResult;
}

async function getInitialData(): Promise<InitialAsset[]> {
  const assets = [
    { name: "Bitcoin", binanceSymbol: "BTCUSDT" },
    { name: "Ethereum", binanceSymbol: "ETHUSDT" },
  ];

  return Promise.all(
    assets.map(async ({ name, binanceSymbol }) => {
      const candles = await fetchCandles(binanceSymbol, "1d", 200);
      return { name, binanceSymbol, initial1d: detectStage(candles) };
    })
  );
}

export const revalidate = 300;

export default async function Power4Page() {
  const assets = await getInitialData();
  return <Power4Dashboard assets={assets} />;
}
