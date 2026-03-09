import { useState, useEffect } from "react";
import { Plus, User, Clock, Eye, XCircle } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  Select,
  SelectTrigger,
  SelectContent,
  SelectItem,
  SelectValue,
} from "@/components/ui/select";
import { Progress } from "@/components/ui/progress";
import {
  Avatar,
  AvatarImage,
  AvatarFallback,
} from "@/components/ui/avatar";

import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";

interface Candidate {
  name: string;
  avatar?: string;
  position?: string;
}

interface PipelineStage {
  stage: string;
  count: number;
  candidates?: Candidate[];
}

interface RecruitmentData {
  openPositions: any[];
  pipeline: PipelineStage[];
  applications: any[];
  metrics?: {
    conversionRate: number;
    averageTimeToHire: number;
  };
}

interface Department {
  id: number | string;
  name: string;
  [key: string]: any;
}

interface Position {
  id: number | string;
  nama_jabatan: string;
  [key: string]: any;
}

export function RecruitmentPipeline() {
  const [recruitmentData, setRecruitmentData] = useState<RecruitmentData>({
    openPositions: [],
    pipeline: [],
    applications: [],
    metrics: { conversionRate: 0, averageTimeToHire: 0 },
  });

  const [departments, setDepartments] = useState<Department[]>([]);
  const [positions, setPositions] = useState<Position[]>([]);
  const [openModal, setOpenModal] = useState(false);
  const [loading, setLoading] = useState(true);

  const [form, setForm] = useState({
    department: "",
    title: "",
    position_id: "",
    urgency: "Medium",
    requirement: "",
  });

  const [requirementsCache, setRequirementsCache] = useState<Record<number, string>>({});

  const handleMouseEnter = async (jobId: number) => {
    if (!requirementsCache[jobId]) {
      try {
        const res = await api_laravel.get(`/api/recruitment/jobs/${jobId}`);
        setRequirementsCache((prev) => ({
          ...prev,
          [jobId]: res.data.requirement,
        }));
      } catch (err) {
        console.error("Failed to fetch requirement:", err);
        setRequirementsCache((prev) => ({
          ...prev,
          [jobId]: "Failed to load requirement",
        }));
      }
    }
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        
        // Fetch recruitment data
        const resRecruitment = await api_laravel.get("/api/recruitment");
        const data = resRecruitment.data;

        const pipelineStages = ["Applied", "Screening", "Interview", "Offer", "Hired"];
        const pipeline: PipelineStage[] = pipelineStages.map((stage) => {
          const key = stage.toLowerCase();
          return {
            stage,
            count: data.statusCounts?.[key] || 0,
            candidates: [],
          };
        });

        setRecruitmentData({
          ...data,
          pipeline,
          metrics: data.metrics ?? { conversionRate: 0, averageTimeToHire: 0 },
        });

        // Fetch departments - handle potential API response structure
        try {
          const resDept = await api_laravel.get("/api/departments");
          let deptData = resDept.data;
          
          // Handle different response structures
          if (deptData && typeof deptData === 'object') {
            if (Array.isArray(deptData)) {
              setDepartments(deptData);
            } else if (deptData.data && Array.isArray(deptData.data)) {
              setDepartments(deptData.data);
            } else if (deptData.departments && Array.isArray(deptData.departments)) {
              setDepartments(deptData.departments);
            } else {
              console.warn("Unexpected departments API structure:", deptData);
              setDepartments([]);
            }
          } else {
            setDepartments([]);
          }
        } catch (deptError) {
          console.error("Error fetching departments:", deptError);
          setDepartments([]);
        }

        // Fetch positions - handle potential API response structure
        try {
          const resPos = await api_laravel.get("/api/employees/master/position");
          let posData = resPos.data;
          
          // Handle different response structures
          if (posData && typeof posData === 'object') {
            if (Array.isArray(posData)) {
              setPositions(posData);
            } else if (posData.data && Array.isArray(posData.data)) {
              setPositions(posData.data);
            } else if (posData.positions && Array.isArray(posData.positions)) {
              setPositions(posData.positions);
            } else {
              console.warn("Unexpected positions API structure:", posData);
              setPositions([]);
            }
          } else {
            setPositions([]);
          }
        } catch (posError) {
          console.error("Error fetching positions:", posError);
          setPositions([]);
        }

      } catch (error) {
        console.error("Error fetching recruitment data:", error);
        Swal.fire({
          icon: "error",
          title: "Error",
          text: "Failed to load recruitment data",
        });
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const getUrgencyBadge = (urgency: string) => {
    switch (urgency) {
      case "High":
        return <Badge variant="destructive">High Priority</Badge>;
      case "Medium":
        return <Badge className="status-pending">Medium</Badge>;
      case "Low":
        return <Badge variant="secondary">Low</Badge>;
      default:
        return <Badge variant="outline">{urgency}</Badge>;
    }
  };

  const handleSubmit = async () => {
    try {
      const res = await api_laravel.post("/api/recruitment/jobs", {
        department: form.department,
        title: form.title,
        position_id: form.position_id,
        urgency: form.urgency,
        requirement: form.requirement,
      });

      setRecruitmentData((prev: any) => ({
        ...prev,
        openPositions: [...(prev.openPositions || []), res.data],
      }));

      setOpenModal(false);

      Swal.fire({
        icon: "success",
        title: "Job Posted",
        text: "New job has been successfully created!",
        timer: 2000,
        showConfirmButton: false,
      });
    } catch (err: any) {
      console.error("Failed to create job", err);
      Swal.fire({
        icon: "error",
        title: "Failed",
        text: err.response?.data?.message || "Failed to create job.",
      });
    }
  };

  const handleCloseJob = async (jobId: number) => {
    Swal.fire({
      title: "Close this job?",
      text: "Are you sure you want to close this job posting?",
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "Yes, close it!",
      cancelButtonText: "No, keep it",
    }).then(async (result) => {
      if (result.isConfirmed) {
        try {
          await api_laravel.put(`/api/recruitment/jobs/${jobId}/close`);
          setRecruitmentData((prev: any) => ({
            ...prev,
            openPositions: (prev.openPositions || []).map((job: any) =>
              job.id === jobId ? { ...job, status: "Closed" } : job
            ),
          }));
          Swal.fire("Closed!", "The job has been closed.", "success");
        } catch (err) {
          Swal.fire("Error", "Failed to close the job.", "error");
        }
      }
    });
  };

  const getDepartmentName = (id: string | number) => {
    // Pastikan departments adalah array sebelum menggunakan find
    if (!Array.isArray(departments) || departments.length === 0) {
      return `Dept ${id}`;
    }
    
    const dept = departments.find((d) => {
      const deptId = typeof d.id === 'number' ? String(d.id) : d.id;
      const searchId = typeof id === 'number' ? String(id) : id;
      return deptId === searchId;
    });
    
    return dept ? dept.name : `Dept ${id}`;
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
          <p className="mt-4 text-muted-foreground">Loading recruitment data...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <Card className="card-dashboard">
        <CardHeader>
          <div className="flex justify-between items-center">
            <div>
              <CardTitle>Recruitment Pipeline</CardTitle>
              <p className="text-muted-foreground">
                Track open positions and candidate progress
              </p>
            </div>
            <Button className="btn-gradient" onClick={() => setOpenModal(true)}>
              <Plus className="h-4 w-4 mr-2" />
              Post New Job
            </Button>
          </div>
        </CardHeader>
      </Card>

      {/* Open Positions */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Open Positions */}
        <Card className="card-dashboard lg:col-span-1">
          <CardHeader>
            <CardTitle className="flex items-center">
              <User className="h-5 w-5 mr-2 text-primary" />
              Open Positions
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {(recruitmentData.openPositions || []).length > 0 ? (
                (recruitmentData.openPositions || []).map((position: any) => (
                  <Tooltip key={position.id}>
                    <TooltipTrigger onMouseEnter={() => handleMouseEnter(position.id)}>
                      <div className="p-4 border rounded-lg hover:shadow-md hover:bg-muted/50 transition-all flex justify-between items-start">
                        {/* Left side: title, department, urgency */}
                        <div className="flex flex-col space-y-1 min-w-0">
                          <h3 className="font-semibold text-sm truncate">{position.title}</h3>
                          <p className="text-xs text-muted-foreground truncate">
                            {getDepartmentName(position.department)}
                          </p>
                          <div>{getUrgencyBadge(position.urgency)}</div>
                        </div>

                        {/* Right side: date & close button */}
                        <div className="flex flex-col items-end space-y-1">
                          <span className="text-xs text-muted-foreground">
                            {position.date_posted || position.datePosted || "-"}
                          </span>
                          {position.status !== "Closed" && (
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() => handleCloseJob(position.id)}
                              className="hover:bg-muted rounded-full"
                            >
                              <XCircle className="h-4 w-4 text-destructive" />
                            </Button>
                          )}
                        </div>
                      </div>
                    </TooltipTrigger>

                    <TooltipContent className="max-w-xs">
                      {requirementsCache[position.id] || "Loading..."}
                    </TooltipContent>
                  </Tooltip>
                ))
              ) : (
                <p className="text-sm text-muted-foreground text-center py-4">
                  No open positions available.
                </p>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Candidate Pipeline */}
        <Card className="card-dashboard lg:col-span-2">
          <CardHeader>
            <CardTitle className="flex items-center">
              <Clock className="h-5 w-5 mr-2 text-primary" />
              Candidate Pipeline
            </CardTitle>
          </CardHeader>

          <CardContent>
            {/* Pipeline Stages */}
            <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
              {(recruitmentData.pipeline || []).map((stage: PipelineStage, index) => (
                <div key={index} className="space-y-3">
                  {/* Stage Title & Count */}
                  <div className="text-center">
                    <h3 className="font-semibold text-sm">{stage.stage}</h3>
                    <p className="text-2xl font-bold text-primary">{stage.count}</p>
                  </div>

                  {/* Candidates */}
                  <div className="space-y-2">
                    {(stage.candidates || []).map(
                      (candidate: Candidate, candidateIndex: number) => (
                        <div
                          key={candidateIndex}
                          className="flex items-center space-x-2 p-2 bg-muted/30 rounded-lg"
                        >
                          <Avatar className="h-6 w-6">
                            <AvatarImage src={candidate.avatar} alt={candidate.name} />
                            <AvatarFallback className="text-xs">
                              {candidate.name
                                .split(" ")
                                .map((n) => n[0])
                                .join("")}
                            </AvatarFallback>
                          </Avatar>
                          <div className="flex-1 min-w-0">
                            <p className="text-xs font-medium truncate">
                              {candidate.name}
                            </p>
                            <p className="text-xs text-muted-foreground truncate">
                              {candidate.position}
                            </p>
                          </div>
                        </div>
                      )
                    )}

                    {/* No candidates case */}
                    {(!stage.candidates || stage.candidates.length === 0) && (
                      <p className="text-xs text-muted-foreground text-center">
                        {stage.count} candidate(s)
                      </p>
                    )}
                  </div>
                </div>
              ))}
            </div>

            {/* Pipeline Metrics */}
            <div className="mt-6 p-4 bg-muted/30 rounded-lg">
              <h4 className="font-semibold mb-2">Overall Pipeline Health</h4>

              <div className="space-y-2">
                {/* Conversion Rate */}
                <div className="flex justify-between text-sm">
                  <span>Conversion Rate</span>
                  <span>{recruitmentData.metrics?.conversionRate ?? 0}%</span>
                </div>
                <Progress
                  value={recruitmentData.metrics?.conversionRate ?? 0}
                  className="h-2"
                />

                {/* Average Time to Hire */}
                <div className="flex justify-between text-sm mt-2">
                  <span>Average Time to Hire</span>
                  <span>{recruitmentData.metrics?.averageTimeToHire ?? 0} days</span>
                </div>
                <Progress
                  value={Math.min(
                    ((recruitmentData.metrics?.averageTimeToHire ?? 0) / 30) * 100,
                    100
                  )}
                  className="h-2"
                />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Recent Applications */}
      <Card className="card-dashboard">
        <CardHeader>
          <CardTitle>Recent Applications</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {(recruitmentData.applications || []).length > 0 ? (
              recruitmentData.applications.slice(0, 5).map((application: any, index: number) => {
                const job = (recruitmentData.openPositions || []).find(
                  (pos) => String(pos.id) === String(application.position_id)
                );
                const jobTitle = job ? job.title : "-";

                return (
                  <div
                    key={index}
                    className="flex items-center justify-between p-3 border rounded-lg"
                  >
                    <div className="flex items-center space-x-3">
                      {/* 👁 tombol lihat CV */}
                      {application.cv && (
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => window.open(application.cv, "_blank")}
                          className="hover:bg-muted rounded-full"
                        >
                          <Eye className="h-5 w-5 text-primary" strokeWidth={2} />
                        </Button>
                      )}
                      <Avatar>
                        {application.avatar ? (
                          <AvatarImage
                            src={application.avatar}
                            alt={application.name}
                          />
                        ) : (
                          <AvatarFallback>
                            {application.name
                              .split(" ")
                              .map((n: string) => n[0])
                              .join("")}
                          </AvatarFallback>
                        )}
                      </Avatar>
                      <div>
                        <p className="font-medium">{application.name}</p>
                        <p className="text-sm text-muted-foreground">
                          {application.position_name || "-"}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-3">
                      <span className="text-sm text-muted-foreground">
                        {application.time || application.applied_at || "-"}
                      </span>

                      {/* status badge */}
                      {application.status === "applied" && (
                        <Badge className="status-pending">Applied</Badge>
                      )}
                      {application.status === "reviewed" && (
                        <Badge className="status-active">Reviewed</Badge>
                      )}
                      {application.status === "scheduled" && (
                        <Badge variant="outline">Scheduled</Badge>
                      )}
                      {application.status === "rejected" && (
                        <Badge variant="destructive">Rejected</Badge>
                      )}
                      {!["applied", "reviewed", "scheduled", "rejected"].includes(
                        application.status
                      ) && (
                        <Badge variant="secondary">{application.status}</Badge>
                      )}
                    </div>
                  </div>
                );
              })
            ) : (
              <p className="text-sm text-muted-foreground text-center py-4">
                No applications yet.
              </p>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Modal Form */}
      <Dialog open={openModal} onOpenChange={setOpenModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Post New Job</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <Select
              onValueChange={(val) => setForm({ ...form, department: val })}
            >
              <SelectTrigger>
                <SelectValue placeholder="Select Department" />
              </SelectTrigger>
              <SelectContent>
                {Array.isArray(departments) && departments.length > 0 ? (
                  departments.map((d) => (
                    <SelectItem key={d.id} value={String(d.id)}>
                      {d.name}
                    </SelectItem>
                  ))
                ) : (
                  <SelectItem value="" disabled>
                    No departments available
                  </SelectItem>
                )}
              </SelectContent>
            </Select>

            <Select
              onValueChange={(val) => {
                const pos = positions.find((p) => String(p.id) === val);
                if (pos) {
                  setForm({ 
                    ...form, 
                    position_id: String(pos.id),
                    title: pos.nama_jabatan
                  });
                }
              }}
            >
              <SelectTrigger>
                <SelectValue placeholder="Select Position" />
              </SelectTrigger>
              <SelectContent>
                {Array.isArray(positions) && positions.length > 0 ? (
                  positions.map((p) => (
                    <SelectItem key={p.id} value={String(p.id)}>
                      {p.nama_jabatan}
                    </SelectItem>
                  ))
                ) : (
                  <SelectItem value="" disabled>
                    No positions available
                  </SelectItem>
                )}
              </SelectContent>
            </Select>

            <Select
              onValueChange={(val) => setForm({ ...form, urgency: val })}
              defaultValue="Medium"
            >
              <SelectTrigger>
                <SelectValue placeholder="Select Urgency" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="High">High</SelectItem>
                <SelectItem value="Medium">Medium</SelectItem>
                <SelectItem value="Low">Low</SelectItem>
              </SelectContent>
            </Select>

            <textarea
              className="w-full border rounded-md p-5 text-sm h-40"
              rows={6}
              placeholder="Enter job requirements..."
              value={form.requirement}
              onChange={(e) =>
                setForm({ ...form, requirement: e.target.value })
              }
            />
          </div>
          <DialogFooter>
            <Button onClick={handleSubmit}>Save</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}