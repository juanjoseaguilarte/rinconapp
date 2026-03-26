export type Role = "SuperAdmin" | "Admin" | "Encargado" | "Empleado";
export type Position = "Sala" | "Cocina" | "Barra" | string;
export type ShiftPeriod = "mañana" | "tarde" | "noche";

export interface Employee {
  id: string;
  name: string;
  pin: number;
  role: Role;
  position: Position;
  active?: boolean;
  createdAt?: Date;
}

export interface Shift {
  id: string;
  employeeId: string;
  date: string; // YYYY-MM-DD
  period: ShiftPeriod;
  entryTime: string;
  exitTime: string;
  isImaginaria: boolean;
}

export interface Tip {
  id: string;
  amount: number;
  date: string; // YYYY-MM-DD
  week: string; // YYYY-WW
  shift: ShiftPeriod;
  employeePayments: Record<string, number>; // employeeId -> amount
  adminShare: number;
  isPaid: boolean;
  isDeleted: boolean;
  createdAt: Date;
}

export interface CashEntry {
  id: string;
  type: "entrada" | "salida";
  amount: number;
  description: string;
  createdBy: string;
  createdAt: Date;
}

export interface ArqueoRecord {
  id: string;
  date: string;
  openingBalance: number;
  closingBalance: number;
  totalEntradas: number;
  totalSalidas: number;
  createdBy: string;
  createdAt: Date;
}

export interface Task {
  id: string;
  title: string;
  description: string;
  assignedTo: string[];
  assignedToStatus: Record<string, boolean>;
  createdBy: string;
  createdAt: Date;
}

export interface FeaturePermissions {
  employees: Role[];
  cash: Role[];
  tips: Role[];
  shifts: Role[];
  tasks: Role[];
  arqueo: Role[];
}

// Helper: roles in DB are capitalized (Admin, Encargado, Empleado)
export const ROLE_LABELS: Record<Role, string> = {
  SuperAdmin: "Super Admin",
  Admin: "Admin",
  Encargado: "Encargado",
  Empleado: "Empleado",
};

export interface AppConfig {
  id: string;
  featurePermissions: FeaturePermissions;
}
