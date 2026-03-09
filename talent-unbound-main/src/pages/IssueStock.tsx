"use client";

import { useState, useEffect } from "react";
import { Plus, Search, Filter, Edit, Trash2, Package, ArrowUpRight } from "lucide-react";
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

interface StockIssue {
  id: number;
  issue_code: string;
  inventory_id: number;
  quantity: number;
  issue_date: string;
  issued_to: string;
  department?: string;
  purpose: string;
  notes?: string;
  status: 'issued' | 'returned' | 'cancelled';
  issued_by?: string;
  created_at?: string;
  updated_at?: string;
  inventory?: {
    id: number;
    code: string;
    name: string;
    unit: string;
    stock: number;
  };
}

interface Inventory {
  id: number;
  code: string;
  name: string;
  unit: string;
  stock: number;
}

export default function IssueStock() {
  const [stockIssues, setStockIssues] = useState<StockIssue[]>([]);
  const [inventories, setInventories] = useState<Inventory[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedStatus, setSelectedStatus] = useState("All");
  const [openDialog, setOpenDialog] = useState(false);
  const [openDeleteDialog, setOpenDeleteDialog] = useState(false);
  const [editingIssue, setEditingIssue] = useState<StockIssue | null>(null);
  const [deleteId, setDeleteId] = useState<number | null>(null);
  const [formData, setFormData] = useState({
    inventory_id: "",
    quantity: 1,
    issue_date: new Date().toISOString().split('T')[0],
    issued_to: "",
    department: "",
    purpose: "",
    notes: "",
    issued_by: "",
    status: "issued" as "issued" | "returned" | "cancelled"
  });

  // Fetch stock issues
  const fetchStockIssues = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (searchTerm) params.append('search', searchTerm);
      if (selectedStatus !== 'All') params.append('status', selectedStatus);

      const response = await api_laravel.get(`/api/stock-issues?${params.toString()}`);
      
      if (response.data.success) {
        setStockIssues(response.data.data);
      }
    } catch (error: any) {
      console.error("Error fetching stock issues:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal mengambil data issue stock", "error");
    } finally {
      setLoading(false);
    }
  };

  // Fetch inventories for dropdown
  const fetchInventories = async () => {
    try {
      const response = await api_laravel.get("/api/stock-issues-inventories");
      if (response.data.success) {
        setInventories(response.data.data);
      }
    } catch (error) {
      console.error("Error fetching inventories:", error);
    }
  };

  useEffect(() => {
    fetchStockIssues();
    fetchInventories();
  }, []);

  // Search debounce
  useEffect(() => {
    const delayDebounce = setTimeout(() => {
      fetchStockIssues();
    }, 500);

    return () => clearTimeout(delayDebounce);
  }, [searchTerm, selectedStatus]);

  const resetForm = () => {
    setFormData({
      inventory_id: "",
      quantity: 1,
      issue_date: new Date().toISOString().split('T')[0],
      issued_to: "",
      department: "",
      purpose: "",
      notes: "",
      issued_by: "",
      status: "issued"
    });
    setEditingIssue(null);
  };

  const handleEdit = (issue: StockIssue) => {
    setEditingIssue(issue);
    setFormData({
      inventory_id: issue.inventory_id.toString(),
      quantity: issue.quantity,
      issue_date: issue.issue_date,
      issued_to: issue.issued_to,
      department: issue.department || "",
      purpose: issue.purpose,
      notes: issue.notes || "",
      issued_by: issue.issued_by || "",
      status: issue.status
    });
    setOpenDialog(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      if (editingIssue) {
        // Update
        const response = await api_laravel.put(`/api/stock-issues/${editingIssue.id}`, formData);
        if (response.data.success) {
          Swal.fire("Success", "Issue stock berhasil diupdate", "success");
          setOpenDialog(false);
          resetForm();
          fetchStockIssues();
        }
      } else {
        // Create
        const response = await api_laravel.post("/api/stock-issues", formData);
        if (response.data.success) {
          Swal.fire("Success", "Stock berhasil di-issue", "success");
          setOpenDialog(false);
          resetForm();
          fetchStockIssues();
          fetchInventories(); // Refresh inventory stock data
        }
      }
    } catch (error: any) {
      console.error("Error saving stock issue:", error);
      const errorMessage = error.response?.data?.message || "Gagal menyimpan issue stock";
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

  const handleDelete = async () => {
    if (!deleteId) return;

    try {
      const response = await api_laravel.delete(`/api/stock-issues/${deleteId}`);
      if (response.data.success) {
        Swal.fire("Success", "Issue stock berhasil dihapus", "success");
        setOpenDeleteDialog(false);
        setDeleteId(null);
        fetchStockIssues();
        fetchInventories(); // Refresh inventory stock data
      }
    } catch (error: any) {
      console.error("Error deleting stock issue:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal menghapus issue stock", "error");
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'issued':
        return <Badge className="bg-blue-100 text-blue-800">Issued</Badge>;
      case 'returned':
        return <Badge className="bg-green-100 text-green-800">Returned</Badge>;
      case 'cancelled':
        return <Badge className="bg-red-100 text-red-800">Cancelled</Badge>;
      default:
        return <Badge variant="secondary">{status}</Badge>;
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('id-ID', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex justify-between items-center">
            <div>
              <CardTitle className="flex items-center">
                <ArrowUpRight className="h-6 w-6 mr-2" />
                Issue Stock
              </CardTitle>
              <p className="text-muted-foreground">Kelola pengeluaran dan pengembalian stock barang</p>
            </div>
            <Dialog open={openDialog} onOpenChange={setOpenDialog}>
              <DialogTrigger asChild>
                <Button onClick={resetForm}>
                  <Plus className="h-4 w-4 mr-2" />
                  Issue Stock
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto bg-white">
                <DialogHeader>
                  <DialogTitle>
                    {editingIssue ? 'Edit Issue Stock' : 'Issue Stock Baru'}
                  </DialogTitle>
                </DialogHeader>
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Barang *</label>
                      <select
                        value={formData.inventory_id}
                        onChange={(e) => setFormData({...formData, inventory_id: e.target.value})}
                        className="w-full border rounded-md px-3 py-2"
                        required
                        disabled={!!editingIssue}
                      >
                        <option value="">Pilih Barang</option>
                        {inventories.map((inventory) => (
                          <option key={inventory.id} value={inventory.id}>
                            {inventory.code} - {inventory.name} (Stok: {inventory.stock} {inventory.unit})
                          </option>
                        ))}
                      </select>
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Quantity *</label>
                      <Input
                        type="number"
                        value={formData.quantity}
                        onChange={(e) => setFormData({...formData, quantity: parseInt(e.target.value) || 1})}
                        min="1"
                        required
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Tanggal Issue *</label>
                      <Input
                        type="date"
                        value={formData.issue_date}
                        onChange={(e) => setFormData({...formData, issue_date: e.target.value})}
                        required
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Diberikan Kepada *</label>
                      <Input
                        value={formData.issued_to}
                        onChange={(e) => setFormData({...formData, issued_to: e.target.value})}
                        placeholder="Nama penerima"
                        required
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Department</label>
                      <Input
                        value={formData.department}
                        onChange={(e) => setFormData({...formData, department: e.target.value})}
                        placeholder="Department penerima"
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Status</label>
                      <select
                        value={formData.status}
                        onChange={(e) => setFormData({...formData, status: e.target.value as "issued" | "returned" | "cancelled"})}
                        className="w-full border rounded-md px-3 py-2"
                        required
                      >
                        <option value="issued">Issued</option>
                        <option value="returned">Returned</option>
                        <option value="cancelled">Cancelled</option>
                      </select>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <label className="text-sm font-medium">Tujuan *</label>
                    <Input
                      value={formData.purpose}
                      onChange={(e) => setFormData({...formData, purpose: e.target.value})}
                      placeholder="Tujuan pengeluaran stock"
                      required
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="text-sm font-medium">Issued By</label>
                    <Input
                      value={formData.issued_by}
                      onChange={(e) => setFormData({...formData, issued_by: e.target.value})}
                      placeholder="Nama yang mengissue"
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="text-sm font-medium">Catatan</label>
                    <textarea
                      value={formData.notes}
                      onChange={(e) => setFormData({...formData, notes: e.target.value})}
                      className="w-full border rounded-md px-3 py-2 min-h-[80px]"
                      placeholder="Catatan tambahan..."
                    />
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
                      {editingIssue ? 'Update' : 'Issue Stock'}
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
                placeholder="Cari kode issue, penerima, atau tujuan..."
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
              <option value="issued">Issued</option>
              <option value="returned">Returned</option>
              <option value="cancelled">Cancelled</option>
            </select>
            <Button variant="outline" className="flex items-center">
              <Filter className="h-4 w-4 mr-2" />
              Filter
            </Button>
          </div>

          {/* Stock Issues Table */}
          <div className="border rounded-lg">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Kode Issue</TableHead>
                  <TableHead>Barang</TableHead>
                  <TableHead>Quantity</TableHead>
                  <TableHead>Penerima</TableHead>
                  <TableHead>Tanggal</TableHead>
                  <TableHead>Tujuan</TableHead>
                  <TableHead>Status</TableHead>
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
                ) : stockIssues.length > 0 ? (
                  stockIssues.map((issue) => (
                    <TableRow key={issue.id}>
                      <TableCell className="font-medium">{issue.issue_code}</TableCell>
                      <TableCell>
                        <div>
                          <div className="font-medium">{issue.inventory?.name}</div>
                          <div className="text-sm text-muted-foreground">
                            {issue.inventory?.code} • {issue.inventory?.unit}
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        {issue.quantity} {issue.inventory?.unit}
                      </TableCell>
                      <TableCell>
                        <div>
                          <div className="font-medium">{issue.issued_to}</div>
                          {issue.department && (
                            <div className="text-sm text-muted-foreground">
                              {issue.department}
                            </div>
                          )}
                        </div>
                      </TableCell>
                      <TableCell>{formatDate(issue.issue_date)}</TableCell>
                      <TableCell className="max-w-xs truncate">
                        {issue.purpose}
                      </TableCell>
                      <TableCell>
                        {getStatusBadge(issue.status)}
                      </TableCell>
                      <TableCell>
                        <div className="flex space-x-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleEdit(issue)}
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="outline"
                            size="sm"
                            className="text-red-600 hover:text-red-700"
                            onClick={() => {
                              setDeleteId(issue.id);
                              setOpenDeleteDialog(true);
                            }}
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))
                ) : (
                  <TableRow>
                    <TableCell colSpan={8} className="text-center py-4">
                      Tidak ada data issue stock
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={openDeleteDialog} onOpenChange={setOpenDeleteDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Hapus Issue Stock</AlertDialogTitle>
            <AlertDialogDescription>
              Apakah Anda yakin ingin menghapus issue stock ini? Stock akan dikembalikan ke inventory.
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