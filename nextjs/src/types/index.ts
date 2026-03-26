export type Role = "superadmin" | "admin" | "encargado" | "empleado";
export type Position = "sala" | "cocina" | "barra";
export type ShiftPeriod = "mañana" | "tarde" | "noche";

export interface Employee {
  id: string;
  name: string;
  pin: string;
  role: Role;
  position: Position;
  active: boolean;
  createdAt: Date;
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

export interface AppConfig {
  id: string;
  featurePermissions: FeaturePermissions;
}
