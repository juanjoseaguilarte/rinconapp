import { create } from "zustand";
import { AppConfig, FeaturePermissions, Role } from "@/types";

const defaultPermissions: FeaturePermissions = {
  employees: ["superadmin", "admin"],
  cash: ["superadmin", "admin", "encargado"],
  tips: ["superadmin", "admin", "encargado"],
  shifts: ["superadmin", "admin", "encargado", "empleado"],
  tasks: ["superadmin", "admin", "encargado", "empleado"],
  arqueo: ["superadmin", "admin"],
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
