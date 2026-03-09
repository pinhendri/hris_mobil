import { Building2, Users, TrendingUp, Plus } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Progress } from "@/components/ui/progress";
import { useEffect, useState } from "react";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";

interface Employee {
  id: number;
  uuid: string;
  name: string;
  position: string;
  position_name: string;
  avatar?: string;
}

interface Department {
  id: number;
  name: string;
  employee_id: string; // ✅ Ubah menjadi string untuk UUID
  head_uuid?: string; // ✅ Tambahkan field khusus UUID
  head_name?: string;
  employees: number; 
  employee: number;
  budget: number;
  growth: number;
  performance: number;
  description: string;
}

const mockDepartments: Department[] = [
  {
    id: 1,
    name: "Engineering",
    employee_id: "uuid-engineering-head", // ✅ Contoh UUID
    employees: 42,
    employee: 3,
    budget: 2800000,
    growth: 15,
    performance: 92,
    description: "Software development and technical innovation",
  },
  {
    id: 2,
    name: "Sales",
    employee_id: "uuid-sales-head", // ✅ Contoh UUID
    employees: 28,
    employee: 3,
    budget: 1500000,
    growth: 8,
    performance: 89,
    description: "Revenue generation and client acquisition",
  },
];

export default function Departments() {
  const [departments, setDepartments] = useState<Department[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState<Partial<Department>>({});
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [editId, setEditId] = useState<number | null>(null);

  useEffect(() => {
    api_laravel.get("/api/departments")
      .then((res) => {
        console.log("RAW DEPARTMENTS:", res.data); 
        
        let departmentsData = [];
        
        if (res.data?.data && Array.isArray(res.data.data)) {
          departmentsData = res.data.data;
        } else if (Array.isArray(res.data)) {
          departmentsData = res.data;
        } else {
          console.error("Struktur response tidak dikenali:", res.data);
          departmentsData = [];
        }
        
        const mapped = departmentsData.map((dept: any) => ({
          ...dept,
          // ✅ FIX: Handle UUID untuk employee_id
          employee_id: dept.employee_uuid || dept.head_uuid || dept.employee_id || '',
          head_uuid: dept.employee_uuid || dept.head_uuid || dept.employee_id || '',
          head_name: dept.head?.name || dept.employee_name || 'Unknown',
          employees: Number(dept.employees ?? 0),
          employee: Number(dept.employee ?? 0),
          budget: Number(dept.budget ?? 0),
          growth: Number(dept.growth ?? 0),
          performance: Number(dept.performance ?? 0),
        }));
        
        console.log("MAPPED DEPARTMENTS:", mapped);
        setDepartments(mapped);
      })
      .catch((err) => {
        console.error("Gagal fetch departments:", err);
        console.log("Gunakan mock data");
        setDepartments(mockDepartments);
      });
  }, []);

  useEffect(() => {
    api_laravel.get("/api/employees/list")
      .then((res) => {
        console.log("RAW EMPLOYEES RESPONSE:", res.data);
        
        let employeesData = [];
        
        if (res.data?.data?.data && Array.isArray(res.data.data.data)) {
          employeesData = res.data.data.data;
        } else if (res.data?.data && Array.isArray(res.data.data)) {
          employeesData = res.data.data;
        } else if (Array.isArray(res.data)) {
          employeesData = res.data;
        } else {
          console.error("Format response employees tidak sesuai", res.data);
          employeesData = [];
        }
        
        console.log("PROCESSED EMPLOYEES:", employeesData);
        setEmployees(employeesData);
      })
      .catch((err) => {
        console.error("Gagal fetch employees", err);
      });
  }, []);

  // ✅ FIX: Cari head berdasarkan UUID
  const getHead = (employeeUuid: string) => {
    if (!employees || employees.length === 0 || !employeeUuid) {
      console.log("No employees data available or invalid UUID");
      return null;
    }
    
    const head = employees.find((e) => e.uuid === employeeUuid);
    
    console.log(`Looking for head with UUID: ${employeeUuid}`, {
      availableEmployees: employees.map(e => ({ uuid: e.uuid, name: e.name })),
      found: head
    });
    
    return head || null;
  };

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>
  ) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };
const handleSubmit = async () => {
  try {
    // ✅ FIX: Sesuaikan payload dengan struktur tabel
    const payload = {
      name: formData.name,
      employee_id: formData.employee_id, // ✅ langsung kirim sebagai employee_id (UUID)
      employee: Number(formData.employee ?? 0),
      budget: Number(formData.budget ?? 0),
      growth: Number(formData.growth ?? 0),
      performance: Number(formData.performance ?? 0),
      description: formData.description,
    };

    console.log("Submitting payload:", payload);

    if (editId) {
      // UPDATE
      const res = await api_laravel.put(`/api/departments/${editId}`, payload);
      const updatedDept = res.data.data || res.data;
      
      setDepartments(
        departments.map((d) => {
          if (d.id === editId) {
            return {
              ...d,
              ...updatedDept,
              employee_id: updatedDept.employee_id || '', // ✅ langsung pakai employee_id dari response
              employees: Number(updatedDept.employees ?? 0),
              employee: Number(updatedDept.employee ?? 0),
              budget: Number(updatedDept.budget ?? 0),
              growth: Number(updatedDept.growth ?? 0),
              performance: Number(updatedDept.performance ?? 0),
            };
          }
          return d;
        })
      );
      Swal.fire({
        icon: "success",
        title: "Updated!",
        text: "Department has been updated successfully.",
        timer: 1500,
        showConfirmButton: false,
      });
    } else {
      // CREATE
      const res = await api_laravel.post("/api/departments", payload);
      const newDept = res.data.data || res.data;
      
      setDepartments([
        ...departments,
        {
          ...newDept,
          employee_id: newDept.employee_id || '', // ✅ langsung pakai employee_id dari response
          employees: Number(newDept.employees ?? 0),
          employee: Number(newDept.employee ?? 0),
          budget: Number(newDept.budget ?? 0),
          growth: Number(newDept.growth ?? 0),
          performance: Number(newDept.performance ?? 0),
        },
      ]);
      Swal.fire({
        icon: "success",
        title: "Created!",
        text: "New department has been added.",
        timer: 1500,
        showConfirmButton: false,
      });
    }

    setShowForm(false);
    setFormData({});
    setEditId(null);
  } catch (err: any) {
    console.error("Gagal simpan department", err);
    const errorMessage = err.response?.data?.message || "Failed to save department.";
    Swal.fire({
      icon: "error",
      title: "Oops...",
      text: errorMessage,
    });
  }
};
  // View detail
  const handleView = (dept: Department) => {
    const head = getHead(dept.employee_id);
    console.log("Viewing department:", dept, "Head:", head);
    
    Swal.fire({
      title: `<strong>${dept.name}</strong>`,
      html: `
        <p><b>Head:</b> ${head?.name || "-"}</p>
        <p><b>Head UUID:</b> ${dept.employee_id}</p>
        <p><b>Employees:</b> ${dept.employees}</p>
        <p><b>Budget:</b> $${(dept.budget / 1000000).toFixed(1)}M</p>
        <p><b>Growth:</b> ${dept.growth}%</p>
        <p><b>Performance:</b> ${dept.performance}%</p>
        <p><b>Description:</b> ${dept.description}</p>
      `,
      icon: "info",
      confirmButtonText: "Close",
    });
  };

  // Edit
  const handleEdit = (dept: Department) => {
    console.log("Editing department:", dept);
    
    // ✅ FIX: Set form data dengan UUID
    setFormData({
      ...dept,
      employee_id: dept.employee_id // ini sudah UUID
    });
    
    setEditId(dept.id);
    setShowForm(true);

    Swal.fire({
      icon: "info",
      title: "Edit Mode",
      text: `You are editing department: ${dept.name}`,
      timer: 1200,
      showConfirmButton: false,
    });
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Departments</h1>
          <p className="text-muted-foreground">
            Manage organizational structure and department performance.
          </p>
        </div>
        <Button className="btn-gradient" onClick={() => setShowForm(true)}>
          <Plus className="h-4 w-4 mr-2" />
          Add Department
        </Button>
      </div>

      {/* Debug Info */}
      {process.env.NODE_ENV === 'development' && (
        <Card className="bg-yellow-50 border-yellow-200">
          <CardHeader>
            <CardTitle className="text-sm">Debug Information</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-xs space-y-2">
              <div>Total Departments: {departments.length}</div>
              <div>Total Employees: {employees.length}</div>
              <div>Using UUID: Yes</div>
              <div>Sample Department Heads: {departments.slice(0, 3).map(dept => 
                `${dept.name}: ${dept.employee_id?.substring(0, 8)}...`
              ).join(', ')}</div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* FORM ADD / EDIT DEPARTMENT */}
      {showForm && (
        <div className="p-6 border rounded-lg bg-white shadow-md">
          <h2 className="text-xl font-semibold mb-4">
            {editId ? "Edit Department" : "Add Department"}
          </h2>
          <div className="grid gap-3">
            <input
              name="name"
              placeholder="Department Name"
              className="border p-2 rounded"
              value={formData.name || ""}
              onChange={handleChange}
            />

            {/* ✅ FIX: Select Head berdasarkan UUID */}
            <select
              name="employee_id"
              className="border p-2 rounded"
              value={formData.employee_id || ""}
              onChange={(e) =>
                setFormData({ ...formData, employee_id: e.target.value })
              }
            >
              <option value="">-- Select Department Head --</option>
              {employees.map((emp) => (
                <option key={emp.uuid} value={emp.uuid}>
                  {emp.name} ({emp.position_name || emp.position})
                </option>
              ))}
            </select>

            {/* Employees target */}
            <input
              name="employee"
              placeholder="Target Employees"
              type="number"
              className="border p-2 rounded"
              value={formData.employee ?? ""}
              onChange={handleChange}
            />

            <input
              name="budget"
              placeholder="Budget"
              type="number"
              className="border p-2 rounded"
              value={formData.budget || ""}
              onChange={handleChange}
            />

            <textarea
              name="description"
              placeholder="Description"
              className="border p-2 rounded"
              value={formData.description || ""}
              onChange={handleChange}
            />
          </div>
          <div className="flex space-x-2 mt-4">
            <Button onClick={handleSubmit}>Save</Button>
            <Button
              variant="outline"
              onClick={() => {
                setShowForm(false);
                setEditId(null);
                setFormData({});
              }}
            >
              Cancel
            </Button>
          </div>
        </div>
      )}

      {/* Department Overview */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Total Departments */}
        <Card className="card-metric">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">
                  Total Departments
                </p>
                <p className="text-3xl font-bold text-foreground">
                  {departments.length}
                </p>
                <p className="text-sm text-success">+1 this quarter</p>
              </div>
              <div className="p-3 rounded-lg bg-primary-light">
                <Building2 className="h-6 w-6 text-primary" />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Total Employees */}
        <Card className="card-metric">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">
                  Total Employees
                </p>
                <p className="text-3xl font-bold text-foreground">
                  {departments.reduce((sum, dept) => sum + dept.employees, 0)}
                </p>
                <p className="text-sm text-success">+12% growth</p>
              </div>
              <div className="p-3 rounded-lg bg-success-light">
                <Users className="h-6 w-6 text-success" />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Avg Performance */}
        <Card className="card-metric bg-gradient-primary text-white">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-white/80">
                  Avg Performance
                </p>
                <p className="text-3xl font-bold text-white">
                  {departments.length > 0
                    ? Math.round(
                        departments.reduce(
                          (sum, dept) => sum + dept.performance,
                          0
                        ) / departments.length
                      )
                    : 0}
                  %
                </p>
                <p className="text-sm text-white/90">Across all departments</p>
              </div>
              <div className="p-3 rounded-lg bg-white/20">
                <TrendingUp className="h-6 w-6 text-white" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Department Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {departments.map((dept) => {
          const head = getHead(dept.employee_id);
          console.log(`Rendering department ${dept.name}:`, { dept, head });
          
          return (
            <Card
              key={dept.id}
              className="card-dashboard hover:shadow-lg transition-shadow duration-200"
            >
              <CardHeader className="pb-3">
                <div className="flex items-center space-x-3">
                  <div className="p-2 bg-primary-light rounded-lg">
                    <Building2 className="h-5 w-5 text-primary" />
                  </div>
                  <div>
                    <CardTitle className="text-lg">{dept.name}</CardTitle>
                    <p className="text-sm text-muted-foreground">
                      {dept.description}
                    </p>
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                {/* Department Head */}
                <div className="flex items-center space-x-3 mb-4">
                  <Avatar className="h-8 w-8">
                    <AvatarImage
                      src={head?.avatar || "/default-avatar.png"}
                      alt={head?.name || "Department Head"}
                    />
                    <AvatarFallback>
                      {head?.name
                        ? head.name.split(" ").map((n) => n[0]).join("")
                        : "DH"}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <p className="text-sm font-medium">
                      {head?.name || "No Head Assigned"}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {head?.position_name || head?.position || "Department Head"}
                      {!head && ` (UUID: ${dept.employee_id?.substring(0, 8)}...)`}
                    </p>
                  </div>
                </div>

                {/* Metrics */}
                <div className="space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-xs text-muted-foreground">Employees</p>
                      <p className="text-lg font-bold">{dept.employees}</p>
                    </div>
                    <div>
                      <p className="text-xs text-muted-foreground">Growth</p>
                      <p className="text-lg font-bold text-success">
                        +{dept.growth}%
                      </p>
                    </div>
                  </div>

                  <div>
                    <div className="flex justify-between items-center mb-2">
                      <p className="text-xs text-muted-foreground">
                        Performance Score
                      </p>
                      <p className="text-xs font-medium">
                        {dept.performance}%
                      </p>
                    </div>
                    <Progress value={dept.performance} className="h-2" />
                  </div>

                  <div>
                    <p className="text-xs text-muted-foreground">
                      Annual Budget
                    </p>
                    <p className="text-sm font-medium">
                      ${(dept.budget / 1000000).toFixed(1)}M
                    </p>
                  </div>
                </div>

                {/* Actions */}
                <div className="flex space-x-2 mt-4 pt-4 border-t">
                  <Button
                    variant="outline"
                    size="sm"
                    className="flex-1"
                    onClick={() => handleView(dept)}
                  >
                    View Details
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    className="flex-1"
                    onClick={() => handleEdit(dept)}
                  >
                    Edit
                  </Button>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>
    </div>
  );
}