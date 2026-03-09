"use client";

import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import api_laravel from "@/lib/utils"; 
import { Plus, Pencil, Trash } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogFooter,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import Swal from "sweetalert2";

interface Employee {
  id: number;
  name: string;
  department: string | number | null;
  department_description?: string;
  position_name?: string; // Tambahkan ini
  position?: {
    id: number;
    nama_jabatan: string;
    level: string;
    deskripsi: string;
  };
  [key: string]: any;
}

interface DepartmentGoal {
  id: number;
  goal_name: string;
  department_id: number;
}

interface EmployeeGoal {
  id: number;
  employee_id: number;
  department_goal_id: number | null;
  goal_name: string;
  status: string;
  due_date: string;
  target_value: number;
  achieved_value: number;
  progress: number;
  employee: Employee;
  department_goal: DepartmentGoal | null;
}

export default function EmployeeGoalsPage() {
  const [goals, setGoals] = useState<EmployeeGoal[]>([]);
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [departmentGoals, setDepartmentGoals] = useState<DepartmentGoal[]>([]);
  const [open, setOpen] = useState(false);
  const [isEdit, setIsEdit] = useState(false);
  const [loading, setLoading] = useState(false);
  const [form, setForm] = useState({
    id: "",
    goal_name: "",
    status: "pending",
    due_date: "",
    target_value: "",
    achieved_value: "",
    progress: "",
    employee_id: "",
    department_id: "",
    department_description: "",
    department_goal_id: "",
  });

  // Fetch semua data sekaligus
  useEffect(() => {
    const fetchAllData = async () => {
      setLoading(true);
      try {
        await Promise.all([
          fetchEmployees(),
          fetchDepartmentGoals(),
          fetchGoals()
        ]);
      } catch (error) {
        console.error("Error fetching data:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchAllData();
  }, []);

  const fetchGoals = async () => {
    try {
      const res = await api_laravel.get("/api/kpi/employee-goals");
      console.log("Goals API Response:", res.data);
      
      const goalsData = res.data.data || [];
      setGoals(goalsData);
    } catch (error) {
      console.error("Error fetching goals:", error);
      Swal.fire("Error", "Failed to load goals", "error");
    }
  };

  const fetchEmployees = async () => {
    try {
      const res = await api_laravel.get("/api/employees/list");
      console.log("Employees API FULL Response:", res);
      
      let employeesData: Employee[] = [];
      
      // Handle nested structure: res.data.data.data
      if (Array.isArray(res.data?.data?.data)) {
        employeesData = res.data.data.data;
        console.log("Using res.data.data.data structure");
      } else if (Array.isArray(res.data?.data)) {
        employeesData = res.data.data;
        console.log("Using res.data.data structure");
      } else if (Array.isArray(res.data)) {
        employeesData = res.data;
        console.log("Using res.data structure");
      } else if (res.data && typeof res.data === 'object') {
        employeesData = [res.data];
        console.log("Using res.data object structure");
      }
      
      console.log("Final employees data:", employeesData);
      console.log("Number of employees:", employeesData.length);
      
      setEmployees(employeesData);
    } catch (error) {
      console.error("Error fetching employees:", error);
      Swal.fire("Error", "Failed to load employees", "error");
    }
  };

  const fetchDepartmentGoals = async () => {
    try {
      const res = await api_laravel.get("/api/kpi/department-goals");
      console.log("Department Goals API Response:", res.data);
      
      let departmentGoalsData: DepartmentGoal[] = [];
      
      if (Array.isArray(res.data)) {
        departmentGoalsData = res.data;
      } else if (Array.isArray(res.data?.data)) {
        departmentGoalsData = res.data.data;
      } else if (res.data && typeof res.data === 'object') {
        departmentGoalsData = [res.data];
      }
      
      console.log("Processed department goals data:", departmentGoalsData);
      setDepartmentGoals(departmentGoalsData);
    } catch (error) {
      console.error("Error fetching department goals:", error);
      Swal.fire("Error", "Failed to load department goals", "error");
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setForm(prev => ({ ...prev, [name]: value }));
  };

  const handleEmployeeChange = (empId: string) => {
    if (!Array.isArray(employees) || employees.length === 0) {
      console.error("Employees is not available or empty:", employees);
      return;
    }

    const selectedEmp = employees.find((e) => String(e.id) === empId);
    console.log("Selected Employee:", selectedEmp);

    if (selectedEmp) {
      setForm(prev => ({
        ...prev,
        employee_id: empId,
        department_id: selectedEmp.department ? String(selectedEmp.department) : "",
        department_description: selectedEmp.position_name || 
                               selectedEmp.position?.nama_jabatan || 
                               selectedEmp.department_description || 
                               "No Department",
        department_goal_id: "",
      }));
    }
  };

  const handleSubmit = async () => {
    if (!form.goal_name || !form.employee_id || !form.due_date) {
      Swal.fire("Error", "Please fill in all required fields", "error");
      return;
    }

    try {
      const payload = {
        goal_name: form.goal_name,
        status: form.status,
        due_date: form.due_date,
        target_value: Number(form.target_value) || 0,
        achieved_value: Number(form.achieved_value) || 0,
        progress: Number(form.progress) || 0,
        employee_id: Number(form.employee_id),
        department_goal_id: form.department_goal_id ? Number(form.department_goal_id) : null,
      };

      console.log("Submitting payload:", payload);

      if (isEdit) {
        await api_laravel.put(`/api/kpi/employee-goals/${form.id}`, payload);
        Swal.fire("Updated!", "Goal updated successfully", "success");
      } else {
        await api_laravel.post("/api/kpi/employee-goals", payload);
        Swal.fire("Added!", "Goal added successfully", "success");
      }
      
      setOpen(false);
      resetForm();
      fetchGoals();
    } catch (error: any) {
      console.error("Error saving goal:", error);
      const errorMessage = error.response?.data?.message || "Failed to save goal";
      Swal.fire("Error", errorMessage, "error");
    }
  };

  const handleEdit = (goal: EmployeeGoal) => {
    console.log("Editing goal:", goal);
    
    setForm({
      id: String(goal.id),
      goal_name: goal.goal_name || "",
      status: goal.status || "pending",
      due_date: goal.due_date || "",
      target_value: String(goal.target_value || ""),
      achieved_value: String(goal.achieved_value || ""),
      progress: String(goal.progress || ""),
      employee_id: String(goal.employee_id || ""),
      department_id: goal.employee?.department ? String(goal.employee.department) : "",
      department_description: goal.employee?.position_name || 
                             goal.employee?.position?.nama_jabatan || 
                             "No Department",
      department_goal_id: goal.department_goal_id ? String(goal.department_goal_id) : "",
    });
    setIsEdit(true);
    setOpen(true);
  };

  const handleDelete = async (id: number) => {
    Swal.fire({
      title: "Are you sure?",
      text: "This goal will be deleted!",
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "Yes, delete it!",
      cancelButtonText: "Cancel"
    }).then(async (result) => {
      if (result.isConfirmed) {
        try {
          await api_laravel.delete(`/api/kpi/employee-goals/${id}`);
          Swal.fire("Deleted!", "Goal has been deleted.", "success");
          fetchGoals();
        } catch (error: any) {
          console.error("Error deleting goal:", error);
          const errorMessage = error.response?.data?.message || "Failed to delete goal";
          Swal.fire("Error", errorMessage, "error");
        }
      }
    });
  };

  const resetForm = () => {
    setForm({
      id: "",
      goal_name: "",
      status: "pending",
      due_date: "",
      target_value: "",
      achieved_value: "",
      progress: "",
      employee_id: "",
      department_id: "",
      department_description: "",
      department_goal_id: "",
    });
    setIsEdit(false);
  };

  // Filter department goals sesuai department employee
  const filteredDepartmentGoals = Array.isArray(departmentGoals) && form.department_id
    ? departmentGoals.filter((dg) => String(dg.department_id) === form.department_id)
    : [];

  // Get department/position name untuk display
  const getEmployeeDepartment = (goal: EmployeeGoal) => {
    return goal.employee?.position_name || 
           goal.employee?.position?.nama_jabatan || 
           goal.employee?.department_description || 
           "-";
  };

  if (loading) {
    return (
      <Card>
        <CardContent className="flex justify-center items-center h-32">
          <div>Loading employee goals...</div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader className="flex flex-row justify-between items-center">
        <CardTitle>Employee Goals</CardTitle>
        <Dialog open={open} onOpenChange={(isOpen) => {
          setOpen(isOpen);
          if (!isOpen) resetForm();
        }}>
          <DialogTrigger asChild>
            <Button size="sm" onClick={() => setOpen(true)}>
              <Plus className="w-4 h-4 mr-1" /> Add Goal
            </Button>
          </DialogTrigger>
          <DialogContent className="bg-white p-6 rounded-md shadow-lg max-h-[90vh] flex flex-col max-w-2xl">
            <DialogHeader>
              <DialogTitle>{isEdit ? "Edit Goal" : "Add Goal"}</DialogTitle>
            </DialogHeader>

            <div className="space-y-4 overflow-y-auto pr-2 flex-1">
              {/* Employee */}
              <div>
                <Label>Employee *</Label>
                <Select value={form.employee_id} onValueChange={handleEmployeeChange}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select Employee" />
                  </SelectTrigger>
                  <SelectContent>
                    {Array.isArray(employees) && employees.length > 0 ? (
                      employees.map((emp) => (
                        <SelectItem key={emp.id} value={String(emp.id)}>
                          {emp.name} {emp.position_name ? `(${emp.position_name})` : 
                                    emp.position?.nama_jabatan ? `(${emp.position.nama_jabatan})` : ''}
                        </SelectItem>
                      ))
                    ) : (
                      <SelectItem value="" disabled>
                        No employees available
                      </SelectItem>
                    )}
                  </SelectContent>
                </Select>
                <p className="text-xs text-muted-foreground mt-1">
                  {Array.isArray(employees) ? `${employees.length} employees available` : 'Loading employees...'}
                </p>
              </div>

              {/* Department/Position (readonly, auto dari employee) */}
              <div>
                <Label>Department/Position</Label>
                <Input value={form.department_description || "Select employee first"} readOnly />
              </div>

              {/* Department Goal filter by dept */}
              <div>
                <Label>Department Goal (Optional)</Label>
                <Select
                  value={form.department_goal_id}
                  onValueChange={(val) => setForm(prev => ({ ...prev, department_goal_id: val }))}
                  disabled={!form.department_id || filteredDepartmentGoals.length === 0}
                >
                  <SelectTrigger>
                    <SelectValue placeholder={
                      !form.department_id ? "Select employee first" : 
                      filteredDepartmentGoals.length === 0 ? "No department goals available" : 
                      "Select Department Goal"
                    } />
                  </SelectTrigger>
                  <SelectContent>
                    {filteredDepartmentGoals.map((dg) => (
                      <SelectItem key={dg.id} value={String(dg.id)}>
                        {dg.goal_name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {form.department_id && filteredDepartmentGoals.length === 0 && (
                  <p className="text-sm text-muted-foreground mt-1">
                    No department goals available for this department
                  </p>
                )}
              </div>

              <div>
                <Label>Goal Name *</Label>
                <Input 
                  name="goal_name" 
                  value={form.goal_name} 
                  onChange={handleChange} 
                  placeholder="Enter goal name"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Status</Label>
                  <Select
                    value={form.status}
                    onValueChange={(val) => setForm(prev => ({ ...prev, status: val }))}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="pending">Pending</SelectItem>
                      <SelectItem value="in_progress">In Progress</SelectItem>
                      <SelectItem value="completed">Completed</SelectItem>
                      <SelectItem value="cancelled">Cancelled</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label>Due Date *</Label>
                  <Input
                    type="date"
                    name="due_date"
                    value={form.due_date}
                    onChange={handleChange}
                  />
                </div>
              </div>

              <div className="grid grid-cols-3 gap-4">
                <div>
                  <Label>Target Value</Label>
                  <Input
                    type="number"
                    name="target_value"
                    value={form.target_value}
                    onChange={handleChange}
                    placeholder="0"
                    min="0"
                  />
                </div>
                <div>
                  <Label>Achieved Value</Label>
                  <Input
                    type="number"
                    name="achieved_value"
                    value={form.achieved_value}
                    onChange={handleChange}
                    placeholder="0"
                    min="0"
                  />
                </div>
                <div>
                  <Label>Progress (%)</Label>
                  <Input
                    type="number"
                    name="progress"
                    value={form.progress}
                    onChange={handleChange}
                    placeholder="0"
                    min="0"
                    max="100"
                  />
                </div>
              </div>
            </div>

            <DialogFooter className="mt-6">
              <Button 
                variant="outline" 
                onClick={() => setOpen(false)}
              >
                Cancel
              </Button>
              <Button onClick={handleSubmit}>
                {isEdit ? "Update" : "Save"} Goal
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </CardHeader>

      {/* Table */}
      <CardContent>
        {!Array.isArray(goals) || goals.length === 0 ? (
          <div className="text-center py-8 text-muted-foreground">
            No goals found. Click "Add Goal" to create one.
          </div>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Employee</TableHead>
                  <TableHead>Department/Position</TableHead>
                  <TableHead>Goal</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Due Date</TableHead>
                  <TableHead>Target</TableHead>
                  <TableHead>Achieved</TableHead>
                  <TableHead>Progress</TableHead>
                  <TableHead>Department Goal</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {goals.map((goal) => (
                  <TableRow key={goal.id}>
                    <TableCell className="font-medium">
                      {goal.employee?.name || "-"}
                    </TableCell>
                    <TableCell>{getEmployeeDepartment(goal)}</TableCell>
                    <TableCell className="max-w-xs truncate" title={goal.goal_name}>
                      {goal.goal_name}
                    </TableCell>
                    <TableCell>
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                        goal.status === 'completed' ? 'bg-green-100 text-green-800' :
                        goal.status === 'in_progress' ? 'bg-blue-100 text-blue-800' :
                        goal.status === 'cancelled' ? 'bg-red-100 text-red-800' :
                        'bg-yellow-100 text-yellow-800'
                      }`}>
                        {goal.status}
                      </span>
                    </TableCell>
                    <TableCell>
                      {goal.due_date ? new Date(goal.due_date).toLocaleDateString() : "-"}
                    </TableCell>
                    <TableCell>{goal.target_value}</TableCell>
                    <TableCell>{goal.achieved_value}</TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <div className="w-16 bg-gray-200 rounded-full h-2">
                          <div 
                            className="bg-blue-600 h-2 rounded-full" 
                            style={{ width: `${Math.min(goal.progress, 100)}%` }}
                          ></div>
                        </div>
                        <span>{Math.min(goal.progress, 100)}%</span>
                      </div>
                    </TableCell>
                    <TableCell>
                      {goal.department_goal?.goal_name || "-"}
                    </TableCell>
                    <TableCell>
                      <div className="flex gap-2">
                        <Button 
                          size="sm" 
                          variant="outline" 
                          onClick={() => handleEdit(goal)}
                        >
                          <Pencil className="w-4 h-4" />
                        </Button>
                        <Button 
                          size="sm" 
                          variant="destructive" 
                          onClick={() => handleDelete(goal.id)}
                        >
                          <Trash className="w-4 h-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>
    </Card>
  );
}