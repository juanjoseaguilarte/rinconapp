import { create } from "zustand";
import { persist } from "zustand/middleware";
import { Employee } from "@/types";

interface AuthState {
  currentEmployee: Employee | null;
  isAuthenticated: boolean;
  login: (employee: Employee) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      currentEmployee: null,
      isAuthenticated: false,
      login: (employee) =>
        set({ currentEmployee: employee, isAuthenticated: true }),
      logout: () =>
        set({ currentEmployee: null, isAuthenticated: false }),
    }),
    {
      name: "auth-storage",
      partialize: (state) => ({
        currentEmployee: state.currentEmployee,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
);
