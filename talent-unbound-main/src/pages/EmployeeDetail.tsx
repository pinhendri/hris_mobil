"use client";

import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import api_laravel from "@/lib/utils";
import { FiEdit, FiSlash } from "react-icons/fi";

type DetailItem = {
  label: string;
  value: unknown;
  type?: "date" | "currency" | "boolean" | "list" | "workHour" | "link";
};

export default function EmployeeDetail() {
  const { uuid } = useParams();
  const navigate = useNavigate();
  const [employee, setEmployee] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [userRole, setUserRole] = useState<string | null>(null);
  const [userRoles, setUserRoles] = useState<string[]>([]);

  const allowedRoles = ["manager", "super-admin"];
  const canEditEmployee =
    userRoles.some((role) => allowedRoles.includes(role)) ||
    allowedRoles.includes(userRole || "");

  const pick = (...values: unknown[]) =>
    values.find((value) => value !== undefined && value !== null && value !== "");

  const formatDate = (dateString: unknown) => {
    if (!dateString) return "-";
    const date = new Date(String(dateString));
    if (Number.isNaN(date.getTime())) return String(dateString);
    return date.toLocaleDateString("id-ID", {
      year: "numeric",
      month: "short",
      day: "numeric",
    });
  };

  const formatCurrency = (value: unknown) => {
    const amount = Number(value || 0);
    if (!amount) return "-";
    return new Intl.NumberFormat("id-ID", {
      style: "currency",
      currency: "IDR",
      maximumFractionDigits: 0,
    }).format(amount);
  };

  const formatBoolean = (value: unknown) => {
    if (value === true || value === 1 || value === "1" || value === "true") return "Yes";
    if (value === false || value === 0 || value === "0" || value === "false") return "No";
    return "-";
  };

  const formatList = (value: unknown) => {
    if (Array.isArray(value)) return value.filter(Boolean).join(", ") || "-";
    return value ? String(value) : "-";
  };

  const formatValue = (item: DetailItem) => {
    if (item.type === "date") return formatDate(item.value);
    if (item.type === "currency") return formatCurrency(item.value);
    if (item.type === "boolean") return formatBoolean(item.value);
    if (item.type === "list") return formatList(item.value);
    if (item.type === "workHour") {
      return employee.clock_in && employee.clock_out
        ? `${employee.clock_in} - ${employee.clock_out}`
        : "-";
    }
    return item.value ? String(item.value) : "-";
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "Active":
        return <Badge className="bg-green-100 text-green-800">{status}</Badge>;
      case "On Leave":
        return <Badge className="bg-yellow-100 text-yellow-800">{status}</Badge>;
      case "Inactive":
      case "deactive":
        return <Badge className="bg-red-100 text-red-800">{status}</Badge>;
      default:
        return <Badge variant="secondary">{status || "-"}</Badge>;
    }
  };

  const detailSection = (title: string, items: DetailItem[]) => (
    <section className="space-y-4 rounded-lg border border-gray-200 bg-white p-5">
      <h2 className="text-lg font-semibold text-gray-900">{title}</h2>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        {items.map((item) => (
          <div key={item.label} className="min-w-0">
            <p className="text-sm text-muted-foreground">{item.label}</p>
            {item.type === "link" && item.value ? (
              <a
                className="font-medium text-blue-600 hover:underline break-words"
                href={String(item.value).startsWith("http") ? String(item.value) : `${api_laravel.defaults.baseURL}/${item.value}`}
                target="_blank"
                rel="noreferrer"
              >
                View file
              </a>
            ) : (
              <p className="font-medium break-words">{formatValue(item)}</p>
            )}
          </div>
        ))}
      </div>
    </section>
  );

  useEffect(() => {
    const fetchEmployee = async () => {
      try {
        if (!uuid) return;

        try {
          const userRes = await api_laravel.get("/api/me");
          const roles = userRes.data?.data?.user?.roles || [];
          const roleNames = roles.map((role: any) =>
            typeof role === "string" ? role : role?.name
          ).filter(Boolean);

          setUserRoles(roleNames);
          if (roleNames.length > 0) setUserRole(roleNames[0]);
        } catch (userError) {
          console.error("Error fetching user data:", userError);
        }

        const res = await api_laravel.get(`/api/employees/${uuid}`);
        setEmployee(res.data?.data?.data || res.data?.data || res.data);
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

  const positionName = String(pick(
    employee.position_name,
    employee.position?.nama_jabatan,
    employee.position?.name,
    employee.position
  ) || "");
  const departmentName = String(pick(
    employee.department_description,
    employee.department_name,
    employee.department?.description,
    employee.department?.name,
    employee.department
  ) || "");
  const shiftName = String(pick(
    employee.shift_name,
    employee.shift_description,
    employee.shift?.name,
    employee.shift?.description
  ) || "");
  const supervisorName = String(
    pick(employee.supervisor_name, employee.supervisor?.name) || ""
  );
  const avatarUrl = pick(employee.avatar, employee.profile_picture, "/default-avatar.png") as string;
  const cvUrl = pick(employee.cv, employee.cv_url, employee.resume);

  return (
    <div className="mx-auto max-w-6xl space-y-6 p-6 animate-fade-in">
      <div className="flex flex-col gap-4 rounded-lg border border-gray-200 bg-white p-6 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-5">
          <Avatar className="h-20 w-20">
            <AvatarImage src={avatarUrl} alt={employee.name || "Employee"} />
            <AvatarFallback>
              {(employee.name || "?")
                .split(" ")
                .map((n: string) => n[0])
                .join("")
                .slice(0, 2)
                .toUpperCase()}
            </AvatarFallback>
          </Avatar>
          <div>
            <h1 className="text-3xl font-bold">{employee.name || "-"}</h1>
            <p className="text-muted-foreground">{positionName || "-"}</p>
            <div className="mt-2">{getStatusBadge(employee.status)}</div>
          </div>
        </div>

        <div className="flex gap-3">
          <Button variant="outline" onClick={() => navigate("/employees")}>
            Back to List
          </Button>
          <Button
            onClick={() => canEditEmployee && navigate(`/employees/edit/${uuid}`)}
            disabled={!canEditEmployee}
            className="relative flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed group"
          >
            <FiEdit className="h-4 w-4" />
            <span>Edit Employee</span>
            {!canEditEmployee && (
              <span className="absolute left-full ml-2 text-red-600 opacity-0 group-hover:opacity-100 transition-opacity">
                <FiSlash className="h-4 w-4" />
              </span>
            )}
          </Button>
        </div>
      </div>

      {detailSection("Basic Information", [
        { label: "Employee ID/NIK", value: pick(employee.nik_employee, employee.employee_id, employee.nik) },
        { label: "Auto Employee Code", value: employee.nik_employee },
        { label: "Email", value: employee.email },
        { label: "Phone", value: employee.phone },
        { label: "Gender", value: employee.gender },
        { label: "Date of Birth", value: employee.date_of_birth, type: "date" },
        { label: "Nationality", value: employee.nationality },
        { label: "Marital Status", value: employee.marital_status },
        { label: "Religion", value: pick(employee.religion_name, employee.religion?.name) },
        { label: "Address", value: employee.address },
      ])}

      {detailSection("Work Information", [
        { label: "Position", value: positionName },
        { label: "Department", value: departmentName },
        { label: "Join Date", value: employee.join_date, type: "date" },
        { label: "Employment Type", value: employee.employment_type },
        { label: "Flag", value: employee.flag },
        { label: "Contract Type", value: employee.contract_type },
        { label: "Contract End Date", value: pick(employee.enddate, employee.end_date, employee.contract_end_date), type: "date" },
        { label: "Supervisor", value: supervisorName },
        { label: "Shift", value: shiftName },
        { label: "Office Location", value: employee.office_location },
        { label: "Work Schedule", value: employee.work_schedule },
        { label: "Work Hour", value: null, type: "workHour" },
      ])}

      {detailSection("Payroll & Compliance", [
        { label: "Salary", value: pick(employee.salary, employee.basic_salary), type: "currency" },
        { label: "PTKP", value: employee.ptkp_code },
        { label: "Tax Number/NPWP", value: employee.tax_number },
        { label: "Bank Name", value: employee.bank_name },
        { label: "Bank Account Number", value: employee.bank_account_number },
        { label: "Account Type", value: employee.account_type },
        { label: "SSN/Identity Number", value: employee.ssn },
        { label: "Work Authorization", value: employee.work_authorization },
      ])}

      {detailSection("Emergency & Health", [
        { label: "Emergency Contact Name", value: employee.emergency_contact_name },
        { label: "Emergency Relationship", value: employee.emergency_contact_relationship },
        { label: "Emergency Phone", value: employee.emergency_contact_phone },
        { label: "Blood Type", value: employee.blood_type },
        { label: "Medical Conditions", value: employee.medical_conditions },
        { label: "Emergency Medical Info", value: employee.emergency_medical_info },
      ])}

      {detailSection("Education & Access", [
        { label: "Highest Education", value: employee.highest_education },
        { label: "Degree/Major", value: employee.degree },
        { label: "Institution", value: employee.institution },
        { label: "Graduation Date", value: employee.graduation_year, type: "date" },
        { label: "Years of Experience", value: employee.years_of_experience },
        { label: "Previous Employers", value: employee.previous_employers },
        { label: "Skills", value: employee.skills, type: "list" },
        { label: "Certifications", value: employee.certifications },
        { label: "Assigned Equipment", value: employee.assigned_equipment, type: "list" },
        { label: "System Access", value: employee.system_access, type: "list" },
        { label: "Training Plan", value: employee.training_plan },
      ])}

      {detailSection("Attachments & Acknowledgement", [
        { label: "CV", value: cvUrl, type: "link" },
        { label: "Company Policies Acknowledged", value: employee.company_policies_acknowledged, type: "boolean" },
        { label: "Handbook Acknowledged", value: employee.handbook_acknowledged, type: "boolean" },
      ])}
    </div>
  );
}
