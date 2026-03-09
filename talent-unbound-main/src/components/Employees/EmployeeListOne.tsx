"use client";

import { useState, useEffect } from "react";
import { Search, Plus, Filter, MoreVertical } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import api_laravel from "@/lib/utils";
import { useNavigate } from "react-router-dom";
import Swal from "sweetalert2";

export function EmployeeListOne() {
  const [employees, setEmployees] = useState<any[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedDepartment, setSelectedDepartment] = useState("All");
  const [departmentsList, setDepartmentsList] = useState<string[]>(["All"]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [meta, setMeta] = useState<any>(null);
  const [userRole, setUserRole] = useState<string | null>(null);
  const [employeeUuid, setEmployeeUuid] = useState<string | null>(null);
  const [userDataLoaded, setUserDataLoaded] = useState(false);
  const navigate = useNavigate();

  // Fungsi untuk menghitung gaji
  const calculateNetSalary = (payrollData: any, employeeName: string) => {
    const basic = parseFloat(payrollData.basic_salary || 0);
    const allowance = parseFloat(payrollData.allowance || 0);
    const mealAllowance = parseFloat(payrollData.meal_allowance || 0);
    const overtime = parseFloat(payrollData.overtime || 0);
    
    // Hitung BPJS
    const bpjsKesehatanPercent = parseFloat(payrollData.bpjs_kesehatan || 0) / 100;
    const bpjsKetenagakerjaanPercent = parseFloat(payrollData.bpjs_ketenagakerjaan || 0) / 100;
    const bpjsJpPercent = parseFloat(payrollData.bpjs_jp || 0) / 100;
    
    const bpjsKesehatan = basic * bpjsKesehatanPercent;
    const bpjsKetenagakerjaan = basic * bpjsKetenagakerjaanPercent;
    const bpjsJp = basic * bpjsJpPercent;
    
    // PKP deduction (contoh sederhana)
    const pkpDeduction = parseFloat(payrollData.ptkp_deduction || 0) || 0;
    
    // Gross salary
    const grossSalary = basic + allowance + mealAllowance + overtime;
    
    // Total deduction
    const totalDeduction = bpjsKesehatan + bpjsKetenagakerjaan + bpjsJp + pkpDeduction;
    
    // Net salary
    const netSalary = grossSalary - totalDeduction;
    
    return {
      bpjsKesehatan,
      bpjsKetenagakerjaan,
      bpjsJp,
      pkpDeduction,
      grossSalary,
      totalDeduction,
      netSalary
    };
  };

  // ✅ SEDERHANA: Cek apakah user bisa melihat semua employee
  const canViewAllEmployees = () => {
    if (!userDataLoaded) return false;
    
    if (userRole === null || userRole === undefined || userRole === "") {
      return false;
    }
    
    const lowerRole = userRole.toLowerCase();
    const canView = 
      lowerRole.includes('hrd') || 
      lowerRole.includes('hr') ||
      lowerRole.includes('super-admin') ||
      lowerRole.includes('administrator') ||
      lowerRole === 'admin';
    
    return canView;
  };

  // Cek apakah user bisa menambah employee
  const canAddEmployee = () => {
    return canViewAllEmployees();
  };

  // Format date
  const formatDate = (dateString: string) => {
    if (!dateString) return "-";
    try {
      const date = new Date(dateString);
      return date.toLocaleDateString("id-ID", { year: "numeric", month: "short", day: "numeric" });
    } catch {
      return dateString;
    }
  };

  // Ambil data departemen
  const fetchDepartments = async () => {
    try {
      const res = await api_laravel.get("/api/departments");
      console.log("Departments response:", res.data);
      
      if (res.data && Array.isArray(res.data.data)) {
        const departmentDescriptions = res.data.data
          .map((dept: any) => dept.description || dept.name)
          .filter(Boolean);
        
        setDepartmentsList(["All", ...departmentDescriptions]);
      }
    } catch (err) {
      console.error("Error fetching departments:", err);
      // Fallback ke default departments
      setDepartmentsList([
        "All",
        "Engineering", 
        "Marketing",
        "Sales",
        "HR",
        "Finance",
        "IT"
      ]);
    }
  };

  // ✅ Ambil user data
  useEffect(() => {
    const loadUserData = async () => {
      try {
        console.log("🔄 Loading user data...");
        
        // Coba ambil dari localStorage dulu
        const userDataStr = localStorage.getItem('user');
        let userData = null;
        
        if (userDataStr) {
          try {
            userData = JSON.parse(userDataStr);
            console.log("📁 User data from localStorage:", userData);
            
            if (userData?.role) {
              setUserRole(userData.role);
            }
            
            if (userData?.employee_uuid || userData?.uuid) {
              setEmployeeUuid(userData.employee_uuid || userData.uuid);
            }
          } catch (e) {
            console.error("❌ Error parsing localStorage:", e);
          }
        }
        
        // Konfirmasi dengan API
        try {
          const res = await api_laravel.get("/api/me");
          console.log("🌐 User API Response:", res.data);
          
          let apiUserData = null;
          if (res.data) {
            // Handle berbagai format response
            if (res.data.data?.user) apiUserData = res.data.data.user;
            else if (res.data.data) apiUserData = res.data.data;
            else if (res.data.user) apiUserData = res.data.user;
            else apiUserData = res.data;
          }
          
          if (apiUserData) {
            console.log("✅ API user data:", apiUserData);
            
            // Set dari API
            setUserRole(apiUserData.role || null);
            
            if (apiUserData.employee_uuid || apiUserData.uuid) {
              setEmployeeUuid(apiUserData.employee_uuid || apiUserData.uuid);
            }
            
            // Simpan ke localStorage
            localStorage.setItem('user', JSON.stringify(apiUserData));
          }
        } catch (apiErr) {
          console.error("⚠️ API error, using stored data:", apiErr);
          // Tetap gunakan data dari localStorage jika ada
          if (!userData && userDataStr) {
            try {
              const parsed = JSON.parse(userDataStr);
              setUserRole(parsed.role || null);
              setEmployeeUuid(parsed.employee_uuid || parsed.uuid || null);
            } catch (e) {
              console.error("❌ Failed to parse stored data:", e);
            }
          }
        }
        
      } catch (err) {
        console.error("❌ Error loading user data:", err);
      } finally {
        // Tandai bahwa user data sudah selesai di-load
        setUserDataLoaded(true);
        console.log("✅ User data loaded, userRole:", userRole);
      }
    };
    
    loadUserData();
    
    // Fetch departments jika bisa melihat semua
    if (canViewAllEmployees()) {
      fetchDepartments();
    }
  }, []);

  // ✅ Fetch employees - hanya panggil setelah userDataLoaded
  const fetchEmployees = async (pageNum = 1, search = "", department = "") => {
    if (!userDataLoaded) {
      console.log("⏳ Waiting for user data to load...");
      return;
    }
    
    setLoading(true);
    try {
      const canViewAll = canViewAllEmployees();
      console.log("🔍 Fetching employees, canViewAll:", canViewAll, "employeeUuid:", employeeUuid);
      
      if (!canViewAll) {
        // HANYA ambil data diri sendiri
        console.log("👤 Fetching ONLY own data");
        
        if (!employeeUuid) {
          console.log("❌ No employeeUuid found");
          setEmployees([]);
          setMeta(null);
          setLoading(false);
          return;
        }
        
        try {
          const res = await api_laravel.get(`/api/employees/${employeeUuid}`);
          console.log("✅ Own employee response:", res.data);
          
          let employeeData = null;
          if (res.data?.data?.data) employeeData = res.data.data.data;
          else if (res.data?.data) employeeData = res.data.data;
          else if (res.data?.success && res.data.data) employeeData = res.data.data;
          else employeeData = res.data;
          
          // Selalu jadikan array dengan 1 employee
          if (employeeData) {
            const emp = Array.isArray(employeeData) ? employeeData[0] : employeeData;
            setEmployees([emp]);
          } else {
            // Buat data dummy dari user info
            const dummyEmp = {
              id: 1,
              uuid: employeeUuid,
              name: "My Profile",
              position: "Employee",
              department_description: "My Department",
              status: "Active",
              join_date: new Date().toISOString().split('T')[0],
              email: "user@example.com",
              avatar: null,
              cv: null,
              clock_in: "09:00",
              clock_out: "17:00",
              shift_description: "Regular"
            };
            setEmployees([dummyEmp]);
          }
          
          setMeta({
            current_page: 1,
            last_page: 1,
            total: 1,
            from: 1,
            to: 1
          });
        } catch (err: any) {
          console.error("❌ Error fetching own data:", err.response?.data || err.message);
          // Tetap tampilkan data dummy
          const dummyEmp = {
            id: 1,
            uuid: employeeUuid,
            name: "My Profile",
            position: "Employee",
            department_description: "My Department",
            status: "Active",
            join_date: new Date().toISOString().split('T')[0],
            email: "user@example.com",
            avatar: null,
            cv: null,
            clock_in: "09:00",
            clock_out: "17:00",
            shift_description: "Regular"
          };
          setEmployees([dummyEmp]);
          setMeta({
            current_page: 1,
            last_page: 1,
            total: 1,
            from: 1,
            to: 1
          });
        }
      } else {
        // Ambil SEMUA data
        console.log("👥 Fetching ALL employees");
        
        const params = new URLSearchParams();
        params.append('page', pageNum.toString());
        if (search) params.append('search', search);
        if (department && department !== "All") params.append('department', department);

        const res = await api_laravel.get(`/api/employees?${params.toString()}`);
        console.log("✅ All employees response:", res.data);
        
        let employeesData = [];
        let metaData = null;

        if (res.data) {
          if (res.data.data && Array.isArray(res.data.data.data)) {
            employeesData = res.data.data.data;
            metaData = res.data.data.meta;
          } else if (res.data.data && Array.isArray(res.data.data)) {
            employeesData = res.data.data;
            metaData = {
              current_page: res.data.current_page || 1,
              last_page: res.data.last_page || 1,
              total: res.data.total || 0,
              from: res.data.from || 1,
              to: res.data.to || 0
            };
          } else if (Array.isArray(res.data.data)) {
            employeesData = res.data.data;
          } else if (Array.isArray(res.data)) {
            employeesData = res.data;
          } else if (res.data.success && Array.isArray(res.data.data)) {
            employeesData = res.data.data;
            metaData = res.data.meta;
          } else if (Array.isArray(res.data?.employees)) {
            employeesData = res.data.employees;
            metaData = res.data.meta;
          }
        }

        setEmployees(employeesData || []);
        setMeta(metaData);
      }
      
      setPage(pageNum);
      
    } catch (err: any) {
      console.error("❌ Error:", err.response?.data || err.message);
      Swal.fire("Error", "Gagal mengambil data", "error");
      setEmployees([]);
      setMeta(null);
    } finally {
      setLoading(false);
    }
  };

  // Fetch data setelah userDataLoaded
  useEffect(() => {
    if (userDataLoaded) {
      console.log("🚀 User data loaded, fetching employees...");
      const timer = setTimeout(() => {
        fetchEmployees();
      }, 100);
      return () => clearTimeout(timer);
    }
  }, [userDataLoaded, employeeUuid]);

  // Search & filter hanya untuk yang bisa lihat semua
  useEffect(() => {
    if (userDataLoaded && canViewAllEmployees()) {
      const delayDebounce = setTimeout(() => {
        const dept = selectedDepartment === "All" ? "" : selectedDepartment;
        fetchEmployees(1, searchTerm, dept);
      }, 500);
      return () => clearTimeout(delayDebounce);
    }
  }, [searchTerm, selectedDepartment, userDataLoaded]);

  // Handle deactivate
  const handleDeactivate = async (employee: any) => {
    if (!canAddEmployee()) {
      Swal.fire("Error", "Tidak ada izin", "error");
      return;
    }

    const { value: formValues } = await Swal.fire({
      title: `Deactivate ${employee.name}`,
      html: `<label>Tanggal Non-Active</label><input type="date" id="deactive_date" class="swal2-input">
             <label>Alasan</label><textarea id="reason" class="swal2-textarea"></textarea>`,
      focusConfirm: false,
      preConfirm: () => {
        const deactive_date = (document.getElementById("deactive_date") as HTMLInputElement).value;
        const reason = (document.getElementById("reason") as HTMLTextAreaElement).value;
        if (!deactive_date) {
          Swal.showValidationMessage("Tanggal wajib diisi");
          return;
        }
        return { deactive_date, reason };
      },
      showCancelButton: true,
      confirmButtonText: "Submit",
      cancelButtonText: "Batal",
    });

    if (formValues) {
      try {
        await api_laravel.post(`/api/employees/deactivate/${employee.uuid}`, {
          deactive_date: formValues.deactive_date,
          reason: formValues.reason,
        });
        Swal.fire("Success", "Berhasil dinonaktifkan", "success");
        fetchEmployees(page, searchTerm, selectedDepartment === "All" ? "" : selectedDepartment);
      } catch (err: any) {
        Swal.fire("Error", err.response?.data?.message || "Gagal", "error");
      }
    }
  };

  const getStatusBadge = (status: string) => {
    if (!status) return <Badge variant="secondary">Unknown</Badge>;
    
    switch (status.toLowerCase()) {
      case "active": return <Badge className="bg-green-100 text-green-800">Active</Badge>;
      case "on leave": 
      case "on_leave": return <Badge className="bg-yellow-100 text-yellow-800">On Leave</Badge>;
      case "inactive": return <Badge className="bg-red-100 text-red-800">Inactive</Badge>;
      case "deactive": return <Badge className="bg-gray-100 text-gray-800">Deactive</Badge>;
      default: return <Badge variant="secondary">{status}</Badge>;
    }
  };

  // Fungsi untuk mendapatkan nama department yang benar
  const getDepartmentName = (employee: any) => {
    // Prioritaskan department_description, lalu department_name, lalu department
    return employee.department_description || 
           employee.department_name || 
           employee.department || 
           "-";
  };

  // Tampilkan loading hanya jika belum load dan belum ada data
  if (loading && employees.length === 0) {
    return (
      <div className="flex flex-col justify-center items-center min-h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mb-4"></div>
        <p className="text-lg text-muted-foreground">Loading employee data...</p>
        <p className="text-sm text-muted-foreground mt-2">
          {!userDataLoaded ? "Loading user information..." : "Fetching employee records..."}
        </p>
      </div>
    );
  }

  // Jika tidak bisa lihat semua dan tidak ada data
  if (!canViewAllEmployees() && employees.length === 0 && !loading) {
    return (
      <div className="space-y-6">
        <Card>
          <CardHeader>
            <div className="flex justify-between items-center">
              <div>
                <CardTitle>My Profile</CardTitle>
                <p className="text-muted-foreground">View your information</p>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-center py-8">
              <p className="text-muted-foreground">No data found for your account</p>
              <p className="text-sm text-muted-foreground mt-2">
                Please contact HR if you believe this is an error.
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex justify-between items-center">
            <div>
              <CardTitle>
                {canViewAllEmployees() ? "Employee Directory" : "My Profile"}
              </CardTitle>
              <p className="text-muted-foreground">
                {canViewAllEmployees() ? "Manage all employees" : "View your information"}
              </p>
            </div>
            
            {canAddEmployee() && (
              <Button className="btn-gradient" onClick={() => navigate("/employees/add")}>
                <Plus className="h-4 w-4 mr-2" /> Add Employee
              </Button>
            )}
          </div>
        </CardHeader>
        <CardContent>
          {/* Debug info - bisa dihapus setelah testing */}
          <div className="mb-4 p-2 bg-blue-50 text-sm text-blue-800 rounded">
            <p><strong>Debug Info:</strong> User Role: "{userRole}" | Can View All: {canViewAllEmployees() ? "Yes" : "No"} | Employee UUID: {employeeUuid || "Not set"}</p>
          </div>

          {canViewAllEmployees() && (
            <>
              <div className="flex flex-col sm:flex-row gap-4 mb-6">
                <div className="relative flex-1">
                  <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input 
                    placeholder="Search by name, email, or position..." 
                    value={searchTerm} 
                    onChange={e => setSearchTerm(e.target.value)} 
                    className="pl-10" 
                  />
                </div>
                
                <select 
                  value={selectedDepartment}
                  onChange={e => setSelectedDepartment(e.target.value)}
                  className="border rounded-md px-3 py-2 bg-white"
                >
                  {departmentsList.map(dept => (
                    <option key={dept} value={dept}>{dept}</option>
                  ))}
                </select>

                <Button variant="outline" className="flex items-center">
                  <Filter className="h-4 w-4 mr-2" /> More Filters
                </Button>
              </div>

              {meta && meta.total > 0 && (
                <div className="mb-4 text-sm text-muted-foreground">
                  Showing {meta.from || 0} to {meta.to || 0} of {meta.total || 0} employees
                </div>
              )}
            </>
          )}

          <div className={`grid ${canViewAllEmployees() ? 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3' : 'grid-cols-1'} gap-4`}>
            {employees.length > 0 ? (
              employees.map(employee => (
                <Card key={employee.id || employee.uuid} className="hover:shadow-md transition-shadow">
                  <CardContent className="p-6">
                    <div className="flex items-start justify-between mb-4">
                      <div className="flex items-center space-x-3">
                        <Avatar className="h-12 w-12">
                          <AvatarImage src={employee.avatar} alt={employee.name} />
                          <AvatarFallback className="bg-blue-100 text-blue-800">
                            {employee.name ? 
                              employee.name.split(" ").map((n: string) => n[0]).join("").toUpperCase().substring(0, 2) 
                              : "?"}
                          </AvatarFallback>
                        </Avatar>
                        <div>
                          <h3 className="font-semibold text-lg">{employee.name || "No Name"}</h3>
                          <p className="text-sm text-muted-foreground">
                            {employee.position_name || employee.position || "-"}
                          </p>
                        </div>
                      </div>

                      {/* DROPDOWN MENU LENGKAP */}
                      {(canViewAllEmployees() || (employeeUuid && employee.uuid === employeeUuid)) ? (
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                              <MoreVertical className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuItem onClick={() => navigate(`/employees/${employee.uuid}`)}>
                              View Details
                            </DropdownMenuItem>
                            
                            <DropdownMenuItem
                              onClick={() => navigate(`/employees/${employee.uuid}/attendance-history`)}
                            >
                              Attendance History (2 Weeks)
                            </DropdownMenuItem>

                            <DropdownMenuItem
                              onClick={() => {
                                if (employee.cv) window.open(`${api_laravel.defaults.baseURL}/${employee.cv}`, "_blank");
                                else alert("CV is not uploaded yet.");
                              }}
                            >
                              Curriculum Vitae
                            </DropdownMenuItem>

                            {/* Payroll Slip - hanya untuk employee sendiri atau admin/HR */}
                            {(canViewAllEmployees() || (employeeUuid && employee.uuid === employeeUuid)) && (
                              <DropdownMenuItem
                                onClick={async () => {
                                  try {
                                    const res = await api_laravel.get(`/api/employees/${employee.uuid}/payroll`);
                                    const payrolls = res.data.data;
                                    if (!payrolls || Object.keys(payrolls).length === 0) {
                                      Swal.fire("Info", "Belum ada data payroll untuk employee ini.", "info");
                                      return;
                                    }

                                    let html = "";
                                    for (const key of Object.keys(payrolls)) {
                                      html += `<strong>📅 ${key}</strong><br/>`;
                                      for (const p of payrolls[key]) {
                                        const calc = calculateNetSalary(p, employee.name);
                                        html += `
                                          Employee: ${employee.name} <br/>
                                          Basic: Rp ${parseFloat(p.basic_salary || 0).toLocaleString("id-ID")} <br/>
                                          Allowance: Rp ${parseFloat(p.allowance || 0).toLocaleString("id-ID")} <br/>
                                          Meal Allowance: Rp ${parseFloat(p.meal_allowance || 0).toLocaleString("id-ID")} <br/>
                                          BPJS Kesehatan (${p.bpjs_kesehatan}%): Rp ${calc.bpjsKesehatan.toLocaleString("id-ID")} <br/>
                                          BPJS Ketenagakerjaan (${p.bpjs_ketenagakerjaan}%): Rp ${calc.bpjsKetenagakerjaan.toLocaleString("id-ID")} <br/>
                                          BPJS Jaminan Pensiun (${p.bpjs_jp}%): Rp ${calc.bpjsJp.toLocaleString("id-ID")} <br/>
                                          PKP Deduction (${p.ptkp_code}): Rp ${calc.pkpDeduction.toLocaleString("id-ID")} <br/>
                                          Overtime: Rp ${parseFloat(p.overtime ?? 0).toLocaleString("id-ID")} <br/>
                                          Gross Salary: Rp ${calc.grossSalary.toLocaleString("id-ID")} <br/>
                                          Total Deduction: Rp ${calc.totalDeduction.toLocaleString("id-ID")} <br/>
                                          Net Salary: Rp ${calc.netSalary.toLocaleString("id-ID")} <br/><br/>
                                        `;
                                      }
                                    }

                                    Swal.fire({
                                      title: `Payroll Slip - ${employee.name}`,
                                      html,
                                      width: 600,
                                      confirmButtonText: "Close",
                                    });
                                  } catch (err) {
                                    console.error(err);
                                    Swal.fire("Error", "Gagal ambil data payroll", "error");
                                  }
                                }}
                              >
                                Payroll Slip
                              </DropdownMenuItem>
                            )}

                            {/* Deactivate option hanya untuk admin/HR */}
                            {canAddEmployee() && employee.status !== "deactive" && (
                              <DropdownMenuItem 
                                className="text-destructive" 
                                onClick={() => handleDeactivate(employee)}
                              >
                                Deactivate
                              </DropdownMenuItem>
                            )}
                          </DropdownMenuContent>
                        </DropdownMenu>
                      ) : null}
                    </div>

                    <div className="space-y-3">
                      <div className="flex items-center justify-between">
                        <span className="text-sm text-muted-foreground">Department</span>
                        <span className="text-sm font-medium">
                          {getDepartmentName(employee)}
                        </span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span className="text-sm text-muted-foreground">Status</span>
                        {getStatusBadge(employee.status || "Active")}
                      </div>
                      <div className="flex items-center justify-between">
                        <span className="text-sm text-muted-foreground">Join Date</span>
                        <span className="text-sm">{formatDate(employee.join_date)}</span>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))
            ) : (
              <div className="col-span-full text-center py-12">
                <div className="mx-auto w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-4">
                  <Search className="h-8 w-8 text-gray-400" />
                </div>
                <h3 className="text-lg font-medium mb-2">No employees found</h3>
                <p className="text-muted-foreground mb-4">
                  {canViewAllEmployees() && (searchTerm || selectedDepartment !== "All") 
                    ? "Try changing your search or filter criteria"
                    : "No employee records available"}
                </p>
                {canViewAllEmployees() && (searchTerm || selectedDepartment !== "All") && (
                  <Button 
                    variant="outline" 
                    onClick={() => {
                      setSearchTerm("");
                      setSelectedDepartment("All");
                      fetchEmployees(1, "", "");
                    }}
                  >
                    Clear Filters
                  </Button>
                )}
              </div>
            )}
          </div>

          {canViewAllEmployees() && meta && meta.last_page > 1 && (
            <div className="flex justify-center items-center space-x-2 mt-8">
              <Button 
                variant="outline" 
                size="sm"
                disabled={page === 1} 
                onClick={() => fetchEmployees(page - 1, searchTerm, selectedDepartment === "All" ? "" : selectedDepartment)}
              >
                Previous
              </Button>
              <span className="text-sm px-4">
                Page {meta.current_page} of {meta.last_page}
              </span>
              <Button 
                variant="outline" 
                size="sm"
                disabled={page === meta.last_page} 
                onClick={() => fetchEmployees(page + 1, searchTerm, selectedDepartment === "All" ? "" : selectedDepartment)}
              >
                Next
              </Button>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

export default EmployeeListOne;