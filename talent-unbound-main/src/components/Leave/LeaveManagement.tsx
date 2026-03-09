"use client";

import { useEffect, useState } from "react";
import {
  Calendar as CalendarIcon,
  Clock,
  CheckCircle,
  XCircle,
  AlertCircle,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";

import { Calendar as BigCalendar, dateFnsLocalizer } from "react-big-calendar";
import { format, parse, startOfWeek, getDay } from "date-fns";
import enUS from "date-fns/locale/en-US";
import "react-big-calendar/lib/css/react-big-calendar.css";

const locales = { "en-US": enUS };
const localizer = dateFnsLocalizer({
  format,
  parse,
  startOfWeek,
  getDay,
  locales,
});

interface LeaveRequest {
  id: string;
  uuid: string;
  employee: {
    id: number;
    name: string;
    avatar: string;
    department?: string;
  };
  type: string;
  start_date: string;
  end_date: string;
  days: number;
  status: string;
  reason: string;
  created_at: string;
  immediate_supervisor: string;
}

interface LeaveBalance {
  uuid?: string;
  employee: string;
  avatar: string;
  department: string;
  annual: { used: number; total: number };
  sick: { used: number; total: number };
  personal: { used: number; total: number };
  employee_id: number;
  employee_uuid?: string;
  c_code?: string;
}

const getCompanyCode = (): string => {
  try {
    const companyData = localStorage.getItem("selectedCompany");
    if (companyData) {
      const parsedData = JSON.parse(companyData);
      return parsedData.c_code || "";
    }
  } catch (error) {
    console.error("Error parsing company data:", error);
  }
  return "";
};

// Helper function untuk menghitung selisih hari
const calculateDaysDifference = (startDate: string, endDate: string): number => {
  try {
    const start = new Date(startDate);
    const end = new Date(endDate);
    
    // Set waktu ke 00:00:00 untuk menghitung hari murni
    start.setHours(0, 0, 0, 0);
    end.setHours(0, 0, 0, 0);
    
    // Hitung selisih dalam miliseconds
    const diffTime = Math.abs(end.getTime() - start.getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    // Tambah 1 karena termasuk hari pertama
    return diffDays + 1;
  } catch (error) {
    console.error("Error calculating days difference:", error);
    return 1; // Fallback ke 1 day
  }
};

// Helper function untuk format tanggal
const formatDate = (dateString: string): string => {
  try {
    const date = new Date(dateString);
    return date.toLocaleDateString('id-ID', {
      day: '2-digit',
      month: 'long',
      year: 'numeric'
    });
  } catch (error) {
    return dateString;
  }
};

export function LeaveManagement() {
  const [selectedTab, setSelectedTab] = useState("requests");
  const [leaveRequests, setLeaveRequests] = useState<LeaveRequest[]>([]);
  const [leaveBalance, setLeaveBalance] = useState<LeaveBalance[]>([]);
  const [loading, setLoading] = useState(true);
  const [calendarEvents, setCalendarEvents] = useState<any[]>([]);
  const [companyCode, setCompanyCode] = useState<string>("");

  // Form state
  const [newRequestType, setNewRequestType] = useState("Annual Leave");
  const [newRequestDays, setNewRequestDays] = useState(1);
  const [newRequestReason, setNewRequestReason] = useState("");
  const [newRequestStartDate, setNewRequestStartDate] = useState("");
  const [newRequestEndDate, setNewRequestEndDate] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const [currentUser, setCurrentUser] = useState<{ 
    uuid: string; 
    role: string;
    roles?: string[];
  }>({
    uuid: "",
    role: "",
  });

  // Hitung days otomatis saat start atau end date berubah
  useEffect(() => {
    if (newRequestStartDate && newRequestEndDate) {
      const days = calculateDaysDifference(newRequestStartDate, newRequestEndDate);
      setNewRequestDays(days > 0 ? days : 1);
    }
  }, [newRequestStartDate, newRequestEndDate]);

  useEffect(() => {
    const code = getCompanyCode();
    setCompanyCode(code);
  }, []);

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const companyCode = getCompanyCode();
        
        // Ambil leave requests
        const resRequests = await api_laravel.get("/api/leave-requests", {
          params: { c_code: companyCode }
        });

        const requestsData = resRequests.data.data || [];
        
        // Debug: cek data yang diterima
        console.log("Received leave requests:", requestsData);
        requestsData.forEach((req: LeaveRequest) => {
          console.log(`Request: ID=${req.id}, Start=${req.start_date}, End=${req.end_date}, Days=${req.days}`);
        });

        setLeaveRequests(requestsData);

        // Buat event untuk calendar
        const events = requestsData.map((req: LeaveRequest) => ({
          id: req.id,
          title: `${req.employee?.name || 'Unknown'} - ${req.type} (${req.status})`,
          start: new Date(req.start_date),
          end: new Date(req.end_date),
          allDay: true,
          resource: req,
        }));
        setCalendarEvents(events);

        // Ambil balance
        const resBalance = await api_laravel.get("/api/leave-balance", {
          params: { c_code: companyCode }
        });
        
        if (resBalance.data?.data) {
          setLeaveBalance(Array.isArray(resBalance.data.data) ? resBalance.data.data : [resBalance.data.data]);
        }

        // Ambil user data
        const resUser = await api_laravel.get("/api/me");
        const userData = resUser.data.data.user;
        
        setCurrentUser({
          uuid: userData.uuid,
          role: userData.roles?.[0] || "user"
        });

      } catch (err: any) {
        console.error("Error fetching data:", err);
        Swal.fire(
          "Error",
          err.response?.data?.message || "Failed to load leave data",
          "error"
        );
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "Approved":
        return <Badge className="bg-green-100 text-green-800">Approved</Badge>;
      case "Pending":
        return <Badge className="bg-yellow-100 text-yellow-800">Pending</Badge>;
      case "Rejected":
        return <Badge className="bg-red-100 text-red-800">Rejected</Badge>;
      default:
        return <Badge variant="outline">{status}</Badge>;
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "Approved":
        return <CheckCircle className="h-4 w-4 text-green-600" />;
      case "Pending":
        return <Clock className="h-4 w-4 text-yellow-600" />;
      case "Rejected":
        return <XCircle className="h-4 w-4 text-red-600" />;
      default:
        return <AlertCircle className="h-4 w-4 text-gray-400" />;
    }
  };

  const handleApproveReject = async (requestId: string, status: "Approved" | "Rejected") => {
    try {
      const companyCode = getCompanyCode();
      if (!companyCode) {
        Swal.fire("Error", "Company code not found", "error");
        return;
      }

      await api_laravel.put(`/api/leave-requests/${requestId}`, { 
        status,
        c_code: companyCode 
      });
      
      Swal.fire({
        icon: "success",
        title: "Success",
        text: `Request ${status.toLowerCase()} successfully`,
        timer: 2000,
        showConfirmButton: false
      });

      // Refresh data
      const resRequests = await api_laravel.get("/api/leave-requests", {
        params: { c_code: companyCode }
      });
      setLeaveRequests(resRequests.data.data || []);
    } catch (err: any) {
      console.error("Error updating request:", err);
      Swal.fire("Error", err.response?.data?.message || "Failed to update request", "error");
    }
  };

  const handleRequestLeave = async () => {
    // Validasi
    if (!newRequestReason.trim()) {
      return Swal.fire("Warning", "Reason is required", "warning");
    }
    if (!newRequestStartDate) {
      return Swal.fire("Warning", "Start date is required", "warning");
    }
    if (!newRequestEndDate) {
      return Swal.fire("Warning", "End date is required", "warning");
    }

    // Validasi tanggal: end date tidak boleh sebelum start date
    const startDate = new Date(newRequestStartDate);
    const endDate = new Date(newRequestEndDate);
    if (endDate < startDate) {
      return Swal.fire("Error", "End date cannot be before start date", "error");
    }

    // Hitung days
    const calculatedDays = calculateDaysDifference(newRequestStartDate, newRequestEndDate);
    if (calculatedDays < 1) {
      return Swal.fire("Error", "Invalid date range", "error");
    }

    try {
      const userRes = await api_laravel.get("/api/me");
      const userData = userRes.data.data.user;
      
      const employeeRes = await api_laravel.get(`/api/employees/${userData.uuid}`);
      const employeeData = employeeRes.data.data;
      
      if (!employeeData) {
        return Swal.fire("Error", "Employee data not found", "error");
      }

      const userBalance = leaveBalance[0];
      if (!userBalance) {
        return Swal.fire("Error", "Leave balance not loaded", "error");
      }

      // Validasi days berdasarkan balance
      let maxDays = 0;
      if (newRequestType === "Annual Leave") maxDays = userBalance.annual.total - userBalance.annual.used;
      if (newRequestType === "Sick Leave") maxDays = userBalance.sick.total - userBalance.sick.used;
      if (newRequestType === "Personal Leave") maxDays = userBalance.personal.total - userBalance.personal.used;

      if (calculatedDays > maxDays) {
        return Swal.fire("Error", `Cannot request more than ${maxDays} days. You have ${maxDays} days remaining.`, "error");
      }

      const companyCode = getCompanyCode();
      if (!companyCode) {
        Swal.fire("Error", "Company code not found", "error");
        return;
      }

      setSubmitting(true);
      
      await api_laravel.post("/api/leave-requests", {
        employee_id: employeeData.id,
        type: newRequestType,
        start_date: newRequestStartDate,
        end_date: newRequestEndDate,
        days: calculatedDays, // Gunakan calculated days
        reason: newRequestReason.trim(),
        c_code: companyCode
      });

      Swal.fire({
        icon: "success",
        title: "Success",
        text: `Leave requested successfully for ${calculatedDays} days`,
        timer: 2000,
        showConfirmButton: false
      });

      // Reset form
      setNewRequestType("Annual Leave");
      setNewRequestDays(1);
      setNewRequestReason("");
      setNewRequestStartDate("");
      setNewRequestEndDate("");
      setSelectedTab("requests");

      // Refresh data
      const [resRequests, resBalance] = await Promise.all([
        api_laravel.get("/api/leave-requests", { params: { c_code: companyCode } }),
        api_laravel.get("/api/leave-balance", { params: { c_code: companyCode } })
      ]);
      
      setLeaveRequests(resRequests.data.data || []);
      if (resBalance.data?.data) {
        setLeaveBalance(Array.isArray(resBalance.data.data) ? resBalance.data.data : [resBalance.data.data]);
      }

    } catch (err: any) {
      console.error("Error submitting leave request:", err);
      
      if (err.response?.status === 422) {
        const messages = Object.values(err.response.data.errors || {})
          .flat()
          .join("\n");
        Swal.fire("Validation Error", messages, "error");
      } else if (err.response?.status === 403) {
        Swal.fire("Unauthorized", err.response?.data?.message || "You are not authorized", "error");
      } else if (err.response?.status === 404) {
        Swal.fire("Not Found", err.response?.data?.message || "Employee not found", "error");
      } else {
        Swal.fire("Error", err.response?.data?.message || "Failed to submit request", "error");
      }
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto"></div>
          <p className="mt-2 text-muted-foreground">Loading leave data...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>Leave Management</CardTitle>
          <div className="flex items-center justify-between">
            <p className="text-muted-foreground">Manage employee leave requests and balances</p>
            <Badge variant="outline">
              Company: {companyCode || "Not selected"}
            </Badge>
          </div>
        </CardHeader>
      </Card>

      <Tabs value={selectedTab} onValueChange={setSelectedTab}>
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="requests">Leave Requests</TabsTrigger>
          <TabsTrigger value="request">Request Leave</TabsTrigger>
          <TabsTrigger value="balance">Leave Balance</TabsTrigger>
          <TabsTrigger value="calendar">Leave Calendar</TabsTrigger>
        </TabsList>

        {/* Leave Requests */}
        <TabsContent value="requests" className="space-y-4">
          <div className="grid gap-4">
            {leaveRequests.length === 0 ? (
              <Card>
                <CardContent className="p-6 text-center">
                  <p className="text-muted-foreground">No leave requests found</p>
                </CardContent>
              </Card>
            ) : (
              leaveRequests.map((request) => (
                <Card key={request.id} className="hover:shadow-md transition-shadow">
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-4">
                        <Avatar>
                          <AvatarImage src={request.employee?.avatar} alt={request.employee?.name} />
                          <AvatarFallback>
                            {request.employee?.name?.split(" ").map((n) => n[0]).join("") || "??"}
                          </AvatarFallback>
                        </Avatar>
                        <div>
                          <h3 className="font-semibold">{request.employee?.name || "Unknown Employee"}</h3>
                          <p className="text-sm text-muted-foreground">{request.type}</p>
                        </div>
                      </div>
                      <div className="flex items-center space-x-2">
                        {getStatusIcon(request.status)}
                        {getStatusBadge(request.status)}
                      </div>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mt-4">
                      <div>
                        <p className="text-sm text-muted-foreground">Start Date</p>
                        <p className="font-medium">{formatDate(request.start_date)}</p>
                      </div>
                      <div>
                        <p className="text-sm text-muted-foreground">End Date</p>
                        <p className="font-medium">{formatDate(request.end_date)}</p>
                      </div>
                      <div>
                        <p className="text-sm text-muted-foreground">Duration</p>
                        <p className="font-medium">
                          {request.days} {request.days === 1 ? 'day' : 'days'}
                          <span className="text-xs text-muted-foreground block">
                            {calculateDaysDifference(request.start_date, request.end_date) === request.days 
                              ? '✓ Calculated correctly' 
                              : '⚠️ Check calculation'}
                          </span>
                        </p>
                      </div>
                      <div>
                        <p className="text-sm text-muted-foreground">Submitted</p>
                        <p className="font-medium">
                          {formatDate(request.created_at)}
                        </p>
                      </div>
                    </div>

                    <div className="mt-4">
                      <p className="text-sm text-muted-foreground">Reason</p>
                      <p className="text-sm">{request.reason}</p>
                    </div>

                    {/* Approve/Reject buttons */}
                    {request.status === "Pending" &&
                      (currentUser.uuid === request.immediate_supervisor || 
                       currentUser.role?.toLowerCase() === "administrator") && (
                      <div className="flex space-x-2 mt-4">
                        <Button
                          variant="default"
                          className="bg-green-600 hover:bg-green-700"
                          onClick={() => handleApproveReject(request.id, "Approved")}
                        >
                          Approve
                        </Button>
                        <Button
                          variant="destructive"
                          onClick={() => handleApproveReject(request.id, "Rejected")}
                        >
                          Reject
                        </Button>
                      </div>
                    )}
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </TabsContent>

        {/* Request Leave */}
        <TabsContent value="request">
          <Card>
            <CardHeader>
              <CardTitle>Request Leave</CardTitle>
              <p className="text-sm text-muted-foreground">Company: {companyCode}</p>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-1">Leave Type</label>
                <select
                  className="w-full border p-2 rounded"
                  value={newRequestType}
                  onChange={(e) => setNewRequestType(e.target.value)}
                >
                  <option value="Annual Leave">Annual Leave</option>
                  <option value="Sick Leave">Sick Leave</option>
                  <option value="Personal Leave">Personal Leave</option>
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium mb-1">Start Date</label>
                  <input
                    type="date"
                    value={newRequestStartDate}
                    onChange={(e) => setNewRequestStartDate(e.target.value)}
                    className="w-full border p-2 rounded"
                    min={new Date().toISOString().split('T')[0]} // Tidak boleh tanggal kemarin
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-1">End Date</label>
                  <input
                    type="date"
                    value={newRequestEndDate}
                    onChange={(e) => setNewRequestEndDate(e.target.value)}
                    className="w-full border p-2 rounded"
                    min={newRequestStartDate || new Date().toISOString().split('T')[0]}
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium mb-1">
                  Duration: <span className="font-bold text-primary">{newRequestDays} {newRequestDays === 1 ? 'day' : 'days'}</span>
                </label>
                <div className="flex items-center space-x-2">
                  <input
                    type="range"
                    min="1"
                    max="30"
                    value={newRequestDays}
                    onChange={(e) => setNewRequestDays(parseInt(e.target.value))}
                    className="flex-1"
                    disabled={!newRequestStartDate || !newRequestEndDate}
                  />
                  <span className="text-sm font-medium w-12">{newRequestDays}d</span>
                </div>
                <p className="text-xs text-muted-foreground mt-1">
                  {newRequestStartDate && newRequestEndDate 
                    ? `From ${formatDate(newRequestStartDate)} to ${formatDate(newRequestEndDate)}`
                    : 'Select start and end dates first'}
                </p>
              </div>

              <div>
                <label className="block text-sm font-medium mb-1">Reason</label>
                <textarea
                  value={newRequestReason}
                  onChange={(e) => setNewRequestReason(e.target.value)}
                  className="w-full border p-2 rounded"
                  rows={3}
                  placeholder="Enter your reason for leave"
                />
              </div>

              {!companyCode && (
                <div className="p-3 bg-yellow-50 border border-yellow-200 rounded">
                  <p className="text-sm text-yellow-700">
                    ⚠️ Company code not found. Please login again or select a company.
                  </p>
                </div>
              )}

              {/* Balance Info */}
              {leaveBalance.length > 0 && (
                <div className="p-3 bg-blue-50 border border-blue-200 rounded">
                  <p className="text-sm font-medium mb-2">Your Leave Balance:</p>
                  <div className="grid grid-cols-3 gap-2 text-sm">
                    <div>
                      <span className="text-muted-foreground">Annual: </span>
                      <span className="font-medium">
                        {leaveBalance[0].annual.total - leaveBalance[0].annual.used} days left
                      </span>
                    </div>
                    <div>
                      <span className="text-muted-foreground">Sick: </span>
                      <span className="font-medium">
                        {leaveBalance[0].sick.total - leaveBalance[0].sick.used} days left
                      </span>
                    </div>
                    <div>
                      <span className="text-muted-foreground">Personal: </span>
                      <span className="font-medium">
                        {leaveBalance[0].personal.total - leaveBalance[0].personal.used} days left
                      </span>
                    </div>
                  </div>
                </div>
              )}

              <Button
                onClick={handleRequestLeave}
                disabled={submitting || !companyCode || !newRequestStartDate || !newRequestEndDate || !newRequestReason.trim()}
                className="w-full"
              >
                {submitting ? "Submitting..." : `Request ${newRequestDays} ${newRequestDays === 1 ? 'day' : 'days'} Leave`}
              </Button>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Calendar */}
        <TabsContent value="calendar">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center">
                <CalendarIcon className="h-5 w-5 mr-2" />
                Leave Calendar - {companyCode}
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="h-[600px]">
                <BigCalendar
                  localizer={localizer}
                  events={calendarEvents}
                  startAccessor="start"
                  endAccessor="end"
                  style={{ height: "100%" }}
                  eventPropGetter={(event) => {
                    let bg = "#3b82f6";
                    if (event.resource.status === "Approved") bg = "#16a34a";
                    if (event.resource.status === "Rejected") bg = "#dc2626";
                    if (event.resource.status === "Pending") bg = "#facc15";
                    return { style: { backgroundColor: bg, color: "white" } };
                  }}
                />
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}