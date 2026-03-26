"use client";

import { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import {
  ArrowLeft,
  Plus,
  TrendingUp,
  TrendingDown,
  History,
  X,
  Calculator,
} from "lucide-react";
import {
  collection,
  doc,
  getDoc,
  getDocs,
  addDoc,
  setDoc,
  query,
  orderBy,
  limit,
  Timestamp,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { useAuthStore } from "@/stores/authStore";

interface CashTransaction {
  id: string;
  userId: string;
  userName: string;
  type: "entrada" | "salida";
  amount: number;
  reason: string;
  date: string;
}

interface Arqueo {
  id: string;
  expectedAmount: number;
  countedAmount: number;
  amount: number;
  userId: string;
  date: Timestamp;
}

function formatCurrency(amount: number) {
  return new Intl.NumberFormat("es-ES", {
    style: "currency",
    currency: "EUR",
  }).format(amount);
}

function formatTime(isoString: string) {
  return new Date(isoString).toLocaleTimeString("es-ES", {
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatDatetime(isoString: string) {
  return new Date(isoString).toLocaleString("es-ES", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatTimestamp(ts: Timestamp) {
  return ts.toDate().toLocaleString("es-ES", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export default function CashPage() {
  const router = useRouter();
  const { currentEmployee, isAuthenticated } = useAuthStore();

  const [initialAmount, setInitialAmount] = useState(0);
  const [transactions, setTransactions] = useState<CashTransaction[]>([]);
  const [balance, setBalance] = useState(0);
  const [loading, setLoading] = useState(true);

  // Transaction modal
  const [showTransactionModal, setShowTransactionModal] = useState(false);
  const [txType, setTxType] = useState<"entrada" | "salida">("entrada");
  const [txAmount, setTxAmount] = useState("");
  const [txReason, setTxReason] = useState("");
  const [txSaving, setTxSaving] = useState(false);

  // Arqueo modal
  const [showArqueoModal, setShowArqueoModal] = useState(false);
  const [countedAmount, setCountedAmount] = useState("");
  const [arqueoSaving, setArqueoSaving] = useState(false);

  // History modal
  const [showHistoryModal, setShowHistoryModal] = useState(false);
  const [arqueoHistory, setArqueoHistory] = useState<Arqueo[]>([]);
  const [historyLoading, setHistoryLoading] = useState(false);

  const isAdminOrEncargado =
    currentEmployee?.role === "Admin" ||
    currentEmployee?.role === "Encargado" ||
    currentEmployee?.role === "SuperAdmin";

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      // Get initial amount and last arqueo date
      const configDoc = await getDoc(doc(db, "config", "initial_amount"));
      const configData = configDoc.exists() ? configDoc.data() : { amount: 0, updatedAt: null };
      const initial = configData.amount ?? 0;
      setInitialAmount(initial);

      const lastArqueoDate: Date | null = configData.updatedAt
        ? new Date(configData.updatedAt)
        : null;

      // Get transactions since last arqueo
      const txSnap = await getDocs(
        query(collection(db, "cash_transactions"), orderBy("date", "desc"))
      );

      const allTx: CashTransaction[] = txSnap.docs.map((d) => ({
        id: d.id,
        ...(d.data() as Omit<CashTransaction, "id">),
      }));

      // Filter transactions since last arqueo
      const relevantTx = lastArqueoDate
        ? allTx.filter((tx) => new Date(tx.date) > lastArqueoDate)
        : allTx;

      setTransactions(allTx);

      const entradas = relevantTx
        .filter((t) => t.type === "entrada")
        .reduce((sum, t) => sum + t.amount, 0);
      const salidas = relevantTx
        .filter((t) => t.type === "salida")
        .reduce((sum, t) => sum + t.amount, 0);

      setBalance(initial + entradas - salidas);
    } catch (err) {
      console.error("Error loading cash data:", err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!isAuthenticated) {
      router.replace("/login");
      return;
    }
    loadData();
  }, [isAuthenticated, router, loadData]);

  const todayStr = new Date().toISOString().slice(0, 10);
  const todayTransactions = transactions.filter((t) =>
    t.date.startsWith(todayStr)
  );

  async function handleSaveTransaction() {
    if (!currentEmployee) return;
    const amount = parseFloat(txAmount);
    if (isNaN(amount) || amount <= 0) return;
    if (!txReason.trim()) return;

    setTxSaving(true);
    try {
      await addDoc(collection(db, "cash_transactions"), {
        userId: currentEmployee.id,
        userName: currentEmployee.name,
        type: txType,
        amount,
        reason: txReason.trim(),
        date: new Date().toISOString(),
      });
      setShowTransactionModal(false);
      setTxAmount("");
      setTxReason("");
      setTxType("entrada");
      await loadData();
    } catch (err) {
      console.error("Error saving transaction:", err);
    } finally {
      setTxSaving(false);
    }
  }

  async function handleSaveArqueo() {
    if (!currentEmployee) return;
    const counted = parseFloat(countedAmount);
    if (isNaN(counted)) return;

    setArqueoSaving(true);
    try {
      const now = new Date();
      await addDoc(collection(db, "arqueos"), {
        expectedAmount: balance,
        countedAmount: counted,
        amount: counted,
        userId: currentEmployee.id,
        date: Timestamp.fromDate(now),
      });

      // Update initial_amount with counted value
      await setDoc(doc(db, "config", "initial_amount"), {
        amount: counted,
        updatedAt: now.toISOString(),
      });

      setShowArqueoModal(false);
      setCountedAmount("");
      await loadData();
    } catch (err) {
      console.error("Error saving arqueo:", err);
    } finally {
      setArqueoSaving(false);
    }
  }

  async function handleOpenHistory() {
    setShowHistoryModal(true);
    setHistoryLoading(true);
    try {
      const snap = await getDocs(
        query(collection(db, "arqueos"), orderBy("date", "desc"), limit(20))
      );
      const history: Arqueo[] = snap.docs.map((d) => ({
        id: d.id,
        ...(d.data() as Omit<Arqueo, "id">),
      }));
      setArqueoHistory(history);
    } catch (err) {
      console.error("Error loading arqueo history:", err);
    } finally {
      setHistoryLoading(false);
    }
  }

  if (!currentEmployee) return null;

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-red-700 text-white px-4 py-4 flex items-center gap-3 shadow-md">
        <button
          onClick={() => router.push("/dashboard")}
          className="p-1 rounded-lg hover:bg-red-600 transition-colors"
        >
          <ArrowLeft size={22} />
        </button>
        <h1 className="text-xl font-bold flex-1">Caja</h1>
        {isAdminOrEncargado && (
          <button
            onClick={handleOpenHistory}
            className="p-2 rounded-lg hover:bg-red-600 transition-colors"
            title="Historial de arqueos"
          >
            <History size={20} />
          </button>
        )}
      </div>

      <div className="max-w-lg mx-auto px-4 py-6 space-y-5">
        {loading ? (
          <div className="flex items-center justify-center py-16">
            <div className="w-8 h-8 border-4 border-red-600 border-t-transparent rounded-full animate-spin" />
          </div>
        ) : (
          <>
            {/* Balance card */}
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
              <p className="text-sm text-gray-500 mb-1">Saldo actual</p>
              <p className="text-4xl font-bold text-gray-900">
                {formatCurrency(balance)}
              </p>
              <p className="text-xs text-gray-400 mt-2">
                Fondo inicial: {formatCurrency(initialAmount)}
              </p>
            </div>

            {/* Action buttons */}
            <div className="flex gap-3">
              <button
                onClick={() => setShowTransactionModal(true)}
                className="flex-1 flex items-center justify-center gap-2 bg-red-600 text-white py-3 rounded-xl font-semibold hover:bg-red-700 active:scale-95 transition-all shadow-sm"
              >
                <Plus size={18} />
                Añadir movimiento
              </button>
              {isAdminOrEncargado && (
                <button
                  onClick={() => setShowArqueoModal(true)}
                  className="flex items-center justify-center gap-2 bg-white border border-gray-200 text-gray-700 py-3 px-4 rounded-xl font-semibold hover:bg-gray-50 active:scale-95 transition-all shadow-sm"
                >
                  <Calculator size={18} />
                  Arqueo
                </button>
              )}
            </div>

            {/* Today's transactions */}
            <div>
              <h2 className="text-base font-semibold text-gray-700 mb-3">
                Movimientos de hoy
              </h2>
              {todayTransactions.length === 0 ? (
                <div className="bg-white rounded-2xl border border-gray-100 p-6 text-center text-gray-400 text-sm">
                  No hay movimientos hoy
                </div>
              ) : (
                <div className="space-y-2">
                  {todayTransactions.map((tx) => (
                    <div
                      key={tx.id}
                      className="bg-white rounded-xl border border-gray-100 p-4 flex items-center gap-3 shadow-sm"
                    >
                      <div
                        className={`w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0 ${
                          tx.type === "entrada"
                            ? "bg-green-100 text-green-600"
                            : "bg-red-100 text-red-600"
                        }`}
                      >
                        {tx.type === "entrada" ? (
                          <TrendingUp size={18} />
                        ) : (
                          <TrendingDown size={18} />
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <span
                            className={`text-xs font-semibold px-2 py-0.5 rounded-full ${
                              tx.type === "entrada"
                                ? "bg-green-100 text-green-700"
                                : "bg-red-100 text-red-700"
                            }`}
                          >
                            {tx.type === "entrada" ? "Entrada" : "Salida"}
                          </span>
                          <span className="text-xs text-gray-400">
                            {formatTime(tx.date)}
                          </span>
                        </div>
                        <p className="text-sm text-gray-700 mt-0.5 truncate">
                          {tx.reason}
                        </p>
                        <p className="text-xs text-gray-400">{tx.userName}</p>
                      </div>
                      <p
                        className={`font-bold text-base flex-shrink-0 ${
                          tx.type === "entrada"
                            ? "text-green-600"
                            : "text-red-600"
                        }`}
                      >
                        {tx.type === "entrada" ? "+" : "-"}
                        {formatCurrency(tx.amount)}
                      </p>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </>
        )}
      </div>

      {/* Transaction Modal */}
      {showTransactionModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-end sm:items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-md shadow-xl">
            <div className="flex items-center justify-between p-5 border-b border-gray-100">
              <h3 className="text-lg font-bold text-gray-900">
                Nuevo movimiento
              </h3>
              <button
                onClick={() => {
                  setShowTransactionModal(false);
                  setTxAmount("");
                  setTxReason("");
                  setTxType("entrada");
                }}
                className="p-1.5 rounded-lg hover:bg-gray-100 transition-colors"
              >
                <X size={20} className="text-gray-500" />
              </button>
            </div>
            <div className="p-5 space-y-4">
              {/* Type selector */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Tipo
                </label>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    onClick={() => setTxType("entrada")}
                    className={`flex items-center justify-center gap-2 py-3 rounded-xl font-semibold border-2 transition-all ${
                      txType === "entrada"
                        ? "border-green-500 bg-green-50 text-green-700"
                        : "border-gray-200 text-gray-500"
                    }`}
                  >
                    <TrendingUp size={16} />
                    Entrada
                  </button>
                  <button
                    onClick={() => setTxType("salida")}
                    className={`flex items-center justify-center gap-2 py-3 rounded-xl font-semibold border-2 transition-all ${
                      txType === "salida"
                        ? "border-red-500 bg-red-50 text-red-700"
                        : "border-gray-200 text-gray-500"
                    }`}
                  >
                    <TrendingDown size={16} />
                    Salida
                  </button>
                </div>
              </div>

              {/* Amount */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  Importe (€)
                </label>
                <input
                  type="number"
                  min="0"
                  step="0.01"
                  value={txAmount}
                  onChange={(e) => setTxAmount(e.target.value)}
                  placeholder="0.00"
                  className="w-full border border-gray-200 rounded-xl px-4 py-3 text-lg font-semibold text-gray-900 focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-transparent"
                />
              </div>

              {/* Reason */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  Motivo
                </label>
                <input
                  type="text"
                  value={txReason}
                  onChange={(e) => setTxReason(e.target.value)}
                  placeholder="Descripción del movimiento"
                  className="w-full border border-gray-200 rounded-xl px-4 py-3 text-gray-900 focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-transparent"
                />
              </div>

              <button
                onClick={handleSaveTransaction}
                disabled={
                  txSaving ||
                  !txAmount ||
                  parseFloat(txAmount) <= 0 ||
                  !txReason.trim()
                }
                className="w-full bg-red-600 text-white py-3.5 rounded-xl font-semibold hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                {txSaving ? "Guardando..." : "Guardar movimiento"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Arqueo Modal */}
      {showArqueoModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-end sm:items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-md shadow-xl">
            <div className="flex items-center justify-between p-5 border-b border-gray-100">
              <h3 className="text-lg font-bold text-gray-900">Arqueo de caja</h3>
              <button
                onClick={() => {
                  setShowArqueoModal(false);
                  setCountedAmount("");
                }}
                className="p-1.5 rounded-lg hover:bg-gray-100 transition-colors"
              >
                <X size={20} className="text-gray-500" />
              </button>
            </div>
            <div className="p-5 space-y-4">
              <div className="bg-gray-50 rounded-xl p-4">
                <p className="text-sm text-gray-500 mb-1">Importe esperado</p>
                <p className="text-2xl font-bold text-gray-900">
                  {formatCurrency(balance)}
                </p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  Importe contado (€)
                </label>
                <input
                  type="number"
                  min="0"
                  step="0.01"
                  value={countedAmount}
                  onChange={(e) => setCountedAmount(e.target.value)}
                  placeholder="0.00"
                  className="w-full border border-gray-200 rounded-xl px-4 py-3 text-lg font-semibold text-gray-900 focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-transparent"
                />
              </div>

              {countedAmount && !isNaN(parseFloat(countedAmount)) && (
                <div
                  className={`rounded-xl p-3 text-sm font-medium ${
                    parseFloat(countedAmount) - balance >= 0
                      ? "bg-green-50 text-green-700"
                      : "bg-red-50 text-red-700"
                  }`}
                >
                  Diferencia:{" "}
                  {parseFloat(countedAmount) - balance >= 0 ? "+" : ""}
                  {formatCurrency(parseFloat(countedAmount) - balance)}
                </div>
              )}

              <button
                onClick={handleSaveArqueo}
                disabled={
                  arqueoSaving ||
                  !countedAmount ||
                  isNaN(parseFloat(countedAmount))
                }
                className="w-full bg-red-600 text-white py-3.5 rounded-xl font-semibold hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                {arqueoSaving ? "Guardando..." : "Confirmar arqueo"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* History Modal */}
      {showHistoryModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-end sm:items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-md shadow-xl max-h-[80vh] flex flex-col">
            <div className="flex items-center justify-between p-5 border-b border-gray-100 flex-shrink-0">
              <h3 className="text-lg font-bold text-gray-900">
                Historial de arqueos
              </h3>
              <button
                onClick={() => setShowHistoryModal(false)}
                className="p-1.5 rounded-lg hover:bg-gray-100 transition-colors"
              >
                <X size={20} className="text-gray-500" />
              </button>
            </div>
            <div className="overflow-y-auto flex-1 p-5 space-y-3">
              {historyLoading ? (
                <div className="flex items-center justify-center py-10">
                  <div className="w-7 h-7 border-4 border-red-600 border-t-transparent rounded-full animate-spin" />
                </div>
              ) : arqueoHistory.length === 0 ? (
                <p className="text-center text-gray-400 text-sm py-8">
                  No hay arqueos registrados
                </p>
              ) : (
                arqueoHistory.map((arqueo) => {
                  const diff = arqueo.countedAmount - arqueo.expectedAmount;
                  return (
                    <div
                      key={arqueo.id}
                      className="bg-gray-50 rounded-xl p-4 space-y-2"
                    >
                      <div className="flex items-center justify-between">
                        <p className="text-sm font-semibold text-gray-800">
                          {formatTimestamp(arqueo.date)}
                        </p>
                        <span
                          className={`text-xs font-semibold px-2 py-0.5 rounded-full ${
                            diff >= 0
                              ? "bg-green-100 text-green-700"
                              : "bg-red-100 text-red-700"
                          }`}
                        >
                          {diff >= 0 ? "+" : ""}
                          {formatCurrency(diff)}
                        </span>
                      </div>
                      <div className="grid grid-cols-2 gap-2 text-xs text-gray-500">
                        <div>
                          <span className="block text-gray-400">Esperado</span>
                          <span className="font-medium text-gray-700">
                            {formatCurrency(arqueo.expectedAmount)}
                          </span>
                        </div>
                        <div>
                          <span className="block text-gray-400">Contado</span>
                          <span className="font-medium text-gray-700">
                            {formatCurrency(arqueo.countedAmount)}
                          </span>
                        </div>
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
