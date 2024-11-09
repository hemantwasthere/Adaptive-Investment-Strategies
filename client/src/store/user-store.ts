import { create } from "zustand";
import { createJSONStorage, persist } from "zustand/middleware";

interface UserStoreProps {
  address: string;
  setAddress: (address: string) => void;
  lastWallet: string;
  setLastWallet: (lastWallet: string) => void;
}

export const userStore = create<UserStoreProps>(
  // persist(
  //   (set) => ({
  //     address: "",
  //     setAddress: (address: string) => set({ address }),
  //     lastWallet: "",
  //     setLastWallet: (lastWallet: string) => set({ lastWallet }),
  //   }),
  //   {
  //     name: "user-storage",
  //     storage: createJSONStorage(() => userStorage),
  //   },
  // ),
  (set) => ({
    address: "",
    setAddress: (address: string) => set({ address }),
    lastWallet: "",
    setLastWallet: (lastWallet: string) => set({ lastWallet }),
  }),
);
