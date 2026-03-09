import { DashboardOverview } from "@/components/Dashboard/DashboardOverview";

export default function Dashboard() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
          <p className="text-muted-foreground">
            Welcome back! Here's what's happening at your organization.
          </p>
        </div>
      </div>
      <DashboardOverview />
    </div>
  );
}