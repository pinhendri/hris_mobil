"use client";

import { useState, useEffect } from "react";
import { Search, Plus, Filter, MoreVertical, Mail, Phone } from "lucide-react";
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

export function EmployeeList() {
  const [employees, setEmployees] = useState<any[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedDepartment, setSelectedDepartment] = useState("All");
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [meta, setMeta] = useState<any>(null);
  const [userRole, setUserRole] = useState<string>(""); 
  const [userRoles, setUserRoles] = useState<string[]>([]);
  const [userId, setUserId] = useState<number | null>(null);
  const [userUuid, setUserUuid] = useState<string | null>(null); // Tambahkan state untuk user UUID
  const [employeeUuid, setEmployeeUuid] = useState<string | null>(null); // Tambahkan state untuk employee UUID
  const [ptkpMasterMap, setPtkpMasterMap] = useState<{ [code: string]: number }>({});
  const navigate = useNavigate();

  // Format date
  const formatDate = (dateString: string) => {
    if (!dateString) return "-";
    const date = new Date(dateString);
    return date.toLocaleDateString("id-ID", { year: "numeric", month: "short", day: "numeric" });
  };

  // ✅ PERBAIKAN: Fetch PTKP master dengan error handling
  useEffect(() => {
    const fetchPtkpMaster = async () => {
      try {
        const resPtkp = await api_laravel.get("/api/employees/ptkp");
        console.log("PTKP API Response:", resPtkp.data);
        
        const map: { [code: string]: number } = {};
        if (resPtkp.data && resPtkp.data.data) {
          resPtkp.data.data.forEach((item: any) => {
            map[item.code] = parseFloat(item.amount || item.ptkp_annual || 0);
          });
        }
        setPtkpMasterMap(map);
      } catch (err) {
        console.error("Error fetching PTKP master:", err);
      }
    };

    fetchPtkpMaster();
  }, []);

  // Calculate net salary
  const calculateNetSalary = (payroll: any, employeeName: string) => {
    try {
      const basicSalary = parseFloat(payroll.basic_salary ?? "0");
      const allowance = parseFloat(payroll.allowance ?? "0");
      const mealAllowance = parseFloat(payroll.meal_allowance ?? "0");

      const bpjsKesehatan = (parseFloat(payroll.bpjs_kesehatan ?? "0") / 100) * basicSalary;
      const bpjsKetenagakerjaan = (parseFloat(payroll.bpjs_ketenagakerjaan ?? "0") / 100) * basicSalary;
      const bpjsJp = (parseFloat(payroll.bpjs_jp ?? "0") / 100) * basicSalary;

      const grossSalary = basicSalary + allowance + mealAllowance;
      const annualIncome = (grossSalary - (bpjsKesehatan + bpjsKetenagakerjaan + bpjsJp)) * 12;

      const ptkpAnnual = ptkpMasterMap[(payroll.ptkp_code ?? "TK").trim()] ?? 54000000;

      let pkpDeduction = 0;
      if (annualIncome > ptkpAnnual) {
        pkpDeduction = ((annualIncome - ptkpAnnual) / 12) * 0.05;
      }

      const totalDeduction = bpjsKesehatan + bpjsKetenagakerjaan + bpjsJp + pkpDeduction;
      const netSalary = grossSalary - totalDeduction;

      return { grossSalary, totalDeduction, netSalary, bpjsKesehatan, bpjsKetenagakerjaan, bpjsJp, pkpDeduction };
    } catch (error) {
      console.error("Error calculating net salary:", error);
      return { grossSalary: 0, totalDeduction: 0, netSalary: 0, bpjsKesehatan: 0, bpjsKetenagakerjaan: 0, bpjsJp: 0, pkpDeduction: 0 };
    }
  };

  // ✅ PERBAIKAN: Fetch employees dengan permission check
  const fetchEmployees = async (pageNum = 1, search = "", department = "") => {
    setLoading(true);
    try {
      // ✅ Jika user adalah "user" atau null, hanya ambil data dirinya sendiri
      if (userRoles.includes("user") || !userRole || userRole === "user") {
        if (employeeUuid) {
          // Gunakan endpoint yang benar untuk mengambil data employee berdasarkan UUID
          const res = await api_laravel.get(`/api/employees/${employeeUuid}`);
          console.log("Fetching single employee:", res.data);
          
          if (res.data) {
            let employeeData = null;
            
            // Handle berbagai struktur response
            if (res.data.data?.data) {
              employeeData = res.data.data.data;
            } else if (res.data.data) {
              employeeData = res.data.data;
            } else if (res.data.success && res.data.data) {
              employeeData = res.data.data;
            } else {
              employeeData = res.data;
            }
            
            console.log("Employee data extracted:", employeeData);
            
            // Set sebagai array dengan satu employee
            if (employeeData) {
              // Jika employeeData adalah array, ambil elemen pertama
              if (Array.isArray(employeeData) && employeeData.length > 0) {
                setEmployees([employeeData[0]]);
              } else if (typeof employeeData === 'object') {
                setEmployees([employeeData]);
              } else {
                setEmployees([]);
              }
            } else {
              setEmployees([]);
            }
            
            setMeta({
              current_page: 1,
              last_page: 1,
              total: employees.length > 0 ? 1 : 0,
              from: employees.length > 0 ? 1 : 0,
              to: employees.length > 0 ? 1 : 0
            });
          }
        } else {
          // Jika tidak ada employeeUuid, coba ambil data dari /api/me
          try {
            const userRes = await api_laravel.get("/api/me");
            if (userRes.data?.data?.user) {
              const userData = userRes.data.data.user;
              // Buat data employee dari user data
              const employeeFromUser = {
                id: userData.id,
                uuid: userData.uuid || employeeUuid,
                name: userData.name,
                email: userData.email,
                department_description: userData.department || "Not Assigned",
                status: "Active",
                position: "Employee",
                join_date: new Date().toISOString().split('T')[0],
                avatar: null,
                cv: null
              };
              setEmployees([employeeFromUser]);
              setMeta({
                current_page: 1,
                last_page: 1,
                total: 1,
                from: 1,
                to: 1
              });
            } else {
              setEmployees([]);
              setMeta(null);
            }
          } catch (err) {
            console.error("Failed to fetch user data:", err);
            setEmployees([]);
            setMeta(null);
          }
        }
      } else {
        // Untuk admin/HR, fetch semua data seperti biasa
        const params = new URLSearchParams();
        params.append('page', pageNum.toString());
        if (search) params.append('search', search);
        if (department && department !== "All") params.append('department', department);

        console.log("Fetching employees with params:", params.toString());
        
        const res = await api_laravel.get(`/api/employees?${params.toString()}`);
        
        console.log("Full API Response:", res);
        console.log("Response data:", res.data);
        
        // Handle berbagai kemungkinan struktur response
        let employeesData = [];
        let metaData = null;

        if (res.data) {
          if (res.data.data && Array.isArray(res.data.data.data)) {
            employeesData = res.data.data.data;
            metaData = res.data.data.meta;
          } else if (res.data.data && Array.isArray(res.data.data)) {
            employeesData = res.data.data;
            metaData = {
              current_page: res.data.current_page,
              last_page: res.data.last_page,
              total: res.data.total,
              from: res.data.from,
              to: res.data.to
            };
          } else if (Array.isArray(res.data.data)) {
            employeesData = res.data.data;
          } else if (Array.isArray(res.data)) {
            employeesData = res.data;
          } else if (res.data.success && Array.isArray(res.data.data)) {
            employeesData = res.data.data;
            metaData = res.data.meta;
          }
        }

        console.log("Processed employees data:", employeesData);
        console.log("Processed meta data:", metaData);

        setEmployees(employeesData || []);
        setMeta(metaData);
      }
      
      setPage(pageNum);
      
    } catch (err: any) {
      console.error("Gagal ambil data employees:", err);
      console.error("Error response:", err.response);
      
      let errorMessage = "Gagal mengambil data employees";
      if (err.response?.data?.message) {
        errorMessage = err.response.data.message;
      } else if (err.message) {
        errorMessage = err.message;
      }
      
      Swal.fire({
        icon: "error",
        title: "Error",
        text: errorMessage,
        timer: 3000
      });
      
      setEmployees([]);
      setMeta(null);
    } finally {
      setLoading(false);
    }
  };

  // ✅ PERBAIKAN: Fetch user data dengan menyimpan semua informasi yang diperlukan
  useEffect(() => {
    const fetchUser = async () => {
      try {
        const res = await api_laravel.get("/api/me");
        console.log("User API Response:", res.data);
        
        let userData = null;
        
        if (res.data) {
          if (res.data.data?.user) {
            userData = res.data.data.user;
          } else if (res.data.data) {
            userData = res.data.data;
          } else if (res.data.user) {
            userData = res.data.user;
          } else {
            userData = res.data;
          }
        }
        
        console.log("Extracted User Data:", userData);
        
        if (userData) {
          // Simpan semua informasi user
          if (userData.id) {
            setUserId(userData.id);
          }
          
          if (userData.uuid) {
            setUserUuid(userData.uuid);
          }
          
          if (userData.employee_uuid) {
            setEmployeeUuid(userData.employee_uuid);
          }
          
          // Simpan roles
          if (userData.roles && Array.isArray(userData.roles)) {
            setUserRoles(userData.roles);
            setUserRole(userData.roles[0] || "");
          } else if (userData.role) {
            setUserRoles([userData.role]);
            setUserRole(userData.role);
          } else {
            // Default role jika tidak ada
            setUserRoles(["user"]);
            setUserRole("user");
          }
        } else {
          // Fallback jika tidak ada data user
          setUserRoles(["user"]);
          setUserRole("user");
        }
      } catch (err) {
        console.error("Error fetching user data:", err);
        // Set default roles jika gagal
        setUserRoles(["user"]);
        setUserRole("user");
      }
    };
    fetchUser();
  }, []);

  // ✅ PERBAIKAN: Check if user can add employee
  const canAddEmployee = () => {
    console.log("Checking permissions - User Roles:", userRoles);
    
    const canAdd = userRoles.includes("administrator") || 
                   userRoles.includes("manager-hrd") || 
                   userRoles.includes("hrd") ||
                   userRole === "administrator" || 
                   userRole === "manager-hrd";
    
    console.log("Can add employee:", canAdd);
    return canAdd;
  };

  // ✅ PERBAIKAN: Check if user can view all employees
  const canViewAllEmployees = () => {
    const canView = userRoles.includes("administrator") || 
                    userRoles.includes("manager-hrd") || 
                    userRoles.includes("hrd") ||
                    userRole === "administrator" || 
                    userRole === "manager-hrd" ||
                    userRole === "hrd";
    
    return canView;
  };

  // ✅ PERBAIKAN: Initial data fetch dengan dependency yang benar
  useEffect(() => {
    if (userRole) {
      // Tunggu sebentar untuk memastikan semua state user sudah terisi
      const timer = setTimeout(() => {
        fetchEmployees();
      }, 100);
      
      return () => clearTimeout(timer);
    }
  }, [userRole, employeeUuid, userUuid]);

  // Search & filter debounce hanya untuk admin/HR
  useEffect(() => {
    if (canViewAllEmployees()) {
      const delayDebounce = setTimeout(() => {
        const dept = selectedDepartment === "All" ? "" : selectedDepartment;
        fetchEmployees(1, searchTerm, dept);
      }, 500);
      return () => clearTimeout(delayDebounce);
    }
  }, [searchTerm, selectedDepartment]);

  // Handle deactivate hanya untuk admin/HR
  const handleDeactivate = async (employee: any) => {
    if (!canAddEmployee()) {
      Swal.fire("Error", "Anda tidak memiliki izin untuk menonaktifkan employee", "error");
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
          Swal.showValidationMessage("Tanggal Non-Active wajib diisi");
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
        Swal.fire("Success", `${employee.name} berhasil dinonaktifkan`, "success");
        fetchEmployees(page, searchTerm, selectedDepartment === "All" ? "" : selectedDepartment);
      } catch (err: any) {
        console.error(err.response?.data || err);
        Swal.fire("Error", err.response?.data?.message || "Gagal menonaktifkan employee", "error");
      }
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "Active": return <Badge className="bg-green-100 text-green-800">Active</Badge>;
      case "On Leave": return <Badge className="bg-yellow-100 text-yellow-800">On Leave</Badge>;
      case "Inactive": return <Badge className="bg-red-100 text-red-800">Inactive</Badge>;
      case "deactive": return <Badge className="bg-gray-100 text-gray-800">Deactive</Badge>;
      default: return <Badge variant="secondary">{status}</Badge>;
    }
  };

  // Departments untuk filter (hanya untuk admin/HR)
  const departments = [
    "All",
    "Engineering", 
    "Marketing",
    "Sales",
    "HR",
    "Finance",
    "IT"
  ];

  if (loading && employees.length === 0) {
    return (
      <div className="flex justify-center items-center min-h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        <p className="ml-2 text-lg">Loading employee data...</p>
      </div>
    );
  }

  // Jika user adalah "user" dan tidak ada data
  if ((userRoles.includes("user") || !userRole || userRole === "user") && employees.length === 0 && !loading) {
    return (
      <div className="space-y-6 animate-fade-in">
        <Card className="card-dashboard">
          <CardHeader>
            <div className="flex justify-between items-center">
              <div>
                <CardTitle>My Profile</CardTitle>
                <p className="text-muted-foreground">View your employee information</p>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-center py-8">
              <p className="text-muted-foreground">No employee data found for your account.</p>
              <p className="text-sm text-muted-foreground mt-2">Please contact HR if this is incorrect.</p>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <Card className="card-dashboard">
        <CardHeader>
          <div className="flex justify-between items-center">
            <div>
              <CardTitle>
                {canViewAllEmployees() ? "Employee Directory" : "My Profile"}
              </CardTitle>
              <p className="text-muted-foreground">
                {canViewAllEmployees() 
                  ? "Manage and view all employee information" 
                  : "View your employee information"}
              </p>
            </div>
            
            {/* ✅ PERBAIKAN: Tombol Add Employee hanya untuk yang berhak */}
            {canAddEmployee() && (
              <Button className="btn-gradient" onClick={() => navigate("/employees/add")}>
                <Plus className="h-4 w-4 mr-2" /> Add Employee
              </Button>
            )}
          </div>
        </CardHeader>
        <CardContent>
          {/* Search & Filter hanya untuk admin/HR */}
          {canViewAllEmployees() && (
            <>
              <div className="flex flex-col sm:flex-row gap-4 mb-6">
                <div className="relative flex-1">
                  <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input 
                    placeholder="Search by name, email, position, department..." 
                    value={searchTerm} 
                    onChange={e => setSearchTerm(e.target.value)} 
                    className="pl-10" 
                  />
                </div>
                
                {/* Department Filter */}
                <select 
                  value={selectedDepartment}
                  onChange={e => setSelectedDepartment(e.target.value)}
                  className="border rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  {departments.map(dept => (
                    <option key={dept} value={dept}>{dept}</option>
                  ))}
                </select>

                <Button variant="outline" className="flex items-center">
                  <Filter className="h-4 w-4 mr-2" /> More Filters
                </Button>
              </div>

              {/* Employee Count hanya untuk admin/HR */}
              {meta && canViewAllEmployees() && (
                <div className="mb-4 text-sm text-muted-foreground">
                  Showing {meta.from || 0} to {meta.to || 0} of {meta.total || 0} employees
                </div>
              )}
            </>
          )}

          {/* Employee Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {employees.length > 0 ? (
              employees.map(employee => (
                <Card key={employee.id || employee.uuid} className="hover:shadow-md transition-shadow duration-200">
                  <CardContent className="p-6">
                    <div className="flex items-start justify-between mb-4">
                      <div className="flex items-center space-x-3">
                        <Avatar>
                          <AvatarImage src={employee.avatar} alt={employee.name} />
                          <AvatarFallback>
                            {employee.name ? employee.name.split(" ").map((n: string) => n[0]).join("") : "?"}
                          </AvatarFallback>
                        </Avatar>
                        <div>
                          <h3 className="font-semibold text-foreground">{employee.name || "No Name"}</h3>
                          <p className="text-sm text-muted-foreground">{employee.position_name || employee.position || "-"}</p>
                        </div>
                      </div>

                      {/* Dropdown dengan permission check */}
                      {canViewAllEmployees() || (employeeUuid && employee.uuid === employeeUuid) ? (
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="sm"><MoreVertical className="h-4 w-4" /></Button>
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

                    {/* Employee Info */}
                    <div className="space-y-2">
                      <div className="flex items-center justify-between">
                        <span className="text-sm text-muted-foreground">Department</span>
                        <span className="text-sm font-medium">{employee.department_description || employee.department || "-"}</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span className="text-sm text-muted-foreground">Status</span>
                        {getStatusBadge(employee.status || "Active")}
                      </div>
                      <div className="flex items-center justify-between">
                        <span className="text-sm text-muted-foreground">Join Date</span>
                        <span className="text-sm">{formatDate(employee.join_date)}</span>
                      </div>
                      {employee.shift_description && (
                        <div className="flex items-center justify-between">
                          <span className="text-sm text-muted-foreground">Shift</span>
                          <span className="text-sm font-medium">{employee.shift_description}</span>
                        </div>
                      )}
                      {(employee.clock_in || employee.clock_out) && (
                        <div className="flex items-center justify-between">
                          <span className="text-sm text-muted-foreground">Work Hour</span>
                          <span className="text-sm font-medium">{employee.clock_in || "-"} - {employee.clock_out || "-"}</span>
                        </div>
                      )}
                    </div>

                    {/* Email / Call */}
                    <div className="flex items-center space-x-2 mt-4 pt-4 border-t">
                      {employee.email && (
                        <Button 
                          variant="outline" 
                          size="sm" 
                          className="flex-1"
                          onClick={() => window.location.href = `mailto:${employee.email}`}
                        >
                          <Mail className="h-3 w-3 mr-1" /> Email
                        </Button>
                      )}
                      <Button variant="outline" size="sm" className="flex-1">
                        <Phone className="h-3 w-3 mr-1" /> Call
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))
            ) : (
              <div className="col-span-full text-center py-8">
                <p className="text-muted-foreground">No employees found</p>
                {canViewAllEmployees() && (searchTerm || selectedDepartment !== "All") ? (
                  <Button 
                    variant="outline" 
                    className="mt-2"
                    onClick={() => {
                      setSearchTerm("");
                      setSelectedDepartment("All");
                      fetchEmployees(1, "", "");
                    }}
                  >
                    Clear Filters
                  </Button>
                ) : null}
              </div>
            )}
          </div>

          {/* Pagination hanya untuk admin/HR */}
          {canViewAllEmployees() && meta && meta.last_page > 1 && (
            <div className="flex justify-center items-center space-x-2 mt-6">
              <Button 
                variant="outline" 
                disabled={page === 1} 
                onClick={() => fetchEmployees(page - 1, searchTerm, selectedDepartment === "All" ? "" : selectedDepartment)}
              >
                Previous
              </Button>
              <span className="text-sm">
                Page {meta.current_page} of {meta.last_page}
              </span>
              <Button 
                variant="outline" 
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