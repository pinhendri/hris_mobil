"use client";

import { useEffect, useState } from "react";
import { Plus, Eye } from "lucide-react"; 
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import Swal from "sweetalert2";
import api_laravel from "@/lib/utils";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";

interface Application {
  id: number;
  name: string;
  email: string;
  phone: string;
  position: string;
  department: string;
  status: string;
  created_at: string;
  cv?: string | null;
}

interface Department {
  id: number;
  name: string;
  description?: string;
}

interface Position {
  id: number;
  position_id: number;
  title: string;
  department: string;
}

// Map untuk konversi antara frontend dan backend values
const statusMap = {
  // Frontend value: Backend value
  'applied': 'Applied',
  'screening': 'Screening', 
  'interview': 'Interview',
  'offer': 'Offer',
  'hired': 'Hired',
  'rejected': 'Rejected'
} as const;

// Reverse map untuk display
const reverseStatusMap = {
  'Applied': 'applied',
  'Screening': 'screening',
  'Interview': 'interview', 
  'Offer': 'offer',
  'Hired': 'hired',
  'Rejected': 'rejected'
} as const;

export default function ApplicationsPage() {
  const [applications, setApplications] = useState<Application[]>([]);
  const [departments, setDepartments] = useState<Department[]>([]);
  const [positions, setPositions] = useState<Position[]>([]);
  const [filters, setFilters] = useState({
    position: "",
    department: "",
    status: "",
  });
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    phone: "",
    position: "",
    department: "",
    cv: null as File | null,
  });
  const [loading, setLoading] = useState({
    applications: false,
    departments: false,
    positions: false,
  });

  const fetchApplications = async () => {
    setLoading(prev => ({ ...prev, applications: true }));
    try {
      const res = await api_laravel.get("/api/recruitment/applications", {
        params: { ...filters },
      });
      console.log("Applications response:", res.data);
      
      // Handle berbagai format response
      let applicationsData: Application[] = [];
      if (res.data) {
        if (Array.isArray(res.data.data)) {
          applicationsData = res.data.data;
        } else if (Array.isArray(res.data)) {
          applicationsData = res.data;
        } else if (res.data.data && Array.isArray(res.data.data.data)) {
          applicationsData = res.data.data.data;
        } else if (res.data.success && Array.isArray(res.data.data)) {
          applicationsData = res.data.data;
        }
      }
      
      setApplications(applicationsData);
    } catch (err) {
      console.error("Error fetching applications:", err);
      Swal.fire("Error", "Gagal mengambil data aplikasi", "error");
    } finally {
      setLoading(prev => ({ ...prev, applications: false }));
    }
  };

  const fetchDepartments = async () => {
    setLoading(prev => ({ ...prev, departments: true }));
    try {
      const res = await api_laravel.get("/api/departments");
      console.log("Departments response:", res.data);
      
      // Handle berbagai format response
      let departmentsData: Department[] = [];
      if (res.data) {
        if (Array.isArray(res.data.data)) {
          departmentsData = res.data.data;
        } else if (Array.isArray(res.data)) {
          departmentsData = res.data;
        } else if (res.data.data && Array.isArray(res.data.data)) {
          departmentsData = res.data.data;
        } else if (Array.isArray(res.data.departments)) {
          departmentsData = res.data.departments;
        }
      }
      
      setDepartments(departmentsData);
    } catch (err) {
      console.error("Error fetching departments:", err);
      // Fallback ke default departments
      setDepartments([
        { id: 1, name: "Engineering" },
        { id: 2, name: "Marketing" },
        { id: 3, name: "Sales" },
        { id: 4, name: "HR" },
        { id: 5, name: "Finance" },
        { id: 6, name: "IT" },
      ]);
    } finally {
      setLoading(prev => ({ ...prev, departments: false }));
    }
  };

  const fetchPositions = async () => {
    setLoading(prev => ({ ...prev, positions: true }));
    try {
      const res = await api_laravel.get("/api/recruitment");
      console.log("Positions response:", res.data);
      
      if (res.data) {
        // Handle berbagai format response
        let positionsData: Position[] = [];
        
        if (Array.isArray(res.data.openPositions)) {
          positionsData = res.data.openPositions.map((item: any) => ({
            id: item.id,
            position_id: item.position_id,
            title: item.title,
            department: item.department,
          }));
        } else if (Array.isArray(res.data.data)) {
          positionsData = res.data.data.map((item: any) => ({
            id: item.id,
            position_id: item.position_id,
            title: item.title,
            department: item.department,
          }));
        } else if (Array.isArray(res.data.positions)) {
          positionsData = res.data.positions.map((item: any) => ({
            id: item.id,
            position_id: item.position_id,
            title: item.title,
            department: item.department,
          }));
        }
        
        setPositions(positionsData);
      }
    } catch (err) {
      console.error("Error fetching positions:", err);
      Swal.fire("Error", "Gagal mengambil data posisi", "error");
    } finally {
      setLoading(prev => ({ ...prev, positions: false }));
    }
  };

  useEffect(() => {
    fetchApplications();
    fetchDepartments();
    fetchPositions();
  }, []);

  const handleAddApplication = async () => {
    if (
      !formData.name ||
      !formData.email ||
      !formData.phone ||
      !formData.position ||
      !formData.department ||
      !formData.cv
    ) {
      Swal.fire("Error", "Lengkapi semua field termasuk upload CV", "error");
      return;
    }

    try {
      const payload = new FormData();
      payload.append("name", formData.name);
      payload.append("email", formData.email);
      payload.append("phone", formData.phone);
      payload.append("position_id", formData.position);
      payload.append("department_id", formData.department);
      payload.append("cv", formData.cv);

      const response = await api_laravel.post("/api/recruitment/applications", payload, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      
      console.log("Add application response:", response.data);

      Swal.fire("Success", "Application added successfully!", "success");
      setShowForm(false);
      setFormData({
        name: "",
        email: "",
        phone: "",
        position: "",
        department: "",
        cv: null,
      });
      fetchApplications();
    } catch (err: any) {
      console.error("Error adding application:", err);
      console.error("Error response:", err.response?.data);
      const errorMessage = err.response?.data?.message || "Gagal menambahkan aplikasi";
      Swal.fire("Error", errorMessage, "error");
    }
  };

  const updateStatus = async (id: number, frontendStatus: string) => {
    try {
      // Convert frontend status to backend format
      const backendStatus = statusMap[frontendStatus as keyof typeof statusMap];
      
      console.log("Updating application:", id, "from:", frontendStatus, "to backend:", backendStatus);
      
      const response = await api_laravel.put(`/api/recruitment/applications/${id}`, { 
        status: backendStatus 
      });
      
      console.log("Update successful:", response.data);
      
      // Update local state dengan status yang sudah dikonversi
      setApplications((prev) =>
        prev.map((app) => 
          app.id === id ? { ...app, status: backendStatus } : app
        )
      );
      Swal.fire("Success", "Status updated successfully!", "success");
    } catch (err: any) {
      console.error("Error updating status:", err);
      
      if (err.response) {
        console.error("Error response data:", err.response.data);
      }
      
      const errorMessage = err.response?.data?.message || "Failed to update status";
      Swal.fire("Error", errorMessage, "error");
    }
  };

  // Get frontend status value for Select component
  const getFrontendStatus = (backendStatus: string): string => {
    return reverseStatusMap[backendStatus as keyof typeof reverseStatusMap] || backendStatus.toLowerCase();
  };

  return (
    <Card>
      <CardHeader className="flex flex-row justify-between items-center">
        <CardTitle>All Applications</CardTitle>

        <Dialog open={showForm} onOpenChange={setShowForm}>
          <DialogTrigger asChild>
            <Button>
              <Plus className="mr-2 w-4 h-4"/> 
              Add Application
            </Button>
          </DialogTrigger>
          <DialogContent className="bg-white max-w-md">
            <DialogHeader>
              <DialogTitle>Add New Application</DialogTitle>
            </DialogHeader>
            <div className="space-y-4">
              <div>
                <Label htmlFor="name">Name</Label>
                <Input 
                  id="name"
                  value={formData.name} 
                  onChange={(e) => setFormData({...formData, name: e.target.value})} 
                />
              </div>
              <div>
                <Label htmlFor="email">Email</Label>
                <Input 
                  id="email"
                  type="email"
                  value={formData.email} 
                  onChange={(e) => setFormData({...formData, email: e.target.value})} 
                />
              </div>
              <div>
                <Label htmlFor="phone">Phone</Label>
                <Input 
                  id="phone"
                  value={formData.phone} 
                  onChange={(e) => setFormData({...formData, phone: e.target.value})} 
                />
              </div>
              <div>
                <Label htmlFor="position">Position</Label>
                <Select 
                  value={formData.position} 
                  onValueChange={(val) => setFormData({...formData, position: val})}
                >
                  <SelectTrigger id="position">
                    <SelectValue placeholder={loading.positions ? "Loading..." : "Select Position"}/>
                  </SelectTrigger>
                  <SelectContent>
                    {Array.isArray(positions) && positions.length > 0 ? (
                      positions.map((pos) => (
                        <SelectItem key={pos.id || pos.position_id} value={String(pos.position_id)}>
                          {pos.title}
                        </SelectItem>
                      ))
                    ) : (
                      <SelectItem value="no-positions" disabled>
                        No positions available
                      </SelectItem>
                    )}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label htmlFor="department">Department</Label>
                <Select 
                  value={formData.department} 
                  onValueChange={(val) => setFormData({...formData, department: val})}
                >
                  <SelectTrigger id="department">
                    <SelectValue placeholder={loading.departments ? "Loading..." : "Select Department"}/>
                  </SelectTrigger>
                  <SelectContent>
                    {Array.isArray(departments) && departments.length > 0 ? (
                      departments.map((dep) => (
                        <SelectItem key={dep.id} value={String(dep.id)}>
                          {dep.description || dep.name}
                        </SelectItem>
                      ))
                    ) : (
                      <SelectItem value="no-departments" disabled>
                        No departments available
                      </SelectItem>
                    )}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label htmlFor="cv">Upload CV (PDF)</Label>
                <Input 
                  id="cv"
                  type="file" 
                  accept=".pdf,.doc,.docx"
                  onChange={(e) => setFormData({...formData, cv: e.target.files?.[0] ?? null})} 
                />
              </div>
            </div>
            <DialogFooter>
              <Button onClick={handleAddApplication}>Save Application</Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </CardHeader>

      <CardContent>
        {loading.applications ? (
          <div className="flex justify-center items-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
            <p className="ml-2 text-muted-foreground">Loading applications...</p>
          </div>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Email</TableHead>
                  <TableHead>Phone</TableHead>
                  <TableHead>Position</TableHead>
                  <TableHead>Department</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Applied On</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {Array.isArray(applications) && applications.length > 0 ? (
                  applications.map((app) => (
                    <TableRow key={app.id}>
                      <TableCell className="flex items-center gap-2">
                        {app.cv && (
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => window.open(app.cv!, "_blank")}
                            className="hover:bg-muted rounded-full h-8 w-8"
                            title="View CV"
                          >
                            <Eye className="h-4 w-4 text-blue-600" />
                          </Button>
                        )}
                        <span className="font-medium">{app.name}</span>
                      </TableCell>
                      <TableCell>{app.email}</TableCell>
                      <TableCell>{app.phone}</TableCell>
                      <TableCell>{app.position}</TableCell>
                      <TableCell>{app.department}</TableCell>
                      <TableCell>
                        <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                          app.status === 'Hired' ? 'bg-green-100 text-green-800' :
                          app.status === 'Rejected' ? 'bg-red-100 text-red-800' :
                          app.status === 'Interview' ? 'bg-blue-100 text-blue-800' :
                          app.status === 'Offer' ? 'bg-purple-100 text-purple-800' :
                          app.status === 'Screening' ? 'bg-yellow-100 text-yellow-800' :
                          'bg-gray-100 text-gray-800'
                        }`}>
                          {app.status}
                        </span>
                      </TableCell>
                      <TableCell>
                        {new Date(app.created_at).toLocaleDateString('en-US', {
                          year: 'numeric',
                          month: 'short',
                          day: 'numeric'
                        })}
                      </TableCell>
                      <TableCell>
                        <Select 
                          value={getFrontendStatus(app.status)} 
                          onValueChange={(val) => updateStatus(app.id, val)}
                        >
                          <SelectTrigger className="w-[150px]">
                            <SelectValue placeholder="Change Status" />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="applied">Applied</SelectItem>
                            <SelectItem value="screening">Screening</SelectItem>
                            <SelectItem value="interview">Interview</SelectItem>
                            <SelectItem value="offer">Offer</SelectItem>
                            <SelectItem value="hired">Hired</SelectItem>
                            <SelectItem value="rejected">Rejected</SelectItem>
                          </SelectContent>
                        </Select>
                      </TableCell>
                    </TableRow>
                  ))
                ) : (
                  <TableRow>
                    <TableCell colSpan={8} className="text-center py-8 text-muted-foreground">
                      No applications found
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>
    </Card>
  );
}