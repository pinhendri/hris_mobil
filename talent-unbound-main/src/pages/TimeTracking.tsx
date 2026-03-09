"use client";

import { useState, useEffect } from "react";
import { Clock, Play, Calendar, BarChart3 } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import api_laravel from "@/lib/utils";

export default function TimeTracking() {
  const [selectedTab, setSelectedTab] = useState("employees");
  const [departmentGoals, setDepartmentGoals] = useState([]);
  const [employeeGoals, setEmployeeGoals] = useState([]);

  useEffect(() => {
    const fetchAllData = async () => {
      try {
        // 🔹 1. Fetch Department Goals
        const resDept = await api_laravel.get("/api/kpi/time-tracking");
        const deptData = resDept.data?.data ?? [];

        const mappedDept = deptData.map((g) => {
          let deadline = "-";
          if (g.year && g.month) {
            const lastDay = new Date(g.year, g.month, 0);
            deadline = lastDay.toISOString().split("T")[0];
          } else if (g.year) {
            deadline = g.year.toString();
          }

          return {
            id: g.id,
            goal_name: g.goal_name,
            target_value: parseFloat(g.target_value || 0),
            team: g.employee_goals_count ?? 0,
            deadline,
            period: g.period ?? "-",
          };
        });
        setDepartmentGoals(mappedDept);

        // 🔹 2. Fetch Employee Goals (User API)
        const resUser = await api_laravel.get("/api/kpi/time-tracking/user");
        const userData = resUser.data?.data ?? [];

        const allEmployees = userData.flatMap((goal) =>
          goal.employee_goals?.map((eg) => ({
            id: eg.id,
            goal_name: eg.goal_name,
            status: eg.status,
            due_date: eg.due_date,
            progress: parseFloat(eg.progress || 0),
            employee_name: eg.employee?.name ?? "Unknown",
            email: eg.employee?.email ?? "-",
            department_goal: goal.goal_name,
          })) ?? []
        );

        setEmployeeGoals(allEmployees);
      } catch (error) {
        console.error("Error fetching KPI data:", error);
        setDepartmentGoals([]);
        setEmployeeGoals([]);
      }
    };

    fetchAllData();
  }, []);

  const summaryStats = {
    totalGoals: departmentGoals.length,
    totalEmployees: employeeGoals.length,
    totalDepartments: new Set(departmentGoals.map((g) => g.department_id)).size,
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Department KPI Tracking</h1>
          <p className="text-muted-foreground">
            Monitor department-level goals and employee achievements.
          </p>
        </div>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card>
          <CardContent className="p-6 flex justify-between items-center">
            <div>
              <p className="text-sm text-muted-foreground">Total Goals</p>
              <p className="text-3xl font-bold">{summaryStats.totalGoals}</p>
               <p className="text-sm text-muted-foreground">Being tracked</p>
            </div>
            <BarChart3 className="h-8 w-8 text-primary" />
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6 flex justify-between items-center">
            <div>
              <p className="text-sm text-muted-foreground">Employees</p>
              <p className="text-3xl font-bold">{summaryStats.totalEmployees}</p>
                <p className="text-sm text-success">Currently tracking</p>
            </div>
            <Play className="h-8 w-8 text-green-500" />
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6 flex justify-between items-center">
            <div>
              <p className="text-sm text-muted-foreground">Deadline Overview</p>
              <p className="text-3xl font-bold">Active</p>
            </div>
            <Clock className="h-8 w-8 text-blue-500" />
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <Tabs value={selectedTab} onValueChange={setSelectedTab}>
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="employees">Employees</TabsTrigger>
          <TabsTrigger value="departments">Department Goals</TabsTrigger>
        </TabsList>

        {/* EMPLOYEES TAB */}
        <TabsContent value="employees" className="space-y-4">
          {employeeGoals.length === 0 ? (
            <p className="text-center text-muted-foreground py-6">
              No employee goals available.
            </p>
          ) : (
            <div className="grid gap-4">
              {employeeGoals.map((e, i) => (
                <Card key={i} className="hover:shadow-md transition">
                  <CardContent className="p-5 flex justify-between items-center">
                    <div className="flex items-center space-x-4">
                      <Avatar>
                        <AvatarImage
                          src={`https://ui-avatars.com/api/?name=${e.employee_name}`}
                        />
                        <AvatarFallback>
                          {e.employee_name
                            .split(" ")
                            .map((n) => n[0])
                            .join("")}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <h3 className="font-semibold">{e.employee_name}</h3>
                        <p className="text-sm text-muted-foreground">{e.email}</p>
                        <p className="text-xs text-muted-foreground">
                          🎯 {e.goal_name}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          📊 Department Goal: {e.department_goal}
                        </p>
                      </div>
                    </div>
                    <div className="text-right">
                      <p
                        className={`text-sm font-semibold ${
                          e.status === "in_progress"
                            ? "text-blue-500"
                            : e.status === "completed"
                            ? "text-green-500"
                            : "text-muted-foreground"
                        }`}
                      >
                        {e.status}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        📅 {e.due_date}
                      </p>
                      <p className="text-sm font-bold text-primary">
                        {e.progress}% progress
                      </p>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>

        {/* DEPARTMENT TAB */}
        <TabsContent value="departments" className="space-y-4">
          {departmentGoals.length === 0 ? (
            <p className="text-center text-muted-foreground py-6">
              No department goals available.
            </p>
          ) : (
            <div className="grid gap-4">
              {departmentGoals.map((g) => (
                <Card
                  key={g.id}
                  className="hover:shadow-md transition border border-gray-200"
                >
                  <CardContent className="p-6 flex justify-between items-center">
                    <div>
                      <h3 className="font-semibold text-lg">{g.goal_name}</h3>
                      <p className="text-sm text-muted-foreground">
                        👥 {g.team} employee
                        {g.team > 1 ? "s" : ""} assigned
                      </p>
                      <p className="text-xs text-muted-foreground">
                        📅 Deadline: {g.deadline}
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="text-2xl font-bold text-primary">
                        {g.target_value.toLocaleString()}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        Period: {g.period}
                      </p>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>
      </Tabs>
    </div>
  );
}
