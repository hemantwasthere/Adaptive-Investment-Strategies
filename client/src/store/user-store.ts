import { create } from "zustand";
import { createJSONStorage, persist } from "zustand/middleware";

interface UserStoreProps {
  address: string;
  setAddress: (address: string) => void;
  lastWallet: string;
  setLastWallet: (lastWallet: string) => void;

  lendingData: string;
  setLendingData: (lending_data: string) => void;

  dexData: string;
  setDexData: (dex_data: string) => void;
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
    lendingData: "",
    setLendingData: (lendingData: string) => set({ lendingData }),
    dexData: "",
    setDexData: (dexData: string) => set({ dexData }),
  }),
);
