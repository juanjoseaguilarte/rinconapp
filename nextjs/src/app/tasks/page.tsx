"use client";

import { useEffect, useState, useCallback } from "react";
import {
  collection,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  doc,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { Employee } from "@/types";
import { useAuthStore } from "@/stores/authStore";
import { useRouter } from "next/navigation";
import { ArrowLeft, Plus, Pencil, Trash2, X, Check } from "lucide-react";
import Link from "next/link";

// ─── Types ────────────────────────────────────────────────────────────────────

interface Task {
  id: string;
  title: string;
  description: string;
  assignedTo: string[];
  assignedToStatus: Record<string, boolean>;
  createdBy: string;
  createdAt: string;
}

type TabKey = "pendientes" | "completadas" | "creadas";

// ─── Main Component ───────────────────────────────────────────────────────────

export default function TasksPage() {
  const { currentEmployee, isAuthenticated } = useAuthStore();
  const router = useRouter();

  const [tasks, setTasks] = useState<Task[]>([]);
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<TabKey>("pendientes");

  // Form modal
  const [showForm, setShowForm] = useState(false);
  const [editingTask, setEditingTask] = useState<Task | null>(null);
  const [formTitle, setFormTitle] = useState("");
  const [formDescription, setFormDescription] = useState("");
  const [formAssignedTo, setFormAssignedTo] = useState<string[]>([]);
  const [saving, setSaving] = useState(false);

  // Delete confirm
  const [deleteConfirm, setDeleteConfirm] = useState<Task | null>(null);
  const [deleting, setDeleting] = useState(false);

  const canManage =
    currentEmployee?.role === "Admin" ||
    currentEmployee?.role === "Encargado" ||
    currentEmployee?.role === "SuperAdmin";

  // ── Auth guard ─────────────────────────────────────────────────────────────

  useEffect(() => {
    if (!isAuthenticated) router.replace("/login");
  }, [isAuthenticated, router]);

  // ── Fetch ──────────────────────────────────────────────────────────────────

  const fetchData = useCallback(async () => {
    setLoading(true);
    const [tasksSnap, empSnap] = await Promise.all([
      getDocs(collection(db, "tasks")),
      getDocs(collection(db, "employees")),
    ]);
    setTasks(
      tasksSnap.docs.map((d) => ({ id: d.id, ...d.data() } as Task))
    );
    setEmployees(
      empSnap.docs.map((d) => ({ id: d.id, ...d.data() } as Employee))
    );
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // ── Filtered tasks ─────────────────────────────────────────────────────────

  const myId = currentEmployee?.id ?? "";

  const filteredTasks = tasks.filter((t) => {
    if (activeTab === "pendientes") {
      return (
        t.assignedTo.includes(myId) && t.assignedToStatus?.[myId] !== true
      );
    }
    if (activeTab === "completadas") {
      return (
        t.assignedTo.includes(myId) && t.assignedToStatus?.[myId] === true
      );
    }
    if (activeTab === "creadas") {
      return t.createdBy === myId;
    }
    return false;
  });

  // ── Toggle complete ────────────────────────────────────────────────────────

  async function toggleComplete(task: Task) {
    const current = task.assignedToStatus?.[myId] === true;
    await updateDoc(doc(db, "tasks", task.id), {
      [`assignedToStatus.${myId}`]: !current,
    });
    await fetchData();
  }

  // ── Open add form ──────────────────────────────────────────────────────────

  function openAdd() {
    setEditingTask(null);
    setFormTitle("");
    setFormDescription("");
    setFormAssignedTo([]);
    setShowForm(true);
  }

  // ── Open edit form ─────────────────────────────────────────────────────────

  function openEdit(task: Task) {
    setEditingTask(task);
    setFormTitle(task.title);
    setFormDescription(task.description);
    setFormAssignedTo([...task.assignedTo]);
    setShowForm(true);
  }

  // ── Save form ──────────────────────────────────────────────────────────────

  async function handleSave() {
    if (!formTitle.trim() || formAssignedTo.length === 0) return;
    setSaving(true);
    try {
      if (editingTask) {
        await updateDoc(doc(db, "tasks", editingTask.id), {
          title: formTitle.trim(),
          description: formDescription.trim(),
          assignedTo: formAssignedTo,
        });
      } else {
        const newId = crypto.randomUUID();
        const statusMap: Record<string, boolean> = {};
        formAssignedTo.forEach((id) => {
          statusMap[id] = false;
        });
        await setDoc(doc(db, "tasks", newId), {
          id: newId,
          title: formTitle.trim(),
          description: formDescription.trim(),
          assignedTo: formAssignedTo,
          assignedToStatus: statusMap,
          createdBy: myId,
          createdAt: new Date().toISOString(),
        });
      }
      await fetchData();
      setShowForm(false);
    } finally {
      setSaving(false);
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  async function handleDelete(task: Task) {
    setDeleting(true);
    try {
      await deleteDoc(doc(db, "tasks", task.id));
      await fetchData();
      setDeleteConfirm(null);
    } finally {
      setDeleting(false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  function employeeName(id: string) {
    return employees.find((e) => e.id === id)?.name ?? id;
  }

  function taskProgress(task: Task): { done: number; total: number } {
    const total = task.assignedTo.length;
    const done = task.assignedTo.filter(
      (id) => task.assignedToStatus?.[id] === true
    ).length;
    return { done, total };
  }

  function toggleAssignee(id: string) {
    setFormAssignedTo((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]
    );
  }

  // ── Render ─────────────────────────────────────────────────────────────────

  if (!currentEmployee) return null;

  const tabs: { key: TabKey; label: string; show: boolean }[] = [
    { key: "pendientes", label: "Pendientes", show: true },
    { key: "completadas", label: "Completadas", show: true },
    { key: "creadas", label: "Creadas por mí", show: canManage },
  ];

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Header */}
      <div className="bg-red-700 text-white px-4 py-4 flex items-center gap-3 shadow-md">
        <Link href="/dashboard" className="text-red-200 hover:text-white shrink-0">
          <ArrowLeft size={22} />
        </Link>
        <h1 className="text-xl font-bold flex-1">Tareas</h1>
      </div>

      {/* Tabs */}
      <div className="bg-white border-b sticky top-0 z-10 shadow-sm">
        <div className="flex overflow-x-auto">
          {tabs
            .filter((t) => t.show)
            .map((tab) => (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key)}
                className={`whitespace-nowrap px-5 py-3 text-sm font-semibold border-b-2 transition-colors
                  ${
                    activeTab === tab.key
                      ? "border-red-600 text-red-700"
                      : "border-transparent text-gray-500 hover:text-gray-700"
                  }`}
              >
                {tab.label}
              </button>
            ))}
        </div>
      </div>

      {/* Task list */}
      <div className="flex-1 max-w-2xl mx-auto w-full p-4 space-y-3 pb-24">
        {loading ? (
          <p className="text-gray-400 text-center py-10 text-sm">
            Cargando tareas...
          </p>
        ) : filteredTasks.length === 0 ? (
          <p className="text-gray-300 text-center py-10 text-sm italic">
            {activeTab === "pendientes" && "No tienes tareas pendientes"}
            {activeTab === "completadas" && "No tienes tareas completadas"}
            {activeTab === "creadas" && "No has creado ninguna tarea"}
          </p>
        ) : (
          filteredTasks.map((task) => {
            const isCreatedTab = activeTab === "creadas";
            const { done, total } = taskProgress(task);
            const isCompleted = task.assignedToStatus?.[myId] === true;

            return (
              <div
                key={task.id}
                className="bg-white rounded-2xl border border-gray-200 p-4 shadow-sm"
              >
                <div className="flex items-start gap-3">
                  {/* Checkbox (only for pendientes / completadas) */}
                  {!isCreatedTab && (
                    <button
                      onClick={() => toggleComplete(task)}
                      className={`mt-0.5 shrink-0 w-5 h-5 rounded border-2 flex items-center justify-center transition-colors
                        ${
                          isCompleted
                            ? "bg-green-500 border-green-500 text-white"
                            : "border-gray-300 hover:border-red-400"
                        }`}
                    >
                      {isCompleted && <Check size={12} strokeWidth={3} />}
                    </button>
                  )}

                  {/* Content */}
                  <div className="flex-1 min-w-0">
                    <p
                      className={`font-semibold text-gray-800 text-sm leading-snug
                        ${isCompleted && !isCreatedTab ? "line-through text-gray-400" : ""}`}
                    >
                      {task.title}
                    </p>
                    {task.description && (
                      <p className="text-xs text-gray-500 mt-1 leading-relaxed">
                        {task.description}
                      </p>
                    )}

                    {/* Assignees */}
                    <div className="flex flex-wrap gap-1 mt-2">
                      {task.assignedTo.map((id) => {
                        const done = task.assignedToStatus?.[id] === true;
                        return (
                          <span
                            key={id}
                            className={`inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded-full font-medium
                              ${
                                done
                                  ? "bg-green-50 text-green-700 border border-green-200"
                                  : "bg-gray-100 text-gray-600"
                              }`}
                          >
                            {done && <Check size={10} strokeWidth={3} />}
                            {employeeName(id)}
                          </span>
                        );
                      })}
                    </div>

                    {/* Progress bar (created tab) */}
                    {isCreatedTab && total > 0 && (
                      <div className="mt-3">
                        <div className="flex items-center justify-between text-xs text-gray-500 mb-1">
                          <span>Progreso</span>
                          <span>
                            {done}/{total} completada{total !== 1 ? "s" : ""}
                          </span>
                        </div>
                        <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden">
                          <div
                            className="h-full bg-green-500 rounded-full transition-all"
                            style={{
                              width: `${total > 0 ? (done / total) * 100 : 0}%`,
                            }}
                          />
                        </div>
                      </div>
                    )}
                  </div>

                  {/* Actions (created tab) */}
                  {isCreatedTab && (
                    <div className="flex items-center gap-1 shrink-0">
                      <button
                        onClick={() => openEdit(task)}
                        className="p-2 rounded-lg hover:bg-gray-100 text-gray-400 hover:text-gray-600 transition-colors"
                      >
                        <Pencil size={16} />
                      </button>
                      <button
                        onClick={() => setDeleteConfirm(task)}
                        className="p-2 rounded-lg hover:bg-red-50 text-gray-400 hover:text-red-500 transition-colors"
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  )}
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* FAB */}
      {canManage && (
        <button
          onClick={openAdd}
          className="fixed bottom-6 right-6 w-14 h-14 bg-red-600 hover:bg-red-700 text-white rounded-full shadow-lg flex items-center justify-center transition-all active:scale-95 z-20"
        >
          <Plus size={26} />
        </button>
      )}

      {/* ── Form Modal ─────────────────────────────────────────────────────── */}
      {showForm && (
        <div className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-md p-6 space-y-4 shadow-xl max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between">
              <h2 className="font-bold text-lg">
                {editingTask ? "Editar tarea" : "Nueva tarea"}
              </h2>
              <button
                onClick={() => setShowForm(false)}
                className="p-2 rounded-lg hover:bg-gray-100 text-gray-400"
              >
                <X size={18} />
              </button>
            </div>

            <div className="space-y-3">
              <input
                placeholder="Título *"
                value={formTitle}
                onChange={(e) => setFormTitle(e.target.value)}
                className="w-full border rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-red-400"
              />
              <textarea
                placeholder="Descripción (opcional)"
                value={formDescription}
                onChange={(e) => setFormDescription(e.target.value)}
                rows={3}
                className="w-full border rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-red-400 resize-none"
              />

              {/* Employee multi-select */}
              <div>
                <p className="text-sm font-medium text-gray-700 mb-2">
                  Asignar a *
                </p>
                <div className="border rounded-lg overflow-hidden max-h-48 overflow-y-auto divide-y">
                  {employees
                    .filter((e) => e.active !== false)
                    .sort((a, b) => a.name.localeCompare(b.name))
                    .map((emp) => {
                      const selected = formAssignedTo.includes(emp.id);
                      return (
                        <label
                          key={emp.id}
                          className={`flex items-center gap-3 px-4 py-2.5 cursor-pointer transition-colors
                            ${selected ? "bg-red-50" : "hover:bg-gray-50"}`}
                        >
                          <div
                            className={`w-5 h-5 rounded border-2 flex items-center justify-center shrink-0 transition-colors
                              ${
                                selected
                                  ? "bg-red-600 border-red-600 text-white"
                                  : "border-gray-300"
                              }`}
                          >
                            {selected && (
                              <Check size={12} strokeWidth={3} />
                            )}
                          </div>
                          <input
                            type="checkbox"
                            className="sr-only"
                            checked={selected}
                            onChange={() => toggleAssignee(emp.id)}
                          />
                          <div>
                            <p className="text-sm font-medium text-gray-800">
                              {emp.name}
                            </p>
                            <p className="text-xs text-gray-400">
                              {emp.role} · {emp.position}
                            </p>
                          </div>
                        </label>
                      );
                    })}
                </div>
              </div>
            </div>

            <div className="flex gap-3 pt-1">
              <button
                onClick={() => setShowForm(false)}
                className="flex-1 py-3 rounded-xl border text-gray-600 hover:bg-gray-50 transition-colors"
              >
                Cancelar
              </button>
              <button
                onClick={handleSave}
                disabled={saving || !formTitle.trim() || formAssignedTo.length === 0}
                className="flex-1 py-3 rounded-xl bg-red-600 text-white font-bold disabled:opacity-40 hover:bg-red-700 transition-colors"
              >
                {saving ? "Guardando..." : "Guardar"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Delete Confirm Modal ───────────────────────────────────────────── */}
      {deleteConfirm && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-sm p-6 shadow-xl space-y-4">
            <h2 className="font-bold text-lg">Eliminar tarea</h2>
            <p className="text-sm text-gray-600">
              ¿Seguro que quieres eliminar{" "}
              <span className="font-semibold">"{deleteConfirm.title}"</span>?
              Esta acción no se puede deshacer.
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setDeleteConfirm(null)}
                className="flex-1 py-3 rounded-xl border text-gray-600 hover:bg-gray-50 transition-colors"
              >
                Cancelar
              </button>
              <button
                onClick={() => handleDelete(deleteConfirm)}
                disabled={deleting}
                className="flex-1 py-3 rounded-xl bg-red-600 text-white font-bold disabled:opacity-40 hover:bg-red-700 transition-colors"
              >
                {deleting ? "Eliminando..." : "Eliminar"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
