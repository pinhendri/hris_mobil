"use client";

import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { api_laravel } from "@/lib/utils"; // Import dari file utils

interface Company {
  id: number;
  c_code: string;
  company_name: string;
}

const Login = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [selectedCompany, setSelectedCompany] = useState<string>("");
  const [companies, setCompanies] = useState<Company[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [showCompanySelection, setShowCompanySelection] = useState(false);
  const navigate = useNavigate();

  // Cek jika user sudah login saat component mount
  useEffect(() => {
    const checkAuth = () => {
      const token = localStorage.getItem("token");
      const userData = localStorage.getItem("userData");
      
      console.log("Check auth on mount:", {
        token: token,
        userData: userData ? "exists" : "null",
        tokenLength: token?.length,
        tokenType: typeof token
      });
      
      // Cek jika token valid (bukan null, undefined, atau string "null")
      if (typeof token === "string" && token.trim() !== "" && token !== "null" && token !== "undefined") {
        console.log("Valid token found, redirecting to /");
        navigate("/", { replace: true });
      } else {
        console.log("No valid token found, staying on login page");
        // Clear invalid token
        if (token === "null" || token === "undefined") {
          localStorage.removeItem("token");
          console.log("Cleared invalid token");
        }
      }
    };

    checkAuth();
  }, [navigate]);

  const clearAuthData = () => {
    console.log("Clearing all auth data");
    localStorage.clear(); // Clear semua localStorage
    sessionStorage.clear(); // Clear semua sessionStorage
    
    // Clear cookies khusus app
    document.cookie.split(";").forEach(function(c) {
      document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/");
    });
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    // Clear dulu sebelum login baru
    // clearAuthData();

    try {
      console.log("Attempting login with:", { email });
      console.log("API base URL:", api_laravel.defaults.baseURL);
      
      // Menggunakan api_laravel untuk login
      const response = await api_laravel.post("/api/login", { 
        email, 
        password 
      });

      const data = response.data;
      console.log("Login response data:", data);

      if (data.success && data.data?.token) {
        const token = data.data.token;
        const userData = data.data.user;
        const companyAssignments = data.data.company_assignments || [];

        console.log("Token received:", token.substring(0, 20) + "...");
        console.log("Token full length:", token.length);
        console.log("User data received:", userData);

        // VALIDASI: Pastikan token adalah string yang valid
        if (typeof token !== 'string' || token.length < 10) {
          throw new Error("Invalid token format received from server");
        }

        // Simpan data dengan sangat hati-hati
        try {
          // 1. Simpan ke localStorage
          localStorage.setItem("token", token);
          localStorage.setItem("userData", JSON.stringify(userData));
          localStorage.setItem("login_time", Date.now().toString());
          
          // 2. Verifikasi penyimpanan
          const savedToken = localStorage.getItem("token");
          if (!savedToken || savedToken !== token) {
            throw new Error("Failed to save token to localStorage");
          }
          
          console.log("✅ Token successfully saved to localStorage");
          console.log("Saved token (first 20 chars):", savedToken.substring(0, 20) + "...");
          
          // 3. Update axios default header dengan token baru
          api_laravel.defaults.headers.common['Authorization'] = `Bearer ${token}`;
          
        } catch (storageError: any) {
          console.error("❌ Storage error:", storageError);
          throw new Error(`Storage error: ${storageError.message}`);
        }

        // Handle companies
        if (companyAssignments.length === 0) {
          console.log("No companies assigned, redirecting to /");
          setTimeout(() => {
            window.location.href = "/";
          }, 100);
          
        } else if (companyAssignments.length === 1) {
          // Auto select single company
          const company = companyAssignments[0];
          console.log("Auto-selecting single company:", company.company_name);
          
          // Simpan company info
          localStorage.setItem("selectedCompany", JSON.stringify(company));
          localStorage.setItem("selectedCompanyId", company.id.toString());
          localStorage.setItem("selectedCcode", company.c_code);
          
          // Update user data
          const updatedUserData = {
            ...userData,
            selected_c_code: company.c_code,
            selected_company_id: company.id,
          };
          localStorage.setItem("userData", JSON.stringify(updatedUserData));
          
          // Call API async (don't wait)
          setCompanyAPI(token, company.id, company.c_code);
          
          // Redirect dengan force reload
          setTimeout(() => {
            console.log("Redirecting after auto-select...");
            window.location.href = "/";
          }, 150);
          
        } else {
          // Show company selection
          console.log("Multiple companies, showing selection screen");
          setCompanies(companyAssignments);
          setShowCompanySelection(true);
        }
        
      } else {
        throw new Error(data.message || "Login failed: No token in response");
      }
      
    } catch (err: any) {
      console.error("❌ Login process error:", err);
      // Tangani error response dari axios
      if (err.response) {
        // Server responded dengan status error
        const errorData = err.response.data;
        setError(errorData.message || `Login failed with status ${err.response.status}`);
      } else if (err.request) {
        // Request dibuat tapi tidak ada response
        setError("Tidak ada response dari server. Periksa koneksi jaringan.");
      } else {
        // Error lainnya
        setError(err.message || "Terjadi kesalahan saat login");
      }
      clearAuthData();
    } finally {
      setLoading(false);
    }
  };

  const setCompanyAPI = async (token: string, companyId: number, cCode: string) => {
    try {
      console.log("Setting company via API...");
      
      // Menggunakan api_laravel dengan token yang sudah ada
      const response = await api_laravel.post("/api/set-selected-company", {
        company_id: companyId,
        c_code: cCode
      });
      
      if (response.status === 200) {
        console.log("✅ Company set via API successful");
      } else {
        console.warn("⚠️ Company set API returned non-ok status:", response.status);
      }
    } catch (apiError) {
      console.warn("⚠️ Company set API error (non-critical):", apiError);
    }
  };

  const handleCompanySelect = async () => {
    const companyToSelect = companies.find(c => c.id.toString() === selectedCompany);
    
    if (!companyToSelect) {
      setError("Silakan pilih perusahaan");
      return;
    }

    setLoading(true);
    setError("");

    try {
      const token = localStorage.getItem("token");
      
      // VALIDASI: Pastikan token valid
      if (!token || token === "null" || token === "undefined" || token.length < 10) {
        throw new Error("Token tidak valid. Silakan login ulang.");
      }

      console.log("Selecting company:", companyToSelect.company_name);

      // Simpan company info
      localStorage.setItem("selectedCompany", JSON.stringify(companyToSelect));
      localStorage.setItem("selectedCompanyId", companyToSelect.id.toString());
      localStorage.setItem("selectedCcode", companyToSelect.c_code);

      // Update user data
      const userDataStr = localStorage.getItem("userData");
      if (userDataStr) {
        try {
          const userData = JSON.parse(userDataStr);
          const updatedUserData = {
            ...userData,
            selected_c_code: companyToSelect.c_code,
            selected_company_id: companyToSelect.id,
          };
          localStorage.setItem("userData", JSON.stringify(updatedUserData));
        } catch (parseError) {
          console.error("Error updating user data:", parseError);
        }
      }

      // Call API menggunakan api_laravel
      await setCompanyAPI(token, companyToSelect.id, companyToSelect.c_code);

      // Redirect dengan force
      console.log("✅ Company selected, redirecting...");
      setTimeout(() => {
        window.location.href = "/";
      }, 100);
      
    } catch (err: any) {
      console.error("❌ Company selection error:", err);
      setError(err.message || "Gagal menyimpan pilihan perusahaan");
      clearAuthData();
    } finally {
      setLoading(false);
    }
  };

  const resetLogin = () => {
    clearAuthData();
    setShowCompanySelection(false);
    setCompanies([]);
    setSelectedCompany("");
    setError("");
    setEmail("");
    setPassword("");
  };

  // Function untuk debug
  const checkCurrentStorage = () => {
    console.log("=== CURRENT STORAGE STATUS ===");
    console.log("LocalStorage token:", localStorage.getItem("token"));
    console.log("LocalStorage token type:", typeof localStorage.getItem("token"));
    console.log("LocalStorage token length:", localStorage.getItem("token")?.length);
    console.log("LocalStorage userData:", localStorage.getItem("userData"));
    console.log("All localStorage items:", { ...localStorage });
    console.log("Axios baseURL:", api_laravel.defaults.baseURL);
    console.log("Axios headers:", api_laravel.defaults.headers);
    console.log("==============================");
  };

  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-50 p-4">
      <div className="w-full max-w-md p-6 bg-white rounded-lg shadow-md">
        <h2 className="text-2xl font-bold mb-6 text-center">Login</h2>
        
        {!showCompanySelection ? (
          <>
            {error && (
              <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded text-red-700 text-sm">
                {error}
              </div>
            )}
            
            <form onSubmit={handleLogin} className="space-y-4">
              <div className="space-y-2">
                <Input
                  type="email"
                  placeholder="Email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  disabled={loading}
                  className="w-full"
                  autoComplete="email"
                />
              </div>
              
              <div className="space-y-2">
                <Input
                  type="password"
                  placeholder="Password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  disabled={loading}
                  className="w-full"
                  autoComplete="current-password"
                />
              </div>
              
              <Button 
                type="submit" 
                className="w-full" 
                disabled={loading}
              >
                {loading ? (
                  <span className="flex items-center justify-center">
                    <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Logging in...
                  </span>
                ) : "Login"}
              </Button>

              {/* Debug Panel */}
              <div className="mt-6 p-4 bg-gray-50 rounded-lg border border-gray-200">
                <div className="flex justify-between items-center mb-2">
                  <h3 className="text-sm font-semibold text-gray-700">Debug Panel</h3>
                  <Button 
                    type="button"
                    variant="ghost" 
                    size="sm" 
                    onClick={checkCurrentStorage}
                    className="text-xs"
                  >
                    Check Storage
                  </Button>
                </div>
                
                <div className="text-xs text-gray-600 space-y-1">
                  <div className="flex justify-between">
                    <span>Token Status:</span>
                    <span className={localStorage.getItem("token") ? "text-green-600 font-medium" : "text-red-600"}>
                      {localStorage.getItem("token") ? "PRESENT" : "MISSING"}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span>Token Length:</span>
                    <span>{localStorage.getItem("token")?.length || 0} chars</span>
                  </div>
                  <div className="flex justify-between">
                    <span>User Data:</span>
                    <span>{localStorage.getItem("userData") ? "PRESENT" : "MISSING"}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Companies:</span>
                    <span>{companies.length}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>API Base URL:</span>
                    <span className="text-blue-600">{api_laravel.defaults.baseURL}</span>
                  </div>
                  
                  <div className="mt-2 pt-2 border-t border-gray-200">
                    <Button 
                      type="button"
                      variant="outline" 
                      size="sm" 
                      className="w-full mb-1"
                      onClick={() => {
                        clearAuthData();
                        console.log("Storage cleared manually");
                        alert("All storage cleared!");
                      }}
                    >
                      Clear All Storage
                    </Button>
                    <Button 
                      type="button"
                      variant="outline" 
                      size="sm" 
                      className="w-full"
                      onClick={() => {
                        console.log("Current URL:", window.location.href);
                        console.log("Token value:", localStorage.getItem("token"));
                        console.log("Full localStorage:", { ...localStorage });
                        console.log("Axios config:", api_laravel.defaults);
                      }}
                    >
                      Log Details
                    </Button>
                  </div>
                </div>
              </div>
            </form>
          </>
        ) : (
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-center">
              Pilih Perusahaan
            </h3>
            
            {error && (
              <div className="p-3 bg-yellow-50 border border-yellow-200 rounded text-yellow-700 text-sm">
                {error}
              </div>
            )}
            
            <div className="space-y-2">
              <Select
                value={selectedCompany}
                onValueChange={setSelectedCompany}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Pilih perusahaan" />
                </SelectTrigger>
                <SelectContent>
                  {companies.map((company) => (
                    <SelectItem key={company.id} value={company.id.toString()}>
                      {company.company_name} ({company.c_code})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            <div className="flex space-x-2">
              <Button
                variant="outline"
                className="flex-1"
                onClick={resetLogin}
                disabled={loading}
              >
                Kembali
              </Button>
              <Button
                onClick={handleCompanySelect}
                className="flex-1"
                disabled={!selectedCompany || loading}
              >
                {loading ? "Memproses..." : "Lanjutkan"}
              </Button>
            </div>
            
            {/* Debug info untuk company selection */}
            <div className="mt-4 p-3 bg-blue-50 rounded border border-blue-200">
              <p className="text-xs font-medium text-blue-700 mb-1">Debug Info:</p>
              <div className="text-xs text-blue-600 space-y-1">
                <p>Token: {localStorage.getItem("token") ? "✓" : "✗"}</p>
                <p>Selected Company ID: {selectedCompany || "None"}</p>
                <p>Total Companies: {companies.length}</p>
                <p>API Base URL: {api_laravel.defaults.baseURL}</p>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Login;