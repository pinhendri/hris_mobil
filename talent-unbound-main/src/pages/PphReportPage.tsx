import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { 
  Loader2, 
  FileText, 
  Download, 
  Filter, 
  Search, 
  Plus, 
  Eye, 
  Edit, 
  Trash2,
  CheckCircle,
  XCircle,
  Calendar,
  ChevronLeft,
  ChevronRight,
  MoreVertical
} from "lucide-react";
import { 
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { toast } from "@/components/ui/use-toast";
import api_laravel from "@/lib/utils";
import { format } from "date-fns";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Checkbox } from "@/components/ui/checkbox";
import { Separator } from "@/components/ui/separator";
import { Switch } from "@/components/ui/switch";

interface PphReport {
  id: number;
  report_number: string;
  period: string;
  type: 'monthly' | 'yearly';
  start_date: string;
  end_date: string;
  c_code: string;
  total_tax: number;
  total_income: number;
  status: 'draft' | 'submitted' | 'approved' | 'rejected';
  prepared_by: string;
  approved_by: string | null;
  submitted_at: string | null;
  approved_at: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export default function PphReportPage() {
  const [reports, setReports] = useState<PphReport[]>([]);
  const [loading, setLoading] = useState(false);
  const [generating, setGenerating] = useState(false);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [typeFilter, setTypeFilter] = useState<string>('all');
  const [periodFilter, setPeriodFilter] = useState<string>('');
  const [dialogOpen, setDialogOpen] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [employees, setEmployees] = useState<any[]>([]);
  const [selectedReport, setSelectedReport] = useState<PphReport | null>(null);
  
  const [generateForm, setGenerateForm] = useState({
    type: 'monthly',
    period: format(new Date(), 'yyyy-MM'),
    includeAll: true,
    employeeIds: [] as number[],
    notes: ''
  });

  // Generate years for dropdown
  const currentYear = new Date().getFullYear();
  const years = Array.from({ length: 10 }, (_, i) => currentYear - i);

  const fetchReports = async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams();
      if (search) params.append('search', search);
      if (statusFilter && statusFilter !== 'all') params.append('status', statusFilter);
      if (typeFilter && typeFilter !== 'all') params.append('type', typeFilter);
      if (periodFilter) params.append('period', periodFilter);
      params.append('page', currentPage.toString());

      const res = await api_laravel.get(`/api/pph/reports?${params.toString()}`);
      
      if (res.data.success) {
        setReports(res.data.data);
        setTotalPages(res.data.meta?.last_page || 1);
      }
    } catch (error) {
      console.error('Error fetching PPH reports:', error);
      toast({
        title: "Error",
        description: "Failed to load PPH reports",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const fetchEmployees = async () => {
    try {
      const res = await api_laravel.get('/api/employees');
      if (res.data.success) {
        setEmployees(res.data.data);
      }
    } catch (error) {
      console.error('Error fetching employees:', error);
    }
  };

  useEffect(() => {
    fetchReports();
    fetchEmployees();
  }, [statusFilter, typeFilter, periodFilter, currentPage]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setCurrentPage(1);
    fetchReports();
  };

  const handleGenerateReport = async () => {
    if (!generateForm.period) {
      toast({
        title: "Validation Error",
        description: "Please select a period",
        variant: "destructive",
      });
      return;
    }

    // Format period based on type
    let formattedPeriod = generateForm.period;
    if (generateForm.type === 'yearly') {
      // Ensure year is 4 digits
      formattedPeriod = generateForm.period.padStart(4, '0');
    }

    setGenerating(true);
    try {
      const payload = {
        type: generateForm.type,
        period: formattedPeriod,
        include_all: generateForm.includeAll,
        employee_ids: generateForm.includeAll ? [] : generateForm.employeeIds,
        notes: generateForm.notes
      };

      const res = await api_laravel.post('/api/pph/reports/generate', payload);
      
      if (res.data.success) {
        toast({
          title: "Success",
          description: "PPH report generated successfully",
        });
        setDialogOpen(false);
        resetGenerateForm();
        fetchReports();
      } else {
        throw new Error(res.data.message || 'Failed to generate report');
      }
    } catch (error: any) {
      console.error('Error generating report:', error);
      toast({
        title: "Error",
        description: error.response?.data?.message || "Failed to generate PPH report",
        variant: "destructive",
      });
    } finally {
      setGenerating(false);
    }
  };

  const handleDownloadReport = async (reportId: number, format: 'pdf' | 'excel' = 'pdf') => {
    try {
      const res = await api_laravel.get(`/api/pph/reports/${reportId}/download?format=${format}`, {
        responseType: 'blob'
      });
      
      const url = window.URL.createObjectURL(new Blob([res.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `pph-report-${reportId}.${format}`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      
      toast({
        title: "Success",
        description: `Report downloaded as ${format.toUpperCase()}`,
      });
    } catch (error) {
      console.error('Error downloading report:', error);
      toast({
        title: "Error",
        description: "Failed to download report",
        variant: "destructive",
      });
    }
  };

  const handleDeleteReport = async (reportId: number) => {
    if (!confirm('Are you sure you want to delete this report?')) return;

    try {
      const res = await api_laravel.delete(`/api/pph/reports/${reportId}`);
      
      if (res.data.success) {
        toast({
          title: "Success",
          description: "Report deleted successfully",
        });
        fetchReports();
      }
    } catch (error) {
      console.error('Error deleting report:', error);
      toast({
        title: "Error",
        description: "Failed to delete report",
        variant: "destructive",
      });
    }
  };

  const handleSubmitReport = async (reportId: number) => {
    try {
      const res = await api_laravel.post(`/api/pph/reports/${reportId}/submit`);
      
      if (res.data.success) {
        toast({
          title: "Success",
          description: "Report submitted successfully",
        });
        fetchReports();
      }
    } catch (error) {
      console.error('Error submitting report:', error);
      toast({
        title: "Error",
        description: "Failed to submit report",
        variant: "destructive",
      });
    }
  };

  const resetGenerateForm = () => {
    setGenerateForm({
      type: 'monthly',
      period: format(new Date(), 'yyyy-MM'),
      includeAll: true,
      employeeIds: [],
      notes: ''
    });
  };

  const getStatusBadge = (status: string) => {
    const variants = {
      draft: "bg-gray-100 text-gray-800",
      submitted: "bg-blue-100 text-blue-800",
      approved: "bg-green-100 text-green-800",
      rejected: "bg-red-100 text-red-800"
    };

    return (
      <Badge className={variants[status as keyof typeof variants]}>
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </Badge>
    );
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0
    }).format(amount);
  };

  const handlePeriodChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (generateForm.type === 'monthly') {
      setGenerateForm({...generateForm, period: e.target.value});
    } else {
      // For yearly, only allow numbers and limit to 4 digits
      const value = e.target.value.replace(/\D/g, '').slice(0, 4);
      setGenerateForm({...generateForm, period: value});
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">PPH Reports</h1>
          <p className="text-muted-foreground">
            Manage and generate PPH 21/26 tax reports
          </p>
        </div>
        <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
          <DialogTrigger asChild>
            <Button>
              <Plus className="mr-2 h-4 w-4" />
              Generate Report
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>Generate PPH Report</DialogTitle>
              <DialogDescription>
                Create a new PPH 21/26 tax report for selected period
              </DialogDescription>
            </DialogHeader>
            
            <div className="space-y-4 py-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="type">Report Type</Label>
                  <Select
                    value={generateForm.type}
                    onValueChange={(value: 'monthly' | 'yearly') => 
                      setGenerateForm({...generateForm, type: value})
                    }
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select type" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="monthly">Monthly</SelectItem>
                      <SelectItem value="yearly">Yearly</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                
                <div className="space-y-2">
                  <Label htmlFor="period">
                    {generateForm.type === 'monthly' ? 'Month' : 'Year'}
                  </Label>
                  {generateForm.type === 'monthly' ? (
                    <Input
                      type="month"
                      value={generateForm.period}
                      onChange={handlePeriodChange}
                      min="2020-01"
                      max={format(new Date(), 'yyyy-MM')}
                    />
                  ) : (
                    <Select
                      value={generateForm.period}
                      onValueChange={(value) => 
                        setGenerateForm({...generateForm, period: value})
                      }
                    >
                      <SelectTrigger>
                        <SelectValue placeholder="Select year" />
                      </SelectTrigger>
                      <SelectContent>
                        {years.map((year) => (
                          <SelectItem key={year} value={year.toString()}>
                            {year}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  )}
                </div>
              </div>

              <div className="space-y-2">
                <div className="flex items-center space-x-2">
                  <Switch
                    checked={generateForm.includeAll}
                    onCheckedChange={(checked) => 
                      setGenerateForm({...generateForm, includeAll: checked})
                    }
                  />
                  <Label>Include All Employees</Label>
                </div>
                
                {!generateForm.includeAll && (
                  <div className="space-y-2">
                    <Label>Select Employees</Label>
                    <div className="border rounded-md p-4 max-h-60 overflow-y-auto">
                      {employees.map((employee) => (
                        <div key={employee.id} className="flex items-center space-x-2 py-2">
                          <Checkbox
                            checked={generateForm.employeeIds.includes(employee.id)}
                            onCheckedChange={(checked) => {
                              if (checked) {
                                setGenerateForm({
                                  ...generateForm,
                                  employeeIds: [...generateForm.employeeIds, employee.id]
                                });
                              } else {
                                setGenerateForm({
                                  ...generateForm,
                                  employeeIds: generateForm.employeeIds.filter(id => id !== employee.id)
                                });
                              }
                            }}
                          />
                          <span>{employee.name} - {employee.employee_id}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              <div className="space-y-2">
                <Label htmlFor="notes">Notes (Optional)</Label>
                <Input
                  id="notes"
                  placeholder="Add any notes about this report..."
                  value={generateForm.notes}
                  onChange={(e) => setGenerateForm({...generateForm, notes: e.target.value})}
                />
              </div>
            </div>

            <DialogFooter>
              <Button
                variant="outline"
                onClick={() => {
                  setDialogOpen(false);
                  resetGenerateForm();
                }}
              >
                Cancel
              </Button>
              <Button onClick={handleGenerateReport} disabled={generating}>
                {generating && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                Generate Report
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>PPH Reports</CardTitle>
          <CardDescription>
            View and manage all PPH 21/26 tax reports
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="flex flex-col md:flex-row gap-4">
              <form onSubmit={handleSearch} className="flex-1">
                <div className="relative">
                  <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input
                    placeholder="Search by report number or period..."
                    className="pl-10"
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault();
                        handleSearch(e);
                      }
                    }}
                  />
                </div>
              </form>
              
              <div className="flex gap-2">
                <Select value={typeFilter} onValueChange={setTypeFilter}>
                  <SelectTrigger className="w-[130px]">
                    <SelectValue placeholder="Type" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Types</SelectItem>
                    <SelectItem value="monthly">Monthly</SelectItem>
                    <SelectItem value="yearly">Yearly</SelectItem>
                  </SelectContent>
                </Select>

                <Select value={statusFilter} onValueChange={setStatusFilter}>
                  <SelectTrigger className="w-[130px]">
                    <SelectValue placeholder="Status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Status</SelectItem>
                    <SelectItem value="draft">Draft</SelectItem>
                    <SelectItem value="submitted">Submitted</SelectItem>
                    <SelectItem value="approved">Approved</SelectItem>
                    <SelectItem value="rejected">Rejected</SelectItem>
                  </SelectContent>
                </Select>

                <Button variant="outline" onClick={() => {
                  setSearch('');
                  setStatusFilter('all');
                  setTypeFilter('all');
                  setPeriodFilter('');
                  setCurrentPage(1);
                }}>
                  <Filter className="mr-2 h-4 w-4" />
                  Clear
                </Button>
              </div>
            </div>

            <div className="rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Report Number</TableHead>
                    <TableHead>Period</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead>Total Income</TableHead>
                    <TableHead>Total Tax</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Prepared By</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {loading ? (
                    <TableRow>
                      <TableCell colSpan={8} className="text-center py-8">
                        <Loader2 className="h-8 w-8 animate-spin mx-auto" />
                        <p className="mt-2 text-muted-foreground">Loading reports...</p>
                      </TableCell>
                    </TableRow>
                  ) : reports.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={8} className="text-center py-8">
                        <FileText className="h-12 w-12 text-muted-foreground mx-auto" />
                        <p className="mt-2 text-muted-foreground">No reports found</p>
                      </TableCell>
                    </TableRow>
                  ) : (
                    reports.map((report) => (
                      <TableRow key={report.id}>
                        <TableCell className="font-medium">
                          {report.report_number}
                        </TableCell>
                        <TableCell>{report.period}</TableCell>
                        <TableCell>
                          <Badge variant="outline">
                            {report.type.charAt(0).toUpperCase() + report.type.slice(1)}
                          </Badge>
                        </TableCell>
                        <TableCell>{formatCurrency(report.total_income)}</TableCell>
                        <TableCell>{formatCurrency(report.total_tax)}</TableCell>
                        <TableCell>{getStatusBadge(report.status)}</TableCell>
                        <TableCell>{report.prepared_by}</TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <DropdownMenu>
                              <DropdownMenuTrigger asChild>
                                <Button variant="ghost" size="sm">
                                  <MoreVertical className="h-4 w-4" />
                                </Button>
                              </DropdownMenuTrigger>
                              <DropdownMenuContent align="end">
                                <DropdownMenuLabel>Actions</DropdownMenuLabel>
                                <DropdownMenuItem onClick={() => setSelectedReport(report)}>
                                  <Eye className="mr-2 h-4 w-4" />
                                  View Details
                                </DropdownMenuItem>
                                <DropdownMenuItem onClick={() => handleDownloadReport(report.id, 'pdf')}>
                                  <Download className="mr-2 h-4 w-4" />
                                  Download PDF
                                </DropdownMenuItem>
                                <DropdownMenuItem onClick={() => handleDownloadReport(report.id, 'excel')}>
                                  <FileText className="mr-2 h-4 w-4" />
                                  Download Excel
                                </DropdownMenuItem>
                                <DropdownMenuSeparator />
                                {report.status === 'draft' && (
                                  <DropdownMenuItem onClick={() => handleSubmitReport(report.id)}>
                                    <CheckCircle className="mr-2 h-4 w-4" />
                                    Submit Report
                                  </DropdownMenuItem>
                                )}
                                {report.status === 'draft' && (
                                  <DropdownMenuItem>
                                    <Edit className="mr-2 h-4 w-4" />
                                    Edit Report
                                  </DropdownMenuItem>
                                )}
                                {report.status === 'draft' && (
                                  <DropdownMenuItem
                                    onClick={() => handleDeleteReport(report.id)}
                                    className="text-red-600"
                                  >
                                    <Trash2 className="mr-2 h-4 w-4" />
                                    Delete Report
                                  </DropdownMenuItem>
                                )}
                              </DropdownMenuContent>
                            </DropdownMenu>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </div>

            {totalPages > 1 && (
              <div className="flex items-center justify-between">
                <div className="text-sm text-muted-foreground">
                  Page {currentPage} of {totalPages}
                </div>
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                    disabled={currentPage === 1}
                  >
                    <ChevronLeft className="h-4 w-4" />
                    Previous
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                    disabled={currentPage === totalPages}
                  >
                    Next
                    <ChevronRight className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Report Details Dialog */}
      <Dialog open={!!selectedReport} onOpenChange={(open) => !open && setSelectedReport(null)}>
        <DialogContent className="max-w-3xl">
          {selectedReport && (
            <>
              <DialogHeader>
                <DialogTitle>Report Details</DialogTitle>
                <DialogDescription>
                  {selectedReport.report_number} - {selectedReport.period}
                </DialogDescription>
              </DialogHeader>
              
              <div className="space-y-6">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1">
                    <Label className="text-muted-foreground">Report Type</Label>
                    <p className="font-medium">{selectedReport.type.toUpperCase()}</p>
                  </div>
                  <div className="space-y-1">
                    <Label className="text-muted-foreground">Status</Label>
                    <div>{getStatusBadge(selectedReport.status)}</div>
                  </div>
                  <div className="space-y-1">
                    <Label className="text-muted-foreground">Period</Label>
                    <p className="font-medium">{selectedReport.period}</p>
                  </div>
                  <div className="space-y-1">
                    <Label className="text-muted-foreground">C Code</Label>
                    <p className="font-medium">{selectedReport.c_code}</p>
                  </div>
                </div>

                <Separator />

                <div className="grid grid-cols-2 gap-4">
                  <Card>
                    <CardHeader className="py-3">
                      <CardTitle className="text-sm">Total Income</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <p className="text-2xl font-bold text-green-600">
                        {formatCurrency(selectedReport.total_income)}
                      </p>
                    </CardContent>
                  </Card>
                  <Card>
                    <CardHeader className="py-3">
                      <CardTitle className="text-sm">Total Tax</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <p className="text-2xl font-bold text-red-600">
                        {formatCurrency(selectedReport.total_tax)}
                      </p>
                    </CardContent>
                  </Card>
                </div>

                <div className="space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-1">
                      <Label className="text-muted-foreground">Prepared By</Label>
                      <p className="font-medium">{selectedReport.prepared_by}</p>
                    </div>
                    <div className="space-y-1">
                      <Label className="text-muted-foreground">Approved By</Label>
                      <p className="font-medium">{selectedReport.approved_by || '-'}</p>
                    </div>
                    <div className="space-y-1">
                      <Label className="text-muted-foreground">Submitted At</Label>
                      <p className="font-medium">
                        {selectedReport.submitted_at ? format(new Date(selectedReport.submitted_at), 'PPP') : '-'}
                      </p>
                    </div>
                    <div className="space-y-1">
                      <Label className="text-muted-foreground">Approved At</Label>
                      <p className="font-medium">
                        {selectedReport.approved_at ? format(new Date(selectedReport.approved_at), 'PPP') : '-'}
                      </p>
                    </div>
                  </div>

                  {selectedReport.notes && (
                    <div className="space-y-1">
                      <Label className="text-muted-foreground">Notes</Label>
                      <p className="font-medium">{selectedReport.notes}</p>
                    </div>
                  )}
                </div>

                <Separator />

                <DialogFooter>
                  <div className="flex gap-2">
                    <Button
                      variant="outline"
                      onClick={() => handleDownloadReport(selectedReport.id, 'pdf')}
                    >
                      <Download className="mr-2 h-4 w-4" />
                      Download PDF
                    </Button>
                    <Button
                      variant="outline"
                      onClick={() => handleDownloadReport(selectedReport.id, 'excel')}
                    >
                      <FileText className="mr-2 h-4 w-4" />
                      Download Excel
                    </Button>
                    <Button onClick={() => setSelectedReport(null)}>
                      Close
                    </Button>
                  </div>
                </DialogFooter>
              </div>
            </>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}