import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Loader2, Send, Check, Users, Building, Bell, AlertCircle, Search } from "lucide-react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
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
import { toast } from "@/components/ui/use-toast";
import api_laravel from "@/lib/utils";

interface Department {
  id: number;
  name: string;
  description?: string;
  employee_count?: number;
}

interface Employee {
  id: number;
  name: string;
  email: string;
  employee_id: string;
  department_id: number;
  department_name: string;
}

interface BroadcastFormData {
  title: string;
  message: string;
  type: 'all' | 'department' | 'custom';
  department_ids: number[];
  employee_ids: number[];
  priority: 'low' | 'medium' | 'high';
}

interface BroadcastHistory {
  id: number;
  title: string;
  message: string;
  sent_at: string;
  sent_by: string;
  recipient_count: number;
  type: string;
  status: 'sent' | 'failed' | 'pending';
}

export default function BroadcastPage() {
  const [loading, setLoading] = useState(false);
  const [sending, setSending] = useState(false);
  const [departments, setDepartments] = useState<Department[]>([]);
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [selectedDepartments, setSelectedDepartments] = useState<number[]>([]);
  const [selectedEmployees, setSelectedEmployees] = useState<number[]>([]);
  const [history, setHistory] = useState<BroadcastHistory[]>([]);
  const [formData, setFormData] = useState<BroadcastFormData>({
    title: '',
    message: '',
    type: 'all',
    department_ids: [],
    employee_ids: [],
    priority: 'medium'
  });
  const [selectedTab, setSelectedTab] = useState('compose');
  const [previewDialog, setPreviewDialog] = useState(false);
  const [employeeSearch, setEmployeeSearch] = useState('');
  const [companyError, setCompanyError] = useState(false);

  // Fetch departments dan employees
  useEffect(() => {
    fetchDepartments();
    fetchEmployees();
    fetchBroadcastHistory();
  }, []);

  const fetchDepartments = async () => {
    try {
      setLoading(true);
      const res = await api_laravel.get('/api/departments');
      console.log('Departments response:', res.data);
      
      // Handle berbagai format response
      if (res.data && Array.isArray(res.data)) {
        setDepartments(res.data);
      } else if (res.data && res.data.data && Array.isArray(res.data.data)) {
        setDepartments(res.data.data);
      } else if (res.data && res.data.success && Array.isArray(res.data.data)) {
        setDepartments(res.data.data);
      } else {
        console.error('Unexpected departments response format:', res.data);
        setDepartments([]);
      }
    } catch (error) {
      console.error('Error fetching departments:', error);
      toast({
        title: "Error",
        description: "Failed to load departments",
        variant: "destructive",
      });
      setDepartments([]);
    } finally {
      setLoading(false);
    }
  };

  const fetchEmployees = async () => {
    try {
      setLoading(true);
      setCompanyError(false);
      
      const res = await api_laravel.get('/api/employees');
      console.log('Employees API response:', res.data);
      
      let employeesData: Employee[] = [];
      
      if (res.data && res.data.success && res.data.data) {
        const employeeArray = res.data.data.data || [];
        
        employeesData = employeeArray.map((emp: any) => ({
          id: emp.id,
          name: emp.name || '',
          email: emp.email || '',
          employee_id: emp.nik_employee || `EMP${emp.id.toString().padStart(5, '0')}`,
          department_id: emp.department ? parseInt(emp.department) : 0,
          department_name: emp.department_description || 'Unknown'
        }));
      } else {
        console.error('Unexpected employees response format:', res.data);
        toast({
          title: "Error",
          description: "Invalid employee data format received",
          variant: "destructive",
        });
      }
      
      console.log('Processed employees:', employeesData.length, employeesData);
      setEmployees(employeesData);
    } catch (error: any) {
      console.error('Error fetching employees:', error);
      
      if (error.response?.data?.message?.includes('select a company')) {
        setCompanyError(true);
        toast({
          title: "Company Required",
          description: "Please select a company first to view employees",
          variant: "destructive",
        });
      } else {
        toast({
          title: "Error",
          description: error.response?.data?.message || "Failed to load employees",
          variant: "destructive",
        });
      }
      
      setEmployees([]);
    } finally {
      setLoading(false);
    }
  };

  const fetchBroadcastHistory = async () => {
    try {
      setLoading(true);
      const res = await api_laravel.get('/api/broadcast/history');
      console.log('Broadcast history API response:', res.data);
      
      let historyData: BroadcastHistory[] = [];
      
      if (res.data && res.data.success && res.data.data) {
        // FIXED: Data berada di res.data.data.data (nested array)
        const historyArray = res.data.data.data || [];
        
        historyData = historyArray.map((item: any) => ({
          id: item.id,
          title: item.title,
          message: item.message,
          sent_at: item.created_at || item.sent_at,
          sent_by: item.sent_by,
          recipient_count: item.recipient_count,
          type: item.type,
          status: item.status || 'sent'
        }));
      } else {
        console.error('Unexpected history response format:', res.data);
      }
      
      console.log('Processed history:', historyData);
      setHistory(historyData);
    } catch (error) {
      console.error('Error fetching history:', error);
      toast({
        title: "Error",
        description: "Failed to load broadcast history",
        variant: "destructive",
      });
      setHistory([]);
    } finally {
      setLoading(false);
    }
  };

  const handleDepartmentToggle = (departmentId: number) => {
    setSelectedDepartments(prev => {
      const newSelection = prev.includes(departmentId)
        ? prev.filter(id => id !== departmentId)
        : [...prev, departmentId];
      
      setFormData(prev => ({
        ...prev,
        department_ids: newSelection,
        type: newSelection.length > 0 ? 'department' : 'all'
      }));
      
      return newSelection;
    });
  };

  const handleEmployeeToggle = (employeeId: number) => {
    setSelectedEmployees(prev => {
      const newSelection = prev.includes(employeeId)
        ? prev.filter(id => id !== employeeId)
        : [...prev, employeeId];
      
      setFormData(prev => ({
        ...prev,
        employee_ids: newSelection,
        type: newSelection.length > 0 ? 'custom' : 'all'
      }));
      
      return newSelection;
    });
  };

  const handleSelectAllDepartments = () => {
    const allIds = departments.map(dept => dept.id);
    setSelectedDepartments(allIds);
    setFormData(prev => ({
      ...prev,
      department_ids: allIds,
      type: 'department'
    }));
  };

  const handleClearDepartments = () => {
    setSelectedDepartments([]);
    setFormData(prev => ({
      ...prev,
      department_ids: [],
      type: 'all'
    }));
  };

  const handleSelectAllEmployees = () => {
    const allIds = employees.map(emp => emp.id);
    setSelectedEmployees(allIds);
    setFormData(prev => ({
      ...prev,
      employee_ids: allIds,
      type: 'custom'
    }));
  };

  const handleClearEmployees = () => {
    setSelectedEmployees([]);
    setFormData(prev => ({
      ...prev,
      employee_ids: [],
      type: 'all'
    }));
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handlePriorityChange = (value: string) => {
    setFormData(prev => ({
      ...prev,
      priority: value as 'low' | 'medium' | 'high'
    }));
  };

  const getRecipientCount = () => {
    if (formData.type === 'all') {
      return employees.length;
    } else if (formData.type === 'department') {
      const selectedDeptIds = selectedDepartments;
      const employeesInSelectedDepts = employees.filter(emp => 
        selectedDeptIds.includes(emp.department_id)
      );
      return employeesInSelectedDepts.length;
    } else if (formData.type === 'custom') {
      return selectedEmployees.length;
    }
    return 0;
  };

  const handleSendBroadcast = async () => {
    if (!formData.title.trim() || !formData.message.trim()) {
      toast({
        title: "Validation Error",
        description: "Title and message are required",
        variant: "destructive",
      });
      return;
    }

    const recipientCount = getRecipientCount();
    if (recipientCount === 0) {
      toast({
        title: "No Recipients",
        description: "Please select at least one recipient",
        variant: "destructive",
      });
      return;
    }

    setSending(true);
    try {
      const payload = {
        ...formData,
        recipient_count: recipientCount
      };

      console.log('Sending broadcast payload:', payload);
      
      const res = await api_laravel.post('/api/broadcast/send', payload);
      console.log('Broadcast send response:', res.data);
      
      if (res.data.success) {
        toast({
          title: "Success",
          description: `Broadcast sent to ${recipientCount} recipients`,
        });
        
        // Reset form
        setFormData({
          title: '',
          message: '',
          type: 'all',
          department_ids: [],
          employee_ids: [],
          priority: 'medium'
        });
        setSelectedDepartments([]);
        setSelectedEmployees([]);
        
        // Refresh history
        fetchBroadcastHistory();
        
        // Switch to history tab
        setSelectedTab('history');
      } else {
        throw new Error(res.data.message || 'Failed to send broadcast');
      }
    } catch (error: any) {
      console.error('Error sending broadcast:', error);
      toast({
        title: "Error",
        description: error.response?.data?.message || "Failed to send broadcast",
        variant: "destructive",
      });
    } finally {
      setSending(false);
    }
  };

  const formatDate = (dateString: string) => {
    try {
      return new Date(dateString).toLocaleString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    } catch (error) {
      return dateString;
    }
  };

  const getPriorityBadge = (priority: string) => {
    const variants = {
      low: 'bg-green-100 text-green-800',
      medium: 'bg-yellow-100 text-yellow-800',
      high: 'bg-red-100 text-red-800'
    };
    return (
      <Badge className={`${variants[priority as keyof typeof variants]}`}>
        {priority.toUpperCase()}
      </Badge>
    );
  };

  const getStatusBadge = (status: string) => {
    const variants = {
      sent: 'bg-green-100 text-green-800',
      failed: 'bg-red-100 text-red-800',
      pending: 'bg-yellow-100 text-yellow-800'
    };
    return (
      <Badge className={`${variants[status as keyof typeof variants]}`}>
        {status.toUpperCase()}
      </Badge>
    );
  };

  // Filter employees berdasarkan search
  const filteredEmployees = employeeSearch 
    ? employees.filter(emp => 
        emp.name.toLowerCase().includes(employeeSearch.toLowerCase()) ||
        emp.email.toLowerCase().includes(employeeSearch.toLowerCase()) ||
        emp.employee_id.toLowerCase().includes(employeeSearch.toLowerCase())
      )
    : employees;

  if (companyError) {
    return (
      <div className="container mx-auto p-6">
        <Card className="max-w-md mx-auto">
          <CardHeader>
            <CardTitle className="text-center">Company Selection Required</CardTitle>
            <CardDescription className="text-center">
              Please select a company first to access broadcast features
            </CardDescription>
          </CardHeader>
          <CardContent className="text-center">
            <Building className="w-16 h-16 mx-auto mb-4 text-muted-foreground" />
            <p className="text-sm text-muted-foreground mb-4">
              You need to select a company before you can send broadcasts to employees.
            </p>
            <Button onClick={() => window.location.href = '/master/company-master'}>
              Select Company
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (loading && employees.length === 0 && departments.length === 0) {
    return (
      <div className="flex items-center justify-center h-screen">
        <Loader2 className="w-8 h-8 animate-spin text-muted-foreground" />
        <span className="ml-2">Loading...</span>
      </div>
    );
  }

  return (
    <div className="container mx-auto p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Broadcast Message</h1>
          <p className="text-muted-foreground">
            Send announcements and notifications to employees
          </p>
        </div>
        <Badge variant="outline" className="px-3 py-1">
          <Bell className="w-4 h-4 mr-2" />
          {employees.length} total employees
        </Badge>
      </div>

      <Tabs value={selectedTab} onValueChange={setSelectedTab} className="space-y-6">
        <TabsList className="grid w-full max-w-md grid-cols-2">
          <TabsTrigger value="compose">Compose Broadcast</TabsTrigger>
          <TabsTrigger value="history">Broadcast History</TabsTrigger>
        </TabsList>

        <TabsContent value="compose" className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Form Section */}
            <Card className="lg:col-span-2">
              <CardHeader>
                <CardTitle>Compose Message</CardTitle>
                <CardDescription>
                  Create your broadcast message and select recipients
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="space-y-2">
                  <Label htmlFor="title">Title *</Label>
                  <Input
                    id="title"
                    name="title"
                    value={formData.title}
                    onChange={handleInputChange}
                    placeholder="Enter broadcast title"
                    className="w-full"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="message">Message *</Label>
                  <Textarea
                    id="message"
                    name="message"
                    value={formData.message}
                    onChange={handleInputChange}
                    placeholder="Type your message here..."
                    rows={8}
                    className="w-full resize-none"
                  />
                  <div className="text-sm text-muted-foreground">
                    {formData.message.length} characters
                  </div>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="priority">Priority</Label>
                  <Select value={formData.priority} onValueChange={handlePriorityChange}>
                    <SelectTrigger>
                      <SelectValue placeholder="Select priority" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="low">Low Priority</SelectItem>
                      <SelectItem value="medium">Medium Priority</SelectItem>
                      <SelectItem value="high">High Priority</SelectItem>
                    </SelectContent>
                  </Select>
                  <div className="flex items-center text-sm text-muted-foreground">
                    <AlertCircle className="w-4 h-4 mr-2" />
                    High priority messages will be highlighted for recipients
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Recipients Section */}
            <Card>
              <CardHeader>
                <CardTitle>Select Recipients</CardTitle>
                <CardDescription>
                  Choose who will receive this broadcast
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="space-y-4">
                  <div className="space-y-2">
                    <Label>Send to:</Label>
                    <div className="flex flex-col space-y-2">
                      <Button
                        variant={formData.type === 'all' ? 'default' : 'outline'}
                        onClick={() => {
                          setFormData(prev => ({ ...prev, type: 'all' }));
                          setSelectedDepartments([]);
                          setSelectedEmployees([]);
                        }}
                        className="justify-start"
                      >
                        <Users className="w-4 h-4 mr-2" />
                        All Employees ({employees.length})
                      </Button>
                      
                      <Dialog>
                        <DialogTrigger asChild>
                          <Button
                            variant={formData.type === 'department' ? 'default' : 'outline'}
                            className="justify-start"
                          >
                            <Building className="w-4 h-4 mr-2" />
                            Specific Departments ({selectedDepartments.length})
                          </Button>
                        </DialogTrigger>
                        <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto">
                          <DialogHeader>
                            <DialogTitle>Select Departments</DialogTitle>
                            <DialogDescription>
                              Choose which departments will receive this broadcast
                            </DialogDescription>
                          </DialogHeader>
                          <div className="space-y-4 py-4">
                            <div className="flex justify-between">
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={handleSelectAllDepartments}
                              >
                                Select All
                              </Button>
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={handleClearDepartments}
                              >
                                Clear All
                              </Button>
                            </div>
                            <div className="grid grid-cols-2 gap-2">
                              {Array.isArray(departments) && departments.map((dept) => (
                                <Button
                                  key={dept.id}
                                  variant={selectedDepartments.includes(dept.id) ? "default" : "outline"}
                                  onClick={() => handleDepartmentToggle(dept.id)}
                                  className="justify-start h-auto py-3"
                                >
                                  <div className="flex items-center space-x-2">
                                    {selectedDepartments.includes(dept.id) && (
                                      <Check className="w-4 h-4" />
                                    )}
                                    <div className="text-left">
                                      <div className="font-medium">{dept.name}</div>
                                      <div className="text-xs text-muted-foreground">
                                        {employees.filter(emp => emp.department_id === dept.id).length} employees
                                      </div>
                                    </div>
                                  </div>
                                </Button>
                              ))}
                            </div>
                          </div>
                          <DialogFooter>
                            <div className="text-sm text-muted-foreground">
                              Selected: {selectedDepartments.length} departments
                            </div>
                          </DialogFooter>
                        </DialogContent>
                      </Dialog>

                      <Dialog>
                        <DialogTrigger asChild>
                          <Button
                            variant={formData.type === 'custom' ? 'default' : 'outline'}
                            className="justify-start"
                          >
                            <Users className="w-4 h-4 mr-2" />
                            Specific Employees ({selectedEmployees.length})
                          </Button>
                        </DialogTrigger>
                        <DialogContent className="max-w-3xl max-h-[80vh] overflow-y-auto">
                          <DialogHeader>
                            <DialogTitle>Select Employees</DialogTitle>
                            <DialogDescription>
                              Choose specific employees to receive this broadcast
                            </DialogDescription>
                          </DialogHeader>
                          <div className="space-y-4 py-4">
                            <div className="flex justify-between">
                              <div className="flex items-center space-x-2">
                                <Button
                                  variant="outline"
                                  size="sm"
                                  onClick={handleSelectAllEmployees}
                                >
                                  Select All
                                </Button>
                                <Button
                                  variant="outline"
                                  size="sm"
                                  onClick={handleClearEmployees}
                                >
                                  Clear All
                                </Button>
                              </div>
                              <div className="relative">
                                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                                <Input
                                  placeholder="Search employees..."
                                  value={employeeSearch}
                                  onChange={(e) => setEmployeeSearch(e.target.value)}
                                  className="pl-9 w-48"
                                />
                              </div>
                            </div>
                            <div className="space-y-2 max-h-[400px] overflow-y-auto">
                              {Array.isArray(filteredEmployees) && filteredEmployees.length > 0 ? (
                                filteredEmployees.map((emp) => (
                                  <Button
                                    key={emp.id}
                                    variant={selectedEmployees.includes(emp.id) ? "default" : "outline"}
                                    onClick={() => handleEmployeeToggle(emp.id)}
                                    className="w-full justify-start h-auto py-3"
                                  >
                                    <div className="flex items-center justify-between w-full">
                                      <div className="flex items-center space-x-3">
                                        {selectedEmployees.includes(emp.id) && (
                                          <Check className="w-4 h-4" />
                                        )}
                                        <div className="text-left">
                                          <div className="font-medium">{emp.name}</div>
                                          <div className="text-xs text-muted-foreground">
                                            {emp.employee_id} • {emp.department_name}
                                          </div>
                                        </div>
                                      </div>
                                      <Badge variant="outline" className="ml-2">
                                        {emp.department_name}
                                      </Badge>
                                    </div>
                                  </Button>
                                ))
                              ) : (
                                <div className="text-center py-8 text-muted-foreground">
                                  No employees found
                                </div>
                              )}
                            </div>
                          </div>
                          <DialogFooter>
                            <div className="text-sm text-muted-foreground">
                              Showing {filteredEmployees.length} of {employees.length} employees • 
                              Selected: {selectedEmployees.length} employees
                            </div>
                          </DialogFooter>
                        </DialogContent>
                      </Dialog>
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label>Recipient Summary</Label>
                    <div className="p-4 bg-muted/50 rounded-lg">
                      <div className="space-y-2">
                        <div className="flex justify-between">
                          <span className="text-sm">Total Recipients:</span>
                          <span className="font-semibold">{getRecipientCount()}</span>
                        </div>
                        {formData.type === 'department' && selectedDepartments.length > 0 && (
                          <div className="space-y-1">
                            <span className="text-sm">Selected Departments:</span>
                            <div className="flex flex-wrap gap-1 mt-1">
                              {departments
                                .filter(dept => selectedDepartments.includes(dept.id))
                                .map(dept => (
                                  <Badge key={dept.id} variant="secondary">
                                    {dept.name}
                                  </Badge>
                                ))
                              }
                            </div>
                          </div>
                        )}
                        {formData.type === 'custom' && selectedEmployees.length > 0 && (
                          <div className="space-y-1">
                            <span className="text-sm">Selected Employees:</span>
                            <div className="text-xs text-muted-foreground">
                              {selectedEmployees.length} employees selected
                            </div>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                </div>

                <div className="flex flex-col space-y-4">
                  <Button
                    onClick={() => setPreviewDialog(true)}
                    variant="outline"
                  >
                    Preview Message
                  </Button>
                  <Button
                    onClick={handleSendBroadcast}
                    disabled={sending || !formData.title || !formData.message}
                    className="w-full"
                  >
                    {sending ? (
                      <>
                        <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                        Sending...
                      </>
                    ) : (
                      <>
                        <Send className="w-4 h-4 mr-2" />
                        Send Broadcast
                      </>
                    )}
                  </Button>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="history">
          <Card>
            <CardHeader>
              <CardTitle>Broadcast History</CardTitle>
              <CardDescription>
                View all previously sent broadcast messages
              </CardDescription>
            </CardHeader>
            <CardContent>
              {loading ? (
                <div className="flex justify-center items-center h-64">
                  <Loader2 className="w-8 h-8 animate-spin text-muted-foreground" />
                </div>
              ) : !Array.isArray(history) || history.length === 0 ? (
                <div className="text-center py-12 text-muted-foreground">
                  <Bell className="w-12 h-12 mx-auto mb-4 opacity-50" />
                  <p>No broadcast history found</p>
                  <Button 
                    onClick={fetchBroadcastHistory} 
                    variant="outline" 
                    className="mt-4"
                  >
                    <Loader2 className={`w-4 h-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
                    Refresh History
                  </Button>
                </div>
              ) : (
                <div className="space-y-4">
                  {history.map((item) => (
                    <Card key={item.id} className="overflow-hidden">
                      <CardContent className="p-6">
                        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
                          <div className="space-y-2 flex-1">
                            <div className="flex items-center gap-2">
                              <h3 className="font-semibold text-lg">{item.title}</h3>
                              {getPriorityBadge('medium')}
                              {getStatusBadge(item.status)}
                            </div>
                            <p className="text-muted-foreground">{item.message}</p>
                            <div className="flex flex-wrap gap-2 text-sm text-muted-foreground">
                              <div className="flex items-center gap-1">
                                <Users className="w-4 h-4" />
                                <span>{item.recipient_count} recipients</span>
                              </div>
                              <span>•</span>
                              <div className="flex items-center gap-1">
                                <Building className="w-4 h-4" />
                                <span>{item.type}</span>
                              </div>
                              <span>•</span>
                              <div>
                                <span>{formatDate(item.sent_at)}</span>
                              </div>
                            </div>
                          </div>
                          <div className="text-right">
                            <div className="text-sm text-muted-foreground">
                              Sent by: {item.sent_by}
                            </div>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Preview Dialog */}
      <Dialog open={previewDialog} onOpenChange={setPreviewDialog}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Preview Broadcast</DialogTitle>
            <DialogDescription>
              This is how your message will appear to recipients
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label className="text-sm font-medium">Title</Label>
              <div className="p-3 bg-muted rounded-md">
                {formData.title || "No title provided"}
              </div>
            </div>
            
            <div className="space-y-2">
              <Label className="text-sm font-medium">Message</Label>
              <div className="p-4 bg-muted rounded-md whitespace-pre-wrap min-h-[200px]">
                {formData.message || "No message provided"}
              </div>
            </div>
            
            <div className="space-y-2">
              <Label className="text-sm font-medium">Recipients</Label>
              <div className="p-3 bg-muted rounded-md space-y-2">
                <div className="flex justify-between">
                  <span>Delivery Type:</span>
                  <Badge>{formData.type.toUpperCase()}</Badge>
                </div>
                <div className="flex justify-between">
                  <span>Total Recipients:</span>
                  <span className="font-semibold">{getRecipientCount()}</span>
                </div>
                <div className="flex justify-between">
                  <span>Priority:</span>
                  {getPriorityBadge(formData.priority)}
                </div>
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setPreviewDialog(false)}>
              Close
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}