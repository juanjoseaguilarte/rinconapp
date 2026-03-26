"use client";

import { useEffect, useState, useCallback } from "react";
import {
  doc,
  getDoc,
  setDoc,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { useAuthStore } from "@/stores/authStore";
import { useConfigStore } from "@/stores/configStore";
import { useRouter } from "next/navigation";
import { ArrowLeft, ShieldCheck } from "lucide-react";
import Link from "next/link";
import { FeaturePermissions, Role } from "@/types";

// ─── Constants ────────────────────────────────────────────────────────────────

const TOGGLEABLE_ROLES: Role[] = ["Admin", "Encargado", "Empleado"];

const FEATURES: { key: keyof FeaturePermissions; label: string; icon: string }[] = [
  { key: "employees", label: "Empleados", icon: "👥" },
  { key: "cash", label: "Caja", icon: "💰" },
  { key: "tips", label: "Propinas", icon: "💸" },
  { key: "shifts", label: "Turnos", icon: "📅" },
  { key: "tasks", label: "Tareas", icon: "✅" },
  { key: "arqueo", label: "Arqueo", icon: "🧾" },
];

const DEFAULT_PERMISSIONS: FeaturePermissions = {
  employees: ["SuperAdmin", "Admin"],
  cash: ["SuperAdmin", "Admin", "Encargado"],
  tips: ["SuperAdmin", "Admin", "Encargado"],
  shifts: ["SuperAdmin", "Admin", "Encargado", "Empleado"],
  tasks: ["SuperAdmin", "Admin", "Encargado", "Empleado"],
  arqueo: ["SuperAdmin", "Admin"],
};

// ─── Toggle Switch ────────────────────────────────────────────────────────────

function ToggleSwitch({
  checked,
  onChange,
  disabled,
}: {
  checked: boolean;
  onChange: (v: boolean) => void;
  disabled?: boolean;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      onClick={() => !disabled && onChange(!checked)}
      className={`relative w-11 h-6 rounded-full transition-colors focus:outline-none
        ${checked ? "bg-red-600" : "bg-gray-200"}
        ${disabled ? "opacity-50 cursor-not-allowed" : "cursor-pointer"}`}
    >
      <span
        className={`absolute top-1 left-1 w-4 h-4 bg-white rounded-full shadow transition-transform
          ${checked ? "translate-x-5" : "translate-x-0"}`}
      />
    </button>
  );
}

// ─── Main Component ───────────────────────────────────────────────────────────

export default function AdminPage() {
  const { currentEmployee, isAuthenticated } = useAuthStore();
  const { setConfig } = useConfigStore();
  const router = useRouter();

  const [permissions, setPermissions] =
    useState<FeaturePermissions>(DEFAULT_PERMISSIONS);
  const [loading, setLoading] = useState(true);
  const [savingKey, setSavingKey] = useState<string | null>(null);

  // ── Auth & role guards ─────────────────────────────────────────────────────

  useEffect(() => {
    if (!isAuthenticated) {
      router.replace("/login");
      return;
    }
    if (currentEmployee && currentEmployee.role !== "SuperAdmin") {
      router.replace("/dashboard");
    }
  }, [isAuthenticated, currentEmployee, router]);

  // ── Fetch permissions ──────────────────────────────────────────────────────

  const fetchPermissions = useCallback(async () => {
    setLoading(true);
    try {
      const snap = await getDoc(doc(db, "config", "permissions"));
      if (snap.exists()) {
        const data = snap.data() as FeaturePermissions;
        setPermissions(data);
        setConfig({ id: "permissions", featurePermissions: data });
      } else {
        setPermissions(DEFAULT_PERMISSIONS);
        setConfig({ id: "permissions", featurePermissions: DEFAULT_PERMISSIONS });
      }
    } catch {
      setPermissions(DEFAULT_PERMISSIONS);
    } finally {
      setLoading(false);
    }
  }, [setConfig]);

  useEffect(() => {
    if (currentEmployee?.role === "SuperAdmin") {
      fetchPermissions();
    }
  }, [currentEmployee, fetchPermissions]);

  // ── Toggle a role for a feature ────────────────────────────────────────────

  async function handleToggle(
    feature: keyof FeaturePermissions,
    role: Role,
    enabled: boolean
  ) {
    const toggleKey = `${feature}_${role}`;
    setSavingKey(toggleKey);

    try {
      const current = permissions[feature] ?? [];
      let updated: Role[];

      if (enabled) {
        // Add role if not present
        updated = current.includes(role) ? current : [...current, role];
      } else {
        // Remove role
        updated = current.filter((r) => r !== role);
      }

      // Always keep SuperAdmin
      if (!updated.includes("SuperAdmin")) {
        updated = ["SuperAdmin", ...updated];
      }

      const newPermissions: FeaturePermissions = {
        ...permissions,
        [feature]: updated,
      };

      await setDoc(doc(db, "config", "permissions"), newPermissions, {
        merge: true,
      });

      setPermissions(newPermissions);
      setConfig({ id: "permissions", featurePermissions: newPermissions });
    } finally {
      setSavingKey(null);
    }
  }

  // ── Render ─────────────────────────────────────────────────────────────────

  if (!currentEmployee || currentEmployee.role !== "SuperAdmin") return null;

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-red-700 text-white px-4 py-4 flex items-center gap-3 shadow-md">
        <Link href="/dashboard" className="text-red-200 hover:text-white shrink-0">
          <ArrowLeft size={22} />
        </Link>
        <h1 className="text-xl font-bold flex-1">Panel de control</h1>
        <ShieldCheck size={22} className="text-red-300" />
      </div>

      <div className="max-w-2xl mx-auto p-4 space-y-6">
        {/* Info banner */}
        <div className="bg-red-50 border border-red-100 rounded-2xl px-4 py-3 flex items-center gap-3">
          <ShieldCheck size={20} className="text-red-600 shrink-0" />
          <p className="text-sm text-red-700">
            Solo visible para <strong>SuperAdmin</strong>. Los cambios se
            guardan automáticamente.
          </p>
        </div>

        {/* Permissions matrix */}
        <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
          <div className="px-5 py-4 border-b border-gray-100">
            <h2 className="font-bold text-gray-800">
              Permisos por funcionalidad
            </h2>
            <p className="text-xs text-gray-400 mt-0.5">
              Activa o desactiva el acceso por rol para cada sección
            </p>
          </div>

          {loading ? (
            <div className="py-10 text-center text-sm text-gray-400">
              Cargando permisos...
            </div>
          ) : (
            <>
              {/* Column headers */}
              <div className="grid grid-cols-[1fr_auto_auto_auto] items-center gap-x-3 px-5 py-2 bg-gray-50 border-b border-gray-100">
                <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
                  Sección
                </span>
                {TOGGLEABLE_ROLES.map((role) => (
                  <span
                    key={role}
                    className="text-xs font-bold text-gray-500 uppercase tracking-wider text-center w-20"
                  >
                    {role}
                  </span>
                ))}
              </div>

              {/* Feature rows */}
              <div className="divide-y divide-gray-100">
                {FEATURES.map((feature) => {
                  const featureRoles = permissions[feature.key] ?? [];

                  return (
                    <div
                      key={feature.key}
                      className="grid grid-cols-[1fr_auto_auto_auto] items-center gap-x-3 px-5 py-4"
                    >
                      {/* Feature name */}
                      <div className="flex items-center gap-2.5">
                        <span className="text-lg leading-none" aria-hidden>
                          {feature.icon}
                        </span>
                        <div>
                          <p className="font-semibold text-sm text-gray-800">
                            {feature.label}
                          </p>
                          <p className="text-xs text-gray-400">
                            SuperAdmin: siempre activo
                          </p>
                        </div>
                      </div>

                      {/* Role toggles */}
                      {TOGGLEABLE_ROLES.map((role) => {
                        const isEnabled = featureRoles.includes(role);
                        const toggleKey = `${feature.key}_${role}`;
                        const isSaving = savingKey === toggleKey;

                        return (
                          <div
                            key={role}
                            className="w-20 flex items-center justify-center"
                          >
                            <div
                              className={`transition-opacity ${isSaving ? "opacity-50" : ""}`}
                            >
                              <ToggleSwitch
                                checked={isEnabled}
                                disabled={isSaving}
                                onChange={(v) =>
                                  handleToggle(feature.key, role, v)
                                }
                              />
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  );
                })}
              </div>

              {/* SuperAdmin row (always on) */}
              <div className="px-5 py-3 bg-gray-50 border-t border-gray-100">
                <div className="grid grid-cols-[1fr_auto_auto_auto] items-center gap-x-3">
                  <div className="flex items-center gap-2">
                    <ShieldCheck size={16} className="text-red-600" />
                    <span className="text-sm font-semibold text-gray-600">
                      SuperAdmin
                    </span>
                  </div>
                  {TOGGLEABLE_ROLES.map((role) => (
                    <div key={role} className="w-20 flex justify-center">
                      <span className="text-xs text-gray-400 italic">—</span>
                    </div>
                  ))}
                </div>
                <p className="text-xs text-gray-400 mt-1 pl-6">
                  El SuperAdmin siempre tiene acceso completo a todas las
                  funcionalidades.
                </p>
              </div>
            </>
          )}
        </div>

        {/* Role legend */}
        <div className="bg-white rounded-2xl border border-gray-200 shadow-sm p-5">
          <h3 className="font-bold text-gray-800 text-sm mb-3">
            Leyenda de roles
          </h3>
          <div className="space-y-2">
            {(
              [
                {
                  role: "SuperAdmin",
                  desc: "Control total del sistema. Acceso a todos los módulos.",
                },
                {
                  role: "Admin",
                  desc: "Gestión de empleados, caja, propinas y arqueos.",
                },
                {
                  role: "Encargado",
                  desc: "Acceso a caja, propinas, turnos y tareas.",
                },
                {
                  role: "Empleado",
                  desc: "Acceso limitado: turnos y tareas asignadas.",
                },
              ] as { role: string; desc: string }[]
            ).map(({ role, desc }) => (
              <div key={role} className="flex items-start gap-3">
                <span
                  className={`inline-block px-2 py-0.5 rounded text-xs font-bold shrink-0
                    ${
                      role === "SuperAdmin"
                        ? "bg-red-100 text-red-700"
                        : role === "Admin"
                        ? "bg-orange-100 text-orange-700"
                        : role === "Encargado"
                        ? "bg-yellow-100 text-yellow-700"
                        : "bg-gray-100 text-gray-600"
                    }`}
                >
                  {role}
                </span>
                <p className="text-xs text-gray-500 leading-relaxed">{desc}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
