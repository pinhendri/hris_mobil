import axios from "axios";
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

// Utility untuk gabung class Tailwind
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

const BASE_URL = import.meta.env.VITE_API_URL || "http://localhost:8000";

// Axios instance
export const api_laravel = axios.create({
  baseURL: BASE_URL,
  headers: {
    "Content-Type": "application/json",
    withCredentials: true,
  },
});

// Tambahkan token otomatis saat request
api_laravel.interceptors.request.use((config) => {
  const token = localStorage.getItem("token"); // ✅ sama seperti saat login
  if (token && config.headers) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});
export default api_laravel;
