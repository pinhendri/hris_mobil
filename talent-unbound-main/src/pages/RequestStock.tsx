"use client";

import { useState, useEffect } from "react";
import { Plus, Search, Filter, Edit, Trash2, Package, ClipboardList, Eye } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { 
  Dialog, 
  DialogContent, 
  DialogHeader, 
  DialogTitle,
  DialogTrigger 
} from "@/components/ui/dialog";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";

interface Inventory {
  id: number;
  code: string;
  name: string;
  category: string;
  description?: string;
  unit: string;
  stock: number;
  min_stock: number;
  max_stock: number;
  purchase_price: number;
  selling_price: number;
  supplier?: string;
  location?: string;
  status: 'active' | 'inactive';
}

interface InventoryRequest {
  id: number;
  request_number: string;
  inventory_id: number;
  inventory?: Inventory;
  quantity: number;
  requested_by: string;
  department: string;
  purpose: string;
  status: 'pending' | 'approved' | 'rejected' | 'completed';
  priority: 'low' | 'medium' | 'high';
  notes?: string;
  approved_by?: string;
  approved_at?: string;
  created_at: string;
  updated_at: string;
}

interface RequestItem {
  inventory_id: number;
  quantity: number;
  purpose: string;
  inventory?: Inventory;
}

interface User {
  id: number;
  name: string;
  email: string;
  uuid: string;
  employee_uuid?: string;
  department?: string;
  department_id?: string;
  roles: string[];
  permissions: string[];
}

interface Notification {
  id: number;
  user_id: number;
  title: string;
  message: string;
  type: string;
  data: any;
  is_read: boolean;
  created_at: string;
  updated_at: string;
}

interface DepartmentHead {
  [key: string]: string;
}

export default function InventoryRequest() {
  const [requests, setRequests] = useState<InventoryRequest[]>([]);
  const [inventories, setInventories] = useState<Inventory[]>([]);
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedStatus, setSelectedStatus] = useState("All");
  const [selectedPriority, setSelectedPriority] = useState("All");
  const [openDialog, setOpenDialog] = useState(false);
  const [openDetailDialog, setOpenDetailDialog] = useState(false);
  const [openDeleteDialog, setOpenDeleteDialog] = useState(false);
  const [selectedRequest, setSelectedRequest] = useState<InventoryRequest | null>(null);
  const [deleteId, setDeleteId] = useState<number | null>(null);
  const [formData, setFormData] = useState({
    requested_by: "",
    department: "",
    priority: "medium" as "low" | "medium" | "high",
    notes: "",
    items: [] as RequestItem[]
  });
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [departmentHeads, setDepartmentHeads] = useState<DepartmentHead>({});

  // Check if user is super-admin
  const isSuperAdmin = () => {
    return currentUser?.roles.includes('super-admin') || false;
  };

  // Check if user is warehouse staff
  const isWarehouseStaff = () => {
    const isWarehouse = currentUser?.roles.includes('warehouse') || 
                       currentUser?.roles.includes('gudang') ||
                       currentUser?.permissions.includes('manage-inventory') ||
                       currentUser?.permissions.includes('issue-stock');
    
    console.log("🔍 Warehouse Staff Check:", {
      user: currentUser?.name,
      roles: currentUser?.roles,
      permissions: currentUser?.permissions,
      isWarehouse: isWarehouse
    });
    
    return isWarehouse;
  };

  // Check if user has global view (super-admin atau warehouse)
  const hasGlobalView = () => {
    return isSuperAdmin() || isWarehouseStaff();
  };

  const isDepartmentHead = (department?: string) => {
    if (!currentUser?.employee_uuid || !department) {
      console.log("❌ Department head check failed:", {
        hasEmployeeUUID: !!currentUser?.employee_uuid,
        departmentProvided: department
      });
      return false;
    }
    
    console.log("🔍 ALL departmentHeads:", departmentHeads);
    console.log("🔍 Looking for department:", department);
    console.log("🔍 Department exists in heads:", department in departmentHeads);
    
    const departmentHeadEmployeeId = departmentHeads[department];
    
    console.log("🔍 Department Head Check DETAIL:", {
      user: currentUser?.name,
      userEmployeeUUID: currentUser?.employee_uuid,
      department: department,
      departmentHeadEmployeeId: departmentHeadEmployeeId,
      departmentHeadsKeys: Object.keys(departmentHeads),
      isHead: departmentHeadEmployeeId === currentUser.employee_uuid
    });
    
    return departmentHeadEmployeeId === currentUser.employee_uuid;
  };

  // Check if user can view request
  const canViewRequest = (requestDepartment: string) => {
    if (hasGlobalView()) return true;
    return currentUser?.department === requestDepartment;
  };

  // Check if user can perform action (edit/delete)
  const canPerformAction = (requestDepartment: string) => {
    if (isSuperAdmin()) return true;
    return currentUser?.department === requestDepartment;
  };

  // Check if user can approve request - FIX: Warehouse TIDAK bisa approve
  const canApproveRequest = (requestDepartment: string) => {
    // Warehouse staff TIDAK bisa approve
    if (isWarehouseStaff()) {
      console.log("❌ Warehouse staff cannot approve requests");
      return false;
    }
    
    // Super admin bisa approve semua
    if (isSuperAdmin()) {
      console.log("✅ Super admin can approve all requests");
      return true;
    }
    
    // Department head bisa approve request dari departmentnya
    if (isDepartmentHead(requestDepartment)) {
      console.log(`✅ Department head can approve requests from ${requestDepartment}`);
      return true;
    }
    
    // Jika tidak ada department heads yang terdefinisi, berikan akses ke user dengan permission tertentu
    if (Object.keys(departmentHeads).length === 0) {
      console.log("⚠️ No department heads defined, checking user permissions");
      if (currentUser?.permissions.includes('approve-requests-stock') || 
          currentUser?.roles.includes('manager') ||
          currentUser?.roles.includes('approver')) {
        console.log("✅ User has special permission to approve");
        return true;
      }
    }
    
    console.log(`❌ User cannot approve requests from ${requestDepartment}`);
    return false;
  };

  // Check if user can complete request (hanya gudang dan super-admin)
  const canCompleteRequest = (requestDepartment: string) => {
    // Warehouse staff bisa complete semua request yang approved
    if (isWarehouseStaff()) {
      console.log("✅ Warehouse staff can complete requests");
      return true;
    }
    
    // Super admin juga bisa complete
    if (isSuperAdmin()) {
      console.log("✅ Super admin can complete requests");
      return true;
    }
    
    console.log(`❌ User cannot complete requests from ${requestDepartment}`);
    return false;
  };

  // Fetch current user
  const fetchCurrentUser = async () => {
    try {
      const response = await api_laravel.get("/api/me");
      if (response.data.success) {
        const userData = response.data.data.user;
        setCurrentUser(userData);
        
        setFormData(prev => ({
          ...prev,
          requested_by: userData.name,
          department: userData.department || ""
        }));
        
        console.log("User data loaded:", {
          name: userData.name,
          department: userData.department,
          roles: userData.roles,
          permissions: userData.permissions,
          employee_uuid: userData.employee_uuid,
          isSuperAdmin: userData.roles.includes('super-admin'),
          isWarehouseStaff: isWarehouseStaff()
        });
      }
    } catch (error) {
      console.error("Error fetching current user:", error);
      Swal.fire("Error", "Gagal mengambil data user", "error");
    }
  };

  const fetchDepartmentHeads = async () => {
    try {
      console.log("🔄 Fetching department heads...");
      const response = await api_laravel.get("/api/departments");
      
      if (response.data.success) {
        const heads: DepartmentHead = {};
        
        response.data.data.forEach((dept: any) => {
          if (dept.employee_id) {
            heads[dept.name] = dept.employee_id.toString();
          }
        });
        
        setDepartmentHeads(heads);
        console.log("🎯 Final departmentHeads:", heads);
      }
    } catch (error) {
      console.error("❌ Error fetching department heads:", error);
      setDepartmentHeads({});
    }
  };

  const fetchNotifications = async () => {
    try {
      const response = await api_laravel.get("/api/notifications");
      if (response.data.success) {
        setNotifications(response.data.data);
        const unread = response.data.data.filter((notif: Notification) => !notif.is_read).length;
        setUnreadCount(unread);
      }
    } catch (error) {
      console.error("Error fetching notifications:", error);
    }
  };

  // Fetch requests dengan filter berdasarkan role
  const fetchRequests = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (searchTerm) params.append('search', searchTerm);
      if (selectedStatus !== 'All') params.append('status', selectedStatus);
      if (selectedPriority !== 'All') params.append('priority', selectedPriority);

      // Super admin dan warehouse tidak perlu filter department
      if (!hasGlobalView() && currentUser?.department) {
        params.append('department', currentUser.department);
      }

      const response = await api_laravel.get(`/api/inventory-requests?${params.toString()}`);
      
      if (response.data.success) {
        let filteredRequests = response.data.data;
        
        // Filter tambahan untuk non-global view users
        if (!hasGlobalView() && currentUser?.department) {
          filteredRequests = filteredRequests.filter((request: InventoryRequest) => 
            request.department === currentUser.department
          );
        }
        
        setRequests(filteredRequests);
        console.log(`Loaded ${filteredRequests.length} requests - Global View: ${hasGlobalView()}`);
      }
    } catch (error: any) {
      console.error("Error fetching requests:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal mengambil data permintaan", "error");
    } finally {
      setLoading(false);
    }
  };

  // Fetch inventories for dropdown
  const fetchInventories = async () => {
    try {
      const response = await api_laravel.get("/api/inventories?status=active");
      if (response.data.success) {
        setInventories(response.data.data);
      }
    } catch (error) {
      console.error("Error fetching inventories:", error);
    }
  };

  // Generate automatic request number
  const generateRequestNumber = async () => {
    try {
      const response = await api_laravel.get("/api/inventory-requests/last-number");
      if (response.data.success) {
        return response.data.data.next_number;
      }
    } catch (error) {
      console.error("Error generating request number:", error);
    }
    
    // Fallback
    if (requests.length > 0) {
      const lastNumber = requests[requests.length - 1].request_number;
      const match = lastNumber.match(/([A-Za-z]+)-?(\d+)/);
      if (match && match.length >= 3) {
        const prefix = match[1] || 'REQ';
        const number = parseInt(match[2]) + 1;
        return `${prefix}-${number.toString().padStart(4, '0')}`;
      }
    }
    
    return "REQ-0001";
  };

  useEffect(() => {
    fetchCurrentUser();
    fetchInventories();
    fetchDepartmentHeads();
  }, []);

  // Fetch requests ketika currentUser sudah terload
  useEffect(() => {
    if (currentUser) {
      fetchRequests();
      fetchNotifications();
    }
  }, [currentUser, searchTerm, selectedStatus, selectedPriority]);

  // Search debounce
  useEffect(() => {
    const delayDebounce = setTimeout(() => {
      if (currentUser) {
        fetchRequests();
      }
    }, 500);

    return () => clearTimeout(delayDebounce);
  }, [searchTerm, selectedStatus, selectedPriority]);

  const resetForm = async () => {
    setFormData({
      requested_by: currentUser?.name || "",
      department: currentUser?.department || "",
      priority: "medium",
      notes: "",
      items: [{ inventory_id: 0, quantity: 1, purpose: "" }]
    });
  };

  const handleAddItem = () => {
    setFormData({
      ...formData,
      items: [...formData.items, { inventory_id: 0, quantity: 1, purpose: "" }]
    });
  };

  const handleRemoveItem = (index: number) => {
    const newItems = formData.items.filter((_, i) => i !== index);
    setFormData({ ...formData, items: newItems });
  };

  const handleItemChange = (index: number, field: string, value: any) => {
    const newItems = [...formData.items];
    newItems[index] = { ...newItems[index], [field]: value };
    setFormData({ ...formData, items: newItems });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // Validation
    if (formData.items.length === 0) {
      Swal.fire("Error", "Minimal harus ada satu item permintaan", "error");
      return;
    }

    for (const item of formData.items) {
      if (item.inventory_id === 0 || item.quantity <= 0) {
        Swal.fire("Error", "Semua item harus memiliki inventory dan quantity yang valid", "error");
        return;
      }
    }

    try {
      const requestData = {
        ...formData,
        request_number: await generateRequestNumber()
      };

      const response = await api_laravel.post("/api/inventory-requests", requestData);
      if (response.data.success) {
        Swal.fire({
          title: "Success",
          text: "Permintaan inventory berhasil dibuat",
          icon: "success",
          timer: 2000,
          showConfirmButton: false
        });
        setOpenDialog(false);
        resetForm();
        fetchRequests();
      }
    } catch (error: any) {
      console.error("Error creating request:", error);
      const errorMessage = error.response?.data?.message || "Gagal membuat permintaan";
      const errors = error.response?.data?.errors;
      
      if (errors) {
        let errorText = "";
        Object.keys(errors).forEach(key => {
          errorText += `${errors[key].join(', ')}\n`;
        });
        Swal.fire("Error", errorText, "error");
      } else {
        Swal.fire("Error", errorMessage, "error");
      }
    }
  };

  const handleReduceStock = async (requestId: number) => {
    try {
      const request = requests.find(req => req.id === requestId);
      if (!request) {
        console.error("Request not found for ID:", requestId);
        return;
      }

      console.log("🔍 Reducing stock for request:", {
        requestId: request.id,
        inventoryId: request.inventory_id,
        quantity: request.quantity,
        inventoryName: request.inventory?.name
      });

      const reduceStockData = {
        inventory_id: request.inventory_id,
        quantity: request.quantity,
        type: 'outgoing',
        notes: `Stock reduced for completed request: ${request.request_number}`,
        completed_by: currentUser?.name || "System"
      };

      // ✅ GUNAKAN ENDPOINT YANG BARU
      const response = await api_laravel.post("/api/inventory/reduce-stock", reduceStockData);
      
      if (response.data.success) {
        console.log("✅ Stock successfully reduced:", {
          inventory: request.inventory?.name,
          quantity: request.quantity,
          newStock: response.data.data.new_stock
        });
        
        fetchInventories();
      } else {
        console.error("❌ Failed to reduce stock:", response.data);
        Swal.fire("Warning", "Gagal mengurangi stock inventory", "warning");
      }
    } catch (error: any) {
      console.error("❌ Error reducing stock:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal mengurangi stock inventory", "error");
    }
  };

  const handleStatusUpdate = async (requestId: number, status: 'approved' | 'rejected' | 'completed') => {
    try {
      const updateData = status === 'approved' 
        ? { 
            status, 
            approved_by: currentUser?.name || "System" 
          }
        : { status };

      const response = await api_laravel.put(`/api/inventory-requests/${requestId}`, updateData);
      if (response.data.success) {
        Swal.fire({
          title: "Success",
          text: `Permintaan berhasil di${status}`,
          icon: "success",
          timer: 2000,
          showConfirmButton: false
        });
        
        if (status === 'approved') {
          await handleAutoIssue(requestId);
        }
        
        if (status === 'completed') {
          await handleReduceStock(requestId);
        }
        
        fetchRequests();
      }
    } catch (error: any) {
      console.error("Error updating request:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal mengupdate permintaan", "error");
    }
  };

  const handleAutoIssue = async (requestId: number) => {
    try {
      const request = requests.find(req => req.id === requestId);
      if (!request) return;

      const issueNumber = await generateIssueNumber();
      
      const issueData = {
        issue_number: issueNumber,
        request_id: requestId,
        issued_by: currentUser?.name || "System",
        notes: `Auto issued untuk request: ${request.request_number}`,
        items: [{
          inventory_id: request.inventory_id,
          quantity: request.quantity,
          purpose: request.purpose
        }]
      };

      const response = await api_laravel.post("/api/issues", issueData);
      if (response.data.success) {
        console.log("Barang berhasil di-issued otomatis");
      }
    } catch (error) {
      console.error("Error auto issuing:", error);
    }
  };

  const generateIssueNumber = async () => {
    try {
      const response = await api_laravel.get("/api/issues/last-number");
      if (response.data.success) {
        return response.data.data.next_number;
      }
    } catch (error) {
      console.error("Error generating issue number:", error);
    }
    return "ISS-0001";
  };

  const handleDelete = async () => {
    if (!deleteId) return;

    try {
      const response = await api_laravel.delete(`/api/inventory-requests/${deleteId}`);
      if (response.data.success) {
        Swal.fire({
          title: "Success",
          text: "Permintaan berhasil dihapus",
          icon: "success",
          timer: 2000,
          showConfirmButton: false
        });
        setOpenDeleteDialog(false);
        setDeleteId(null);
        fetchRequests();
      }
    } catch (error: any) {
      console.error("Error deleting request:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal menghapus permintaan", "error");
    }
  };

  const getStatusBadge = (status: string) => {
    const variants = {
      pending: "bg-yellow-100 text-yellow-800",
      approved: "bg-blue-100 text-blue-800",
      rejected: "bg-red-100 text-red-800",
      completed: "bg-green-100 text-green-800"
    };
    return variants[status as keyof typeof variants] || "bg-gray-100 text-gray-800";
  };

  const getPriorityBadge = (priority: string) => {
    const variants = {
      low: "bg-gray-100 text-gray-800",
      medium: "bg-blue-100 text-blue-800",
      high: "bg-red-100 text-red-800"
    };
    return variants[priority as keyof typeof variants] || "bg-gray-100 text-gray-800";
  };

  const getStatusText = (status: string) => {
    const texts = {
      pending: "Menunggu",
      approved: "Disetujui",
      rejected: "Ditolak",
      completed: "Selesai"
    };
    return texts[status as keyof typeof texts] || status;
  };

  const getPriorityText = (priority: string) => {
    const texts = {
      low: "Rendah",
      medium: "Sedang",
      high: "Tinggi"
    };
    return texts[priority as keyof typeof texts] || priority;
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('id-ID', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  const markAsRead = async (notificationId: number) => {
    try {
      await api_laravel.put(`/api/notifications/${notificationId}/read`);
      fetchNotifications();
    } catch (error) {
      console.error("Error marking notification as read:", error);
    }
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex justify-between items-center">
            <div>
              <CardTitle className="flex items-center">
                <ClipboardList className="h-6 w-6 mr-2" />
                Request Inventory
                {isSuperAdmin() && (
                  <Badge variant="outline" className="ml-2 bg-purple-100 text-purple-800">
                    Super Admin
                  </Badge>
                )}
                {isWarehouseStaff() && (
                  <Badge variant="outline" className="ml-2 bg-blue-100 text-blue-800">
                    Warehouse Staff
                  </Badge>
                )}
                {currentUser?.department && isDepartmentHead(currentUser.department) && (
                  <Badge variant="outline" className="ml-2 bg-orange-100 text-orange-800">
                    Department Head
                  </Badge>
                )}
              </CardTitle>
              <p className="text-muted-foreground">
                {hasGlobalView() 
                  ? "Anda dapat melihat semua request dari semua department" 
                  : `Anda hanya dapat melihat dan mengelola request dari department: ${currentUser?.department}`
                }
                {currentUser && ` - Login sebagai: ${currentUser.name}`}
              </p>
              {/* Debug info - hanya di development */}
              {process.env.NODE_ENV === 'development' && (
                <div className="text-xs text-gray-500 mt-2">
                  <div>Roles: {currentUser?.roles?.join(', ') || 'None'}</div>
                  <div>Permissions: {currentUser?.permissions?.join(', ') || 'None'}</div>
                  <div>Department Heads Loaded: {Object.keys(departmentHeads).length}</div>
                  <div>Global View: {hasGlobalView() ? 'Yes' : 'No'}</div>
                </div>
              )}
            </div>
            <Dialog open={openDialog} onOpenChange={setOpenDialog}>
              <DialogTrigger asChild>
                <Button onClick={resetForm}>
                  <Plus className="h-4 w-4 mr-2" />
                  Buat Request
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto bg-white">
                <DialogHeader>
                  <DialogTitle>Buat Request Inventory Baru</DialogTitle>
                </DialogHeader>
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Request By *</label>
                      <Input
                        value={formData.requested_by}
                        onChange={(e) => setFormData({...formData, requested_by: e.target.value})}
                        placeholder="Nama pemohon"
                        required
                        readOnly
                        className="bg-gray-50"
                      />
                      <p className="text-xs text-muted-foreground">Diambil dari data user login: {currentUser?.name}</p>
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Department *</label>
                      <Input
                        value={formData.department}
                        onChange={(e) => setFormData({...formData, department: e.target.value})}
                        placeholder="Department pemohon"
                        required
                        readOnly
                        className="bg-gray-50"
                      />
                      <p className="text-xs text-muted-foreground">Diambil dari data user login: {currentUser?.department}</p>
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Priority *</label>
                      <select
                        value={formData.priority}
                        onChange={(e) => setFormData({...formData, priority: e.target.value as "low" | "medium" | "high"})}
                        className="w-full border rounded-md px-3 py-2"
                        required
                      >
                        <option value="low">Low</option>
                        <option value="medium">Medium</option>
                        <option value="high">High</option>
                      </select>
                    </div>
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium">Notes</label>
                    <textarea
                      value={formData.notes}
                      onChange={(e) => setFormData({...formData, notes: e.target.value})}
                      className="w-full border rounded-md px-3 py-2 min-h-[80px]"
                      placeholder="Catatan tambahan..."
                    />
                  </div>

                  {/* Items Section */}
                  <div className="space-y-4">
                    <div className="flex justify-between items-center">
                      <label className="text-sm font-medium">Items *</label>
                      <Button type="button" variant="outline" size="sm" onClick={handleAddItem}>
                        <Plus className="h-4 w-4 mr-1" />
                        Tambah Item
                      </Button>
                    </div>

                    {formData.items.map((item, index) => (
                      <div key={index} className="border rounded-lg p-4 space-y-3">
                        <div className="flex justify-between items-start">
                          <h4 className="font-medium">Item {index + 1}</h4>
                          {formData.items.length > 1 && (
                            <Button
                              type="button"
                              variant="outline"
                              size="sm"
                              className="text-red-600 hover:text-red-700"
                              onClick={() => handleRemoveItem(index)}
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          )}
                        </div>

                        <div className="grid grid-cols-3 gap-4">
                          <div className="space-y-2">
                            <label className="text-sm font-medium">Inventory *</label>
                            <select
                              value={item.inventory_id}
                              onChange={(e) => handleItemChange(index, 'inventory_id', parseInt(e.target.value))}
                              className="w-full border rounded-md px-3 py-2"
                              required
                            >
                              <option value={0}>Pilih Inventory</option>
                              {inventories.map((inventory) => (
                                <option key={inventory.id} value={inventory.id}>
                                  {inventory.code} - {inventory.name}
                                </option>
                              ))}
                            </select>
                          </div>

                          <div className="space-y-2">
                            <label className="text-sm font-medium">Quantity *</label>
                            <Input
                              type="number"
                              value={item.quantity}
                              onChange={(e) => handleItemChange(index, 'quantity', parseInt(e.target.value) || 1)}
                              min="1"
                              required
                            />
                          </div>

                          <div className="space-y-2">
                            <label className="text-sm font-medium">Purpose *</label>
                            <Input
                              value={item.purpose}
                              onChange={(e) => handleItemChange(index, 'purpose', e.target.value)}
                              placeholder="Tujuan penggunaan"
                              required
                            />
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>

                  <div className="flex justify-end space-x-2 pt-4">
                    <Button
                      type="button"
                      variant="outline"
                      onClick={() => setOpenDialog(false)}
                    >
                      Batal
                    </Button>
                    <Button type="submit">
                      Simpan Request
                    </Button>
                  </div>
                </form>
              </DialogContent>
            </Dialog>
          </div>
        </CardHeader>
        <CardContent>
          {/* Search & Filter */}
          <div className="flex flex-col sm:flex-row gap-4 mb-6">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Cari nomor request, pemohon, atau department..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
            <select
              value={selectedStatus}
              onChange={(e) => setSelectedStatus(e.target.value)}
              className="border rounded-md px-3 py-2"
            >
              <option value="All">Semua Status</option>
              <option value="pending">Menunggu</option>
              <option value="approved">Disetujui</option>
              <option value="rejected">Ditolak</option>
              <option value="completed">Selesai</option>
            </select>
            <select
              value={selectedPriority}
              onChange={(e) => setSelectedPriority(e.target.value)}
              className="border rounded-md px-3 py-2"
            >
              <option value="All">Semua Priority</option>
              <option value="low">Rendah</option>
              <option value="medium">Sedang</option>
              <option value="high">Tinggi</option>
            </select>
            <Button variant="outline" className="flex items-center" onClick={fetchRequests}>
              <Filter className="h-4 w-4 mr-2" />
              Filter
            </Button>
          </div>

          {/* Requests Table */}
          <div className="border rounded-lg">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>No. Request</TableHead>
                  <TableHead>Pemohon</TableHead>
                  <TableHead>Department</TableHead>
                  <TableHead>Jumlah Item</TableHead>
                  <TableHead>Priority</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Tanggal</TableHead>
                  <TableHead>Aksi</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading ? (
                  <TableRow>
                    <TableCell colSpan={8} className="text-center py-4">
                      Loading...
                    </TableCell>
                  </TableRow>
                ) : requests.length > 0 ? (
                  requests
                    .filter(request => canViewRequest(request.department))
                    .map((request) => {
                      const canApprove = canApproveRequest(request.department);
                      const canPerform = canPerformAction(request.department);
                      const canComplete = canCompleteRequest(request.department);
                      
                      if (process.env.NODE_ENV === 'development') {
                        console.log(`Request ${request.request_number}:`, {
                          department: request.department,
                          status: request.status,
                          canApprove,
                          canPerform,
                          canComplete,
                          userDepartment: currentUser?.department,
                          isSuperAdmin: isSuperAdmin(),
                          isWarehouseStaff: isWarehouseStaff(),
                          hasGlobalView: hasGlobalView()
                        });
                      }

                      return (
                        <TableRow key={request.id}>
                          <TableCell className="font-medium">{request.request_number}</TableCell>
                          <TableCell>{request.requested_by}</TableCell>
                          <TableCell>{request.department}</TableCell>
                          <TableCell>
                            <Badge variant="outline">
                              {request.quantity} item
                            </Badge>
                          </TableCell>
                          <TableCell>
                            <Badge className={getPriorityBadge(request.priority)}>
                              {getPriorityText(request.priority)}
                            </Badge>
                          </TableCell>
                          <TableCell>
                            <Badge className={getStatusBadge(request.status)}>
                              {getStatusText(request.status)}
                            </Badge>
                          </TableCell>
                          <TableCell>{formatDate(request.created_at)}</TableCell>
                          <TableCell>
                            <div className="flex space-x-2">
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => {
                                  setSelectedRequest(request);
                                  setOpenDetailDialog(true);
                                }}
                              >
                                <Eye className="h-4 w-4" />
                              </Button>
                              
                              {/* Tombol Approve/Reject hanya untuk request pending dan user yang berwenang */}
                              {request.status === 'pending' && canApprove && (
                                <>
                                  <Button
                                    variant="outline"
                                    size="sm"
                                    className="text-green-600 hover:text-green-700 border-green-600"
                                    onClick={() => handleStatusUpdate(request.id, 'approved')}
                                  >
                                    Approve
                                  </Button>
                                  <Button
                                    variant="outline"
                                    size="sm"
                                    className="text-red-600 hover:text-red-700 border-red-600"
                                    onClick={() => handleStatusUpdate(request.id, 'rejected')}
                                  >
                                    Reject
                                  </Button>
                                </>
                              )}

                              {/* Tombol Complete hanya untuk request approved dan user yang berwenang */}
                              {request.status === 'approved' && canComplete && (
                                <Button
                                  variant="outline"
                                  size="sm"
                                  className="text-blue-600 hover:text-blue-700 border-blue-600"
                                  onClick={() => handleStatusUpdate(request.id, 'completed')}
                                >
                                  Complete
                                </Button>
                              )}

                              {/* Tombol Delete hanya untuk user yang berwenang dan request belum completed */}
                              {canPerform && request.status !== 'completed' && (
                                <Button
                                  variant="outline"
                                  size="sm"
                                  className="text-red-600 hover:text-red-700 border-red-600"
                                  onClick={() => {
                                    setDeleteId(request.id);
                                    setOpenDeleteDialog(true);
                                  }}
                                >
                                  <Trash2 className="h-4 w-4" />
                                </Button>
                              )}
                            </div>
                          </TableCell>
                        </TableRow>
                      );
                    })
                ) : (
                  <TableRow>
                    <TableCell colSpan={8} className="text-center py-4">
                      {currentUser 
                        ? hasGlobalView() 
                          ? "Tidak ada data permintaan" 
                          : `Tidak ada data permintaan untuk department ${currentUser.department}`
                        : "Loading user data..."
                      }
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      {/* Detail Dialog */}
      <Dialog open={openDetailDialog} onOpenChange={setOpenDetailDialog}>
        <DialogContent className="max-w-3xl bg-white">
          <DialogHeader>
            <DialogTitle>Detail Request Inventory</DialogTitle>
          </DialogHeader>
          {selectedRequest && canViewRequest(selectedRequest.department) ? (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium">No. Request</label>
                  <p className="font-semibold">{selectedRequest.request_number}</p>
                </div>
                <div>
                  <label className="text-sm font-medium">Tanggal</label>
                  <p>{formatDate(selectedRequest.created_at)}</p>
                </div>
                <div>
                  <label className="text-sm font-medium">Pemohon</label>
                  <p>{selectedRequest.requested_by}</p>
                </div>
                <div>
                  <label className="text-sm font-medium">Department</label>
                  <p>{selectedRequest.department}</p>
                </div>
                <div>
                  <label className="text-sm font-medium">Priority</label>
                  <Badge className={getPriorityBadge(selectedRequest.priority)}>
                    {getPriorityText(selectedRequest.priority)}
                  </Badge>
                </div>
                <div>
                  <label className="text-sm font-medium">Status</label>
                  <Badge className={getStatusBadge(selectedRequest.status)}>
                    {getStatusText(selectedRequest.status)}
                  </Badge>
                </div>
              </div>

              <div>
                <label className="text-sm font-medium">Catatan</label>
                <p className="border rounded-md p-3 bg-gray-50">
                  {selectedRequest.notes || "-"}
                </p>
              </div>

              {selectedRequest.approved_by && (
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-sm font-medium">Disetujui Oleh</label>
                    <p>{selectedRequest.approved_by}</p>
                  </div>
                  <div>
                    <label className="text-sm font-medium">Tanggal Persetujuan</label>
                    <p>{selectedRequest.approved_at ? formatDate(selectedRequest.approved_at) : "-"}</p>
                  </div>
                </div>
              )}

              <div>
                <label className="text-sm font-medium">Item Request</label>
                <div className="border rounded-md">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Kode Barang</TableHead>
                        <TableHead>Nama Barang</TableHead>
                        <TableHead>Quantity</TableHead>
                        <TableHead>Tujuan</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      <TableRow>
                        <TableCell>{selectedRequest.inventory?.code}</TableCell>
                        <TableCell>{selectedRequest.inventory?.name}</TableCell>
                        <TableCell>{selectedRequest.quantity} {selectedRequest.inventory?.unit}</TableCell>
                        <TableCell>{selectedRequest.purpose}</TableCell>
                      </TableRow>
                    </TableBody>
                  </Table>
                </div>
              </div>
            </div>
          ) : (
            <div className="text-center py-8">
              <p className="text-muted-foreground">Anda tidak memiliki akses untuk melihat detail request ini.</p>
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={openDeleteDialog} onOpenChange={setOpenDeleteDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Hapus Request</AlertDialogTitle>
            <AlertDialogDescription>
              Apakah Anda yakin ingin menghapus request ini? Tindakan ini tidak dapat dibatalkan.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Batal</AlertDialogCancel>
            <AlertDialogAction 
              onClick={handleDelete}
              className="bg-red-600 hover:bg-red-700"
            >
              Hapus
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}