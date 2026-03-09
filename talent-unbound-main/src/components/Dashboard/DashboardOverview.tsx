"use client";

import { useEffect, useState } from "react";
import { Users, UserPlus, Calendar, TrendingUp, Clock, Award } from "lucide-react";
import { MetricCard } from "./MetricCard";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import api_laravel from "@/lib/utils";

interface Employee {
  id: number;
  name: string;
  status: string;
  join_date: string;
  department?: string;
  department_description?: string;
  position_name?: string;
  c_code?: string;
  company_code?: string;
}

interface Department {
  id: number;
  name: string;
  employees?: number;
  c_code?: string;
  company_code?: string;
}

interface DepartmentStat {
  name: string;
  employees: number;
  employeesPrev: number;
  change: string;
}

interface RecentActivity {
  id: number;
  name: string;
  created_at: string;
  position_name?: string;
}

export function DashboardOverview() {
  const [metrics, setMetrics] = useState<any[]>([
    { title: "Total Employees", value: 0, change: "Loading...", trend: "neutral" as const, icon: Users },
    { title: "New Hires", value: 0, change: "Loading...", trend: "neutral" as const, icon: UserPlus },
    { title: "Open Positions", value: 0, trend: "neutral" as const, icon: Calendar },
    { title: "Performance Score", value: "N/A", trend: "neutral" as const, icon: TrendingUp, gradient: true },
  ]);

  const [departmentStats, setDepartmentStats] = useState<DepartmentStat[]>([]);
  const [recentActivity, setRecentActivity] = useState<RecentActivity[]>([]);
  const [totalActiveEmployees, setTotalActiveEmployees] = useState<number>(0);
  const [selectedCompany, setSelectedCompany] = useState<string>("");
  const [debugInfo, setDebugInfo] = useState<any>({});
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // Function untuk mendapatkan c_code dari localStorage dengan lebih robust
  const getCurrentCompanyCode = (): string | null => {
    try {
      // Cek dari localStorage user data
      const userDataStr = localStorage.getItem("user");
      if (userDataStr) {
        const userData = JSON.parse(userDataStr);
        const c_code = userData.selected_c_code || userData.c_code || userData.company_code;
        console.log("🏢 Current company code from user data:", c_code);
        return c_code;
      }
      
      // Cek berbagai kemungkinan key di localStorage
      const possibleKeys = ["selectedCcode", "c_code", "company_code", "selected_company_code"];
      for (const key of possibleKeys) {
        const value = localStorage.getItem(key);
        if (value) {
          console.log(`🏢 Found company code from ${key}:`, value);
          return value;
        }
      }
      
      console.log("⚠️ No company code found in localStorage");
      return null;
    } catch (error) {
      console.error("Error getting company code:", error);
      return null;
    }
  };

  // Function untuk mengekstrak employees data dari berbagai struktur response
  const extractEmployeesData = (response: any): Employee[] => {
    console.log("📦 Extracting employees data from response structure:", response);
    
    if (!response) {
      console.log("⚠️ No response");
      return [];
    }
    
    // Cek berbagai kemungkinan struktur data
    const data = response.data;
    if (!data) {
      console.log("⚠️ No data in response");
      return [];
    }
    
    // Case 1: response.data adalah array langsung
    if (Array.isArray(data)) {
      console.log("✅ Employees data is direct array, count:", data.length);
      return data;
    }
    
    // Case 2: response.data.data adalah array
    if (data.data && Array.isArray(data.data)) {
      console.log("✅ Employees data from data.data array, count:", data.data.length);
      return data.data;
    }
    
    // Case 3: response.data.data.data adalah array (pagination)
    if (data.data?.data && Array.isArray(data.data.data)) {
      console.log("✅ Employees data from data.data.data array, count:", data.data.data.length);
      return data.data.data;
    }
    
    // Case 4: response.data memiliki field tertentu yang berisi array
    if (data.employees && Array.isArray(data.employees)) {
      console.log("✅ Employees data from employees field, count:", data.employees.length);
      return data.employees;
    }
    
    // Case 5: response adalah array langsung
    if (Array.isArray(response)) {
      console.log("✅ Response is direct array, count:", response.length);
      return response;
    }
    
    console.log("❌ Could not extract employees data from response structure:", data);
    return [];
  };

  // Function untuk mengekstrak departments data
  const extractDepartmentsData = (response: any): Department[] => {
    console.log("📦 Extracting departments data from:", response);
    
    if (!response) {
      console.log("⚠️ No departments response");
      return [];
    }
    
    const data = response.data;
    if (!data) {
      console.log("⚠️ No data in departments response");
      return [];
    }
    
    // Case 1: response.data adalah array langsung
    if (Array.isArray(data)) {
      console.log("✅ Departments data is direct array, count:", data.length);
      return data;
    }
    
    // Case 2: response.data.data adalah array
    if (data.data && Array.isArray(data.data)) {
      console.log("✅ Departments data from data.data array, count:", data.data.length);
      return data.data;
    }
    
    // Case 3: response.data memiliki field tertentu
    if (data.departments && Array.isArray(data.departments)) {
      console.log("✅ Departments data from departments field, count:", data.departments.length);
      return data.departments;
    }
    
    // Case 4: response adalah array langsung
    if (Array.isArray(response)) {
      console.log("✅ Departments response is direct array, count:", response.length);
      return response;
    }
    
    console.log("❌ Could not extract departments data from response structure:", data);
    return [];
  };

  // Function untuk filter data berdasarkan c_code dengan logging yang lebih detail
  const filterByCompanyCode = <T extends Employee | Department>(data: T[], companyCode: string): T[] => {
    if (!companyCode) {
      console.log("ℹ️ No company code provided, returning all data");
      return data;
    }
    
    if (data.length === 0) {
      console.log("ℹ️ No data to filter");
      return data;
    }
    
    console.log(`🔍 Filtering ${data.length} items for company: ${companyCode}`);
    
    const filtered = data.filter(item => {
      const itemCode = item.c_code || item.company_code;
      const matches = itemCode === companyCode;
      if (!matches && process.env.NODE_ENV === 'development') {
        console.log(`   ❌ Item ${item.name || item.id} has c_code: ${itemCode}, expected: ${companyCode}`);
      }
      return matches;
    });
    
    console.log(`✅ Filtered to ${filtered.length} items for company: ${companyCode}`);
    
    // Log sample of filtered data
    if (filtered.length > 0 && process.env.NODE_ENV === 'development') {
      console.log("📋 Sample filtered items:", filtered.slice(0, 3).map(item => ({
        name: item.name || 'No name',
        c_code: item.c_code || item.company_code,
        id: item.id
      })));
    }
    
    return filtered;
  };

  // Function untuk menghitung statistik departemen
  const calculateDepartmentStats = (employees: Employee[]): DepartmentStat[] => {
    if (employees.length === 0) {
      return [];
    }
    
    const departmentMap: { [key: string]: number } = {};
    
    employees.forEach(emp => {
      const deptName = emp.department_description || emp.department || "Unassigned";
      departmentMap[deptName] = (departmentMap[deptName] || 0) + 1;
    });
    
    const departmentsArray: DepartmentStat[] = Object.entries(departmentMap)
      .map(([name, count]) => {
        // Simple growth calculation (assume 10% growth for demo)
        const employeesPrev = Math.round(count * 0.9);
        const growth = count - employeesPrev;
        const change = growth > 0 
          ? `+${growth} from last month` 
          : growth < 0 
            ? `${growth} from last month`
            : "No change";
        
        return {
          name,
          employees: count,
          employeesPrev,
          change
        };
      })
      .sort((a, b) => b.employees - a.employees);
    
    return departmentsArray;
  };

  useEffect(() => {
    // Set selected company dari localStorage
    const currentCompanyCode = getCurrentCompanyCode();
    if (currentCompanyCode) {
      setSelectedCompany(currentCompanyCode);
      console.log("✅ Company code set to:", currentCompanyCode);
    } else {
      console.log("⚠️ No company code found in storage");
      setError("Please select a company first");
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const fetchData = async () => {
      if (!selectedCompany) {
        console.log("⏳ Waiting for company code...");
        return;
      }

      setLoading(true);
      setError(null);
      console.log("🔄 Starting data fetch for company:", selectedCompany);
      
      try {
        // Fetch employees data
        console.log("📡 Fetching employees data...");
        const empRes = await api_laravel.get("/api/employees");
        console.log("👥 Raw employees API response structure:", empRes);
        
        const allEmployees = extractEmployeesData(empRes);
        console.log(`👥 Total Employees extracted: ${allEmployees.length}`);
        
        // Log beberapa sample data untuk debugging
        if (allEmployees.length > 0 && process.env.NODE_ENV === 'development') {
          console.log("📋 Sample employees (first 3):", allEmployees.slice(0, 3).map(emp => ({
            id: emp.id,
            name: emp.name,
            c_code: emp.c_code,
            status: emp.status
          })));
        }
        
        // Filter employees berdasarkan c_code
        const employees = filterByCompanyCode(allEmployees, selectedCompany);
        console.log(`👥 Employees for company ${selectedCompany}: ${employees.length}`);
        
        if (employees.length === 0) {
          console.log("⚠️ No employees found for company:", selectedCompany);
          console.log("ℹ️ Checking if company code matches...");
          const uniqueCompanyCodes = [...new Set(allEmployees.map(emp => emp.c_code || emp.company_code))];
          console.log("🏢 Available company codes in data:", uniqueCompanyCodes);
        }

        // Fetch departments data
        console.log("📡 Fetching departments data...");
        const deptRes = await api_laravel.get("/api/departments");
        console.log("🏢 Raw departments API response structure:", deptRes);
        
        const allDepartments = extractDepartmentsData(deptRes);
        console.log(`🏢 Total Departments extracted: ${allDepartments.length}`);
        
        // Filter departments berdasarkan c_code
        const departments = filterByCompanyCode(allDepartments, selectedCompany);
        console.log(`🏢 Departments for company ${selectedCompany}: ${departments.length}`);

        // ====== TOTAL ACTIVE EMPLOYEES ======
        const activeEmployees = employees.filter(emp => {
          const status = (emp.status || '').toLowerCase();
          return !['inactive', 'deactive', 'terminated', 'resigned'].includes(status);
        }).length;
        
        setTotalActiveEmployees(activeEmployees);
        console.log(`✅ Active employees: ${activeEmployees}`);

        // ====== NEW HIRES (this month) ======
        const now = new Date();
        const currentMonthStart = new Date(now.getFullYear(), now.getMonth(), 1);
        const currentMonthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0);
        
        const newHires = employees.filter(emp => {
          if (!emp.join_date) return false;
          try {
            const joinDate = new Date(emp.join_date);
            return joinDate >= currentMonthStart && joinDate <= currentMonthEnd;
          } catch {
            return false;
          }
        }).length;
        
        console.log(`✅ New hires this month: ${newHires}`);

        // ====== OPEN POSITIONS ======
        let openPositions = 0;
        try {
          console.log("📡 Fetching recruitment data...");
          const recruitmentRes = await api_laravel.get("/api/recruitment");
          console.log("📋 Recruitment API response:", recruitmentRes);
          
          if (recruitmentRes.data?.openPositions && Array.isArray(recruitmentRes.data.openPositions)) {
            openPositions = recruitmentRes.data.openPositions.length;
          } else if (Array.isArray(recruitmentRes.data)) {
            openPositions = recruitmentRes.data.length;
          }
        } catch (err) {
          console.log("⚠️ Recruitment API error, setting open positions to 0");
        }
        
        console.log(`✅ Open positions: ${openPositions}`);

        // ====== UPDATE METRICS ======
        setMetrics([
          { 
            title: "Total Employees", 
            value: activeEmployees, 
            change: activeEmployees > 0 ? `${employees.length} total employees` : "No employees", 
            trend: activeEmployees > 0 ? "up" : "neutral" as const, 
            icon: Users 
          },
          { 
            title: "New Hires", 
            value: newHires, 
            change: newHires > 0 ? `Hired this month` : "No new hires this month", 
            trend: newHires > 0 ? "up" : "neutral" as const, 
            icon: UserPlus 
          },
          { 
            title: "Open Positions", 
            value: openPositions, 
            change: openPositions > 0 ? "Positions to fill" : "All positions filled", 
            trend: "neutral" as const, 
            icon: Calendar 
          },
          { 
            title: "Performance Score", 
            value: "N/A", 
            change: "Data not available", 
            trend: "neutral" as const, 
            icon: TrendingUp, 
            gradient: true 
          },
        ]);

        // ====== RECENT ACTIVITY ======
        const recent = employees
          .filter(emp => emp.join_date)
          .sort((a, b) => new Date(b.join_date).getTime() - new Date(a.join_date).getTime())
          .slice(0, 5)
          .map(emp => ({
            id: emp.id,
            name: emp.name,
            created_at: emp.join_date,
            position_name: emp.position_name || "Employee",
          }));
        
        setRecentActivity(recent);
        console.log(`✅ Recent activity count: ${recent.length}`);

        // ====== DEPARTMENT STATS ======
        const departmentsArray = calculateDepartmentStats(employees);
        setDepartmentStats(departmentsArray);
        console.log(`✅ Department stats count: ${departmentsArray.length}`);

        // ====== DEBUG INFO ======
        setDebugInfo({
          selectedCompany,
          totalEmployeesAll: allEmployees.length,
          totalEmployeesFiltered: employees.length,
          totalActiveEmployees: activeEmployees,
          newHires,
          openPositions,
          departmentCount: departmentsArray.length,
          fetchTime: new Date().toLocaleTimeString(),
          employeesSample: employees.slice(0, 3).map(e => ({ 
            name: e.name, 
            status: e.status,
            c_code: e.c_code,
            join_date: e.join_date 
          })),
          allCompanyCodes: [...new Set(allEmployees.map(emp => emp.c_code || emp.company_code))],
          filteredEmployeesCount: employees.length,
        });

        console.log("✅ Data fetch completed successfully");

      } catch (err: any) {
        console.error("❌ Failed to fetch dashboard data:", err);
        setError(err.message || "Failed to load dashboard data");
        
        setMetrics(prev => prev.map(m => ({
          ...m,
          value: m.title === "Performance Score" ? "N/A" : 0,
          change: "Error loading data"
        })));
        
        setDebugInfo({
          error: err.message,
          selectedCompany,
          fetchTime: new Date().toLocaleTimeString(),
          stack: err.stack,
        });
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [selectedCompany]);

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h2 className="text-2xl font-bold">Dashboard Overview</h2>
            <p className="text-muted-foreground">
              {selectedCompany ? `Loading data for ${selectedCompany}...` : "Loading..."}
            </p>
          </div>
          {selectedCompany && (
            <div className="flex items-center gap-2">
              <div className="px-3 py-1 bg-primary/10 text-primary rounded-full text-sm font-medium">
                {selectedCompany}
              </div>
              <div className="animate-pulse px-3 py-1 bg-gray-100 rounded-full text-sm">
                Loading...
              </div>
            </div>
          )}
        </div>
        
        <div className="flex flex-col justify-center items-center min-h-64 space-y-4">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          <div className="text-center">
            <p className="text-lg font-medium">Loading dashboard data...</p>
            <p className="text-sm text-muted-foreground mt-1">
              Fetching data for company: {selectedCompany}
            </p>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h2 className="text-2xl font-bold">Dashboard Overview</h2>
            <p className="text-muted-foreground">Error loading data</p>
          </div>
        </div>
        
        <Card className="border-red-200 bg-red-50">
          <CardContent className="py-8 text-center">
            <div className="text-red-600 font-medium mb-2">Error Loading Data</div>
            <p className="text-muted-foreground mb-4">{error}</p>
            <button 
              onClick={() => window.location.reload()}
              className="px-4 py-2 bg-primary text-white rounded-md hover:bg-primary/90"
            >
              Retry
            </button>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (!selectedCompany) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h2 className="text-2xl font-bold">Dashboard Overview</h2>
            <p className="text-muted-foreground">Please select a company first</p>
          </div>
        </div>
        
        <Card>
          <CardContent className="py-8 text-center">
            <div className="text-amber-600 font-medium mb-2">No Company Selected</div>
            <p className="text-muted-foreground">
              Please select a company from the company selector or check your localStorage.
            </p>
            <div className="mt-4 p-4 bg-gray-50 rounded text-sm text-left">
              <p className="font-medium">Debug Info:</p>
              <p>LocalStorage user: {localStorage.getItem("user") ? "Exists" : "Not found"}</p>
              <p>selectedCcode: {localStorage.getItem("selectedCcode") || "Not found"}</p>
              <p>c_code: {localStorage.getItem("c_code") || "Not found"}</p>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Company Info */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-2xl font-bold">Dashboard Overview</h2>
          <p className="text-muted-foreground">
            Showing data for company: <span className="font-medium">{selectedCompany}</span>
          </p>
        </div>
        <div className="flex items-center gap-2">
          <div className="px-3 py-1 bg-primary/10 text-primary rounded-full text-sm font-medium">
            {selectedCompany}
          </div>
          <div className="px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm font-medium">
            {totalActiveEmployees} Active
          </div>
        </div>
      </div>

      {/* Debug Info - Hanya tampil di development */}


      {/* Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {metrics.map((metric, index) => (
          <MetricCard key={index} {...metric} />
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Activity */}
        <Card className="card-dashboard">
          <CardHeader>
            <CardTitle className="flex items-center">
              <Clock className="h-5 w-5 mr-2 text-primary" />
              Recent Activity
            </CardTitle>
            <CardDescription>
              Latest hires for {selectedCompany}
              {recentActivity.length > 0 && ` (${recentActivity.length} records)`}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {recentActivity.length > 0 ? (
                <>
                  {recentActivity.map(activity => (
                    <div key={activity.id} className="flex items-start space-x-3 p-3 rounded-lg bg-muted/50 hover:bg-muted/70 transition-colors">
                      <div className="w-2 h-2 bg-primary rounded-full mt-2 flex-shrink-0"></div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium truncate">
                          {activity.name} {activity.position_name ? `joined as ${activity.position_name}` : 'joined the company'}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          {new Date(activity.created_at).toLocaleDateString('en-US', { 
                            year: 'numeric', 
                            month: 'long', 
                            day: 'numeric' 
                          })}
                        </p>
                      </div>
                    </div>
                  ))}
                </>
              ) : (
                <div className="text-center py-8">
                  <Clock className="h-12 w-12 text-muted-foreground/50 mx-auto mb-3" />
                  <p className="text-sm text-muted-foreground">
                    No recent activity for {selectedCompany}
                  </p>
                  <p className="text-xs text-muted-foreground mt-1">
                    New hires will appear here
                  </p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Department Overview */}
        <Card className="card-dashboard">
          <CardHeader>
            <CardTitle className="flex items-center">
              <Award className="h-5 w-5 mr-2 text-primary" />
              Department Overview
            </CardTitle>
            <CardDescription>
              Employee distribution for {selectedCompany}
              {departmentStats.length > 0 && ` (${departmentStats.length} departments)`}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {departmentStats.length > 0 ? (
                <>
                  {departmentStats.map((dept, index) => (
                    <div key={index} className="space-y-2">
                      <div className="flex justify-between items-center">
                        <span className="text-sm font-medium truncate pr-2">{dept.name}</span>
                        <div className="flex flex-col items-end shrink-0">
                          <span className="text-sm font-semibold">
                            {dept.employees} {dept.employees === 1 ? 'employee' : 'employees'}
                          </span>
                          <span className="text-xs text-muted-foreground">
                            {dept.change}
                          </span>
                        </div>
                      </div>
                      <Progress
                        value={totalActiveEmployees > 0 ? (dept.employees / totalActiveEmployees) * 100 : 0}
                        className="h-2"
                      />
                    </div>
                  ))}
                  <div className="pt-2 border-t">
                    <div className="flex justify-between text-sm">
                      <span className="font-medium">Total</span>
                      <span className="font-semibold">{totalActiveEmployees} active employees</span>
                    </div>
                    <div className="flex justify-between text-xs text-muted-foreground mt-1">
                      <span>Across {departmentStats.length} departments</span>
                      <span>{selectedCompany}</span>
                    </div>
                  </div>
                </>
              ) : (
                <div className="text-center py-8">
                  <Award className="h-12 w-12 text-muted-foreground/50 mx-auto mb-3" />
                  <p className="text-sm text-muted-foreground">
                    No department data available for {selectedCompany}
                  </p>
                  <p className="text-xs text-muted-foreground mt-1">
                    Employee department assignments will appear here
                  </p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}