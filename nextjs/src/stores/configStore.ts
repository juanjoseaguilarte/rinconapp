import { create } from "zustand";
import { AppConfig, FeaturePermissions, Role } from "@/types";

const defaultPermissions: FeaturePermissions = {
  employees: ["SuperAdmin", "Admin"],
  cash: ["SuperAdmin", "Admin", "Encargado"],
  tips: ["SuperAdmin", "Admin", "Encargado"],
  shifts: ["SuperAdmin", "Admin", "Encargado", "Empleado"],
  tasks: ["SuperAdmin", "Admin", "Encargado", "Empleado"],
  arqueo: ["SuperAdmin", "Admin"],
};

interface ConfigState {
  config: AppConfig;
  setConfig: (config: AppConfig) => void;
  hasAccess: (feature: keyof FeaturePermissions, role: Role) => boolean;
}

export const useConfigStore = create<ConfigState>((set, get) => ({
  config: {
    id: "default",
    featurePermissions: defaultPermissions,
  },
  setConfig: (config) => set({ config }),
  hasAccess: (feature, role) => {
    const permissions = get().config.featurePermissions;
    return permissions[feature]?.includes(role) ?? false;
  },
}));
