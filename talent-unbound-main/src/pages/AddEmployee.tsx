"use client";

import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import api_laravel from "@/lib/utils";
import { useNavigate } from "react-router-dom";
import Swal from "sweetalert2";

interface PayrollSettings {
  bpjs_kesehatan: number;
  bpjs_ketenagakerjaan: number;
  bpjs_jp: number;
  pkp: number;
}

interface PTKP {
  code: string;
  description: string;
}

interface Position {
  id: number;
  nama_jabatan: string;
  level: string;
  deskripsi: string;
}

interface Department {
  id: number;
  name: string;
}

interface Employee {
  id?: number;
  uuid: string;
  name: string;
  position: string;
}

interface Shift {
  id: number;
  deskripsi: string;
  clock_in: string;
  clock_out: string;
}

// ✅ Fungsi untuk mengambil company code dari localStorage
const getCompanyCode = (): string => {
  try {
    // Coba ambil dari user data terlebih dahulu
    const userDataStr = localStorage.getItem("user");
    if (userDataStr) {
      const userData = JSON.parse(userDataStr);
      if (userData.selected_c_code) return userData.selected_c_code;
      if (userData.c_code) return userData.c_code;
    }

    // Coba dari selectedCompany
    const companyData = localStorage.getItem("selectedCompany");
    if (companyData) {
      const parsedData = JSON.parse(companyData);
      if (parsedData.c_code) return parsedData.c_code;
    }

    // Coba langsung dari localStorage
    const directCCode = localStorage.getItem('c_code');
    if (directCCode) return directCCode;

    console.warn("c_code tidak ditemukan di localStorage");
    return "";
  } catch (error) {
    console.error("Error parsing company data:", error);
    return "";
  }
};

export default function AddEmployee() {
  const navigate = useNavigate();

  const [form, setForm] = useState({
    name: "",
    nik: "",
    email: "",
    phone: "",
    position: "",
    department: "",
    shift: "",
    status: "Active",
    salary: "",
    join_date: "",
    flag: "Permanen",
    enddate: "",
    basic_salary: "",
    allowance: "",
    meal_allowance: "",
    overtime_rate: "",
    bpjs_kesehatan: "0",
    bpjs_ketenagakerjaan: "0",
    pkp: "0",
    tax_number: "",
    bpjs_jp: "0",
    c_code: "",
  });

  const [departments, setDepartments] = useState<Department[]>([]);
  const [loading, setLoading] = useState(false);
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);
  const [cvFile, setCvFile] = useState<File | null>(null);
  const [ptkpOptions, setPtkpOptions] = useState<PTKP[]>([]);
  const [selectedPtkp, setSelectedPtkp] = useState<string>("");
  const [supervisors, setSupervisors] = useState<Employee[]>([]);
  const [positions, setPositions] = useState<Position[]>([]);
  const [shifts, setShifts] = useState<Shift[]>([]);
  const [supervisorLoaded, setSupervisorLoaded] = useState(false);
  const [selectedSupervisor, setSelectedSupervisor] = useState<string | null>(null);
  const [cCodeError, setCCodeError] = useState<string | null>(null);

  const validSupervisors = supervisors.map(s => ({
    uuid: s.uuid ?? s.id?.toString() ?? "",
    name: s.name,
    position: s.position
  }));

  // ✅ PERBAIKAN: Gunakan getCompanyCode() untuk mengambil c_code
  useEffect(() => {
    const fetchCompanyCode = () => {
      try {
        const cCode = getCompanyCode();
        console.log("c_code dari getCompanyCode():", cCode);
        
        if (cCode) {
          setForm(prev => ({
            ...prev,
            c_code: cCode
          }));
          setCCodeError(null);
        } else {
          const errorMsg = "c_code tidak ditemukan. Periksa localStorage untuk key 'selectedCompany' atau 'user'";
          console.warn(errorMsg);
          setCCodeError(errorMsg);
          
          // Fallback: coba cek localStorage langsung untuk c_code
          const directCCode = localStorage.getItem('c_code');
          if (directCCode) {
            console.log("Fallback: Menggunakan c_code langsung dari localStorage");
            setForm(prev => ({
              ...prev,
              c_code: directCCode
            }));
            setCCodeError(null);
          }
        }
      } catch (error) {
        console.error("Error mengambil c_code:", error);
        setCCodeError("Error mengambil company code dari localStorage");
      }
    };

    fetchCompanyCode();
  }, []);

  // ambil master PTKP
  useEffect(() => {
    api_laravel.get("/api/master-ptkp")
      .then((res) => {
        if (res.data && Array.isArray(res.data)) {
          setPtkpOptions(res.data);
        } else if (res.data?.data && Array.isArray(res.data.data)) {
          setPtkpOptions(res.data.data);
        } else {
          console.error("Struktur PTKP response tidak dikenali:", res.data);
          setPtkpOptions([]);
        }
      })
      .catch((err) => {
        console.error("Error fetching PTKP:", err);
        Swal.fire("Error", "Gagal ambil master PTKP", "error");
      });
  }, []);

  // ambil data department
  useEffect(() => {
    api_laravel.get("/api/departments")
      .then((res) => {
        let departmentsData: Department[] = [];
        
        if (res.data && Array.isArray(res.data)) {
          departmentsData = res.data;
        } else if (res.data?.data && Array.isArray(res.data.data)) {
          departmentsData = res.data.data;
        } else {
          console.error("Struktur departments response tidak dikenali:", res.data);
        }
        
        setDepartments(departmentsData);
      })
      .catch((err) => {
        console.error("Error fetching departments:", err);
        Swal.fire("Error", "Gagal ambil departments", "error");
      });
  }, []);

  // ambil data shifts
  useEffect(() => {
    api_laravel.get("/api/employees/master/shifts")
      .then((res) => {
        console.log("Shifts API Response:", res.data);
        
        let shiftsData: Shift[] = [];
        
        if (res.data.success && Array.isArray(res.data.data)) {
          shiftsData = res.data.data;
        } else if (Array.isArray(res.data.data)) {
          shiftsData = res.data.data;
        } else if (Array.isArray(res.data)) {
          shiftsData = res.data;
        } else {
          console.error("Struktur shifts response tidak dikenali:", res.data);
        }
        
        setShifts(shiftsData);
      })
      .catch((err) => {
        console.error("Error fetching shifts:", err);
        Swal.fire("Error", "Gagal ambil shift", "error");
      });
  }, []);

  // ambil data positions
  useEffect(() => {
    api_laravel.get("/api/employees/master/position")
      .then(res => {
        console.log("Positions API Response:", res.data);
        
        let positionsData: Position[] = [];
        
        if (res.data.success && Array.isArray(res.data.data)) {
          positionsData = res.data.data;
        } else if (Array.isArray(res.data.data)) {
          positionsData = res.data.data;
        } else if (Array.isArray(res.data)) {
          positionsData = res.data;
        } else {
          console.error("Struktur positions response tidak dikenali:", res.data);
        }
        
        console.log("Processed Positions:", positionsData);
        setPositions(positionsData);
      })
      .catch((err) => {
        console.error("Error fetching positions:", err);
        Swal.fire("Error", "Gagal ambil posisi", "error");
      });
  }, []);

  // ambil daftar employee untuk supervisor
  useEffect(() => {
    const fetchSupervisors = async () => {
      try {
        console.log("🔄 Fetching supervisors...");
        
        const res = await api_laravel.get("/api/employees");
        console.log("📊 Supervisors API Response:", res.data);

        let employeesData: any[] = [];
        
        // Handle berbagai struktur response
        if (res.data.success && res.data.data) {
          if (Array.isArray(res.data.data.data)) {
            employeesData = res.data.data.data;
            console.log("✅ Using nested data.data.data structure");
          } else if (Array.isArray(res.data.data)) {
            employeesData = res.data.data;
            console.log("✅ Using data.data structure");
          }
        } else if (Array.isArray(res.data.data)) {
          employeesData = res.data.data;
          console.log("✅ Using data.data structure (no success flag)");
        } else if (Array.isArray(res.data)) {
          employeesData = res.data;
          console.log("✅ Using direct array structure");
        } else {
          console.error("❌ Struktur supervisors response tidak dikenali:", res.data);
          employeesData = [];
        }

        console.log(`👥 Raw Employees Count: ${employeesData.length}`);

        const data: Employee[] = employeesData
          .filter((e: any) => e && e.id)
          .map((e: any) => ({
            id: e.id,
            uuid: e.uuid || e.id?.toString() || `emp-${e.id}`,
            name: e.name || "Unknown Employee",
            position: e.position_name || e.position || "No Position"
          }));

        console.log(`✅ Processed Supervisors Count: ${data.length}`);
        console.log("✅ Processed Supervisors:", data.slice(0, 3));

        setSupervisors(data);
        setSupervisorLoaded(true);

      } catch (err: any) {
        console.error("❌ Error fetching supervisors:", err);
        
        setSupervisors([]);
        setSupervisorLoaded(true);
        
        Swal.fire({
          icon: "error",
          title: "Error",
          text: "Gagal ambil daftar supervisor",
          timer: 3000,
          showConfirmButton: false,
        });
      }
    };

    fetchSupervisors();
  }, []);

  // ambil default payroll settings
  useEffect(() => {
    api_laravel.get("/api/payroll/settings")
      .then((res) => {
        console.log("Payroll Settings API Response:", res.data);
        
        let settingsData = res.data;
        
        // Handle nested data structure
        if (res.data.data) {
          settingsData = res.data.data;
        }
        
        const data: PayrollSettings = {
          bpjs_kesehatan: parseFloat(settingsData?.bpjs_kesehatan_percent ?? settingsData?.bpjs_kesehatan ?? 0),
          bpjs_ketenagakerjaan: parseFloat(settingsData?.bpjs_ketenaga_percent ?? settingsData?.bpjs_ketenagakerjaan ?? 0),
          bpjs_jp: parseFloat(settingsData?.bpjs_jpensiun_percent ?? settingsData?.bpjs_jp ?? 0),
          pkp: parseFloat(settingsData?.pajak_percent ?? settingsData?.pkp ?? 0),
        };

        console.log("Processed Payroll Settings:", data);

        setForm((prev) => ({
          ...prev,
          bpjs_kesehatan: data.bpjs_kesehatan.toString(),
          bpjs_ketenagakerjaan: data.bpjs_ketenagakerjaan.toString(),
          bpjs_jp: data.bpjs_jp.toString(),
          pkp: data.pkp.toString(),
        }));
      })
      .catch((err) => {
        console.error("Error fetching payroll settings:", err);
        // Tetap lanjutkan meski gagal, gunakan nilai default
        Swal.fire({
          icon: "warning",
          title: "Warning",
          text: "Gagal ambil payroll settings, menggunakan nilai default",
          timer: 2000,
        });
      });
  }, []);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setForm(prev => ({ ...prev, [name]: value }));
  };

  const handleSelectChange = (name: string, value: string) => {
    setForm(prev => ({ ...prev, [name]: value }));
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setAvatarFile(file);
      setAvatarPreview(URL.createObjectURL(file));
    }
  };

  const handleCvChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.type !== "application/pdf") {
        Swal.fire("Error", "Hanya file PDF yang diperbolehkan!", "error");
        e.target.value = "";
        return;
      }
      setCvFile(file);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // ✅ Validasi c_code sebelum submit
    if (!form.c_code) {
      // Coba ambil ulang c_code sebelum menampilkan error
      const currentCCode = getCompanyCode();
      if (currentCCode) {
        setForm(prev => ({ ...prev, c_code: currentCCode }));
      } else {
        Swal.fire({
          icon: "warning",
          title: "Company Code Required",
          html: `
            <div class="text-left">
              <p><strong>c_code tidak ditemukan!</strong></p>
              <p class="mt-2">Silakan:</p>
              <ul class="list-disc pl-4 mt-1">
                <li>Pilih perusahaan terlebih dahulu</li>
                <li>Login ulang</li>
                <li>Hubungi administrator</li>
              </ul>
            </div>
          `,
          confirmButtonText: "OK"
        });
        return;
      }
    }
    
    // Validasi form
    if (!form.name || !form.nik || !form.email || !form.join_date) {
      Swal.fire({
        icon: "error",
        title: "Validation Error",
        text: "Harap isi semua field yang wajib diisi",
      });
      return;
    }
    
    setLoading(true);

    try {
      const formData = new FormData();
      
      // ✅ Tambahkan semua field ke FormData
      Object.entries(form).forEach(([key, value]) => {
        if (value !== null && value !== undefined && value !== "") {
          formData.append(key, value.toString());
        }
      });

      if (avatarFile) formData.append("avatar", avatarFile);
      if (cvFile) formData.append("cv", cvFile);

      if (selectedSupervisor) {
        formData.append("immediate_supervisor", selectedSupervisor);
      }
      
      // tambahkan PTKP
      if (selectedPtkp) {
        formData.append("ptkp_code", selectedPtkp);
      }
      
      // ✅ Log data yang akan dikirim (termasuk c_code)
      console.log("Data yang akan dikirim:", {
        ...form,
        avatarFile: avatarFile?.name || "none",
        cvFile: cvFile?.name || "none",
        selectedSupervisor,
        selectedPtkp,
      });

      const response = await api_laravel.post("/api/employees", formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });

      console.log("Response dari server:", response.data);

      Swal.fire({
        icon: "success",
        title: "Success",
        text: "Employee berhasil ditambahkan!",
        timer: 2000,
        showConfirmButton: false,
      });
      
      setTimeout(() => navigate("/employees"), 2000);
    } catch (err: any) {
      console.error("Error response:", err.response || err);
      console.error("Error details:", err.response?.data);
      
      let errorMessage = "Gagal tambah employee";
      if (err.response?.data?.message) {
        errorMessage = err.response.data.message;
      } else if (err.response?.data?.errors) {
        // Jika ada validation errors
        const errors = Object.values(err.response.data.errors).flat().join(", ");
        errorMessage = `Validation Error: ${errors}`;
      }
      
      Swal.fire(
        "Error",
        errorMessage,
        "error"
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto mt-8">
      <Card>
        <CardHeader>
          <div className="flex justify-between items-start">
            <div>
              <CardTitle>Add Employee</CardTitle>
              <p className={`text-sm mt-1 ${form.c_code ? 'text-green-600' : 'text-red-600'}`}>
                Company Code: <span className="font-semibold">{form.c_code || "Not found"}</span>
              </p>
              {cCodeError && (
                <p className="text-xs text-red-500 mt-1">{cCodeError}</p>
              )}
            </div>
            {!form.c_code && (
              <Button 
                variant="outline" 
                size="sm"
                onClick={() => {
                  // Refresh data dari localStorage
                  const cCode = getCompanyCode();
                  if (cCode) {
                    setForm(prev => ({ ...prev, c_code: cCode }));
                    setCCodeError(null);
                    Swal.fire({
                      icon: "success",
                      title: "Success",
                      text: `c_code ditemukan: ${cCode}`,
                      timer: 2000,
                    });
                  } else {
                    Swal.fire({
                      icon: "error",
                      title: "Error",
                      text: "c_code masih tidak ditemukan. Periksa localStorage.",
                      timer: 3000,
                    });
                  }
                }}
              >
                Refresh c_code
              </Button>
            )}
          </div>
        </CardHeader>
        <CardContent>
          {cCodeError && (
            <div className="bg-yellow-50 border border-yellow-200 rounded-md p-4 mb-4">
              <p className="text-yellow-800 font-medium">Warning: Company Code Issue</p>
              <p className="text-yellow-600 text-sm mt-1">{cCodeError}</p>
              <p className="text-yellow-600 text-xs mt-2">
                Please select a company from the dashboard first, or contact your administrator.
              </p>
            </div>
          )}
          
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Hidden input untuk c_code */}
            <input 
              type="hidden" 
              name="c_code" 
              value={form.c_code} 
            />
            
            <div>
              <label className="text-sm font-medium mb-1 block">Full Name *</label>
              <Input
                placeholder="Enter employee name"
                name="name"
                value={form.name}
                onChange={handleChange}
                required
              />
            </div>
            
            <div>
              <label className="text-sm font-medium mb-1 block">Employee ID (NIK) *</label>
              <Input
                placeholder="Enter employee ID"
                name="nik"
                value={form.nik}
                onChange={handleChange}
                required
              />
            </div>
            
            <div>
              <label className="text-sm font-medium mb-1 block">Email *</label>
              <Input
                placeholder="Enter email address"
                name="email"
                type="email"
                value={form.email}
                onChange={handleChange}
                required
              />
            </div>
            
            <div>
              <label className="text-sm font-medium mb-1 block">Phone Number</label>
              <Input
                placeholder="Enter phone number"
                name="phone"
                value={form.phone}
                onChange={handleChange}
              />
            </div>
            
            <div>
              <label className="text-sm font-medium mb-1 block">Position *</label>
              <Select
                value={form.position}
                onValueChange={(val) => handleSelectChange("position", val)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select Position" />
                </SelectTrigger>
                <SelectContent>
                  {positions.map((pos) => (
                    <SelectItem key={pos.id} value={pos.id.toString()}>
                      {pos.nama_jabatan} ({pos.level})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div>
              <label className="text-sm font-medium mb-1 block">Department *</label>
              <Select
                value={form.department}
                onValueChange={(val) => handleSelectChange("department", val)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select Department" />
                </SelectTrigger>
                <SelectContent>
                  {departments.map((dept) => (
                    <SelectItem key={dept.id} value={dept.id.toString()}>
                      {dept.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div>
              <label className="text-sm font-medium mb-1 block">Supervisor</label>
              <Select
                value={selectedSupervisor ?? "none"}
                onValueChange={val => setSelectedSupervisor(val === "none" ? null : val)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select Supervisor" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="none">No Supervisor</SelectItem>
                  {supervisorLoaded && validSupervisors.map(sup => (
                    <SelectItem key={sup.uuid} value={sup.uuid}>
                      {sup.name} - {sup.position}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div>
              <label className="text-sm font-medium mb-1 block">Status *</label>
              <Select
                value={form.status}
                onValueChange={(val) => handleSelectChange("status", val)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Active">Active</SelectItem>
                  <SelectItem value="On Leave">On Leave</SelectItem>
                  <SelectItem value="Inactive">Inactive</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div>
              <label className="text-sm font-medium mb-1 block">Join Date *</label>
              <Input
                placeholder="Join Date"
                name="join_date"
                type="date"
                value={form.join_date}
                onChange={handleChange}
                required
              />
            </div>

            <div>
              <label className="text-sm font-medium mb-1 block">Employment Type *</label>
              <Select
                value={form.flag}
                onValueChange={(val) => handleSelectChange("flag", val)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select employment type" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Permanen">Permanent</SelectItem>
                  <SelectItem value="Kontrak">Contract</SelectItem>
                </SelectContent>
              </Select>
            </div>
            
            {form.flag === "Kontrak" && (
              <div>
                <label className="text-sm font-medium mb-1 block">Contract End Date *</label>
                <Input
                  placeholder="End Date"
                  name="enddate"
                  type="date"
                  value={form.enddate}
                  onChange={handleChange}
                  required={form.flag === "Kontrak"}
                />
              </div>
            )}

            <h3 className="text-lg font-semibold mt-6 pt-4 border-t">Payroll Information</h3>
            
            <div>
              <label className="text-sm font-medium mb-1 block">Basic Salary</label>
              <Input
                placeholder="Basic Salary"
                name="basic_salary"
                type="number"
                value={form.basic_salary}
                onChange={handleChange}
              />
            </div>
            
            <div>
              <label className="text-sm font-medium mb-1 block">Allowance</label>
              <Input
                placeholder="Allowance"
                name="allowance"
                type="number"
                value={form.allowance}
                onChange={handleChange}
              />
            </div>
            
            <div>
              <label className="text-sm font-medium mb-1 block">Meal Allowance</label>
              <Input
                placeholder="Meal Allowance"
                name="meal_allowance"
                type="number"
                value={form.meal_allowance}
                onChange={handleChange}
              />
            </div>
            
            <div>
              <label className="text-sm font-medium mb-1 block">Overtime Rate per Hour</label>
              <Input
                placeholder="Overtime Rate per Hour"
                name="overtime_rate"
                type="number"
                value={form.overtime_rate}
                onChange={handleChange}
              />
            </div>

            <div>
              <label className="text-sm font-medium mb-1 block">Shift</label>
              <Select
                value={form.shift}
                onValueChange={(val) => handleSelectChange("shift", val)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select Shift" />
                </SelectTrigger>
                <SelectContent>
                  {shifts.map((s) => (
                    <SelectItem key={s.id} value={s.id.toString()}>
                      {s.deskripsi} ({s.clock_in} - {s.clock_out})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div>
              <label className="text-sm font-medium mb-1 block">BPJS Kesehatan</label>
              <div className="flex items-center space-x-2">
                <Input
                  type="number"
                  step="0.01"
                  name="bpjs_kesehatan"
                  value={form.bpjs_kesehatan}
                  onChange={handleChange}
                  disabled
                  className="text-left"
                />
                <span className="text-sm">%</span>
              </div>
              <p className="text-xs text-muted-foreground mt-1">
                Health insurance deduction from salary
              </p>
            </div>

            <div>
              <label className="text-sm font-medium mb-1 block">BPJS Employment</label>
              <div className="flex items-center space-x-2">
                <Input
                  type="number"
                  step="0.01"
                  name="bpjs_ketenagakerjaan"
                  value={form.bpjs_ketenagakerjaan}
                  onChange={handleChange}
                  disabled
                  className="text-left"
                />
                <span className="text-sm">%</span>
              </div>
              <p className="text-xs text-muted-foreground mt-1">
                Employment insurance deduction
              </p>
            </div>

            <div>
              <label className="text-sm font-medium mb-1 block">BPJS Pension</label>
              <div className="flex items-center space-x-2">
                <Input
                  type="number"
                  step="0.01"
                  name="bpjs_jp"
                  value={form.bpjs_jp}
                  onChange={handleChange}
                  disabled
                  className="text-left"
                />
                <span className="text-sm">%</span>
              </div>
              <p className="text-xs text-muted-foreground mt-1">
                Pension insurance deduction
              </p>
            </div>

            <div>
              <label className="text-sm font-medium mb-1 block">Income Tax (PKP)</label>
              <div className="flex items-center space-x-2">
                <Input
                  type="number"
                  step="0.01"
                  name="pkp"
                  value={form.pkp}
                  onChange={handleChange}
                  disabled
                  className="text-left"
                />
                <span className="text-sm">%</span>
              </div>
              <p className="text-xs text-muted-foreground mt-1">
                Income tax percentage
              </p>
            </div>

            <div>
              <label className="text-sm font-medium mb-1 block">Tax Number (NPWP)</label>
              <Input
                placeholder="Enter tax number"
                name="tax_number"
                value={form.tax_number}
                onChange={handleChange}
              />
            </div>

            <div>
              <label className="text-sm font-medium mb-1 block">PTKP</label>
              <Select
                value={selectedPtkp}
                onValueChange={(val) => setSelectedPtkp(val)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select PTKP" />
                </SelectTrigger>
                <SelectContent>
                  {ptkpOptions.map((ptkp) => (
                    <SelectItem key={ptkp.code} value={ptkp.code}>
                      {ptkp.code} - {ptkp.description}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div>
              <label className="text-sm font-medium mb-1 block">Profile Photo</label>
              <Input type="file" accept="image/*" onChange={handleFileChange} />
              {avatarPreview && (
                <div className="mt-2">
                  <img
                    src={avatarPreview}
                    alt="Preview"
                    className="h-24 w-24 rounded-full object-cover border"
                  />
                </div>
              )}
            </div>

            <div>
              <label className="text-sm font-medium mb-1 block">CV (PDF)</label>
              <Input type="file" accept=".pdf" onChange={handleCvChange} />
              {cvFile && (
                <p className="mt-1 text-sm text-gray-500">File: {cvFile.name}</p>
              )}
            </div>

            <div className="pt-4">
              <Button 
                type="submit" 
                disabled={loading || !form.c_code}
                className="w-full"
              >
                {loading ? "Saving..." : form.c_code ? "Save Employee" : "Waiting for Company Code..."}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}