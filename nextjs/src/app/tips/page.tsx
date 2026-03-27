"use client";

import { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import {
  ArrowLeft,
  Banknote,
  Users,
  CheckCircle,
  Plus,
  X,
  ChevronRight,
} from "lucide-react";
import {
  collection,
  doc,
  getDocs,
  addDoc,
  updateDoc,
  query,
  orderBy,
  writeBatch,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { useAuthStore } from "@/stores/authStore";
import { Employee, ShiftPeriod } from "@/types";

interface EmployeePayment {
  cash: number;
  card: number;
  isDeleted: boolean;
}

interface Tip {
  id: string;
  amount: number;
  date: string;
  shift: ShiftPeriod;
  employeePayments: Record<string, EmployeePayment>;
  adminShare: number;
  isDeleted: boolean;
}

type Tab = "activas" | "crear" | "pagar";

function formatCurrency(amount: number) {
  return new Intl.NumberFormat("es-ES", {
    style: "currency",
    currency: "EUR",
  }).format(amount);
}

function getWeekKey(dateStr: string) {
  const date = new Date(dateStr);
  const startOfYear = new Date(date.getFullYear(), 0, 1);
  const weekNum = Math.ceil(
    ((date.getTime() - startOfYear.getTime()) / 86400000 +
      startOfYear.getDay() +
      1) /
      7
  );
  return `${date.getFullYear()}-W${String(weekNum).padStart(2, "0")}`;
}

function getWeekRange(weekKey: string) {
  const [year, week] = weekKey.split("-W").map(Number);
  const jan1 = new Date(year, 0, 1);
  const dayOfWeek = jan1.getDay() || 7;
  const mondayOfWeek1 = new Date(jan1);
  mondayOfWeek1.setDate(jan1.getDate() - (dayOfWeek - 1));
  const monday = new Date(mondayOfWeek1);
  monday.setDate(mondayOfWeek1.getDate() + (week - 1) * 7);
  const sunday = new Date(monday);
  sunday.setDate(monday.getDate() + 6);
  const fmt = (d: Date) =>
    d.toLocaleDateString("es-ES", { day: "2-digit", month: "2-digit" });
  return `${fmt(monday)} – ${fmt(sunday)}`;
}

const SHIFT_LABELS: Record<ShiftPeriod, string> = {
  mañana: "Mañana",
  tarde: "Tarde",
  noche: "Noche",
};

const SHIFT_COLORS: Record<ShiftPeriod, string> = {
  mañana: "bg-yellow-100 text-yellow-700",
  tarde: "bg-orange-100 text-orange-700",
  noche: "bg-indigo-100 text-indigo-700",
};

export default function TipsPage() {
  const router = useRouter();
  const { currentEmployee, isAuthenticated } = useAuthStore();

  const [activeTab, setActiveTab] = useState<Tab>("activas");
  const [tips, setTips] = useState<Tip[]>([]);
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [loading, setLoading] = useState(true);

  // Detail modal for a tip
  const [selectedTip, setSelectedTip] = useState<Tip | null>(null);

  // Create tip form
  const [createAmount, setCreateAmount] = useState("");
  const [createShift, setCreateShift] = useState<ShiftPeriod>("mañana");
  const [createDate, setCreateDate] = useState(
    new Date().toISOString().slice(0, 10)
  );
  const [selectedEmployeeIds, setSelectedEmployeeIds] = useState<Set<string>>(
    new Set()
  );
  const [adminSharePct, setAdminSharePct] = useState("0");
  const [createSaving, setCreateSaving] = useState(false);

  const isAdminOrEncargado =
    currentEmployee?.role === "Admin" ||
    currentEmployee?.role === "Encargado" ||
    currentEmployee?.role === "SuperAdmin";

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [tipsSnap, empSnap] = await Promise.all([
        getDocs(query(collection(db, "tips"), orderBy("date", "desc"))),
        getDocs(collection(db, "employees")),
      ]);

      const tipsData: Tip[] = tipsSnap.docs.map((d) => ({
        id: d.id,
        ...(d.data() as Omit<Tip, "id">),
      }));
      setTips(tipsData);

      const empsData: Employee[] = empSnap.docs.map((d) => ({
        id: d.id,
        ...(d.data() as Omit<Employee, "id">),
      }));
      setEmployees(empsData.filter((e) => e.active !== false));
    } catch (err) {
      console.error("Error loading tips data:", err);
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

  const activeTips = tips.filter((t) => !t.isDeleted);

  // Group active tips by week
  const tipsByWeek: Record<string, Tip[]> = {};
  for (const tip of activeTips) {
    const wk = getWeekKey(tip.date);
    if (!tipsByWeek[wk]) tipsByWeek[wk] = [];
    tipsByWeek[wk].push(tip);
  }
  const sortedWeeks = Object.keys(tipsByWeek).sort((a, b) =>
    b.localeCompare(a)
  );

  // Current week unpaid tips
  const todayWeek = getWeekKey(new Date().toISOString().slice(0, 10));
  const currentWeekTips = activeTips.filter(
    (t) => getWeekKey(t.date) === todayWeek
  );

  // Per-employee totals for current week
  const employeeTotals: Record<string, number> = {};
  for (const tip of currentWeekTips) {
    for (const [empId, payment] of Object.entries(tip.employeePayments)) {
      if (!payment.isDeleted) {
        employeeTotals[empId] =
          (employeeTotals[empId] ?? 0) + payment.cash + payment.card;
      }
    }
  }

  function getTipEmployeeCount(tip: Tip) {
    return Object.keys(tip.employeePayments).length;
  }

  function getTipPerEmployee(tip: Tip) {
    const count = getTipEmployeeCount(tip);
    if (count === 0) return 0;
    const adminShareAmt = (tip.adminShare / 100) * tip.amount;
    return (tip.amount - adminShareAmt) / count;
  }

  function toggleEmployee(id: string) {
    setSelectedEmployeeIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  }

  async function handleCreateTip() {
    if (!currentEmployee) return;
    const amount = parseFloat(createAmount);
    if (isNaN(amount) || amount <= 0) return;
    if (selectedEmployeeIds.size === 0) return;

    setCreateSaving(true);
    try {
      const adminPct = parseFloat(adminSharePct) || 0;
      const adminShareAmt = (adminPct / 100) * amount;
      const remaining = amount - adminShareAmt;
      const perEmployee = remaining / selectedEmployeeIds.size;

      const employeePayments: Record<string, EmployeePayment> = {};
      for (const empId of selectedEmployeeIds) {
        employeePayments[empId] = {
          cash: perEmployee,
          card: 0,
          isDeleted: false,
        };
      }

      await addDoc(collection(db, "tips"), {
        amount,
        date: createDate,
        shift: createShift,
        employeePayments,
        adminShare: adminPct,
        isDeleted: false,
      });

      setCreateAmount("");
      setCreateShift("mañana");
      setCreateDate(new Date().toISOString().slice(0, 10));
      setSelectedEmployeeIds(new Set());
      setAdminSharePct("0");
      setActiveTab("activas");
      await loadData();
    } catch (err) {
      console.error("Error creating tip:", err);
    } finally {
      setCreateSaving(false);
    }
  }

  async function handlePayEmployee(empId: string) {
    // Mark employeePayments[empId].isDeleted = true across all current week tips
    const batch = writeBatch(db);
    for (const tip of currentWeekTips) {
      if (tip.employeePayments[empId] && !tip.employeePayments[empId].isDeleted) {
        const tipRef = doc(db, "tips", tip.id);
        batch.update(tipRef, {
          [`employeePayments.${empId}.isDeleted`]: true,
        });
      }
    }
    await batch.commit();
    await loadData();
  }

  async function handlePayAll() {
    const batch = writeBatch(db);
    for (const tip of currentWeekTips) {
      const tipRef = doc(db, "tips", tip.id);
      batch.update(tipRef, { isDeleted: true });
    }
    await batch.commit();
    await loadData();
  }

  async function handlePayTipEmployee(tip: Tip, empId: string) {
    await updateDoc(doc(db, "tips", tip.id), {
      [`employeePayments.${empId}.isDeleted`]: true,
    });
    await loadData();
    // Refresh selected tip
    const updated = tips.find((t) => t.id === tip.id);
    if (updated) setSelectedTip(updated);
  }

  if (!currentEmployee) return null;

  const tabs: { id: Tab; label: string }[] = [
    { id: "activas", label: "Activas" },
    ...(isAdminOrEncargado
      ? [
          { id: "crear" as Tab, label: "Crear" },
          { id: "pagar" as Tab, label: "Pagar semana" },
        ]
      : []),
  ];

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
        <h1 className="text-xl font-bold flex-1">Propinas</h1>
      </div>

      {/* Tabs */}
      <div className="bg-white border-b border-gray-200 px-4">
        <div className="flex gap-1 max-w-lg mx-auto">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`px-4 py-3.5 text-sm font-semibold border-b-2 transition-colors ${
                activeTab === tab.id
                  ? "border-red-600 text-red-600"
                  : "border-transparent text-gray-500 hover:text-gray-700"
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      <div className="max-w-lg mx-auto px-4 py-6">
        {loading ? (
          <div className="flex items-center justify-center py-16">
            <div className="w-8 h-8 border-4 border-red-600 border-t-transparent rounded-full animate-spin" />
          </div>
        ) : (
          <>
            {/* Tab: Activas */}
            {activeTab === "activas" && (
              <div className="space-y-5">
                {/* Total pending */}
                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
                  <p className="text-sm text-gray-500 mb-1">Total pendiente</p>
                  <p className="text-3xl font-bold text-gray-900">
                    {formatCurrency(
                      activeTips.reduce((sum, t) => sum + t.amount, 0)
                    )}
                  </p>
                  <p className="text-xs text-gray-400 mt-1">
                    {activeTips.length} propina
                    {activeTips.length !== 1 ? "s" : ""} activa
                    {activeTips.length !== 1 ? "s" : ""}
                  </p>
                </div>

                {sortedWeeks.length === 0 ? (
                  <div className="bg-white rounded-2xl border border-gray-100 p-8 text-center text-gray-400 text-sm">
                    No hay propinas activas
                  </div>
                ) : (
                  sortedWeeks.map((week) => (
                    <div key={week}>
                      <div className="flex items-center justify-between mb-2">
                        <h2 className="text-sm font-semibold text-gray-500 uppercase tracking-wide">
                          Semana {getWeekRange(week)}
                        </h2>
                        <span className="text-sm font-semibold text-gray-700">
                          {formatCurrency(
                            tipsByWeek[week].reduce(
                              (sum, t) => sum + t.amount,
                              0
                            )
                          )}
                        </span>
                      </div>
                      <div className="space-y-2">
                        {tipsByWeek[week].map((tip) => (
                          <button
                            key={tip.id}
                            onClick={() =>
                              isAdminOrEncargado && setSelectedTip(tip)
                            }
                            className={`w-full bg-white rounded-xl border border-gray-100 p-4 shadow-sm text-left ${
                              isAdminOrEncargado
                                ? "hover:border-red-200 active:scale-[0.99] transition-all"
                                : ""
                            }`}
                          >
                            <div className="flex items-center justify-between">
                              <div className="flex items-center gap-2">
                                <span
                                  className={`text-xs font-semibold px-2 py-0.5 rounded-full ${
                                    SHIFT_COLORS[tip.shift]
                                  }`}
                                >
                                  {SHIFT_LABELS[tip.shift]}
                                </span>
                                <span className="text-xs text-gray-400">
                                  {new Date(tip.date).toLocaleDateString(
                                    "es-ES",
                                    {
                                      weekday: "short",
                                      day: "2-digit",
                                      month: "2-digit",
                                    }
                                  )}
                                </span>
                              </div>
                              <div className="flex items-center gap-2">
                                <p className="font-bold text-gray-900">
                                  {formatCurrency(tip.amount)}
                                </p>
                                {isAdminOrEncargado && (
                                  <ChevronRight
                                    size={14}
                                    className="text-gray-400"
                                  />
                                )}
                              </div>
                            </div>
                            <div className="flex items-center gap-3 mt-2 text-xs text-gray-500">
                              <span className="flex items-center gap-1">
                                <Users size={12} />
                                {getTipEmployeeCount(tip)} empleados
                              </span>
                              <span>
                                {formatCurrency(getTipPerEmployee(tip))} /
                                persona
                              </span>
                            </div>
                          </button>
                        ))}
                      </div>
                    </div>
                  ))
                )}
              </div>
            )}

            {/* Tab: Crear */}
            {activeTab === "crear" && isAdminOrEncargado && (
              <div className="space-y-4">
                <h2 className="text-base font-bold text-gray-800">
                  Nueva propina
                </h2>

                {/* Amount */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">
                    Importe total (€)
                  </label>
                  <input
                    type="number"
                    min="0"
                    step="0.01"
                    value={createAmount}
                    onChange={(e) => setCreateAmount(e.target.value)}
                    placeholder="0.00"
                    className="w-full border border-gray-200 rounded-xl px-4 py-3 text-lg font-semibold text-gray-900 focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-transparent"
                  />
                </div>

                {/* Date */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">
                    Fecha
                  </label>
                  <input
                    type="date"
                    value={createDate}
                    onChange={(e) => setCreateDate(e.target.value)}
                    className="w-full border border-gray-200 rounded-xl px-4 py-3 text-gray-900 focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-transparent"
                  />
                </div>

                {/* Shift */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Turno
                  </label>
                  <div className="grid grid-cols-3 gap-2">
                    {(["mañana", "tarde", "noche"] as ShiftPeriod[]).map(
                      (s) => (
                        <button
                          key={s}
                          onClick={() => setCreateShift(s)}
                          className={`py-2.5 rounded-xl text-sm font-semibold border-2 transition-all ${
                            createShift === s
                              ? "border-red-500 bg-red-50 text-red-700"
                              : "border-gray-200 text-gray-500"
                          }`}
                        >
                          {SHIFT_LABELS[s]}
                        </button>
                      )
                    )}
                  </div>
                </div>

                {/* Admin share */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">
                    Parte del encargado (%)
                  </label>
                  <input
                    type="number"
                    min="0"
                    max="100"
                    step="1"
                    value={adminSharePct}
                    onChange={(e) => setAdminSharePct(e.target.value)}
                    placeholder="0"
                    className="w-full border border-gray-200 rounded-xl px-4 py-3 text-gray-900 focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-transparent"
                  />
                </div>

                {/* Employee selector */}
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <label className="text-sm font-medium text-gray-700">
                      Empleados
                    </label>
                    <button
                      onClick={() => {
                        if (selectedEmployeeIds.size === employees.length) {
                          setSelectedEmployeeIds(new Set());
                        } else {
                          setSelectedEmployeeIds(
                            new Set(employees.map((e) => e.id))
                          );
                        }
                      }}
                      className="text-xs text-red-600 font-medium"
                    >
                      {selectedEmployeeIds.size === employees.length
                        ? "Deseleccionar todos"
                        : "Seleccionar todos"}
                    </button>
                  </div>
                  <div className="bg-white rounded-xl border border-gray-200 divide-y divide-gray-100 overflow-hidden">
                    {employees.length === 0 ? (
                      <p className="text-sm text-gray-400 text-center py-4">
                        No hay empleados
                      </p>
                    ) : (
                      employees.map((emp) => {
                        const selected = selectedEmployeeIds.has(emp.id);
                        const amount = parseFloat(createAmount) || 0;
                        const adminAmt =
                          ((parseFloat(adminSharePct) || 0) / 100) * amount;
                        const perPerson =
                          selectedEmployeeIds.size > 0
                            ? (amount - adminAmt) / selectedEmployeeIds.size
                            : 0;
                        return (
                          <button
                            key={emp.id}
                            onClick={() => toggleEmployee(emp.id)}
                            className="w-full flex items-center gap-3 px-4 py-3 hover:bg-gray-50 transition-colors text-left"
                          >
                            <div
                              className={`w-5 h-5 rounded-full border-2 flex items-center justify-center flex-shrink-0 transition-colors ${
                                selected
                                  ? "border-red-600 bg-red-600"
                                  : "border-gray-300"
                              }`}
                            >
                              {selected && (
                                <CheckCircle
                                  size={12}
                                  className="text-white fill-white"
                                />
                              )}
                            </div>
                            <div className="flex-1">
                              <p className="text-sm font-medium text-gray-800">
                                {emp.name}
                              </p>
                              <p className="text-xs text-gray-400">
                                {emp.position}
                              </p>
                            </div>
                            {selected && amount > 0 && (
                              <span className="text-sm font-semibold text-green-600">
                                {formatCurrency(perPerson)}
                              </span>
                            )}
                          </button>
                        );
                      })
                    )}
                  </div>
                </div>

                {/* Summary */}
                {createAmount && selectedEmployeeIds.size > 0 && (
                  <div className="bg-green-50 rounded-xl p-4 text-sm space-y-1">
                    <div className="flex justify-between text-gray-600">
                      <span>Total propina</span>
                      <span className="font-semibold">
                        {formatCurrency(parseFloat(createAmount) || 0)}
                      </span>
                    </div>
                    {parseFloat(adminSharePct) > 0 && (
                      <div className="flex justify-between text-gray-600">
                        <span>
                          Encargado ({adminSharePct}%)
                        </span>
                        <span className="font-semibold">
                          {formatCurrency(
                            ((parseFloat(adminSharePct) || 0) / 100) *
                              (parseFloat(createAmount) || 0)
                          )}
                        </span>
                      </div>
                    )}
                    <div className="flex justify-between text-green-700 font-bold pt-1 border-t border-green-200">
                      <span>
                        Por empleado ({selectedEmployeeIds.size})
                      </span>
                      <span>
                        {formatCurrency(
                          (() => {
                            const amt = parseFloat(createAmount) || 0;
                            const admin =
                              ((parseFloat(adminSharePct) || 0) / 100) * amt;
                            return (
                              (amt - admin) /
                              (selectedEmployeeIds.size || 1)
                            );
                          })()
                        )}
                      </span>
                    </div>
                  </div>
                )}

                <button
                  onClick={handleCreateTip}
                  disabled={
                    createSaving ||
                    !createAmount ||
                    parseFloat(createAmount) <= 0 ||
                    selectedEmployeeIds.size === 0
                  }
                  className="w-full flex items-center justify-center gap-2 bg-red-600 text-white py-3.5 rounded-xl font-semibold hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  <Plus size={18} />
                  {createSaving ? "Guardando..." : "Crear propina"}
                </button>
              </div>
            )}

            {/* Tab: Pagar semana */}
            {activeTab === "pagar" && isAdminOrEncargado && (
              <div className="space-y-5">
                <div className="flex items-center justify-between">
                  <div>
                    <h2 className="text-base font-bold text-gray-800">
                      Semana actual
                    </h2>
                    <p className="text-xs text-gray-400 mt-0.5">
                      {getWeekRange(todayWeek)}
                    </p>
                  </div>
                  <span className="text-sm font-bold text-gray-900">
                    {formatCurrency(
                      currentWeekTips.reduce((sum, t) => sum + t.amount, 0)
                    )}
                  </span>
                </div>

                {currentWeekTips.length === 0 ? (
                  <div className="bg-white rounded-2xl border border-gray-100 p-8 text-center text-gray-400 text-sm">
                    No hay propinas pendientes esta semana
                  </div>
                ) : (
                  <>
                    {/* Pay all button */}
                    <button
                      onClick={handlePayAll}
                      className="w-full flex items-center justify-center gap-2 bg-red-600 text-white py-3.5 rounded-xl font-semibold hover:bg-red-700 active:scale-95 transition-all shadow-sm"
                    >
                      <CheckCircle size={18} />
                      Pagar todo
                    </button>

                    {/* Per employee */}
                    <div>
                      <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
                        Por empleado
                      </h3>
                      <div className="space-y-2">
                        {Object.entries(employeeTotals)
                          .filter(([, total]) => total > 0)
                          .sort(([, a], [, b]) => b - a)
                          .map(([empId, total]) => {
                            const emp = employees.find((e) => e.id === empId);
                            return (
                              <div
                                key={empId}
                                className="bg-white rounded-xl border border-gray-100 p-4 flex items-center gap-3 shadow-sm"
                              >
                                <div className="w-10 h-10 rounded-full bg-red-100 flex items-center justify-center flex-shrink-0">
                                  <span className="text-red-700 font-bold text-sm">
                                    {emp?.name.charAt(0).toUpperCase() ?? "?"}
                                  </span>
                                </div>
                                <div className="flex-1 min-w-0">
                                  <p className="font-semibold text-gray-800 text-sm">
                                    {emp?.name ?? empId}
                                  </p>
                                  <p className="text-xs text-gray-400">
                                    {emp?.position}
                                  </p>
                                </div>
                                <div className="flex items-center gap-3">
                                  <span className="font-bold text-gray-900">
                                    {formatCurrency(total)}
                                  </span>
                                  <button
                                    onClick={() => handlePayEmployee(empId)}
                                    className="flex items-center gap-1.5 bg-green-600 text-white px-3 py-1.5 rounded-lg text-xs font-semibold hover:bg-green-700 active:scale-95 transition-all"
                                  >
                                    <Banknote size={14} />
                                    Pagar
                                  </button>
                                </div>
                              </div>
                            );
                          })}
                      </div>
                    </div>

                    {/* Tips list */}
                    <div>
                      <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
                        Propinas de la semana
                      </h3>
                      <div className="space-y-2">
                        {currentWeekTips.map((tip) => (
                          <div
                            key={tip.id}
                            className="bg-white rounded-xl border border-gray-100 p-4 shadow-sm"
                          >
                            <div className="flex items-center justify-between">
                              <div className="flex items-center gap-2">
                                <span
                                  className={`text-xs font-semibold px-2 py-0.5 rounded-full ${
                                    SHIFT_COLORS[tip.shift]
                                  }`}
                                >
                                  {SHIFT_LABELS[tip.shift]}
                                </span>
                                <span className="text-xs text-gray-400">
                                  {new Date(tip.date).toLocaleDateString(
                                    "es-ES",
                                    { weekday: "short", day: "2-digit", month: "2-digit" }
                                  )}
                                </span>
                              </div>
                              <span className="font-bold text-gray-900">
                                {formatCurrency(tip.amount)}
                              </span>
                            </div>
                            <div className="mt-2 space-y-1">
                              {Object.entries(tip.employeePayments).map(
                                ([empId, payment]) => {
                                  const emp = employees.find(
                                    (e) => e.id === empId
                                  );
                                  return (
                                    <div
                                      key={empId}
                                      className="flex items-center justify-between text-xs"
                                    >
                                      <span
                                        className={`${
                                          payment.isDeleted
                                            ? "line-through text-gray-300"
                                            : "text-gray-600"
                                        }`}
                                      >
                                        {emp?.name ?? empId}
                                      </span>
                                      <span
                                        className={`font-medium ${
                                          payment.isDeleted
                                            ? "text-gray-300"
                                            : "text-gray-800"
                                        }`}
                                      >
                                        {formatCurrency(
                                          payment.cash + payment.card
                                        )}
                                        {payment.isDeleted && " ✓"}
                                      </span>
                                    </div>
                                  );
                                }
                              )}
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  </>
                )}
              </div>
            )}
          </>
        )}
      </div>

      {/* Tip detail modal */}
      {selectedTip && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-end sm:items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-md shadow-xl max-h-[85vh] flex flex-col">
            <div className="flex items-center justify-between p-5 border-b border-gray-100 flex-shrink-0">
              <div>
                <h3 className="text-lg font-bold text-gray-900">
                  Detalle propina
                </h3>
                <p className="text-sm text-gray-400">
                  {new Date(selectedTip.date).toLocaleDateString("es-ES", {
                    weekday: "long",
                    day: "2-digit",
                    month: "long",
                  })}{" "}
                  · {SHIFT_LABELS[selectedTip.shift]}
                </p>
              </div>
              <button
                onClick={() => setSelectedTip(null)}
                className="p-1.5 rounded-lg hover:bg-gray-100 transition-colors"
              >
                <X size={20} className="text-gray-500" />
              </button>
            </div>
            <div className="p-5 overflow-y-auto flex-1 space-y-4">
              <div className="bg-gray-50 rounded-xl p-4 flex justify-between items-center">
                <span className="text-sm text-gray-500">Total propina</span>
                <span className="text-xl font-bold text-gray-900">
                  {formatCurrency(selectedTip.amount)}
                </span>
              </div>

              <div>
                <h4 className="text-sm font-semibold text-gray-600 mb-2">
                  Empleados
                </h4>
                <div className="space-y-2">
                  {Object.entries(selectedTip.employeePayments).map(
                    ([empId, payment]) => {
                      const emp = employees.find((e) => e.id === empId);
                      return (
                        <div
                          key={empId}
                          className={`flex items-center gap-3 p-3 rounded-xl border transition-colors ${
                            payment.isDeleted
                              ? "bg-green-50 border-green-200"
                              : "bg-white border-gray-200"
                          }`}
                        >
                          <div className="flex-1 min-w-0">
                            <p
                              className={`text-sm font-medium ${
                                payment.isDeleted
                                  ? "text-green-700 line-through"
                                  : "text-gray-800"
                              }`}
                            >
                              {emp?.name ?? empId}
                            </p>
                            <p className="text-xs text-gray-400">
                              {formatCurrency(payment.cash + payment.card)}
                            </p>
                          </div>
                          {payment.isDeleted ? (
                            <span className="flex items-center gap-1 text-xs text-green-600 font-medium">
                              <CheckCircle size={14} />
                              Pagado
                            </span>
                          ) : (
                            <button
                              onClick={() =>
                                handlePayTipEmployee(selectedTip, empId)
                              }
                              className="flex items-center gap-1.5 bg-red-600 text-white px-3 py-1.5 rounded-lg text-xs font-semibold hover:bg-red-700 active:scale-95 transition-all"
                            >
                              <Banknote size={13} />
                              Pagar
                            </button>
                          )}
                        </div>
                      );
                    }
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
