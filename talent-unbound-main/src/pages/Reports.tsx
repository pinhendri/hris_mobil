import { BarChart3, Download, FileText, Calendar, TrendingUp, Users, ArrowLeft } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useEffect, useState } from "react";
import api_laravel from "@/lib/utils";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import exportToPDF from "@/helpers/exportPDF";

export default function Reports() {
  const [employees, setEmployees] = useState<any[]>([]);
  const [departments, setDepartments] = useState<any[]>([]);
  const [attendances, setAttendances] = useState<any[]>([]);
  const [leaveRequests, setLeaveRequests] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeReport, setActiveReport] = useState<any | null>(null);
  const [dailyReport, setDailyReport] = useState<any[]>([]);
  const today = new Date().toISOString().split("T")[0];
  const [selectedDate, setSelectedDate] = useState(today);
  const [deactivatedEmployees, setDeactivatedEmployees] = useState<any[]>([]);

  // Helper untuk filter karyawan baru 1 minggu terakhir
  const getNewRecruits = () => {
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

    return employees.filter((emp) => {
      if (!emp.created_at) return false;
      const createdDate = new Date(emp.created_at);
      return createdDate >= oneWeekAgo;
    });
  };

  // Helper untuk filter turnover (status inactive)
  const getTurnover = () => {
    return employees.filter(
      (emp) => emp.status && emp.status.toLowerCase() === "deactive"
    );
  };

  const fetchDailyReport = () => {
    setLoading(true);
    api_laravel.get(`/api/attendances/daily-report?date=${selectedDate}`)
      .then((res) => {
        setDailyReport(
          Array.isArray(res.data.data)
            ? res.data.data
            : Array.isArray(res.data)
            ? res.data
            : []
        );
      })
      .catch((err) => console.error("Error fetching daily report:", err))
      .finally(() => setLoading(false));
  };

  const employeeReports = [
    {
      name: "Employee Directory",
      type: "1",
      description: "Complete list of all employees",
      lastGenerated: new Date().toISOString().split("T")[0],
      total: employees.length,
    },
    {
      name: "Department Summary",
      type: "2",
      description: "Employee distribution by department",
      lastGenerated: new Date().toISOString().split("T")[0],
      total: departments.length,
    },
    {
      name: "New Hires Report",
      type: "3",
      description: "Recent additions to the team",
      lastGenerated: new Date().toISOString().split("T")[0],
      total: getNewRecruits().length,
    },
    {
      name: "Employee Turnover",
      type: "4",
      description: "Turnover analysis and trends",
      lastGenerated: new Date().toISOString().split("T")[0],
      total: deactivatedEmployees.length > 0 ? deactivatedEmployees.length : getTurnover().length,
    },
  ];

  const TimeAttendance = [
    {
      name: "Time Tracking Summary",
      type: "5",
      description: "Hours logged by employees",
      lastGenerated: new Date().toISOString().split("T")[0],
      total: employees.length,
    },
    {
      name: "Attendance Report",
      type: "6",
      description: "Employee attendance patterns",
      lastGenerated: new Date().toISOString().split("T")[0],
      total: new Set(employees.map((e) => e.department)).size,
    },
    {
      name: "Leave Analytics",
      type: "7",
      description: "Leave usage and patterns",
      lastGenerated: new Date().toISOString().split("T")[0],
      total: getNewRecruits().length,
    },
    {
      name: "Overtime Report",
      type: "8",
      description: "Overtime hours analysis",
      lastGenerated: new Date().toISOString().split("T")[0],
      total: getTurnover().length,
    },
  ];

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const token = localStorage.getItem("token");
        const headers = {
          Authorization: `Bearer ${token}`,
        };

        const [empRes, deptRes, attRes, leaveRes, dailyRes, deactiveRes] = await Promise.all([
          api_laravel.get("/api/employees/list", { headers }),
          api_laravel.get("/api/departments", { headers }),
          api_laravel.get("/api/attendances", {
            params: { date: selectedDate },
            headers
          }),
          api_laravel.get("/api/leave-requests", { headers }),
          api_laravel.get("/api/attendances/daily-report", {
            params: { date: selectedDate }
          }),
          api_laravel.get("/api/employees/deactivated", { headers })
        ]);

        console.log("Employees API Response:", empRes.data);
        console.log("Departments API Response:", deptRes.data);
        console.log("Attendances API Response:", attRes.data);
        console.log("Leave Requests API Response:", leaveRes.data);
        console.log("Daily Report API Response:", dailyRes.data);
        console.log("Deactivated Employees API Response:", deactiveRes.data);

        // ✅ PERBAIKAN: Access data dari struktur response yang benar
        // Employees: res.data.data.data (karena ada wrapper success, message, data)
        setEmployees(
          empRes.data.success && empRes.data.data && Array.isArray(empRes.data.data.data) 
            ? empRes.data.data.data 
            : Array.isArray(empRes.data.data) 
            ? empRes.data.data 
            : Array.isArray(empRes.data) 
            ? empRes.data 
            : []
        );

        // Departments: res.data.data.data atau res.data.data
        setDepartments(
          deptRes.data.success && deptRes.data.data && Array.isArray(deptRes.data.data.data)
            ? deptRes.data.data.data
            : Array.isArray(deptRes.data.data)
            ? deptRes.data.data
            : Array.isArray(deptRes.data)
            ? deptRes.data
            : []
        );

        // Attendances: res.data.data.data atau res.data.data
        setAttendances(
          attRes.data.success && attRes.data.data && Array.isArray(attRes.data.data.data)
            ? attRes.data.data.data
            : Array.isArray(attRes.data.data)
            ? attRes.data.data
            : Array.isArray(attRes.data)
            ? attRes.data
            : []
        );

        // Leave Requests: res.data.data.data atau res.data.data
        setLeaveRequests(
          leaveRes.data.success && leaveRes.data.data && Array.isArray(leaveRes.data.data.data)
            ? leaveRes.data.data.data
            : Array.isArray(leaveRes.data.data)
            ? leaveRes.data.data
            : Array.isArray(leaveRes.data)
            ? leaveRes.data
            : []
        );

        // Daily Report: res.data.data.data atau res.data.data
        setDailyReport(
          dailyRes.data.success && dailyRes.data.data && Array.isArray(dailyRes.data.data.data)
            ? dailyRes.data.data.data
            : Array.isArray(dailyRes.data.data)
            ? dailyRes.data.data
            : Array.isArray(dailyRes.data)
            ? dailyRes.data
            : []
        );

        // Deactivated Employees: res.data.data atau res.data
        setDeactivatedEmployees(
          deactiveRes.data.success && Array.isArray(deactiveRes.data.data)
            ? deactiveRes.data.data
            : Array.isArray(deactiveRes.data)
            ? deactiveRes.data
            : []
        );

      } catch (err) {
        console.error("Error fetching data:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [selectedDate]);

  // Re-fetch daily report when date changes
  useEffect(() => {
    fetchDailyReport();
  }, [selectedDate]);

  const handleView = (report: any) => {
    setActiveReport(report);
  };

  const handleExport = (report: any) => {
    let rows: any[] = [];
    let filename = "";
    let title = "";

    switch (report.type) {
      case "1": // Employee Directory
        rows = employees.map((emp) => ({
          "Employee ID": emp.nik_employee || "-",
          Name: emp.name,
          "Join Date": emp.join_date
            ? new Intl.DateTimeFormat("id-ID", {
                day: "2-digit",
                month: "long",
                year: "numeric",
              }).format(new Date(emp.join_date))
            : "-",
          Department: emp.department_description || emp.department || "-",
          Position: emp.position_name || emp.position || "-",
          Status: emp.status || "-",
        }));
        filename = "employee-directory.pdf";
        title = "Employee Directory";
        break;

      case "2": // Department Summary
        rows = departments.map((dept) => ({
          ID: dept.id,
          Name: dept.name,
          Head: dept.head || "-",
          Employees: dept.employees || 0,
          Budget: dept.budget
            ? `Rp ${new Intl.NumberFormat("id-ID").format(Number(dept.budget))}`
            : "-",
          Growth: dept.growth ? `${dept.growth}%` : "-",
          Description: dept.description || "-",
          "Created At": dept.created_at
            ? new Intl.DateTimeFormat("id-ID", {
                day: "2-digit",
                month: "long",
                year: "numeric",
              }).format(new Date(dept.created_at))
            : "-",
        }));
        filename = "department-summary.pdf";
        title = "Department Summary";
        break;

      case "3": // New Recruits
        rows = getNewRecruits().map((emp) => ({
          "Employee ID": emp.nik_employee || "-",
          Name: emp.name,
          "Join Date": emp.join_date
            ? new Intl.DateTimeFormat("id-ID", {
                day: "2-digit",
                month: "long",
                year: "numeric",
              }).format(new Date(emp.join_date))
            : "-",
          Department: emp.department_description || emp.department || "-",
          Position: emp.position_name || emp.position || "-",
        }));
        filename = "new-hires.pdf";
        title = "New Hires Report";
        break;

      case "4": // Deactivated Employees
        const deactivatedData = deactivatedEmployees.length > 0 ? deactivatedEmployees : getTurnover();
        rows = deactivatedData.map((emp) => ({
          "Employee ID": emp.employee?.id || emp.id,
          Name: emp.employee?.name || emp.name,
          NIK: emp.employee?.nik_employee || emp.nik_employee || "-",
          Reason: emp.reason || "Status: Deactive",
          "Deactivated Date": emp.deactive_date || emp.created_at
            ? new Intl.DateTimeFormat("id-ID", {
                day: "2-digit",
                month: "long",
                year: "numeric",
              }).format(new Date(emp.deactive_date || emp.created_at))
            : "-",
        }));
        filename = "deactivated_employees.pdf";
        title = "Deactivated Employees";
        break;

      case "5": // Time Tracking Summary
        rows = attendances.map((att) => ({
          "Employee ID": att.employee?.nik_employee || "-",
          Date: att.date,
          "Clock In": att.clock_in || "-",
          "Clock Out": att.clock_out || "-",
          Hours: att.total_hours || 0,
        }));
        filename = "time-tracking.pdf";
        title = "Time Tracking Summary";
        break;

      case "6": // Attendance Report
        rows = dailyReport.map((r) => ({
          "Employee ID": r.nik_employee || "-",
          Name: r.employee_name || "-",
          Date: r.date || "-",
          "Clock In": r.clock_in || "-",
          "Clock Out": r.clock_out || "-",
          "Leave Type": r.leave_type || "-",
          "Leave Status": r.leave_status || "-",
        }));
        filename = "attendance-report.pdf";
        title = "Attendance Report";
        break;

      case "7": // Leave Analytics
        rows = leaveRequests.map((leave) => ({
          "Employee ID": leave.employee?.nik_employee || leave.employee_id || "-",
          Name: leave.employee?.name || "-",
          Type: leave.type,
          "Start Date": leave.start_date,
          "End Date": leave.end_date,
          Status: leave.status,
        }));
        filename = "leave-analytics.pdf";
        title = "Leave Analytics";
        break;

      case "8": // Overtime Report
        rows = attendances
          .filter((att) => att.overtime_hours && att.overtime_hours > 0)
          .map((att) => ({
            "Employee ID": att.employee?.nik_employee || att.employee_id || "-",
            Date: att.date,
            "Overtime Hours": att.overtime_hours,
          }));
        filename = "overtime-report.pdf";
        title = "Overtime Report";
        break;

      default:
        alert("Export untuk report ini belum tersedia.");
        return;
    }

    console.log("Report Type:", report.type);
    console.log("Employees count:", employees.length);
    console.log("Departments count:", departments.length);
    console.log("Rows hasil mapping:", rows);

    if (rows.length === 0) {
      alert("Tidak ada data untuk diexport.");
      return;
    }

    exportToPDF(filename, rows, title);
  };

  const reportCategories = [
    {
      title: "Employee Reports",
      icon: Users,
      reports: employeeReports,
    },
    {
      title: "Performance Reports",
      icon: TrendingUp,
      reports: [
        { name: "Performance Summary", description: "Overall performance metrics", lastGenerated: "2024-01-28" },
        { name: "Goal Achievement", description: "Employee goal completion rates", lastGenerated: "2024-01-26" },
        { name: "Review Analytics", description: "Performance review insights", lastGenerated: "2024-01-24" },
        { name: "Top Performers", description: "Highest performing employees", lastGenerated: "2024-01-22" },
      ],
    },
    {
      title: "Time & Attendance",
      icon: Calendar,
      reports: TimeAttendance,
    },
  ];

  return (
    <div className="space-y-6 animate-fade-in">
      {!activeReport ? (
        <>
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold tracking-tight">Reports & Analytics</h1>
              <p className="text-muted-foreground">Generate comprehensive reports and analyze HR data.</p>
            </div>
            <Button className="btn-gradient">
              <FileText className="h-4 w-4 mr-2" />
              Create Custom Report
            </Button>
          </div>

          {/* Quick Stats */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            <Card className="card-metric">
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Total Reports</p>
                    <p className="text-3xl font-bold text-foreground">24</p>
                    <p className="text-sm text-muted-foreground">Available</p>
                  </div>
                  <div className="p-3 rounded-lg bg-primary-light">
                    <FileText className="h-6 w-6 text-primary" />
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="card-metric">
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Generated Today</p>
                    <p className="text-3xl font-bold text-foreground">8</p>
                    <p className="text-sm text-success">+3 from yesterday</p>
                  </div>
                  <div className="p-3 rounded-lg bg-success-light">
                    <BarChart3 className="h-6 w-6 text-success" />
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="card-metric">
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Downloads</p>
                    <p className="text-3xl font-bold text-foreground">156</p>
                    <p className="text-sm text-muted-foreground">This month</p>
                  </div>
                  <div className="p-3 rounded-lg bg-warning-light">
                    <Download className="h-6 w-6 text-warning" />
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="card-metric bg-gradient-primary text-white">
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-white/80">Automated</p>
                    <p className="text-3xl font-bold text-white">12</p>
                    <p className="text-sm text-white/90">Scheduled reports</p>
                  </div>
                  <div className="p-3 rounded-lg bg-white/20">
                    <Calendar className="h-6 w-6 text-white" />
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          <Tabs defaultValue="all" className="space-y-6">
            <TabsList>
              <TabsTrigger value="all">All Reports</TabsTrigger>
              <TabsTrigger value="scheduled">Scheduled</TabsTrigger>
              <TabsTrigger value="custom">Custom</TabsTrigger>
            </TabsList>

            <TabsContent value="all" className="space-y-6">
              {reportCategories.map((category, index) => (
                <Card key={index} className="card-dashboard">
                  <CardHeader>
                    <CardTitle className="flex items-center">
                      <category.icon className="h-5 w-5 mr-2 text-primary" />
                      {category.title}
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {category.reports.map((report, i) => (
                        <div
                          key={report.name + i}
                          className="flex items-center justify-between p-4 border rounded-lg hover:bg-muted/50 transition-colors"
                        >
                          <div className="flex-1">
                            <h4 className="font-medium text-sm">
                              {report.name}
                            </h4>
                            <p className="text-xs text-muted-foreground">
                              {report.description}
                            </p>
                            <p className="text-xs text-muted-foreground mt-1">
                              Last generated: {report.lastGenerated}
                            </p>
                            {"total" in report && (
                              <p className="text-xs text-primary mt-1">
                                Total: {report.total}
                              </p>
                            )}
                          </div>
                          <div className="flex space-x-2">
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => handleView(report)}
                            >
                              <BarChart3 className="h-3 w-3 mr-1" />
                              View
                            </Button>
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => handleExport(report)}
                            >
                              <Download className="h-3 w-3 mr-1" />
                              Export
                            </Button>
                          </div>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              ))}
            </TabsContent>
          </Tabs>
        </>
      ) : (
        <Card>
          <CardHeader className="flex justify-between items-center">
            <div>
              <CardTitle>{activeReport.name}</CardTitle>
              <p className="text-sm text-muted-foreground">
                {activeReport.description}
              </p>
            </div>
            <Button variant="outline" onClick={() => setActiveReport(null)}>
              <ArrowLeft className="h-4 w-4 mr-1" /> Back
            </Button>
          </CardHeader>

          <CardContent>
            {/* Employee Report */}
            {activeReport.type === "1" && (
              loading ? (
                <p>Loading employees...</p>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Employee ID</TableHead>
                      <TableHead>Name</TableHead>
                      <TableHead>Join Date</TableHead>
                      <TableHead>Department</TableHead>
                      <TableHead>Position</TableHead>
                      <TableHead>Status</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {employees.map((emp) => {
                      const formattedDate = emp.join_date
                        ? new Intl.DateTimeFormat("id-ID", {
                            day: "2-digit",
                            month: "long",
                            year: "numeric",
                          }).format(new Date(emp.join_date))
                        : "-";

                      return (
                        <TableRow key={emp.uuid || emp.id}>
                          <TableCell>{emp.nik_employee || "-"}</TableCell>
                          <TableCell>{emp.name}</TableCell>
                          <TableCell>{formattedDate}</TableCell>
                          <TableCell>{emp.department_description || emp.department || "-"}</TableCell>
                          <TableCell>{emp.position_name || emp.position || "-"}</TableCell>
                          <TableCell>{emp.status || "-"}</TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              )
            )}

            {/* Department Report */}
            {activeReport.type === "2" && (
              <Card className="mt-4">
                <CardHeader>
                  <CardTitle>Department List</CardTitle>
                </CardHeader>
                <CardContent>
                  {loading ? (
                    <p>Loading...</p>
                  ) : (
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>ID</TableHead>
                          <TableHead>Name</TableHead>
                          <TableHead>Head</TableHead>
                          <TableHead>Employees</TableHead>
                          <TableHead>Budget</TableHead>
                          <TableHead>Growth (%)</TableHead>
                          <TableHead>Description</TableHead>
                          <TableHead>Created At</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {departments.map((dept, index) => {
                          const formattedDate = dept.created_at
                            ? new Intl.DateTimeFormat("id-ID", {
                                day: "2-digit",
                                month: "long",
                                year: "numeric",
                              }).format(new Date(dept.created_at))
                            : "-";

                          return (
                            <TableRow key={dept.id || index}>
                              <TableCell>{dept.id}</TableCell>
                              <TableCell>{dept.name}</TableCell>
                              <TableCell>{dept.head || "-"}</TableCell>
                              <TableCell>{dept.employees || 0}</TableCell>
                              <TableCell>
                                {dept.budget
                                  ? `Rp ${new Intl.NumberFormat("id-ID").format(Number(dept.budget))}`
                                  : "-"}
                              </TableCell>
                              <TableCell>{dept.growth ? `${dept.growth}%` : "-"}</TableCell>
                              <TableCell>{dept.description || "-"}</TableCell>
                              <TableCell>{formattedDate}</TableCell>
                            </TableRow>
                          );
                        })}
                      </TableBody>
                    </Table>
                  )}
                </CardContent>
              </Card>
            )}

            {/* New Recruitment */}
            {activeReport.type === "3" && (
              <Card className="mt-4">
                <CardHeader>
                  <CardTitle>New Recruits (Last 7 Days)</CardTitle>
                </CardHeader>
                <CardContent>
                  {loading ? (
                    <p>Loading...</p>
                  ) : (
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>Employee ID</TableHead>
                          <TableHead>Name</TableHead>
                          <TableHead>Join Date</TableHead>
                          <TableHead>Department</TableHead>
                          <TableHead>Position</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {getNewRecruits().map((emp) => {
                          const formattedDate = emp.join_date
                            ? new Intl.DateTimeFormat("id-ID", {
                                day: "2-digit",
                                month: "long",
                                year: "numeric",
                              }).format(new Date(emp.join_date))
                            : "-";

                          return (
                            <TableRow key={emp.uuid || emp.id}>
                              <TableCell>{emp.nik_employee || "-"}</TableCell>
                              <TableCell>{emp.name}</TableCell>
                              <TableCell>{formattedDate}</TableCell>
                              <TableCell>{emp.department_description || emp.department || "-"}</TableCell>
                              <TableCell>{emp.position_name || emp.position || "-"}</TableCell>
                            </TableRow>
                          );
                        })}
                      </TableBody>
                    </Table>
                  )}
                </CardContent>
              </Card>
            )}

            {/* Deactivated Employees */}
            {activeReport.type === "4" && (
              <Card>
                <CardHeader>
                  <CardTitle>{activeReport.name}</CardTitle>
                  <p className="text-sm text-muted-foreground">
                    {activeReport.description}
                  </p>
                </CardHeader>
                <CardContent>
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>ID</TableHead>
                        <TableHead>Nama</TableHead>
                        <TableHead>NIK</TableHead>
                        <TableHead>Reason</TableHead>
                        <TableHead>Tanggal Deactive</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {(deactivatedEmployees.length > 0 ? deactivatedEmployees : getTurnover()).map((emp) => (
                        <TableRow key={emp.id || emp.uuid}>
                          <TableCell>{emp.employee?.id || emp.id}</TableCell>
                          <TableCell>{emp.employee?.name || emp.name}</TableCell>
                          <TableCell>{emp.employee?.nik_employee || emp.nik_employee || "-"}</TableCell>
                          <TableCell>{emp.reason || "Status: Deactive"}</TableCell>
                          <TableCell>
                            {emp.deactive_date || emp.created_at
                              ? new Date(emp.deactive_date || emp.created_at).toLocaleDateString("id-ID", {
                                  year: "numeric",
                                  month: "long",
                                  day: "numeric",
                                })
                              : "-"}
                          </TableCell>
                        </TableRow>
                      ))}
                      {(deactivatedEmployees.length === 0 && getTurnover().length === 0) && (
                        <TableRow>
                          <TableCell colSpan={5} className="text-center text-gray-400">
                            Tidak ada employee yang dinonaktifkan
                          </TableCell>
                        </TableRow>
                      )}
                    </TableBody>
                  </Table>
                </CardContent>
              </Card>
            )}

            {/* ... other report types remain the same ... */}
            {!["1", "2", "3", "4"].includes(activeReport.type) && (
              <p>
                Report "{activeReport.name}" belum ada tampilan khusus.
              </p>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  );
}