"use client";

import { useEffect, useState } from "react";
import { collection, getDocs, query, where } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { Employee } from "@/types";
import { useAuthStore } from "@/stores/authStore";
import { useRouter } from "next/navigation";

type EmployeeGroup = {
  superadmins: Employee[];
  admins: Employee[];
  encargados: Employee[];
  sala: Employee[];
  cocina: Employee[];
};

export default function LoginPage() {
  const router = useRouter();
  const { login, isAuthenticated } = useAuthStore();

  const [groups, setGroups] = useState<EmployeeGroup>({
    superadmins: [],
    admins: [],
    encargados: [],
    sala: [],
    cocina: [],
  });
  const [selected, setSelected] = useState<Employee | null>(null);
  const [pin, setPin] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (isAuthenticated) router.replace("/dashboard");
  }, [isAuthenticated, router]);

  useEffect(() => {
    fetchEmployees();
  }, []);

  async function fetchEmployees() {
    try {
      const snap = await getDocs(
        query(collection(db, "employees"), where("active", "==", true))
      );
      const employees = snap.docs.map((d) => ({
        id: d.id,
        ...d.data(),
        createdAt: d.data().createdAt?.toDate?.() ?? new Date(),
      })) as Employee[];

      setGroups({
        superadmins: employees.filter((e) => e.role === "superadmin"),
        admins: employees.filter((e) => e.role === "admin"),
        encargados: employees.filter((e) => e.role === "encargado"),
        sala: employees.filter(
          (e) => e.role === "empleado" && e.position === "sala"
        ),
        cocina: employees.filter(
          (e) => e.role === "empleado" && e.position === "cocina"
        ),
      });
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }

  function handleSelect(employee: Employee) {
    setSelected(employee);
    setPin("");
    setError("");
  }

  function handlePinKey(key: string) {
    if (key === "del") {
      setPin((p) => p.slice(0, -1));
      setError("");
    } else if (pin.length < 6) {
      setPin((p) => p + key);
    }
  }

  async function handleConfirm() {
    if (!selected) return;
    if (pin === selected.pin) {
      login(selected);
      router.replace("/dashboard");
    } else {
      setError("PIN incorrecto");
      setPin("");
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-gray-400 text-lg">Cargando...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Header */}
      <div className="bg-red-700 text-white px-6 py-4 shadow-md">
        <h1 className="text-xl font-bold tracking-wide">
          {selected ? `PIN — ${selected.name}` : "Selecciona tu usuario"}
        </h1>
      </div>

      <div className="flex-1 flex flex-col lg:flex-row">
        {/* Employee list */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4">
          <EmployeeSection
            label="Administradores"
            employees={[...groups.superadmins, ...groups.admins]}
            selected={selected}
            onSelect={handleSelect}
          />
          <EmployeeSection
            label="Encargados"
            employees={groups.encargados}
            selected={selected}
            onSelect={handleSelect}
          />
          <EmployeeSection
            label="Sala"
            employees={groups.sala}
            selected={selected}
            onSelect={handleSelect}
          />
          <EmployeeSection
            label="Cocina"
            employees={groups.cocina}
            selected={selected}
            onSelect={handleSelect}
          />
        </div>

        {/* PIN pad */}
        {selected && (
          <div className="lg:w-80 p-6 flex flex-col items-center justify-center bg-white border-t lg:border-t-0 lg:border-l border-gray-200 shadow-inner">
            <p className="text-gray-500 text-sm mb-2">
              Introduce tu PIN
            </p>

            {/* PIN dots */}
            <div className="flex gap-3 mb-4">
              {Array.from({ length: 4 }).map((_, i) => (
                <div
                  key={i}
                  className={`w-4 h-4 rounded-full border-2 transition-colors ${
                    i < pin.length
                      ? "bg-red-600 border-red-600"
                      : "border-gray-300"
                  }`}
                />
              ))}
            </div>

            {error && (
              <p className="text-red-500 text-sm mb-3">{error}</p>
            )}

            {/* Numpad */}
            <div className="grid grid-cols-3 gap-3 w-full max-w-[220px]">
              {["1","2","3","4","5","6","7","8","9","","0","del"].map((k) => (
                <button
                  key={k}
                  onClick={() => k && handlePinKey(k)}
                  className={`h-14 rounded-xl text-xl font-semibold transition-all
                    ${k === "" ? "invisible" : ""}
                    ${k === "del"
                      ? "bg-gray-100 text-gray-500 hover:bg-gray-200 text-base"
                      : "bg-gray-100 hover:bg-red-50 hover:text-red-700 active:scale-95"
                    }
                  `}
                >
                  {k === "del" ? "⌫" : k}
                </button>
              ))}
            </div>

            <button
              onClick={handleConfirm}
              disabled={pin.length < 4}
              className="mt-5 w-full max-w-[220px] py-3 rounded-xl bg-red-600 text-white font-bold
                disabled:opacity-40 hover:bg-red-700 transition-colors active:scale-95"
            >
              Entrar
            </button>

            <button
              onClick={() => setSelected(null)}
              className="mt-3 text-sm text-gray-400 hover:text-gray-600"
            >
              Cancelar
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

function EmployeeSection({
  label,
  employees,
  selected,
  onSelect,
}: {
  label: string;
  employees: Employee[];
  selected: Employee | null;
  onSelect: (e: Employee) => void;
}) {
  if (employees.length === 0) return null;
  return (
    <div>
      <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">
        {label}
      </p>
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
        {employees.map((emp) => (
          <button
            key={emp.id}
            onClick={() => onSelect(emp)}
            className={`p-3 rounded-xl border-2 text-left transition-all active:scale-95
              ${selected?.id === emp.id
                ? "border-red-600 bg-red-50 text-red-700"
                : "border-gray-200 bg-white hover:border-red-300 hover:bg-red-50"
              }
            `}
          >
            <p className="font-semibold text-sm truncate">{emp.name}</p>
            <p className="text-xs text-gray-400 capitalize">{emp.position}</p>
          </button>
        ))}
      </div>
    </div>
  );
}
