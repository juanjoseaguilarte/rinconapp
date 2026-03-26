"use client";

import { useEffect, useState } from "react";
import {
  collection,
  getDocs,
  addDoc,
  updateDoc,
  doc,
  serverTimestamp,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { Employee, Role, Position } from "@/types";
import { useAuthStore } from "@/stores/authStore";
import { useRouter } from "next/navigation";
import { ArrowLeft, Plus, Pencil, UserCheck, UserX } from "lucide-react";
import Link from "next/link";

const ROLES: Role[] = ["Admin", "Encargado", "Empleado"];
const POSITIONS: Position[] = ["Sala", "Cocina", "Barra"];

const emptyForm = {
  name: "",
  pin: "",
  role: "Empleado" as Role,
  position: "Sala" as Position,
};

export default function EmployeesPage() {
  const { currentEmployee, isAuthenticated } = useAuthStore();
  const router = useRouter();

  const [employees, setEmployees] = useState<Employee[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<Employee | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState(emptyForm);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!isAuthenticated) router.replace("/login");
  }, [isAuthenticated, router]);

  useEffect(() => {
    fetchEmployees();
  }, []);

  async function fetchEmployees() {
    const snap = await getDocs(collection(db, "employees"));
    setEmployees(
      snap.docs.map((d) => ({
        id: d.id,
        ...d.data(),
        createdAt: d.data().createdAt?.toDate?.() ?? new Date(),
      })) as Employee[]
    );
    setLoading(false);
  }

  function openNew() {
    setEditing(null);
    setForm(emptyForm);
    setShowForm(true);
  }

  function openEdit(emp: Employee) {
    setEditing(emp);
    setForm({
      name: emp.name,
      pin: String(emp.pin),
      role: emp.role,
      position: emp.position,
    });
    setShowForm(true);
  }

  async function handleSave() {
    if (!form.name || !form.pin) return;
    setSaving(true);
    try {
      const pinNumber = Number(form.pin);
      if (editing) {
        await updateDoc(doc(db, "employees", editing.id), {
          name: form.name,
          pin: pinNumber,
          role: form.role,
          position: form.position,
        });
      } else {
        await addDoc(collection(db, "employees"), {
          name: form.name,
          pin: pinNumber,
          role: form.role,
          position: form.position,
          active: true,
          createdAt: serverTimestamp(),
        });
      }
      await fetchEmployees();
      setShowForm(false);
    } finally {
      setSaving(false);
    }
  }

  async function toggleActive(emp: Employee) {
    await updateDoc(doc(db, "employees", emp.id), { active: !emp.active });
    await fetchEmployees();
  }

  if (!currentEmployee) return null;

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-red-700 text-white px-6 py-4 flex items-center gap-4 shadow-md">
        <Link href="/dashboard" className="text-red-200 hover:text-white">
          <ArrowLeft size={22} />
        </Link>
        <h1 className="text-xl font-bold flex-1">Empleados</h1>
        <button
          onClick={openNew}
          className="flex items-center gap-2 bg-white text-red-700 px-4 py-2 rounded-lg font-semibold text-sm hover:bg-red-50 transition-colors"
        >
          <Plus size={18} /> Nuevo
        </button>
      </div>

      {/* List */}
      <div className="max-w-2xl mx-auto p-4 space-y-3">
        {loading ? (
          <p className="text-gray-400 text-center py-10">Cargando...</p>
        ) : (
          employees
            .sort((a, b) => a.name.localeCompare(b.name))
            .map((emp) => (
              <div
                key={emp.id}
                className={`bg-white rounded-xl border p-4 flex items-center gap-4 shadow-sm transition-opacity
                  ${!emp.active ? "opacity-50" : ""}`}
              >
                <div className="flex-1">
                  <p className="font-semibold">{emp.name}</p>
                  <p className="text-sm text-gray-400 capitalize">
                    {emp.role} · {emp.position}
                  </p>
                </div>
                <button
                  onClick={() => openEdit(emp)}
                  className="p-2 rounded-lg hover:bg-gray-100 text-gray-500"
                >
                  <Pencil size={18} />
                </button>
                <button
                  onClick={() => toggleActive(emp)}
                  className={`p-2 rounded-lg transition-colors
                    ${emp.active
                      ? "hover:bg-red-50 text-red-400"
                      : "hover:bg-green-50 text-green-500"
                    }`}
                >
                  {emp.active ? <UserX size={18} /> : <UserCheck size={18} />}
                </button>
              </div>
            ))
        )}
      </div>

      {/* Form modal */}
      {showForm && (
        <div className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-md p-6 space-y-4">
            <h2 className="font-bold text-lg">
              {editing ? "Editar empleado" : "Nuevo empleado"}
            </h2>

            <div className="space-y-3">
              <input
                placeholder="Nombre"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                className="w-full border rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-red-400"
              />
              <input
                placeholder="PIN (4-6 dígitos)"
                type="password"
                inputMode="numeric"
                value={form.pin}
                onChange={(e) => setForm({ ...form, pin: e.target.value })}
                className="w-full border rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-red-400"
              />
              <select
                value={form.role}
                onChange={(e) => setForm({ ...form, role: e.target.value as Role })}
                className="w-full border rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-red-400"
              >
                {ROLES.map((r) => (
                  <option key={r} value={r} className="capitalize">
                    {r.charAt(0).toUpperCase() + r.slice(1)}
                  </option>
                ))}
              </select>
              <select
                value={form.position}
                onChange={(e) =>
                  setForm({ ...form, position: e.target.value as Position })
                }
                className="w-full border rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-red-400"
              >
                {POSITIONS.map((p) => (
                  <option key={p} value={p} className="capitalize">
                    {p.charAt(0).toUpperCase() + p.slice(1)}
                  </option>
                ))}
              </select>
            </div>

            <div className="flex gap-3 pt-2">
              <button
                onClick={() => setShowForm(false)}
                className="flex-1 py-3 rounded-xl border text-gray-600 hover:bg-gray-50"
              >
                Cancelar
              </button>
              <button
                onClick={handleSave}
                disabled={saving || !form.name || !form.pin}
                className="flex-1 py-3 rounded-xl bg-red-600 text-white font-bold disabled:opacity-40 hover:bg-red-700"
              >
                {saving ? "Guardando..." : "Guardar"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
