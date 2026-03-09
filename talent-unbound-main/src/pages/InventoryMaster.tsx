"use client";

import { useState, useEffect } from "react";
import { Plus, Search, Filter, Edit, Trash2, Package } from "lucide-react";
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
  created_at?: string;
  updated_at?: string;
}

export default function InventoryMaster() {
  const [inventories, setInventories] = useState<Inventory[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("All");
  const [selectedStatus, setSelectedStatus] = useState("All");
  const [categories, setCategories] = useState<string[]>([]);
  const [openDialog, setOpenDialog] = useState(false);
  const [openDeleteDialog, setOpenDeleteDialog] = useState(false);
  const [editingInventory, setEditingInventory] = useState<Inventory | null>(null);
  const [deleteId, setDeleteId] = useState<number | null>(null);
  const [formData, setFormData] = useState({
    code: "",
    name: "",
    category: "",
    description: "",
    unit: "",
    stock: 0,
    min_stock: 0,
    max_stock: 0,
    purchase_price: 0,
    selling_price: 0,
    supplier: "",
    location: "",
    status: "active" as "active" | "inactive"
  });

  // Fetch inventories
  const fetchInventories = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (searchTerm) params.append('search', searchTerm);
      if (selectedCategory !== 'All') params.append('category', selectedCategory);
      if (selectedStatus !== 'All') params.append('status', selectedStatus);

      const response = await api_laravel.get(`/api/inventories?${params.toString()}`);
      
      if (response.data.success) {
        setInventories(response.data.data);
      }
    } catch (error: any) {
      console.error("Error fetching inventories:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal mengambil data inventory", "error");
    } finally {
      setLoading(false);
    }
  };

  // Fetch categories
  const fetchCategories = async () => {
    try {
      const response = await api_laravel.get("/api/inventories-categories");
      if (response.data.success) {
        setCategories(response.data.data);
      }
    } catch (error) {
      console.error("Error fetching categories:", error);
    }
  };


  // Generate automatic code
// Generate automatic code
const generateAutoCode = async () => {
  try {
    const response = await api_laravel.get("/api/inventories/last-code");
    console.log("API Response:", response.data); // Debug log
    if (response.data.success) {
      return response.data.data.next_code;
    }
  } catch (error) {
    console.error("Error generating code:", error);
  }
  
  // Fallback: generate code manually based on existing data
  if (inventories.length > 0) {
    const lastCode = inventories[inventories.length - 1].code;
    console.log("Last code from inventories:", lastCode); // Debug log
    // Pattern untuk format INV-0001
    const match = lastCode.match(/([A-Za-z]+)-?(\d+)/);
    if (match && match.length >= 3) {
      const prefix = match[1] || 'INV'; // 'INV'
      const number = parseInt(match[2]) + 1;
      const generatedCode = `${prefix}-${number.toString().padStart(4, '0')}`;
      console.log("Generated code:", generatedCode); // Debug log
      return generatedCode;
    }
  }
  
  // Default code if no data
  return "INV-0001";
};

  useEffect(() => {
    fetchInventories();
    fetchCategories();
  }, []);

  // Search debounce
  useEffect(() => {
    const delayDebounce = setTimeout(() => {
      fetchInventories();
    }, 500);

    return () => clearTimeout(delayDebounce);
  }, [searchTerm, selectedCategory, selectedStatus]);

  const resetForm = async () => {
    const autoCode = await generateAutoCode();
    setFormData({
      code: autoCode,
      name: "",
      category: "",
      description: "",
      unit: "",
      stock: 0,
      min_stock: 0,
      max_stock: 0,
      purchase_price: 0,
      selling_price: 0,
      supplier: "",
      location: "",
      status: "active"
    });
    setEditingInventory(null);
  };

  const handleEdit = (inventory: Inventory) => {
    setEditingInventory(inventory);
    setFormData({
      code: inventory.code,
      name: inventory.name,
      category: inventory.category,
      description: inventory.description || "",
      unit: inventory.unit,
      stock: inventory.stock,
      min_stock: inventory.min_stock,
      max_stock: inventory.max_stock,
      purchase_price: inventory.purchase_price,
      selling_price: inventory.selling_price,
      supplier: inventory.supplier || "",
      location: inventory.location || "",
      status: inventory.status
    });
    setOpenDialog(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      if (editingInventory) {
        // Update
        const response = await api_laravel.put(`/api/inventories/${editingInventory.id}`, formData);
        if (response.data.success) {
          Swal.fire("Success", "Inventory berhasil diupdate", "success");
          setOpenDialog(false);
          resetForm();
          fetchInventories();
        }
      } else {
        // Create
        const response = await api_laravel.post("/api/inventories", formData);
        if (response.data.success) {
          Swal.fire("Success", "Inventory berhasil dibuat", "success");
          setOpenDialog(false);
          resetForm();
          fetchInventories();
        }
      }
    } catch (error: any) {
      console.error("Error saving inventory:", error);
      const errorMessage = error.response?.data?.message || "Gagal menyimpan inventory";
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
      const response = await api_laravel.delete(`/api/inventories/${deleteId}`);
      if (response.data.success) {
        Swal.fire("Success", "Inventory berhasil dihapus", "success");
        setOpenDeleteDialog(false);
        setDeleteId(null);
        fetchInventories();
      }
    } catch (error: any) {
      console.error("Error deleting inventory:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal menghapus inventory", "error");
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0
    }).format(amount);
  };

  const getStockStatus = (stock: number, minStock: number, maxStock: number) => {
    if (stock <= minStock) {
      return { label: "Low Stock", variant: "destructive" };
    } else if (stock >= maxStock) {
      return { label: "Over Stock", variant: "warning" };
    } else {
      return { label: "Normal", variant: "success" };
    }
  };

  // Auto generate code when dialog opens for new inventory
  useEffect(() => {
    if (openDialog && !editingInventory) {
      const generateCode = async () => {
        const autoCode = await generateAutoCode();
        setFormData(prev => ({ ...prev, code: autoCode }));
      };
      generateCode();
    }
  }, [openDialog, editingInventory]);

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex justify-between items-center">
            <div>
              <CardTitle className="flex items-center">
                <Package className="h-6 w-6 mr-2" />
                Inventory Master
              </CardTitle>
              <p className="text-muted-foreground">Kelola data inventory dan stok barang</p>
            </div>
            <Dialog open={openDialog} onOpenChange={setOpenDialog}>
              <DialogTrigger asChild>
                <Button onClick={resetForm}>
                  <Plus className="h-4 w-4 mr-2" />
                  Tambah Inventory
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto bg-white">
                <DialogHeader>
                  <DialogTitle>
                    {editingInventory ? 'Edit Inventory' : 'Tambah Inventory Baru'}
                  </DialogTitle>
                </DialogHeader>
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Kode Barang *</label>
                      <Input
                        value={formData.code}
                        onChange={(e) => setFormData({...formData, code: e.target.value})}
                        placeholder="INV-0001"
                        required
                        readOnly={!editingInventory} // Readonly untuk tambah baru
                        className={!editingInventory ? "bg-gray-100" : ""}
                      />
                      {!editingInventory && (
                        <p className="text-xs text-muted-foreground">
                          Kode barang di-generate otomatis
                        </p>
                      )}
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Nama Barang *</label>
                      <Input
                        value={formData.name}
                        onChange={(e) => setFormData({...formData, name: e.target.value})}
                        placeholder="Nama barang"
                        required
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Kategori *</label>
                      <Input
                        value={formData.category}
                        onChange={(e) => setFormData({...formData, category: e.target.value})}
                        placeholder="Elektronik, ATK, dll"
                        required
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Satuan *</label>
                      <Input
                        value={formData.unit}
                        onChange={(e) => setFormData({...formData, unit: e.target.value})}
                        placeholder="Pcs, Unit, Box, dll"
                        required
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Stok *</label>
                      <Input
                        type="number"
                        value={formData.stock}
                        onChange={(e) => setFormData({...formData, stock: parseInt(e.target.value) || 0})}
                        min="0"
                        required
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Stok Minimum *</label>
                      <Input
                        type="number"
                        value={formData.min_stock}
                        onChange={(e) => setFormData({...formData, min_stock: parseInt(e.target.value) || 0})}
                        min="0"
                        required
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Stok Maksimum *</label>
                      <Input
                        type="number"
                        value={formData.max_stock}
                        onChange={(e) => setFormData({...formData, max_stock: parseInt(e.target.value) || 0})}
                        min="0"
                        required
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Harga Beli *</label>
                      <Input
                        type="number"
                        value={formData.purchase_price}
                        onChange={(e) => setFormData({...formData, purchase_price: parseFloat(e.target.value) || 0})}
                        min="0"
                        step="0.01"
                        required
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Harga Jual *</label>
                      <Input
                        type="number"
                        value={formData.selling_price}
                        onChange={(e) => setFormData({...formData, selling_price: parseFloat(e.target.value) || 0})}
                        min="0"
                        step="0.01"
                        required
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Supplier</label>
                      <Input
                        value={formData.supplier}
                        onChange={(e) => setFormData({...formData, supplier: e.target.value})}
                        placeholder="Nama supplier"
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Lokasi</label>
                      <Input
                        value={formData.location}
                        onChange={(e) => setFormData({...formData, location: e.target.value})}
                        placeholder="Gudang A, Rak B, dll"
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Status *</label>
                      <select
                        value={formData.status}
                        onChange={(e) => setFormData({...formData, status: e.target.value as "active" | "inactive"})}
                        className="w-full border rounded-md px-3 py-2"
                        required
                      >
                        <option value="active">Active</option>
                        <option value="inactive">Inactive</option>
                      </select>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <label className="text-sm font-medium">Deskripsi</label>
                    <textarea
                      value={formData.description}
                      onChange={(e) => setFormData({...formData, description: e.target.value})}
                      className="w-full border rounded-md px-3 py-2 min-h-[80px]"
                      placeholder="Deskripsi barang..."
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
                      {editingInventory ? 'Update' : 'Simpan'}
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
                placeholder="Cari kode, nama, atau kategori..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
            <select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className="border rounded-md px-3 py-2"
            >
              <option value="All">Semua Kategori</option>
              {categories.map((category) => (
                <option key={category} value={category}>{category}</option>
              ))}
            </select>
            <select
              value={selectedStatus}
              onChange={(e) => setSelectedStatus(e.target.value)}
              className="border rounded-md px-3 py-2"
            >
              <option value="All">Semua Status</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </select>
            <Button variant="outline" className="flex items-center">
              <Filter className="h-4 w-4 mr-2" />
              Filter
            </Button>
          </div>

          {/* Inventory Table */}
          <div className="border rounded-lg">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Kode</TableHead>
                  <TableHead>Nama Barang</TableHead>
                  <TableHead>Kategori</TableHead>
                  <TableHead>Stok</TableHead>
                  <TableHead>Harga Beli</TableHead>
                  <TableHead>Harga Jual</TableHead>
                  <TableHead>Status Stok</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Aksi</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading ? (
                  <TableRow>
                    <TableCell colSpan={9} className="text-center py-4">
                      Loading...
                    </TableCell>
                  </TableRow>
                ) : inventories.length > 0 ? (
                  inventories.map((inventory) => {
                    const stockStatus = getStockStatus(
                      inventory.stock,
                      inventory.min_stock,
                      inventory.max_stock
                    );
                    
                    return (
                      <TableRow key={inventory.id}>
                        <TableCell className="font-medium">{inventory.code}</TableCell>
                        <TableCell>
                          <div>
                            <div className="font-medium">{inventory.name}</div>
                            <div className="text-sm text-muted-foreground">
                              {inventory.unit} • {inventory.location || '-'}
                            </div>
                          </div>
                        </TableCell>
                        <TableCell>{inventory.category}</TableCell>
                        <TableCell>
                          <div className="flex items-center space-x-2">
                            <span>{inventory.stock}</span>
                            <span className="text-xs text-muted-foreground">
                              (min: {inventory.min_stock}, max: {inventory.max_stock})
                            </span>
                          </div>
                        </TableCell>
                        <TableCell>{formatCurrency(inventory.purchase_price)}</TableCell>
                        <TableCell>{formatCurrency(inventory.selling_price)}</TableCell>
                        <TableCell>
                          <Badge className={
                            stockStatus.variant === "destructive" ? "bg-red-100 text-red-800" :
                            stockStatus.variant === "warning" ? "bg-yellow-100 text-yellow-800" :
                            "bg-green-100 text-green-800"
                          }>
                            {stockStatus.label}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <Badge className={
                            inventory.status === "active" 
                              ? "bg-green-100 text-green-800" 
                              : "bg-gray-100 text-gray-800"
                          }>
                            {inventory.status === "active" ? "Active" : "Inactive"}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <div className="flex space-x-2">
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => handleEdit(inventory)}
                            >
                              <Edit className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="outline"
                              size="sm"
                              className="text-red-600 hover:text-red-700"
                              onClick={() => {
                                setDeleteId(inventory.id);
                                setOpenDeleteDialog(true);
                              }}
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    );
                  })
                ) : (
                  <TableRow>
                    <TableCell colSpan={9} className="text-center py-4">
                      Tidak ada data inventory
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
            <AlertDialogTitle>Hapus Inventory</AlertDialogTitle>
            <AlertDialogDescription>
              Apakah Anda yakin ingin menghapus inventory ini? Tindakan ini tidak dapat dibatalkan.
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