"use client";

import { useAuthStore } from "@/stores/authStore";
import { useConfigStore } from "@/stores/configStore";
import { useRouter } from "next/navigation";
import { useEffect } from "react";
import Link from "next/link";
import {
  Users,
  Wallet,
  Banknote,
  CalendarDays,
  ClipboardList,
  Settings,
  LogOut,
} from "lucide-react";
import { FeaturePermissions } from "@/types";

const menuItems: {
  label: string;
  icon: React.ReactNode;
  href: string;
  feature: keyof FeaturePermissions | null;
}[] = [
  {
    label: "Caja",
    icon: <Wallet size={32} />,
    href: "/cash",
    feature: "cash",
  },
  {
    label: "Propinas",
    icon: <Banknote size={32} />,
    href: "/tips",
    feature: "tips",
  },
  {
    label: "Turnos",
    icon: <CalendarDays size={32} />,
    href: "/shifts",
    feature: "shifts",
  },
  {
    label: "Tareas",
    icon: <ClipboardList size={32} />,
    href: "/tasks",
    feature: "tasks",
  },
  {
    label: "Empleados",
    icon: <Users size={32} />,
    href: "/employees",
    feature: "employees",
  },
  {
    label: "Admin",
    icon: <Settings size={32} />,
    href: "/admin",
    feature: null,
  },
];

export default function DashboardPage() {
  const { currentEmployee, logout, isAuthenticated } = useAuthStore();
  const { hasAccess } = useConfigStore();
  const router = useRouter();

  useEffect(() => {
    if (!isAuthenticated) router.replace("/login");
  }, [isAuthenticated, router]);

  if (!currentEmployee) return null;

  const isSuperAdmin = currentEmployee.role === "superadmin";
  const isAdmin = currentEmployee.role === "admin" || isSuperAdmin;

  const visibleItems = menuItems.filter((item) => {
    if (item.feature === null) return isAdmin;
    return hasAccess(item.feature, currentEmployee.role);
  });

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Header */}
      <div className="bg-red-700 text-white px-6 py-4 flex items-center justify-between shadow-md">
        <div>
          <h1 className="text-xl font-bold">Hola, {currentEmployee.name}</h1>
          <p className="text-red-200 text-sm capitalize">{currentEmployee.role}</p>
        </div>
        <button
          onClick={() => {
            logout();
            router.replace("/login");
          }}
          className="flex items-center gap-2 text-red-200 hover:text-white transition-colors"
        >
          <LogOut size={20} />
          <span className="text-sm hidden sm:inline">Salir</span>
        </button>
      </div>

      {/* Menu grid */}
      <div className="flex-1 p-6">
        <div className="max-w-2xl mx-auto grid grid-cols-2 sm:grid-cols-3 gap-4">
          {visibleItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="flex flex-col items-center justify-center gap-3 bg-white rounded-2xl
                border border-gray-200 p-6 shadow-sm hover:shadow-md hover:border-red-300
                hover:text-red-700 transition-all active:scale-95 text-gray-700"
            >
              {item.icon}
              <span className="font-semibold text-sm">{item.label}</span>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}
