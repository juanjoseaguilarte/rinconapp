"use client";

import { useEffect, useState, useCallback } from "react";
import {
  collection,
  getDocs,
  setDoc,
  deleteDoc,
  doc,
  Timestamp,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { Employee } from "@/types";
import { useAuthStore } from "@/stores/authStore";
import { useRouter } from "next/navigation";
import {
  startOfWeek,
  endOfWeek,
  addWeeks,
  subWeeks,
  format,
  eachDayOfInterval,
} from "date-fns";
import { es } from "date-fns/locale";
import { ArrowLeft, ChevronLeft, ChevronRight, Plus, X, Trash2 } from "lucide-react";
import Link from "next/link";

// ─── Types ──────────────────────────────────────────────────────────────────

type Period = "manana" | "tarde";

interface ShiftDoc {
  id: string; // {employeeId}_{YYYY-MM-DD}_{period}
  employeeId: string;
  employeeName: string;
  date: Timestamp;
  period: Period;
  entryTime: string;
  isImaginaria: boolean;
}

// ─── Constants ───────────────────────────────────────────────────────────────

const ENTRY_TIMES = [
  "12:00",
  "12:30",
  "13:00",
  "13:30",
  "14:00",
  "19:30",
  "20:00",
  "20:30",
  "21:00",
  "LIBRE",
];

const PERIOD_LABELS: Record<Period, string> = {
  manana: "Mañana",
  tarde: "Tarde",
};

// ─── Main Component ──────────────────────────────────────────────────────────

export default function ShiftsPage() {
  const { currentEmployee, isAuthenticated } = useAuthStore();
  const router = useRouter();

  const [weekBase, setWeekBase] = useState<Date>(new Date());
  const [shifts, setShifts] = useState<ShiftDoc[]>([]);
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [loading, setLoading] = useState(true);

  // Edit modal state
  const [editModal, setEditModal] = useState<{
    shift: ShiftDoc | null;
    dayStr: string;
    period: Period;
  } | null>(null);
  const [editEntryTime, setEditEntryTime] = useState("12:00");
  const [editIsImaginaria, setEditIsImaginaria] = useState(false);
  const [saving, setSaving] = useState(false);

  // Add modal state
  const [addModal, setAddModal] = useState<{
    dayStr: string;
    period: Period;
  } | null>(null);
  const [addEmployeeId, setAddEmployeeId] = useState("");
  const [addEntryTime, setAddEntryTime] = useState("12:00");
  const [addIsImaginaria, setAddIsImaginaria] = useState(false);

  const canEdit =
    currentEmployee?.role === "Admin" ||
    currentEmployee?.role === "Encargado" ||
    currentEmployee?.role === "SuperAdmin";

  // ── Auth guard ─────────────────────────────────────────────────────────────

  useEffect(() => {
    if (!isAuthenticated) router.replace("/login");
  }, [isAuthenticated, router]);

  // ── Derived week days ──────────────────────────────────────────────────────

  const weekStart = startOfWeek(weekBase, { weekStartsOn: 1 });
  const weekEnd = endOfWeek(weekBase, { weekStartsOn: 1 });
  const weekDays = eachDayOfInterval({ start: weekStart, end: weekEnd });

  // ── Fetch ──────────────────────────────────────────────────────────────────

  const fetchData = useCallback(async () => {
    setLoading(true);
    const [shiftsSnap, empSnap] = await Promise.all([
      getDocs(collection(db, "shifts")),
      getDocs(collection(db, "employees")),
    ]);
    setShifts(
      shiftsSnap.docs.map((d) => ({ id: d.id, ...d.data() } as ShiftDoc))
    );
    setEmployees(
      empSnap.docs.map((d) => ({ id: d.id, ...d.data() } as Employee))
    );
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // ── Helpers ────────────────────────────────────────────────────────────────

  function shiftsForDayPeriod(dayStr: string, period: Period): ShiftDoc[] {
    return shifts.filter(
      (s) =>
        format(s.date.toDate(), "yyyy-MM-dd") === dayStr && s.period === period
    );
  }

  function employeesNotInShift(dayStr: string, period: Period): Employee[] {
    const assigned = shiftsForDayPeriod(dayStr, period).map(
      (s) => s.employeeId
    );
    return employees.filter(
      (e) => !assigned.includes(e.id) && e.active !== false
    );
  }

  // ── Open edit modal ────────────────────────────────────────────────────────

  function openEdit(shift: ShiftDoc, dayStr: string, period: Period) {
    if (!canEdit) return;
    setEditModal({ shift, dayStr, period });
    setEditEntryTime(shift.entryTime);
    setEditIsImaginaria(shift.isImaginaria);
  }

  // ── Save edit ──────────────────────────────────────────────────────────────

  async function handleSaveEdit() {
    if (!editModal?.shift) return;
    setSaving(true);
    try {
      await setDoc(
        doc(db, "shifts", editModal.shift.id),
        {
          ...editModal.shift,
          entryTime: editEntryTime,
          isImaginaria: editIsImaginaria,
        },
        { merge: true }
      );
      await fetchData();
      setEditModal(null);
    } finally {
      setSaving(false);
    }
  }

  // ── Delete shift ───────────────────────────────────────────────────────────

  async function handleDelete() {
    if (!editModal?.shift) return;
    setSaving(true);
    try {
      await deleteDoc(doc(db, "shifts", editModal.shift.id));
      await fetchData();
      setEditModal(null);
    } finally {
      setSaving(false);
    }
  }

  // ── Open add modal ─────────────────────────────────────────────────────────

  function openAdd(dayStr: string, period: Period) {
    setAddModal({ dayStr, period });
    setAddEmployeeId("");
    setAddEntryTime("12:00");
    setAddIsImaginaria(false);
  }

  // ── Save add ───────────────────────────────────────────────────────────────

  async function handleSaveAdd() {
    if (!addModal || !addEmployeeId) return;
    const emp = employees.find((e) => e.id === addEmployeeId);
    if (!emp) return;
    setSaving(true);
    try {
      const docId = `${addEmployeeId}_${addModal.dayStr}_${addModal.period}`;
      const [year, month, day] = addModal.dayStr.split("-").map(Number);
      await setDoc(doc(db, "shifts", docId), {
        employeeId: addEmployeeId,
        employeeName: emp.name,
        date: Timestamp.fromDate(new Date(year, month - 1, day)),
        period: addModal.period,
        entryTime: addEntryTime,
        isImaginaria: addIsImaginaria,
      });
      await fetchData();
      setAddModal(null);
    } finally {
      setSaving(false);
    }
  }

  // ── Render ─────────────────────────────────────────────────────────────────

  if (!currentEmployee) return null;

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-red-700 text-white px-4 py-4 flex items-center gap-3 shadow-md">
        <Link href="/dashboard" className="text-red-200 hover:text-white shrink-0">
          <ArrowLeft size={22} />
        </Link>
        <h1 className="text-xl font-bold flex-1">Turnos</h1>
      </div>

      {/* Week navigation */}
      <div className="bg-white border-b px-4 py-3 flex items-center justify-between shadow-sm sticky top-0 z-10">
        <button
          onClick={() => setWeekBase((w) => subWeeks(w, 1))}
          className="p-2 rounded-lg hover:bg-gray-100 text-gray-600 transition-colors"
        >
          <ChevronLeft size={22} />
        </button>
        <span className="font-semibold text-gray-800 text-sm text-center">
          {format(weekStart, "d MMM", { locale: es })} –{" "}
          {format(weekEnd, "d MMM yyyy", { locale: es })}
        </span>
        <button
          onClick={() => setWeekBase((w) => addWeeks(w, 1))}
          className="p-2 rounded-lg hover:bg-gray-100 text-gray-600 transition-colors"
        >
          <ChevronRight size={22} />
        </button>
      </div>

      {/* Calendar body */}
      {loading ? (
        <div className="flex items-center justify-center py-20">
          <p className="text-gray-400 text-sm">Cargando turnos...</p>
        </div>
      ) : (
        <div className="overflow-x-auto">
          <div className="min-w-[700px] p-4 space-y-3">
            {weekDays.map((day) => {
              const dayStr = format(day, "yyyy-MM-dd");
              const dayLabel = format(day, "EEEE d", { locale: es });
              const isToday =
                format(day, "yyyy-MM-dd") === format(new Date(), "yyyy-MM-dd");

              return (
                <div
                  key={dayStr}
                  className={`bg-white rounded-2xl border shadow-sm overflow-hidden
                    ${isToday ? "border-red-300 ring-1 ring-red-200" : "border-gray-200"}`}
                >
                  {/* Day header */}
                  <div
                    className={`px-4 py-2 font-semibold text-sm capitalize
                      ${isToday ? "bg-red-700 text-white" : "bg-gray-50 text-gray-700 border-b"}`}
                  >
                    {dayLabel}
                  </div>

                  {/* Periods */}
                  <div className="divide-y">
                    {(["manana", "tarde"] as Period[]).map((period) => {
                      const periodShifts = shiftsForDayPeriod(dayStr, period);
                      const availableEmployees = employeesNotInShift(
                        dayStr,
                        period
                      );

                      return (
                        <div key={period} className="px-4 py-3">
                          <div className="flex items-center gap-2 mb-2">
                            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
                              {PERIOD_LABELS[period]}
                            </span>
                            {canEdit && availableEmployees.length > 0 && (
                              <button
                                onClick={() => openAdd(dayStr, period)}
                                className="ml-auto flex items-center gap-1 text-xs text-red-600 hover:text-red-800 font-semibold bg-red-50 hover:bg-red-100 px-2 py-1 rounded-lg transition-colors"
                              >
                                <Plus size={13} />
                                Añadir
                              </button>
                            )}
                          </div>

                          {periodShifts.length === 0 ? (
                            <p className="text-xs text-gray-300 italic">
                              Sin turnos asignados
                            </p>
                          ) : (
                            <div className="flex flex-wrap gap-2">
                              {periodShifts.map((s) => (
                                <button
                                  key={s.id}
                                  onClick={() =>
                                    canEdit
                                      ? openEdit(s, dayStr, period)
                                      : undefined
                                  }
                                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold
                                    transition-all
                                    ${
                                      s.isImaginaria
                                        ? "bg-amber-100 text-amber-800 border border-amber-300 hover:bg-amber-200"
                                        : "bg-red-50 text-red-800 border border-red-200 hover:bg-red-100"
                                    }
                                    ${canEdit ? "cursor-pointer active:scale-95" : "cursor-default"}`}
                                >
                                  <span>{s.employeeName}</span>
                                  {s.entryTime !== "LIBRE" && (
                                    <span
                                      className={`opacity-70 font-normal
                                        ${s.isImaginaria ? "text-amber-600" : "text-red-500"}`}
                                    >
                                      {s.entryTime}
                                    </span>
                                  )}
                                  {s.entryTime === "LIBRE" && (
                                    <span className="opacity-60 font-normal">
                                      LIBRE
                                    </span>
                                  )}
                                  {s.isImaginaria && (
                                    <span className="text-amber-500">★</span>
                                  )}
                                </button>
                              ))}
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* ── Edit Modal ─────────────────────────────────────────────────────── */}
      {editModal && (
        <div className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-sm p-6 space-y-4 shadow-xl">
            <div className="flex items-center justify-between">
              <h2 className="font-bold text-lg">Editar turno</h2>
              <button
                onClick={() => setEditModal(null)}
                className="p-2 rounded-lg hover:bg-gray-100 text-gray-400"
              >
                <X size={18} />
              </button>
            </div>

            <div className="space-y-1">
              <p className="font-semibold text-gray-800">
                {editModal.shift?.employeeName}
              </p>
              <p className="text-sm text-gray-400 capitalize">
                {PERIOD_LABELS[editModal.period]} ·{" "}
                {format(
                  new Date(editModal.dayStr + "T00:00:00"),
                  "EEEE d MMM",
                  { locale: es }
                )}
              </p>
            </div>

            <div className="space-y-3">
              <div>
                <label className="text-sm font-medium text-gray-700 block mb-1">
                  Hora de entrada
                </label>
                <select
                  value={editEntryTime}
                  onChange={(e) => setEditEntryTime(e.target.value)}
                  className="w-full border rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-red-400"
                >
                  {ENTRY_TIMES.map((t) => (
                    <option key={t} value={t}>
                      {t}
                    </option>
                  ))}
                </select>
              </div>

              <label className="flex items-center gap-3 cursor-pointer select-none">
                <div className="relative">
                  <input
                    type="checkbox"
                    className="sr-only"
                    checked={editIsImaginaria}
                    onChange={(e) => setEditIsImaginaria(e.target.checked)}
                  />
                  <div
                    className={`w-10 h-6 rounded-full transition-colors ${
                      editIsImaginaria ? "bg-amber-400" : "bg-gray-200"
                    }`}
                  />
                  <div
                    className={`absolute top-1 left-1 w-4 h-4 bg-white rounded-full shadow transition-transform ${
                      editIsImaginaria ? "translate-x-4" : "translate-x-0"
                    }`}
                  />
                </div>
                <span className="text-sm font-medium text-gray-700">
                  Imaginaria
                </span>
              </label>
            </div>

            <div className="flex gap-3 pt-1">
              <button
                onClick={handleDelete}
                disabled={saving}
                className="flex items-center gap-1.5 px-4 py-3 rounded-xl border border-red-200 text-red-500 hover:bg-red-50 font-semibold text-sm disabled:opacity-40 transition-colors"
              >
                <Trash2 size={16} />
                Eliminar
              </button>
              <button
                onClick={handleSaveEdit}
                disabled={saving}
                className="flex-1 py-3 rounded-xl bg-red-600 text-white font-bold disabled:opacity-40 hover:bg-red-700 transition-colors"
              >
                {saving ? "Guardando..." : "Guardar"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Add Modal ──────────────────────────────────────────────────────── */}
      {addModal && (
        <div className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-sm p-6 space-y-4 shadow-xl">
            <div className="flex items-center justify-between">
              <h2 className="font-bold text-lg">Añadir turno</h2>
              <button
                onClick={() => setAddModal(null)}
                className="p-2 rounded-lg hover:bg-gray-100 text-gray-400"
              >
                <X size={18} />
              </button>
            </div>

            <p className="text-sm text-gray-400 capitalize">
              {PERIOD_LABELS[addModal.period]} ·{" "}
              {format(new Date(addModal.dayStr + "T00:00:00"), "EEEE d MMM", {
                locale: es,
              })}
            </p>

            <div className="space-y-3">
              <div>
                <label className="text-sm font-medium text-gray-700 block mb-1">
                  Empleado
                </label>
                <select
                  value={addEmployeeId}
                  onChange={(e) => setAddEmployeeId(e.target.value)}
                  className="w-full border rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-red-400"
                >
                  <option value="">Seleccionar empleado...</option>
                  {employeesNotInShift(addModal.dayStr, addModal.period).map(
                    (emp) => (
                      <option key={emp.id} value={emp.id}>
                        {emp.name}
                      </option>
                    )
                  )}
                </select>
              </div>

              <div>
                <label className="text-sm font-medium text-gray-700 block mb-1">
                  Hora de entrada
                </label>
                <select
                  value={addEntryTime}
                  onChange={(e) => setAddEntryTime(e.target.value)}
                  className="w-full border rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-red-400"
                >
                  {ENTRY_TIMES.map((t) => (
                    <option key={t} value={t}>
                      {t}
                    </option>
                  ))}
                </select>
              </div>

              <label className="flex items-center gap-3 cursor-pointer select-none">
                <div className="relative">
                  <input
                    type="checkbox"
                    className="sr-only"
                    checked={addIsImaginaria}
                    onChange={(e) => setAddIsImaginaria(e.target.checked)}
                  />
                  <div
                    className={`w-10 h-6 rounded-full transition-colors ${
                      addIsImaginaria ? "bg-amber-400" : "bg-gray-200"
                    }`}
                  />
                  <div
                    className={`absolute top-1 left-1 w-4 h-4 bg-white rounded-full shadow transition-transform ${
                      addIsImaginaria ? "translate-x-4" : "translate-x-0"
                    }`}
                  />
                </div>
                <span className="text-sm font-medium text-gray-700">
                  Imaginaria
                </span>
              </label>
            </div>

            <div className="flex gap-3 pt-1">
              <button
                onClick={() => setAddModal(null)}
                className="flex-1 py-3 rounded-xl border text-gray-600 hover:bg-gray-50 transition-colors"
              >
                Cancelar
              </button>
              <button
                onClick={handleSaveAdd}
                disabled={saving || !addEmployeeId}
                className="flex-1 py-3 rounded-xl bg-red-600 text-white font-bold disabled:opacity-40 hover:bg-red-700 transition-colors"
              >
                {saving ? "Guardando..." : "Añadir"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
