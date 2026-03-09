"use client";

import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import api_laravel from "@/lib/utils";
import { FiEdit, FiSlash } from "react-icons/fi";

export default function EmployeeDetail() {
  const { uuid } = useParams();
  const navigate = useNavigate();
  const [employee, setEmployee] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [userRole, setUserRole] = useState<string | null>(null);
  const [userRoles, setUserRoles] = useState<string[]>([]); // Untuk handle multiple roles

  // Definisikan roles yang boleh edit
  const allowedRoles = ["manager", "super-admin"];
  
  // Cek apakah user memiliki salah satu role yang diizinkan
  const canEditEmployee = userRoles.some(role => allowedRoles.includes(role)) || 
                         allowedRoles.includes(userRole || "");

  const formatDate = (dateString: string) => {
    if (!dateString) return "-";
    const date = new Date(dateString);
    return date.toLocaleDateString("id-ID", {
      year: "numeric",
      month: "short",
      day: "numeric",
    });
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "Active":
        return <Badge className="bg-green-100 text-green-800">{status}</Badge>;
      case "On Leave":
        return <Badge className="bg-yellow-100 text-yellow-800">{status}</Badge>;
      case "Inactive":
        return <Badge className="bg-red-100 text-red-800">{status}</Badge>;
      default:
        return <Badge variant="secondary">{status}</Badge>;
    }
  };

  useEffect(() => {
    const fetchEmployee = async () => {
      try {
        if (!uuid) return;

        // Ambil role user login
        try {
          const userRes = await api_laravel.get("/api/me");
          console.log("User API Response:", userRes.data);
          
          // Extract roles dari response
          const roles = userRes.data?.data?.user?.roles || [];
          console.log("User Roles:", roles);
          
          setUserRoles(roles);
          
          // Untuk kompatibilitas dengan kode lama, set juga primary role
          if (roles.length > 0) {
            setUserRole(roles[0]); // Ambil role pertama sebagai primary
          }
        } catch (userError) {
          console.error("Error fetching user data:", userError);
        }

        // Ambil data employee
        const res = await api_laravel.get(`/api/employees/${uuid}`);
        console.log("Employee API:", res.data.data);
        setEmployee(res.data.data);
      } catch (err) {
        console.error("Gagal ambil detail employee:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchEmployee();
  }, [uuid]);

  if (loading) return <p className="text-center mt-10">Loading...</p>;
  if (!employee) return <p className="text-center mt-10">Employee not found</p>;

  return (
    <div className="max-w-3xl mx-auto mt-10 p-6 bg-white shadow-md rounded-lg animate-fade-in">
      {/* Header */}
      <div className="flex items-center space-x-6 mb-6">
        <Avatar className="w-24 h-24">
          {employee?.avatar ? (
            <AvatarImage src={employee.avatar} alt={employee.name} />
          ) : (
            <AvatarImage src="/default-avatar.png" alt="Default Avatar" />
          )}
          <AvatarFallback>
            {employee.name
              .split(" ")
              .map((n: string) => n[0])
              .join("")}
          </AvatarFallback>
        </Avatar>
        <div>
          <h1 className="text-3xl font-bold">{employee.name}</h1>
          <p className="text-muted-foreground">{employee.position_name}</p>
          <div className="mt-2">{getStatusBadge(employee.status)}</div>
        </div>
      </div>

      {/* Detail Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-6">
        <div>
          <p className="text-sm text-muted-foreground">NIK</p>
          <p className="font-medium">{employee.nik}</p>
        </div>
        <div>
          <p className="text-sm text-muted-foreground">Email</p>
          <p className="font-medium">{employee.email}</p>
        </div>
        <div>
          <p className="text-sm text-muted-foreground">Phone</p>
          <p className="font-medium">{employee.phone || "-"}</p>
        </div>
        <div>
          <p className="text-sm text-muted-foreground">Department</p>
          <p className="font-medium">{employee.department_name || "-"}</p>
        </div>
        <div>
          <p className="text-sm text-muted-foreground">Join Date</p>
          <p className="font-medium">{formatDate(employee.join_date)}</p>
        </div>
        <div>
          <p className="text-sm text-muted-foreground">PTKP</p>
          <p className="font-medium">{employee.ptkp_code || "-"}</p>
        </div>
        <div>
          <p className="text-sm text-muted-foreground">Flag</p>
          <p className="font-medium">{employee.flag || "-"}</p>
        </div>
        {employee.flag === "Kontrak" && (
          <div>
            <p className="text-sm text-muted-foreground">End Date</p>
            <p className="font-medium">{formatDate(employee.enddate)}</p>
          </div>
        )}
        <div>
          <p className="text-sm text-muted-foreground">Tax Number (NPWP)</p>
          <p className="font-medium">{employee.tax_number || "-"}</p>
        </div>
        <div>
          <p className="text-sm text-muted-foreground">Employee ID</p>
          <p className="font-medium">{employee.nik_employee || "-"}</p>
        </div>

        {/* Immediate Supervisor */}
        <div>
          <p className="text-sm text-muted-foreground">Immediate Supervisor</p>
          <p className="font-medium">{employee.supervisor_name || "-"}</p>
        </div>

        {/* Work Hour */}
        <div>
          <p className="text-sm text-muted-foreground">Work Hour</p>
          <p className="font-medium">
            {employee.clock_in && employee.clock_out
              ? `${employee.clock_in} - ${employee.clock_out}`
              : "-"}
          </p>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex justify-end space-x-4">
        <Button variant="outline" onClick={() => navigate("/employees")}>
          Back to List
        </Button>

        {/* Tombol Edit hanya aktif jika user memiliki role manager atau super-admin */}
        <Button
          onClick={() => canEditEmployee && navigate(`/employees/edit/${uuid}`)}
          disabled={!canEditEmployee}
          className="relative flex items-center space-x-2 transition-colors duration-200 group
                     disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <FiEdit className="w-4 h-4" />
          <span>Edit Employee</span>

          {/* Icon silang muncul saat hover hanya jika tidak boleh edit */}
          {!canEditEmployee && (
            <span className="absolute left-full ml-2 text-red-600 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
              <FiSlash className="w-4 h-4" />
            </span>
          )}
        </Button>
      </div>

      {/* Debug info untuk testing */}
      <div className="mt-4 p-2 bg-gray-100 rounded text-xs">
        <p><strong>User Role Debug Info:</strong></p>
        <p>Primary User Role: {userRole || "Not found"}</p>
        <p>All User Roles: {userRoles.join(", ") || "None"}</p>
        <p>Can Edit: {canEditEmployee ? "Yes" : "No"}</p>
        <p>Allowed Roles: {allowedRoles.join(", ")}</p>
      </div>
    </div>
  );
}