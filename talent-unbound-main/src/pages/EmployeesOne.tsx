import { EmployeeList } from "@/components/Employees/EmployeeList";

export default function Employees() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Employees</h1>
          <p className="text-muted-foreground">
            Manage your team members and their information.
          </p>
        </div>
      </div>
      <EmployeeList />
    </div>
  );
}