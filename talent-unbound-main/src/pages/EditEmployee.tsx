"use client";

import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import Swal from "sweetalert2";
import api_laravel from "@/lib/utils";

// Interfaces
interface Department { id: number; name: string; }
interface Shift { id: number; deskripsi: string; clock_in: string; clock_out: string; }
interface EmployeeMini { 
  id: number; 
  name: string; 
  uuid: string;
  position_name?: string;
  department_name?: string;
}
interface Position { id: number; nama_jabatan: string; employees: EmployeeMini[]; }
interface PTKP {
  code: string;
  description: string;
  ptkp_annual: string;
}

interface Religion {
  id: number;
  name: string;
}

export default function EditEmployeePage() {
  const { uuid } = useParams();
  const navigate = useNavigate();
  const [employee, setEmployee] = useState<any>({});
  const [departments, setDepartments] = useState<Department[]>([]);
  const [shifts, setShifts] = useState<Shift[]>([]);
  const [positions, setPositions] = useState<Position[]>([]);
  const [ptkpOptions, setPtkpOptions] = useState<PTKP[]>([]);
  const [religions, setReligions] = useState<Religion[]>([]);
  const [loading, setLoading] = useState(false);
  const [formValid, setFormValid] = useState(false);
  const [employeesList, setEmployeesList] = useState<EmployeeMini[]>([]);

  // Validasi form
  useEffect(() => {
    const requiredFields = ['name', 'email', 'phone', 'position', 'department'];
    const isValid = requiredFields.every(field => 
      employee[field] && employee[field].toString().trim() !== ''
    );
    setFormValid(isValid);
  }, [employee]);

  // Ambil data employee
  useEffect(() => {
    if (!uuid) {
      Swal.fire("Error", "Employee UUID tidak ditemukan", "error");
      navigate('/employees');
      return;
    }

    const fetchEmployee = async () => {
      try {
        setLoading(true);
        const res = await api_laravel.get(`/api/employees/${uuid}`);
        const data = res.data.data;
        
        if (!data) {
          throw new Error("Data employee tidak ditemukan");
        }

        setEmployee({
          ...data,
          department: data.department?.toString() || "",
          immediate_supervisor: data.immediate_supervisor || "",
          position_id: data.position?.toString() || "",
          religion_id: data.religion_id?.toString() || "",
          shift_id: data.shift_id?.toString() || "",
          ptkp_code: data.ptkp_code || ""
        });
      } catch (err: any) {
        console.error("Error fetching employee:", err);
        Swal.fire("Error", err.response?.data?.message || "Gagal memuat data employee", "error");
        navigate('/employees');
      } finally {
        setLoading(false);
      }
    };

    fetchEmployee();
  }, [uuid, navigate]);

  // Ambil master data
 useEffect(() => {
  const fetchMasterData = async () => {
    try {
      setLoading(true);

      const [
        departmentsRes,
        shiftsRes,
        positionsRes,
        ptkpRes,
        religionsRes,
        employeesRes
      ] = await Promise.all([
        api_laravel.get("/api/departments"),
        api_laravel.get("/api/employees/master/shifts"),
        api_laravel.get("/api/employees/master/position"),
        api_laravel.get("/api/master-ptkp"),
        api_laravel.get("/api/religions"),
        api_laravel.get("/api/employees/list"),
      ]);

      // ✅ tangani semua format data aman
      const extractData = (res: any) => {
        if (Array.isArray(res?.data)) return res.data;
        if (Array.isArray(res?.data?.data)) return res.data.data;
        if (Array.isArray(res?.data?.data?.data)) return res.data.data.data;
        return [];
      };

      setDepartments(extractData(departmentsRes));
      setShifts(extractData(shiftsRes));
      setPositions(extractData(positionsRes));
      setPtkpOptions(extractData(ptkpRes));
      setReligions(extractData(religionsRes));

      // 🔥 ambil employee list
      const employeesRaw = extractData(employeesRes);

      console.log("💡 API Employees Raw:", employeesRaw);

      const validEmployees = employeesRaw
        .filter((emp: any) => emp && emp.uuid && emp.name)
        .map((emp: any) => ({
          id: emp.id,
          uuid: emp.uuid,
          name: emp.name,
          position_name: emp.position_name || "",
          department_name: emp.department_name || "",
        }));

      console.log("✅ Employees Parsed:", validEmployees);
      setEmployeesList(validEmployees);
    } catch (error) {
      console.error("Error fetching master data:", error);
      Swal.fire("Error", "Gagal memuat data master", "error");
    } finally {
      setLoading(false);
    }
  };

  fetchMasterData();
}, []);


  const handleSubmit = async () => {
    if (!formValid) {
      Swal.fire("Error", "Harap lengkapi semua field yang wajib diisi", "error");
      return;
    }

    if (!uuid) {
      Swal.fire("Error", "Employee UUID tidak valid", "error");
      return;
    }

    try {
      setLoading(true);
      
      const payload = {
        name: employee.name,
        nik: employee.nik,
        email: employee.email,
        phone: employee.phone,
        religion_id: employee.religion_id ? parseInt(employee.religion_id) : null,
        immediate_supervisor: employee.immediate_supervisor || null,
        position: employee.position_id ? parseInt(employee.position_id) : null,
        department: employee.department ? employee.department.toString() : null,
        shift_id: employee.shift_id ? parseInt(employee.shift_id) : null,
        basic_salary: employee.basic_salary ? parseFloat(employee.basic_salary) : 0,
        allowance: employee.allowance ? parseFloat(employee.allowance) : 0,
        meal_allowance: employee.meal_allowance ? parseFloat(employee.meal_allowance) : 0,
        ptkp_code: employee.ptkp_code || null,
        tax_number: employee.tax_number || null
      };

      console.log("Submitting payload:", payload);

      await api_laravel.put(`/api/employees/${uuid}`, payload);
      
      Swal.fire({
        title: "Success!",
        text: "Employee berhasil diupdate",
        icon: "success",
        confirmButtonText: "OK"
      }).then(() => {
        navigate(`/employees/${uuid}`);
      });
      
    } catch (err: any) {
      console.error("Error updating employee:", err);
      const errorMessage = err.response?.data?.message || 
                          err.response?.data?.error || 
                          "Gagal update employee";
      Swal.fire("Error", errorMessage, "error");
    } finally {
      setLoading(false);
    }
  };

  // Cari nama supervisor yang sedang dipilih
  const getCurrentSupervisorName = () => {
    if (!employee.immediate_supervisor) return "Select supervisor";
    
    const found = employeesList.find(emp => emp.uuid === employee.immediate_supervisor);
    if (found) {
      return `${found.name}${found.position_name ? ` - ${found.position_name}` : ''}`;
    }
    
    // Fallback: jika tidak ditemukan di employeesList, tampilkan supervisor_name dari employee data
    return employee.supervisor_name || "Select supervisor";
  };

  // Validasi dan filter employees untuk supervisor - DIPERBAIKI
  const getValidSupervisors = () => {
    const validEmployees = employeesList
      .filter(emp => {
        // Filter data yang valid
        if (!emp || !emp.uuid || !emp.name) return false;
        
        // Tidak bisa pilih diri sendiri
        if (emp.uuid === uuid) return false;
        
        return true;
      })
      .map(emp => ({
        ...emp,
        // Pastikan key unik
        key: emp.uuid || `emp-${emp.id}`,
        value: emp.uuid || `emp-${emp.id}`,
        label: `${emp.name}${emp.position_name ? ` - ${emp.position_name}` : ''}${emp.department_name ? ` (${emp.department_name})` : ''}`
      }));

    console.log("Valid Supervisors:", validEmployees);
    return validEmployees;
  };

  // Fungsi untuk menangani perubahan supervisor - BARU
  const handleSupervisorChange = (value: string) => {
    console.log("Supervisor changed to:", value);
    // Jika value adalah "none", set ke null/empty string
    if (value === "none") {
      setEmployee({ ...employee, immediate_supervisor: "" });
    } else {
      setEmployee({ ...employee, immediate_supervisor: value });
    }
  };

  if (loading && Object.keys(employee).length === 0) {
    return (
      <div className="max-w-4xl mx-auto mt-10 p-6 bg-white shadow-md rounded-lg">
        <div className="text-center">Loading employee data...</div>
      </div>
    );
  }

  const validSupervisors = getValidSupervisors();

  return (
    <div className="max-w-4xl mx-auto mt-10 p-6 bg-white shadow-md rounded-lg">
      <h1 className="text-2xl font-bold mb-6">Edit Employee</h1>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        {/* Name */}
        <div>
          <label className="text-sm text-muted-foreground mb-1 block">Name *</label>
          <Input
            value={employee.name || ""}
            onChange={(e) => setEmployee({ ...employee, name: e.target.value })}
            placeholder="Enter employee name"
            disabled={loading}
          />
        </div>

        {/* NIK */}
        <div>
          <label className="text-sm text-muted-foreground mb-1 block">NIK</label>
          <Input
            value={employee.nik || ""}
            onChange={(e) => setEmployee({ ...employee, nik: e.target.value })}
            placeholder="Enter NIK"
            disabled={loading}
          />
        </div>

        {/* Email */}
        <div>
          <label className="text-sm text-muted-foreground mb-1 block">Email *</label>
          <Input
            value={employee.email || ""}
            onChange={(e) => setEmployee({ ...employee, email: e.target.value })}
            placeholder="Enter email"
            disabled={loading}
          />
        </div>

        {/* Phone */}
        <div>
          <label className="text-sm text-muted-foreground mb-1 block">Phone *</label>
          <Input
            value={employee.phone || ""}
            onChange={(e) => setEmployee({ ...employee, phone: e.target.value })}
            placeholder="Enter phone number"
            disabled={loading}
          />
        </div>

        {/* Religion */}
        <div>
          <label className="text-sm text-muted-foreground mb-1 block">Religion</label>
          <Select
            value={employee.religion_id?.toString() || ""}
            onValueChange={(val) => setEmployee({ ...employee, religion_id: val })}
            disabled={loading}
          >
            <SelectTrigger>
              <SelectValue placeholder="Select religion" />
            </SelectTrigger>
            <SelectContent>
              {religions.map(rel => (
                <SelectItem key={`rel-${rel.id}`} value={rel.id.toString()}>
                  {rel.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

     {/* Immediate Supervisor */}
<div>
  <label className="text-sm text-muted-foreground mb-1 block">Immediate Supervisor</label>
  <Select
    value={employee.immediate_supervisor || ""}
    onValueChange={(val) => {
      if (val === "none") {
        setEmployee({
          ...employee,
          immediate_supervisor: "",
          supervisor_name: "",
        });
      } else {
        const selected = employeesList.find((emp) => emp.uuid === val);
        setEmployee({
          ...employee,
          immediate_supervisor: val,
          supervisor_name: selected ? selected.name : "",
        });
      }
    }}
    disabled={loading}
  >
    <SelectTrigger>
      <SelectValue>
        {/* Tampilkan nama supervisor saat ini */}
        {employee.supervisor_name
          ? employee.supervisor_name
          : employee.immediate_supervisor
          ? employeesList.find((emp) => emp.uuid === employee.immediate_supervisor)?.name ||
            "Select supervisor"
          : "Select supervisor"}
      </SelectValue>
    </SelectTrigger>

    <SelectContent>
      {/* Opsi "No Supervisor" */}
      <SelectItem value="none">No Supervisor</SelectItem>

      {/* Supervisor lama (jika tidak ada di daftar employeesList) */}
      {employee.immediate_supervisor &&
        employee.supervisor_name &&
        !employeesList.some(
          (emp) => emp.uuid === employee.immediate_supervisor
        ) && (
          <SelectItem
            key={`current-${employee.immediate_supervisor}`}
            value={employee.immediate_supervisor}
          >
            {employee.supervisor_name} (Current)
          </SelectItem>
        )}

      {/* Daftar semua employee */}
      {employeesList
        .filter(
          (emp) =>
            emp.uuid !== uuid && // Tidak bisa pilih dirinya sendiri
            emp.name && emp.uuid
        )
        .map((emp) => (
          <SelectItem key={emp.uuid} value={emp.uuid}>
            {emp.name}
            {emp.position_name ? ` - ${emp.position_name}` : ""}
            {emp.department_name ? ` (${emp.department_name})` : ""}
          </SelectItem>
        ))}
    </SelectContent>
  </Select>
</div>


        {/* Position */}
        <div>
          <label className="text-sm text-muted-foreground mb-1 block">Position *</label>
          <Select
            value={employee.position_id?.toString() || ""}
            onValueChange={(val) => setEmployee({ ...employee, position_id: val })}
            disabled={loading}
          >
            <SelectTrigger>
              <SelectValue placeholder="Select position" />
            </SelectTrigger>
            <SelectContent>
              {positions.map((pos) => (
                <SelectItem key={`pos-${pos.id}`} value={pos.id.toString()}>
                  {pos.nama_jabatan}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        {/* Department */}
        <div>
          <label className="text-sm text-muted-foreground mb-1 block">Department *</label>
          <Select
            value={employee.department || ""}
            onValueChange={(val) => setEmployee({ ...employee, department: val })}
            disabled={loading}
          >
            <SelectTrigger>
              <SelectValue placeholder="Select department" />
            </SelectTrigger>
            <SelectContent>
              {departments.map(dep => (
                <SelectItem key={`dep-${dep.id}`} value={dep.id.toString()}>
                  {dep.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        {/* Shift */}
        <div>
          <label className="text-sm text-muted-foreground mb-1 block">Shift</label>
          <Select
            value={employee.shift_id?.toString() || ""}
            onValueChange={(val) => setEmployee({ ...employee, shift_id: val })}
            disabled={loading}
          >
            <SelectTrigger>
              <SelectValue placeholder="Select shift" />
            </SelectTrigger>
            <SelectContent>
              {shifts.map(shift => (
                <SelectItem key={`shift-${shift.id}`} value={shift.id.toString()}>
                  {shift.deskripsi} ({shift.clock_in} - {shift.clock_out})
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        {/* Basic Salary */}
        <div>
          <label className="text-sm text-muted-foreground mb-1 block">Basic Salary</label>
          <Input
            type="number"
            value={employee.basic_salary || ""}
            onChange={(e) => setEmployee({ ...employee, basic_salary: e.target.value })}
            placeholder="Enter basic salary"
            disabled={loading}
          />
        </div>

        {/* Allowance */}
        <div>
          <label className="text-sm text-muted-foreground mb-1 block">Allowance</label>
          <Input
            type="number"
            value={employee.allowance || ""}
            onChange={(e) => setEmployee({ ...employee, allowance: e.target.value })}
            placeholder="Enter allowance"
            disabled={loading}
          />
        </div>

        {/* Meal Allowance */}
        <div>
          <label className="text-sm text-muted-foreground mb-1 block">Meal Allowance</label>
          <Input
            type="number"
            value={employee.meal_allowance || ""}
            onChange={(e) => setEmployee({ ...employee, meal_allowance: e.target.value })}
            placeholder="Enter meal allowance"
            disabled={loading}
          />
        </div>

        {/* PTKP */}
        <div>
          <label className="text-sm text-muted-foreground mb-1 block">PTKP</label>
          <Select
            value={employee.ptkp_code || ""}
            onValueChange={(val) => setEmployee({ ...employee, ptkp_code: val })}
            disabled={loading}
          >
            <SelectTrigger>
              <SelectValue placeholder="Select PTKP" />
            </SelectTrigger>
            <SelectContent>
              {ptkpOptions.map(ptkp => (
                <SelectItem key={`ptkp-${ptkp.code}`} value={ptkp.code}>
                  {ptkp.description} ({parseFloat(ptkp.ptkp_annual || '0').toLocaleString()})
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex justify-end mt-6 space-x-4">
        <Button 
          variant="outline" 
          onClick={() => navigate(`/employees/${uuid}`)}
          disabled={loading}
        >
          Cancel
        </Button>
        <Button 
          onClick={handleSubmit}
          disabled={loading || !formValid}
        >
          {loading ? "Saving..." : "Save"}
        </Button>
      </div>

      {/* Debug info */}
      <div className="mt-4 p-3 bg-gray-100 rounded text-xs">
        <p>Form Valid: {formValid ? "Yes" : "No"}</p>
        <p>Loading: {loading ? "Yes" : "No"}</p>
        <p>Employee UUID: {uuid}</p>
        <p>Employees List Count: {employeesList.length}</p>
        <p>Valid Supervisors Count: {validSupervisors.length}</p>
        <p>Current Supervisor: {getCurrentSupervisorName()}</p>
        <p>Supervisor UUID: {employee.immediate_supervisor || "None"}</p>
      </div>
    </div>
  );
}