import { useEffect, useMemo, useState } from "react";
import { Award, Star, Target, TrendingUp } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Progress } from "@/components/ui/progress";
import api_laravel from "@/lib/utils";

interface Evaluation {
  id: number;
  employee_id: number;
  employee_name: string;
  period: string;
  final_score: number;
  grade: string;
  is_locked: number;
  created_at: string | null;
  updated_at: string | null;
}

interface Assignment {
  employee_kpi_id?: number;
  master_kpi_detail_id?: number;
  id?: number;
}

interface History {
  period: string;
  final_score: number;
  grade: string;
  is_locked: number;
}

interface EmployeePerformance {
  employeeId: number;
  employeeName: string;
  latestEvaluation: Evaluation;
  assignments: Assignment[];
  history: History[];
}

export default function Performance() {
  const [performanceData, setPerformanceData] = useState<EmployeePerformance[]>(
    [],
  );
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadPerformance();
  }, []);

  const loadPerformance = async () => {
    setLoading(true);
    setError(null);

    try {
      const evaluationResponse = await api_laravel.get(
        "/api/kpi/evaluation/list",
      );
      const evaluations = extractList(evaluationResponse.data, [
        "evaluations",
        "data",
        "items",
      ])
        .map(normalizeEvaluation)
        .filter((item): item is Evaluation => item !== null);

      const latestByEmployee = latestEvaluationsByEmployee(evaluations);
      const enriched = await Promise.all(
        latestByEmployee.map(async (evaluation) => {
          const [assignments, history] = await Promise.all([
            loadAssignments(evaluation.employee_id),
            loadHistory(evaluation.employee_id),
          ]);

          return {
            employeeId: evaluation.employee_id,
            employeeName: evaluation.employee_name,
            latestEvaluation: evaluation,
            assignments,
            history,
          };
        }),
      );

      setPerformanceData(enriched);
    } catch (err: any) {
      setError(
        err?.response?.data?.message ||
          err?.message ||
          "Gagal memuat data performa KPI.",
      );
      setPerformanceData([]);
    } finally {
      setLoading(false);
    }
  };

  const overview = useMemo(() => {
    const totalEmployees = performanceData.length;
    const scores = performanceData.map(
      (item) => item.latestEvaluation.final_score,
    );
    const averageScore =
      scores.length === 0
        ? 0
        : scores.reduce((sum, score) => sum + score, 0) / scores.length;
    const lockedCount = performanceData.filter(
      (item) => item.latestEvaluation.is_locked === 1,
    ).length;
    const totalAssignments = performanceData.reduce(
      (sum, item) => sum + item.assignments.length,
      0,
    );

    return { totalEmployees, averageScore, lockedCount, totalAssignments };
  }, [performanceData]);

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Performance</h1>
          <p className="text-muted-foreground">
            Track KPI assignments, evaluation scores, and review history.
          </p>
        </div>
        <button
          type="button"
          onClick={loadPerformance}
          className="rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted"
        >
          Refresh
        </button>
      </div>

      <div className="grid grid-cols-1 gap-6 md:grid-cols-4">
        <MetricCard
          title="Average Score"
          value={formatScore(overview.averageScore)}
          helper="From latest KPI evaluations"
          icon={<Star className="h-6 w-6 text-primary" />}
        />
        <MetricCard
          title="Evaluated Employees"
          value={overview.totalEmployees.toString()}
          helper="Employees with KPI history"
          icon={<TrendingUp className="h-6 w-6 text-primary" />}
        />
        <MetricCard
          title="Assigned KPIs"
          value={overview.totalAssignments.toString()}
          helper="Current assignment records"
          icon={<Target className="h-6 w-6 text-primary" />}
        />
        <MetricCard
          title="Locked Reviews"
          value={overview.lockedCount.toString()}
          helper="Finalized evaluations"
          icon={<Award className="h-6 w-6 text-primary" />}
        />
      </div>

      {loading && (
        <Card>
          <CardContent className="p-6 text-sm text-muted-foreground">
            Loading KPI performance data...
          </CardContent>
        </Card>
      )}

      {!loading && error && (
        <Card>
          <CardContent className="p-6 text-sm text-destructive">
            {error}
          </CardContent>
        </Card>
      )}

      {!loading && !error && performanceData.length === 0 && (
        <Card>
          <CardContent className="p-6 text-sm text-muted-foreground">
            No KPI evaluations found.
          </CardContent>
        </Card>
      )}

      <div className="grid gap-6">
        {performanceData.map((employee) => {
          const evaluation = employee.latestEvaluation;
          const totalKpis = employee.assignments.length;
          const historyCount = employee.history.length;
          const score = evaluation.final_score;

          return (
            <Card key={employee.employeeId} className="card-dashboard">
              <CardContent className="p-6">
                <div className="mb-6 flex items-center justify-between">
                  <div className="flex items-center space-x-4">
                    <Avatar className="h-12 w-12">
                      <AvatarFallback>
                        {initials(employee.employeeName)}
                      </AvatarFallback>
                    </Avatar>
                    <div>
                      <h3 className="text-lg font-semibold">
                        {employee.employeeName}
                      </h3>
                      <p className="text-sm text-muted-foreground">
                        Employee ID {employee.employeeId}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        Latest period {evaluation.period || "-"}
                      </p>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-2xl font-bold text-primary">
                      {formatScore(score)}
                    </div>
                    <p className="text-xs text-muted-foreground">
                      KPI Final Score
                    </p>
                  </div>
                </div>

                <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
                  <div className="space-y-3">
                    <h4 className="text-sm font-semibold">KPI Assignment</h4>
                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span>Assigned KPI</span>
                        <span>{totalKpis}</span>
                      </div>
                      <Progress
                        value={totalKpis > 0 ? 100 : 0}
                        className="h-2"
                      />
                    </div>
                  </div>

                  <div className="space-y-3">
                    <h4 className="text-sm font-semibold">
                      Evaluation History
                    </h4>
                    <div className="space-y-1 text-sm">
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Reviews</span>
                        <span>{historyCount}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Updated</span>
                        <span>{formatDate(evaluation.updated_at)}</span>
                      </div>
                    </div>
                  </div>

                  <div className="space-y-3">
                    <h4 className="text-sm font-semibold">Performance Level</h4>
                    <div className="flex flex-wrap items-center gap-2">
                      <Badge className={badgeClass(score)}>
                        Grade {evaluation.grade || gradeForScore(score)}
                      </Badge>
                      <Badge variant="outline">
                        {evaluation.is_locked === 1 ? "Locked" : "Draft"}
                      </Badge>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>
    </div>
  );
}

function MetricCard({
  title,
  value,
  helper,
  icon,
}: {
  title: string;
  value: string;
  helper: string;
  icon: React.ReactNode;
}) {
  return (
    <Card className="card-metric">
      <CardContent className="p-6">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-muted-foreground">{title}</p>
            <p className="text-3xl font-bold text-foreground">{value}</p>
            <p className="mt-1 text-sm text-muted-foreground">{helper}</p>
          </div>
          <div className="rounded-lg bg-primary-light p-3">{icon}</div>
        </div>
      </CardContent>
    </Card>
  );
}

async function loadAssignments(employeeId: number): Promise<Assignment[]> {
  try {
    const response = await api_laravel.get(
      `/api/kpi/evaluation/employee/${employeeId}/kpi`,
    );
    const items = extractList(response.data, ["data", "items", "kpis"]);
    if (items.length > 0) return items as Assignment[];
  } catch {
    // The legacy endpoint below covers older deployments.
  }

  try {
    const response = await api_laravel.get(`/api/kpi/employee-kpi/${employeeId}`);
    return extractList(response.data, ["data", "items", "kpis"]) as Assignment[];
  } catch {
    return [];
  }
}

async function loadHistory(employeeId: number): Promise<History[]> {
  try {
    const response = await api_laravel.get(
      `/api/kpi/evaluation/history/${employeeId}`,
    );
    return extractList(response.data, [
      "history",
      "data",
      "evaluations",
      "items",
    ]).map(normalizeHistory);
  } catch {
    return [];
  }
}

function latestEvaluationsByEmployee(evaluations: Evaluation[]): Evaluation[] {
  const byEmployee = new Map<number, Evaluation>();

  for (const evaluation of evaluations) {
    const current = byEmployee.get(evaluation.employee_id);
    if (!current || compareEvaluationRecency(evaluation, current) > 0) {
      byEmployee.set(evaluation.employee_id, evaluation);
    }
  }

  return Array.from(byEmployee.values()).sort((left, right) =>
    left.employee_name.localeCompare(right.employee_name),
  );
}

function compareEvaluationRecency(left: Evaluation, right: Evaluation) {
  const periodComparison = left.period.localeCompare(right.period);
  if (periodComparison !== 0) return periodComparison;

  return timestamp(left.updated_at || left.created_at) -
    timestamp(right.updated_at || right.created_at);
}

function extractList(payload: unknown, keys: string[]): Record<string, unknown>[] {
  if (Array.isArray(payload)) {
    return payload.filter(isRecord);
  }

  if (!isRecord(payload)) {
    return [];
  }

  for (const key of keys) {
    const value = payload[key];
    if (Array.isArray(value)) {
      return value.filter(isRecord);
    }

    if (isRecord(value) && Array.isArray(value.data)) {
      return value.data.filter(isRecord);
    }
  }

  return [];
}

function normalizeEvaluation(item: Record<string, unknown>): Evaluation | null {
  const employeeId = toNumber(item.employee_id);
  if (employeeId <= 0) return null;

  return {
    id: toNumber(item.id || item.evaluation_id),
    employee_id: employeeId,
    employee_name: toText(item.employee_name || item.name || item.employee),
    period: toText(item.period),
    final_score: toNumber(item.final_score),
    grade: toText(item.grade),
    is_locked: toNumber(item.is_locked),
    created_at: nullableText(item.created_at),
    updated_at: nullableText(item.updated_at),
  };
}

function normalizeHistory(item: Record<string, unknown>): History {
  return {
    period: toText(item.period),
    final_score: toNumber(item.final_score),
    grade: toText(item.grade),
    is_locked: toNumber(item.is_locked),
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function toNumber(value: unknown): number {
  if (typeof value === "number") return value;
  if (typeof value === "string") return Number(value) || 0;
  return 0;
}

function toText(value: unknown): string {
  if (typeof value === "string") return value;
  if (typeof value === "number") return value.toString();
  if (isRecord(value) && typeof value.name === "string") return value.name;
  return "";
}

function nullableText(value: unknown): string | null {
  const text = toText(value);
  return text.length > 0 ? text : null;
}

function timestamp(value: string | null): number {
  if (!value) return 0;
  const parsed = new Date(value).getTime();
  return Number.isNaN(parsed) ? 0 : parsed;
}

function formatDate(value: string | null) {
  if (!value) return "-";
  return new Intl.DateTimeFormat("id-ID", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  }).format(new Date(value));
}

function formatScore(value: number) {
  return value.toFixed(2);
}

function gradeForScore(score: number) {
  if (score >= 90) return "A";
  if (score >= 75) return "B";
  return "C";
}

function badgeClass(score: number) {
  if (score >= 90) return "status-active";
  if (score >= 75) return "status-pending";
  return "status-inactive";
}

function initials(name: string) {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return "HR";
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
}
