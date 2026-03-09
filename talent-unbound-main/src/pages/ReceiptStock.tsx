"use client";

import { useState, useEffect } from "react";
import { Plus, Search, Filter, Edit, Trash2, Package, ClipboardList, Eye, Upload, CheckCircle } from "lucide-react";
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

interface Receipt {
  id: number;
  receipt_number: string;
  inventory_id: number;
  inventory?: Inventory;
  quantity: number;
  received_by: string;
  supplier: string;
  purchase_price: number;
  total_price: number;
  receipt_date: string;
  notes?: string;
  status: 'draft' | 'received' | 'cancelled';
  created_by?: string;
  created_at: string;
  updated_at: string;
}

interface ReceiptItem {
  inventory_id: number;
  quantity: number;
  purchase_price: number;
  total_price: number;
  inventory?: Inventory;
}

export default function ReceiptStock() {
  const [receipts, setReceipts] = useState<Receipt[]>([]);
  const [inventories, setInventories] = useState<Inventory[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedStatus, setSelectedStatus] = useState("All");
  const [openDialog, setOpenDialog] = useState(false);
  const [openDetailDialog, setOpenDetailDialog] = useState(false);
  const [openReceiveDialog, setOpenReceiveDialog] = useState(false);
  const [openDeleteDialog, setOpenDeleteDialog] = useState(false);
  const [selectedReceipt, setSelectedReceipt] = useState<Receipt | null>(null);
  const [deleteId, setDeleteId] = useState<number | null>(null);
  const [formData, setFormData] = useState({
    received_by: "",
    supplier: "",
    receipt_date: new Date().toISOString().split('T')[0],
    notes: "",
    items: [] as ReceiptItem[]
  });

  // Fetch receipts
  const fetchReceipts = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (searchTerm) params.append('search', searchTerm);
      if (selectedStatus !== 'All') params.append('status', selectedStatus);

      const response = await api_laravel.get(`/api/receipts?${params.toString()}`);
      
      if (response.data.success) {
        setReceipts(response.data.data);
      }
    } catch (error: any) {
      console.error("Error fetching receipts:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal mengambil data penerimaan", "error");
    } finally {
      setLoading(false);
    }
  };

  // Fetch inventories for dropdown
  const fetchInventories = async () => {
    try {
      const response = await api_laravel.get("/api/inventories");
      if (response.data.success) {
        setInventories(response.data.data);
      }
    } catch (error) {
      console.error("Error fetching inventories:", error);
    }
  };

  // Generate automatic receipt number
  const generateReceiptNumber = async () => {
    try {
      const response = await api_laravel.get("/api/receipts/last-number");
      if (response.data.success) {
        return response.data.data.next_number;
      }
    } catch (error) {
      console.error("Error generating receipt number:", error);
    }
    
    // Fallback
    if (receipts.length > 0) {
      const lastNumber = receipts[receipts.length - 1].receipt_number;
      const match = lastNumber.match(/([A-Za-z]+)-?(\d+)/);
      if (match && match.length >= 3) {
        const prefix = match[1] || 'RCV';
        const number = parseInt(match[2]) + 1;
        return `${prefix}-${number.toString().padStart(4, '0')}`;
      }
    }
    
    return "RCV-0001";
  };

  useEffect(() => {
    fetchReceipts();
    fetchInventories();
  }, []);

  // Search debounce
  useEffect(() => {
    const delayDebounce = setTimeout(() => {
      fetchReceipts();
    }, 500);

    return () => clearTimeout(delayDebounce);
  }, [searchTerm, selectedStatus]);

  const resetForm = async () => {
    const receiptNumber = await generateReceiptNumber();
    setFormData({
      received_by: "",
      supplier: "",
      receipt_date: new Date().toISOString().split('T')[0],
      notes: "",
      items: [{ 
        inventory_id: 0, 
        quantity: 1, 
        purchase_price: 0,
        total_price: 0
      }]
    });
  };

  const handleAddItem = () => {
    setFormData({
      ...formData,
      items: [...formData.items, { 
        inventory_id: 0, 
        quantity: 1, 
        purchase_price: 0,
        total_price: 0
      }]
    });
  };

  const handleRemoveItem = (index: number) => {
    const newItems = formData.items.filter((_, i) => i !== index);
    setFormData({ ...formData, items: newItems });
  };

  const handleItemChange = (index: number, field: string, value: any) => {
    const newItems = [...formData.items];
    newItems[index] = { ...newItems[index], [field]: value };
    
    // Calculate total price if quantity or purchase_price changes
    if (field === 'quantity' || field === 'purchase_price') {
      const quantity = field === 'quantity' ? value : newItems[index].quantity;
      const purchase_price = field === 'purchase_price' ? value : newItems[index].purchase_price;
      newItems[index].total_price = quantity * purchase_price;
    }
    
    setFormData({ ...formData, items: newItems });
  };

  const calculateTotal = () => {
    return formData.items.reduce((total, item) => total + item.total_price, 0);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // Validation
    if (formData.items.length === 0) {
      Swal.fire("Error", "Minimal harus ada satu item penerimaan", "error");
      return;
    }

    for (const item of formData.items) {
      if (item.inventory_id === 0 || item.quantity <= 0) {
        Swal.fire("Error", "Semua item harus memiliki inventory dan quantity yang valid", "error");
        return;
      }
      if (item.purchase_price < 0) {
        Swal.fire("Error", "Harga beli tidak boleh negatif", "error");
        return;
      }
    }

    try {
      const receiptData = {
        ...formData,
        receipt_number: await generateReceiptNumber(),
        total_price: calculateTotal(),
        status: 'draft'
      };

      const response = await api_laravel.post("/api/receipts", receiptData);
      if (response.data.success) {
        Swal.fire("Success", "Penerimaan stock berhasil dibuat", "success");
        setOpenDialog(false);
        resetForm();
        fetchReceipts();
      }
    } catch (error: any) {
      console.error("Error creating receipt:", error);
      const errorMessage = error.response?.data?.message || "Gagal membuat penerimaan";
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

  const handleReceiveStock = async (receiptId: number) => {
    try {
      const response = await api_laravel.put(`/api/receipts/${receiptId}/receive`);
      if (response.data.success) {
        Swal.fire("Success", "Stock berhasil diterima dan ditambahkan ke inventory", "success");
        setOpenReceiveDialog(false);
        fetchReceipts();
        // Refresh inventories to update stock
        fetchInventories();
      }
    } catch (error: any) {
      console.error("Error receiving stock:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal menerima stock", "error");
    }
  };

  const handleCancelReceipt = async (receiptId: number) => {
    try {
      const response = await api_laravel.put(`/api/receipts/${receiptId}/cancel`);
      if (response.data.success) {
        Swal.fire("Success", "Penerimaan berhasil dibatalkan", "success");
        fetchReceipts();
      }
    } catch (error: any) {
      console.error("Error cancelling receipt:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal membatalkan penerimaan", "error");
    }
  };

  const handleDelete = async () => {
    if (!deleteId) return;

    try {
      const response = await api_laravel.delete(`/api/receipts/${deleteId}`);
      if (response.data.success) {
        Swal.fire("Success", "Penerimaan berhasil dihapus", "success");
        setOpenDeleteDialog(false);
        setDeleteId(null);
        fetchReceipts();
      }
    } catch (error: any) {
      console.error("Error deleting receipt:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal menghapus penerimaan", "error");
    }
  };

  const getStatusBadge = (status: string) => {
    const variants = {
      draft: "bg-gray-100 text-gray-800",
      received: "bg-green-100 text-green-800",
      cancelled: "bg-red-100 text-red-800"
    };
    return variants[status as keyof typeof variants] || "bg-gray-100 text-gray-800";
  };

  const getStatusText = (status: string) => {
    const texts = {
      draft: "Draft",
      received: "Diterima",
      cancelled: "Dibatalkan"
    };
    return texts[status as keyof typeof texts] || status;
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0
    }).format(amount);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('id-ID', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  const canReceiveStock = (receipt: Receipt) => {
    return receipt.status === 'draft';
  };

  const canCancelReceipt = (receipt: Receipt) => {
    return receipt.status === 'draft';
  };

  const canDeleteReceipt = (receipt: Receipt) => {
    return receipt.status === 'draft' || receipt.status === 'cancelled';
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex justify-between items-center">
            <div>
              <CardTitle className="flex items-center">
                <Upload className="h-6 w-6 mr-2" />
                Receipt Stock
              </CardTitle>
              <p className="text-muted-foreground">Kelola penerimaan dan pemasukan stock inventory</p>
            </div>
            <Dialog open={openDialog} onOpenChange={setOpenDialog}>
              <DialogTrigger asChild>
                <Button onClick={resetForm}>
                  <Plus className="h-4 w-4 mr-2" />
                  Tambah Receipt
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto bg-white">
                <DialogHeader>
                  <DialogTitle>Tambah Receipt Stock Baru</DialogTitle>
                </DialogHeader>
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div className="grid grid-cols-3 gap-4">
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Diterima Oleh *</label>
                      <Input
                        value={formData.received_by}
                        onChange={(e) => setFormData({...formData, received_by: e.target.value})}
                        placeholder="Nama penerima"
                        required
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Supplier *</label>
                      <Input
                        value={formData.supplier}
                        onChange={(e) => setFormData({...formData, supplier: e.target.value})}
                        placeholder="Nama supplier"
                        required
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Tanggal Receipt *</label>
                      <Input
                        type="date"
                        value={formData.receipt_date}
                        onChange={(e) => setFormData({...formData, receipt_date: e.target.value})}
                        required
                      />
                    </div>
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

                        <div className="grid grid-cols-4 gap-4">
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
                            <label className="text-sm font-medium">Harga Beli *</label>
                            <Input
                              type="number"
                              value={item.purchase_price}
                              onChange={(e) => handleItemChange(index, 'purchase_price', parseFloat(e.target.value) || 0)}
                              min="0"
                              step="0.01"
                              required
                            />
                          </div>

                          <div className="space-y-2">
                            <label className="text-sm font-medium">Total Harga</label>
                            <Input
                              value={formatCurrency(item.total_price)}
                              className="bg-gray-50"
                              readOnly
                            />
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>

                  {/* Total Summary */}
                  <div className="border-t pt-4">
                    <div className="flex justify-between items-center text-lg font-semibold">
                      <span>Total Keseluruhan:</span>
                      <span>{formatCurrency(calculateTotal())}</span>
                    </div>
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
                      Simpan Receipt
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
                placeholder="Cari nomor receipt, supplier, atau penerima..."
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
              <option value="draft">Draft</option>
              <option value="received">Diterima</option>
              <option value="cancelled">Dibatalkan</option>
            </select>
            <Button variant="outline" className="flex items-center" onClick={fetchReceipts}>
              <Filter className="h-4 w-4 mr-2" />
              Filter
            </Button>
          </div>

          {/* Receipts Table */}
          <div className="border rounded-lg">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>No. Receipt</TableHead>
                  <TableHead>Supplier</TableHead>
                  <TableHead>Diterima Oleh</TableHead>
                  <TableHead>Item</TableHead>
                  <TableHead>Quantity</TableHead>
                  <TableHead>Total Harga</TableHead>
                  <TableHead>Tanggal</TableHead>
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
                ) : receipts.length > 0 ? (
                  receipts.map((receipt) => (
                    <TableRow key={receipt.id}>
                      <TableCell className="font-medium">{receipt.receipt_number}</TableCell>
                      <TableCell>{receipt.supplier}</TableCell>
                      <TableCell>{receipt.received_by}</TableCell>
                      <TableCell>
                        <div>
                          <div className="font-medium">{receipt.inventory?.name}</div>
                          <div className="text-sm text-muted-foreground">{receipt.inventory?.code}</div>
                        </div>
                      </TableCell>
                      <TableCell>
                        {receipt.quantity} {receipt.inventory?.unit}
                      </TableCell>
                      <TableCell>{formatCurrency(receipt.total_price)}</TableCell>
                      <TableCell>{formatDate(receipt.receipt_date)}</TableCell>
                      <TableCell>
                        <Badge className={getStatusBadge(receipt.status)}>
                          {getStatusText(receipt.status)}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <div className="flex space-x-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => {
                              setSelectedReceipt(receipt);
                              setOpenDetailDialog(true);
                            }}
                          >
                            <Eye className="h-4 w-4" />
                          </Button>
                          
                          {canReceiveStock(receipt) && (
                            <Button
                              variant="outline"
                              size="sm"
                              className="text-green-600 hover:text-green-700"
                              onClick={() => {
                                setSelectedReceipt(receipt);
                                setOpenReceiveDialog(true);
                              }}
                            >
                              <CheckCircle className="h-4 w-4" />
                            </Button>
                          )}

                          {canCancelReceipt(receipt) && (
                            <Button
                              variant="outline"
                              size="sm"
                              className="text-red-600 hover:text-red-700"
                              onClick={() => handleCancelReceipt(receipt.id)}
                            >
                              Batalkan
                            </Button>
                          )}

                          {canDeleteReceipt(receipt) && (
                            <Button
                              variant="outline"
                              size="sm"
                              className="text-red-600 hover:text-red-700"
                              onClick={() => {
                                setDeleteId(receipt.id);
                                setOpenDeleteDialog(true);
                              }}
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          )}
                        </div>
                      </TableCell>
                    </TableRow>
                  ))
                ) : (
                  <TableRow>
                    <TableCell colSpan={9} className="text-center py-4">
                      Tidak ada data penerimaan
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
            <DialogTitle>Detail Receipt Stock</DialogTitle>
          </DialogHeader>
          {selectedReceipt && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium">No. Receipt</label>
                  <p className="font-semibold">{selectedReceipt.receipt_number}</p>
                </div>
                <div>
                  <label className="text-sm font-medium">Tanggal Receipt</label>
                  <p>{formatDate(selectedReceipt.receipt_date)}</p>
                </div>
                <div>
                  <label className="text-sm font-medium">Diterima Oleh</label>
                  <p>{selectedReceipt.received_by}</p>
                </div>
                <div>
                  <label className="text-sm font-medium">Supplier</label>
                  <p>{selectedReceipt.supplier}</p>
                </div>
                <div>
                  <label className="text-sm font-medium">Status</label>
                  <Badge className={getStatusBadge(selectedReceipt.status)}>
                    {getStatusText(selectedReceipt.status)}
                  </Badge>
                </div>
                <div>
                  <label className="text-sm font-medium">Total Harga</label>
                  <p className="font-semibold">{formatCurrency(selectedReceipt.total_price)}</p>
                </div>
              </div>

              <div>
                <label className="text-sm font-medium">Catatan</label>
                <p className="border rounded-md p-3 bg-gray-50">
                  {selectedReceipt.notes || "-"}
                </p>
              </div>

              <div>
                <label className="text-sm font-medium">Item Receipt</label>
                <div className="border rounded-md">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Kode Barang</TableHead>
                        <TableHead>Nama Barang</TableHead>
                        <TableHead>Quantity</TableHead>
                        <TableHead>Harga Beli</TableHead>
                        <TableHead>Total Harga</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      <TableRow>
                        <TableCell>{selectedReceipt.inventory?.code}</TableCell>
                        <TableCell>{selectedReceipt.inventory?.name}</TableCell>
                        <TableCell>{selectedReceipt.quantity} {selectedReceipt.inventory?.unit}</TableCell>
                        <TableCell>{formatCurrency(selectedReceipt.purchase_price)}</TableCell>
                        <TableCell>{formatCurrency(selectedReceipt.total_price)}</TableCell>
                      </TableRow>
                    </TableBody>
                  </Table>
                </div>
              </div>

              {selectedReceipt.created_by && (
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-sm font-medium">Dibuat Oleh</label>
                    <p>{selectedReceipt.created_by}</p>
                  </div>
                  <div>
                    <label className="text-sm font-medium">Tanggal Dibuat</label>
                    <p>{formatDate(selectedReceipt.created_at)}</p>
                  </div>
                </div>
              )}
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* Receive Confirmation Dialog */}
      <AlertDialog open={openReceiveDialog} onOpenChange={setOpenReceiveDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Konfirmasi Penerimaan Stock</AlertDialogTitle>
            <AlertDialogDescription>
              {selectedReceipt && (
                <div className="space-y-2">
                  <p>Apakah Anda yakin ingin menerima stock berikut?</p>
                  <div className="bg-green-50 p-3 rounded-md">
                    <p><strong>Item:</strong> {selectedReceipt.inventory?.name}</p>
                    <p><strong>Quantity:</strong> {selectedReceipt.quantity} {selectedReceipt.inventory?.unit}</p>
                    <p><strong>Harga Beli:</strong> {formatCurrency(selectedReceipt.purchase_price)}</p>
                    <p><strong>Stok saat ini:</strong> {selectedReceipt.inventory?.stock} {selectedReceipt.inventory?.unit}</p>
                    <p><strong>Stok setelah penerimaan:</strong> {(selectedReceipt.inventory?.stock || 0) + selectedReceipt.quantity} {selectedReceipt.inventory?.unit}</p>
                  </div>
                  <p className="text-green-600 font-medium">Tindakan ini akan menambah stok inventory dan mengupdate harga beli!</p>
                </div>
              )}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Batal</AlertDialogCancel>
            <AlertDialogAction 
              onClick={() => selectedReceipt && handleReceiveStock(selectedReceipt.id)}
              className="bg-green-600 hover:bg-green-700"
            >
              Konfirmasi Penerimaan
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={openDeleteDialog} onOpenChange={setOpenDeleteDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Hapus Receipt</AlertDialogTitle>
            <AlertDialogDescription>
              Apakah Anda yakin ingin menghapus receipt ini? Tindakan ini tidak dapat dibatalkan.
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