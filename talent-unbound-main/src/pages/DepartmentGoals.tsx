"use client";

import { useEffect, useState } from "react";
import api_laravel from "@/lib/utils"; // axios instance
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { Table, TableHeader, TableRow, TableHead, TableBody, TableCell } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
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

interface Department {
  id: number;
  name: string;
}

interface DepartmentGoal {
  id: number;
  department_id: number;
  goal_name: string;
  target_value: number;
  period: string;
  year: number;
  month?: number;
  created_at: string;
}

export default function DepartmentGoals() {
  const [goals, setGoals] = useState<DepartmentGoal[]>([]);
  const [departments, setDepartments] = useState<Department[]>([]);
  const [open, setOpen] = useState(false);
  const [isEdit, setIsEdit] = useState(false);
  const [form, setForm] = useState({
    id: "",
    department_id: "",
    goal_name: "",
    target_value: "",
    period: "",
    year: "",
    month: "",
  });

  useEffect(() => {
    fetchGoals();
    fetchDepartments();
  }, []);

  const fetchGoals = async () => {
    const res = await api_laravel.get("/api/kpi/department-goals");
    setGoals(res.data.data || []);
  };

  const fetchDepartments = async () => {
    api_laravel.get("/api/departments")
      .then((res) => setDepartments(res.data))
      .catch(() => Swal.fire("Error", "Gagal ambil departments", "error"));
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleSubmit = async () => {
  try {
    if (isEdit) {
      await api_laravel.put(`/api/kpi/department-goals/${form.id}`, {
        department_id: form.department_id,
        goal_name: form.goal_name,
        target_value: form.target_value,
        period: form.period,
        year: form.year,
        month: form.month || null,
      });
      Swal.fire("Success", "Goal updated successfully", "success");
    } else {
      await api_laravel.post("/api/kpi/department-goals", {
        department_id: form.department_id,
        goal_name: form.goal_name,
        target_value: form.target_value,
        period: form.period,
        year: form.year,
        month: form.month || null,
      });
      Swal.fire("Success", "Goal created successfully", "success");
    }
    setOpen(false);
    resetForm();
    fetchGoals();
  } catch (error) {
    console.error(error);
    Swal.fire("Error", "Something went wrong", "error");
  }
};

  const handleEdit = (goal: DepartmentGoal) => {
    setForm({
      id: String(goal.id),
      department_id: String(goal.department_id),
      goal_name: goal.goal_name,
      target_value: String(goal.target_value),
      period: goal.period,
      year: String(goal.year),
      month: goal.month ? String(goal.month).padStart(2, "0") : "",
    });
    setIsEdit(true);
    setOpen(true);
  };

  const handleDelete = async (id: number) => {
  Swal.fire({
    title: "Are you sure?",
    text: "This goal will be permanently deleted!",
    icon: "warning",
    showCancelButton: true,
    confirmButtonColor: "#3085d6",
    cancelButtonColor: "#d33",
    confirmButtonText: "Yes, delete it!",
  }).then(async (result) => {
    if (result.isConfirmed) {
      try {
        await api_laravel.delete(`/api/kpi/department-goals/${id}`);
        Swal.fire("Deleted!", "Goal has been deleted.", "success");
        fetchGoals();
      } catch (error) {
        console.error(error);
        Swal.fire("Error", "Failed to delete goal", "error");
      }
    }
  });
};

  const resetForm = () => {
    setForm({
      id: "",
      department_id: "",
      goal_name: "",
      target_value: "",
      period: "",
      year: "",
      month: "",
    });
    setIsEdit(false);
  };

  return (
    <Card>
      <CardHeader className="flex justify-between items-center">
        <CardTitle>Department/Project Goals</CardTitle>
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <Button
              size="sm"
              onClick={() => {
                resetForm();
                setIsEdit(false);
              }}
            >
              <Plus className="w-4 h-4 mr-2" /> Add Goal
            </Button>
          </DialogTrigger>
          <DialogContent className="bg-white p-6 rounded-md shadow-lg">
            <DialogHeader>
              <DialogTitle>{isEdit ? "Edit Department Goal" : "Add Department Goal"}</DialogTitle>
            </DialogHeader>
            <div className="space-y-3">
              <div>
                <Label>Department</Label>
                <Select
                  value={form.department_id}
                  onValueChange={(val) => setForm({ ...form, department_id: val })}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select Department" />
                  </SelectTrigger>
                  <SelectContent>
                    {departments.map((dept) => (
                      <SelectItem key={dept.id} value={String(dept.id)}>
                        {dept.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label>Goal Name</Label>
                <Input name="goal_name" value={form.goal_name} onChange={handleChange} />
              </div>
              <div>
                <Label>Target Value</Label>
                <Input
                  name="target_value"
                  type="number"
                  value={form.target_value}
                  onChange={handleChange}
                />
              </div>
              <div>
                <Label>Period</Label>
                <Select
                    value={form.period}
                    onValueChange={(val) => setForm({ ...form, period: val })}
                >
                    <SelectTrigger>
                    <SelectValue placeholder="Select Period" />
                    </SelectTrigger>
                    <SelectContent>
                    <SelectItem value="monthly">Monthly</SelectItem>
                    <SelectItem value="quarterly">Quarterly</SelectItem>
                    <SelectItem value="yearly">Yearly</SelectItem>
                    </SelectContent>
                </Select>
                </div>
              <div>
                <Label>Year & Month</Label>
                <Input
                  type="month"
                  value={form.year && form.month ? `${form.year}-${form.month}` : ""}
                  onChange={(e) => {
                    const [y, m] = e.target.value.split("-");
                    setForm({ ...form, year: y, month: m });
                  }}
                />
              </div>
            </div>
            <DialogFooter className="flex justify-end gap-2">
                <Button variant="outline" onClick={() => setOpen(false)}>
                    Cancel
                </Button>
                <Button onClick={handleSubmit}>
                    {isEdit ? "Update" : "Save"}
                </Button>
                </DialogFooter>
          </DialogContent>
        </Dialog>
      </CardHeader>

      <CardContent>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>No</TableHead>
              <TableHead>Department</TableHead>
              <TableHead>Goal Name</TableHead>
              <TableHead>Target Value</TableHead>
              <TableHead>Period</TableHead>
              <TableHead>Year</TableHead>
              <TableHead>Month</TableHead>
              <TableHead>Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {goals.map((goal, i) => {
              const deptName =
                departments.find((d) => d.id === goal.department_id)?.name || goal.department_id;
              return (
                <TableRow key={goal.id}>
                  <TableCell>{i + 1}</TableCell>
                  <TableCell>{deptName}</TableCell>
                  <TableCell>{goal.goal_name}</TableCell>
                  <TableCell>{goal.target_value.toLocaleString("id-ID")}</TableCell>
                  <TableCell>{goal.period}</TableCell>
                  <TableCell>{goal.year}</TableCell>
                  <TableCell>{goal.month ?? "-"}</TableCell>
                  <TableCell className="flex gap-2">
                    <Button size="sm" variant="outline" onClick={() => handleEdit(goal)}>
                      <Pencil className="w-4 h-4" />
                    </Button>
                   <Button 
                    size="sm" 
                    variant="destructive" 
                    onClick={() => handleDelete(goal.id)}
                    >
                    <Trash className="w-4 h-4" />
                    </Button>
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  );
}
