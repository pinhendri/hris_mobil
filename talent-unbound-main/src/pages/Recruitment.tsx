import { RecruitmentPipeline } from "@/components/Recruitment/RecruitmentPipeline";

export default function Recruitment() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Recruitment</h1>
          <p className="text-muted-foreground">
            Manage job postings and track candidate applications.
          </p>
        </div>
      </div>
      <RecruitmentPipeline />
    </div>
  );
}