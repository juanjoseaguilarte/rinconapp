import { fetchCandles } from "@/lib/power4/api";
import { analyzeMarket, MarketIndicators } from "@/lib/indicators";
import DeltaNeutralDashboard from "./DeltaNeutralDashboard";

export const revalidate = 300;

export default async function DeltaNeutralPage() {
  const candles = await fetchCandles("BTCUSDT", "1h", 220);
  const market = analyzeMarket(candles);
  return <DeltaNeutralDashboard initialMarket={market} />;
}
