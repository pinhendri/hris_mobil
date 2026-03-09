import { LeaveManagement } from "@/components/Leave/LeaveManagement";

export default function Leave() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Leave Management</h1>
          <p className="text-muted-foreground">
            Track and manage employee leave requests and balances.
          </p>
        </div>
      </div>
      <LeaveManagement />
    </div>
  );
}