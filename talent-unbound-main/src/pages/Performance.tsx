"use client";

import { useEffect, useState } from "react";
import { Star, TrendingUp, Target, Award } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Progress } from "@/components/ui/progress";
import api_laravel from "@/lib/utils"; // axios helper

interface Employee {
  id: number;
  employee: string;
  avatar: string;
  position: string;
  department: string;
  overallScore: number;
  goals: { completed: number; total: number };
  lastReview: string | null;
  nextReview: string | null;
  strengths: string[];
  improvements: string[];
 
}

interface Department {
  id: number;
  name: string;
  description?: string;
}

interface Position {
  id: number;
  name: string;
  nama_jabatan?: string;
}

export default function Performance() {
  const [performanceData, setPerformanceData] = useState<Employee[]>([]);

  const formatDate = (dateString: string | null) => {
  if (!dateString) return "-";
  const date = new Date(dateString);
  return new Intl.DateTimeFormat("id-ID", {
    day: "2-digit",
    month: "long",
    year: "numeric",
  }).format(date);
};



  useEffect(() => {
    api_laravel.get("api/employee-goals").then((res) => {
      if (res.data?.data) {
        const mapped: Employee[] = res.data.data.map((item: any) => ({
        id: item.id,
        employee: item.employee?.name ?? "-",
        avatar: item.employee?.avatar ?? "-",
        position: item.employee?.position?.nama_jabatan ?? "-", // ✅ ambil deskripsi jabatan
        department: item.department_goal?.department_id 
                      ? `Dept ID: ${item.department_goal.department_id}` 
                      : "-", // sementara tampilkan id saja
        overallScore: item.progress ?? 0,
        goals: {
          completed: item.achieved_value ? 1 : 0,
          total: 1,
        },
        lastReview: item.created_at ?? null,
        nextReview: item.due_date ?? null,
        strengths: ["Teamwork", "Discipline"],
        improvements: ["Time Management"],
      }));
        setPerformanceData(mapped);
      }
    });
  }, []);

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Performance</h1>
          <p className="text-muted-foreground">
            Track employee performance and manage reviews.
          </p>
        </div>
      </div>

      {/* Performance Overview */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <Card className="card-metric">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Average Score</p>
                <p className="text-3xl font-bold text-foreground">91.7%</p>
                <p className="text-sm text-success flex items-center mt-1">
                  <span className="mr-1">↗</span>
                  +3.2% from last quarter
                </p>
              </div>
              <div className="p-3 rounded-lg bg-primary-light">
                <Star className="h-6 w-6 text-primary" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="card-metric">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Goals Completed</p>
                <p className="text-3xl font-bold text-foreground">86%</p>
                <p className="text-sm text-success flex items-center mt-1">
                  <span className="mr-1">↗</span>
                  24/28 this quarter
                </p>
              </div>
              <div className="p-3 rounded-lg bg-success-light">
                <Target className="h-6 w-6 text-success" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="card-metric">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Reviews Due</p>
                <p className="text-3xl font-bold text-foreground">7</p>
                <p className="text-sm text-warning flex items-center mt-1">
                  <span className="mr-1">⏰</span>
                  Next 30 days
                </p>
              </div>
              <div className="p-3 rounded-lg bg-warning-light">
                <TrendingUp className="h-6 w-6 text-warning" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="card-metric bg-gradient-primary text-white">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-white/80">Top Performers</p>
                <p className="text-3xl font-bold text-white">12</p>
                <p className="text-sm text-white/90 flex items-center mt-1">
                  <span className="mr-1">🏆</span>
                  Score 90%+
                </p>
              </div>
              <div className="p-3 rounded-lg bg-white/20">
                <Award className="h-6 w-6 text-white" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Employee Performance Cards */}
      <div className="grid gap-6">
        {performanceData.map((employee, index) => (
          <Card key={index} className="card-dashboard">
            <CardContent className="p-6">
              <div className="flex items-center justify-between mb-6">
                <div className="flex items-center space-x-4">
                  <Avatar className="h-12 w-12">
                    <AvatarImage src={employee.avatar} alt={employee.employee} />
                    <AvatarFallback>
                      {employee.employee
                        .split(" ")
                        .map((n) => n[0])
                        .join("")}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <h3 className="text-lg font-semibold">{employee.employee}</h3>
                   <p className="text-sm text-muted-foreground">
  {employee.position.nama_jabatan}
</p>
                    <p className="text-xs text-muted-foreground">
  Department {employee.department.description}
</p>
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-2xl font-bold text-primary">
                    {employee.overallScore}%
                  </div>
                  <p className="text-xs text-muted-foreground">Overall Score</p>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                {/* Goals Progress */}
                <div className="space-y-3">
                  <h4 className="font-semibold text-sm">Goals Progress</h4>
                  <div className="space-y-2">
                    <div className="flex justify-between text-sm">
                      <span>Completed</span>
                      <span>
                        {employee.goals.completed}/{employee.goals.total}
                      </span>
                    </div>
                    <Progress
                      value={(employee.goals.completed / employee.goals.total) * 100}
                      className="h-2"
                    />
                  </div>
                </div>

                {/* Review Timeline */}
                <div className="space-y-3">
                  <h4 className="font-semibold text-sm">Review Timeline</h4>
                  <div className="space-y-1">
                    <div className="flex justify-between text-sm">
                      <span className="text-muted-foreground">Last Review</span>
                     <span>{formatDate(employee.lastReview)}</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-muted-foreground">Next Review</span>
                    <span>{formatDate(employee.lastReview)}</span>
                    </div>
                  </div>
                </div>

                {/* Performance Indicators */}
                <div className="space-y-3">
                  <h4 className="font-semibold text-sm">Performance Level</h4>
                  <div className="flex items-center space-x-2">
                    {employee.overallScore >= 90 ? (
                      <Badge className="status-active">Excellent</Badge>
                    ) : employee.overallScore >= 80 ? (
                      <Badge className="status-pending">Good</Badge>
                    ) : (
                      <Badge className="status-inactive">Needs Improvement</Badge>
                    )}
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
