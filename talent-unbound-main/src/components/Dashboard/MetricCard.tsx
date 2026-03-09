import { LucideIcon } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";

interface MetricCardProps {
  title: string;
  value: string | number;
  change?: string;
  trend?: "up" | "down" | "neutral";
  icon: LucideIcon;
  gradient?: boolean;
}

export function MetricCard({ title, value, change, trend, icon: Icon, gradient }: MetricCardProps) {
  const getTrendColor = () => {
    switch (trend) {
      case "up":
        return "text-success";
      case "down":
        return "text-destructive";
      default:
        return "text-muted-foreground";
    }
  };

  const getTrendIcon = () => {
    switch (trend) {
      case "up":
        return "↗";
      case "down":
        return "↘";
      default:
        return "→";
    }
  };

  return (
    <Card className={`card-metric ${gradient ? "bg-gradient-primary text-white" : ""}`}>
      <CardContent className="p-6">
        <div className="flex items-center justify-between">
          <div>
            <p className={`text-sm font-medium ${gradient ? "text-white/80" : "text-muted-foreground"}`}>
              {title}
            </p>
            <p className={`text-3xl font-bold ${gradient ? "text-white" : "text-foreground"}`}>
              {value}
            </p>
            {change && (
              <p className={`text-sm flex items-center mt-1 ${gradient ? "text-white/90" : getTrendColor()}`}>
                <span className="mr-1">{getTrendIcon()}</span>
                {change}
              </p>
            )}
          </div>
          <div className={`p-3 rounded-lg ${gradient ? "bg-white/20" : "bg-primary-light"}`}>
            <Icon className={`h-6 w-6 ${gradient ? "text-white" : "text-primary"}`} />
          </div>
        </div>
      </CardContent>
    </Card>
  );
}