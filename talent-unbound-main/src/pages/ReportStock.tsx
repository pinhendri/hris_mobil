"use client";

import { useState, useEffect } from "react";
import { Download, Filter, Calendar, BarChart3, Package, ClipboardList, Upload } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";

interface InventoryRequest {
  id: number;
  request_number: string;
  inventory_id: number;
  inventory?: {
    code: string;
    name: string;
    unit: string;
  };
  quantity: number;
  requested_by: string;
  department: string;
  purpose: string;
  status: 'pending' | 'approved' | 'rejected' | 'issued';
  priority: 'low' | 'medium' | 'high';
  approved_by?: string;
  approved_at?: string;
  issued_by?: string;
  issued_at?: string;
  created_at: string;
}

interface StockIssue {
  id: number;
  issue_code: string;
  inventory_id: number;
  inventory?: {
    code: string;
    name: string;
    unit: string;
  };
  quantity: number;
  issue_date: string;
  issued_to: string;
  department: string;
  purpose: string;
  notes?: string;
  issued_by: string;
  status: 'issued' | 'returned' | 'cancelled';
  request_id?: number;
  request?: {
    request_number: string;
  };
  created_at: string;
  updated_at: string;
}

interface Receipt {
  id: number;
  receipt_number: string;
  inventory_id: number;
  inventory?: {
    code: string;
    name: string;
    unit: string;
  };
  quantity: number;
  received_by: string;
  supplier: string;
  purchase_price: number;
  total_price: number;
  receipt_date: string;
  status: 'draft' | 'received' | 'cancelled';
  created_at: string;
}

interface ReportData {
  requests: InventoryRequest[];
  issues: StockIssue[];
  receipts: Receipt[];
  summary: {
    total_requests: number;
    total_approved: number;
    total_issued: number;
    total_received: number;
    total_request_quantity: number;
    total_issue_quantity: number;
    total_receipt_quantity: number;
    total_receipt_value: number;
  };
}

export default function InventoryReport() {
  const [reportData, setReportData] = useState<ReportData | null>(null);
  const [loading, setLoading] = useState(true);
  const [dateRange, setDateRange] = useState({
    start_date: new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString().split('T')[0],
    end_date: new Date().toISOString().split('T')[0]
  });
  const [reportType, setReportType] = useState<'all' | 'requests' | 'issues' | 'receipts'>('all');

  // Fetch combined data dari semua endpoint
  const fetchCombinedData = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({
        start_date: dateRange.start_date,
        end_date: dateRange.end_date
      });

      // Fetch semua data secara parallel
      const [requestsResponse, issuesResponse, receiptsResponse] = await Promise.all([
        api_laravel.get(`/api/inventory-requests?${params.toString()}`),
        api_laravel.get(`/api/stock-issues?${params.toString()}`),
        api_laravel.get(`/api/receipts?${params.toString()}`)
      ]);

      let requests: InventoryRequest[] = [];
      let issues: StockIssue[] = [];
      let receipts: Receipt[] = [];

      if (requestsResponse.data.success) {
        requests = requestsResponse.data.data;
      }

      if (issuesResponse.data.success) {
        issues = issuesResponse.data.data;
      }

      if (receiptsResponse.data.success) {
        receipts = receiptsResponse.data.data;
      }

      // Ambil nilai langsung dari data tanpa menghitung ulang
      const totalRequests = requests.length;
      const totalApproved = requests.filter(req => req.status === 'approved').length;
      const totalIssued = requests.filter(req => req.status === 'issued').length;
      const totalReceived = receipts.filter(r => r.status === 'received').length;
      
      // Ambil quantity langsung dari data
      const totalRequestQuantity = requests.reduce((sum, req) => sum + req.quantity, 0);
      const totalIssueQuantity = issues.reduce((sum, issue) => sum + issue.quantity, 0);
      const totalReceiptQuantity = receipts.reduce((sum, receipt) => sum + receipt.quantity, 0);
      const totalReceiptValue = receipts.reduce((sum, receipt) => sum + receipt.total_price, 0);

      setReportData({
        requests,
        issues,
        receipts,
        summary: {
          total_requests: totalRequests,
          total_approved: totalApproved,
          total_issued: totalIssued,
          total_received: totalReceived,
          total_request_quantity: totalRequestQuantity,
          total_issue_quantity: totalIssueQuantity,
          total_receipt_quantity: totalReceiptQuantity,
          total_receipt_value: totalReceiptValue
        }
      });

    } catch (error: any) {
      console.error("Error fetching combined data:", error);
      Swal.fire("Error", "Gagal mengambil data laporan", "error");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCombinedData();
  }, [dateRange, reportType]);

  const handleExport = async (format: 'pdf' | 'excel') => {
    try {
      const params = new URLSearchParams({
        start_date: dateRange.start_date,
        end_date: dateRange.end_date,
        type: reportType,
        format: format
      });

      const response = await api_laravel.get(`/api/inventory-reports/export?${params.toString()}`, {
        responseType: 'blob'
      });

      // Create blob link to download
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      
      const filename = `inventory-report-${dateRange.start_date}-to-${dateRange.end_date}.${format}`;
      link.setAttribute('download', filename);
      document.body.appendChild(link);
      link.click();
      link.remove();

      Swal.fire("Success", `Laporan berhasil diexport sebagai ${format.toUpperCase()}`, "success");
    } catch (error: any) {
      console.error("Error exporting report:", error);
      Swal.fire("Error", "Gagal mengexport laporan", "error");
    }
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

  const getStatusBadge = (status: string) => {
    const variants = {
      pending: "bg-yellow-100 text-yellow-800",
      approved: "bg-blue-100 text-blue-800",
      rejected: "bg-red-100 text-red-800",
      issued: "bg-green-100 text-green-800",
      draft: "bg-gray-100 text-gray-800",
      received: "bg-green-100 text-green-800",
      cancelled: "bg-red-100 text-red-800",
      returned: "bg-purple-100 text-purple-800"
    };
    return variants[status as keyof typeof variants] || "bg-gray-100 text-gray-800";
  };

  const getStatusText = (status: string) => {
    const texts = {
      pending: "Menunggu",
      approved: "Disetujui",
      rejected: "Ditolak",
      issued: "Terkeluarkan",
      draft: "Draft",
      received: "Diterima",
      cancelled: "Dibatalkan",
      returned: "Dikembalikan"
    };
    return texts[status as keyof typeof texts] || status;
  };

  // Fungsi untuk mendapatkan summary dari data yang sudah ada
  const getSummaryData = () => {
    if (!reportData) return null;

    const { requests, issues, receipts } = reportData;

    return {
      // Request data
      totalRequests: requests.length,
      pendingRequests: requests.filter(req => req.status === 'pending').length,
      approvedRequests: requests.filter(req => req.status === 'approved').length,
      issuedRequests: requests.filter(req => req.status === 'issued').length,
      rejectedRequests: requests.filter(req => req.status === 'rejected').length,
      
      // Quantity data - SESUAI dengan detail
      totalRequestQuantity: requests.reduce((sum, req) => sum + req.quantity, 0),
      totalIssuedQuantity: requests
        .filter(req => req.status === 'issued')
        .reduce((sum, req) => sum + req.quantity, 0),
      totalApprovedQuantity: requests
        .filter(req => req.status === 'approved')
        .reduce((sum, req) => sum + req.quantity, 0),
      
      // ✅ TERKELUARKAN DIAMBIL DARI STOCK ISSUES
      totalIssues: issues.length,
      totalIssuesQuantity: issues.reduce((sum, issue) => sum + issue.quantity, 0),
      
      // Receipts data
      totalReceipts: receipts.length,
      totalReceiptQuantity: receipts.reduce((sum, receipt) => sum + receipt.quantity, 0),
      totalReceiptValue: receipts.reduce((sum, receipt) => sum + receipt.total_price, 0)
    };
  };

  const summaryData = getSummaryData();

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex justify-between items-center">
            <div>
              <CardTitle className="flex items-center">
                <BarChart3 className="h-6 w-6 mr-2" />
                Laporan Inventory
              </CardTitle>
              <p className="text-muted-foreground">Laporan permintaan, pengeluaran, dan penerimaan inventory</p>
            </div>
            <div className="flex space-x-2">
              <Button
                variant="outline"
                onClick={() => handleExport('excel')}
                disabled={loading}
              >
                <Download className="h-4 w-4 mr-2" />
                Export Excel
              </Button>
              <Button
                variant="outline"
                onClick={() => handleExport('pdf')}
                disabled={loading}
              >
                <Download className="h-4 w-4 mr-2" />
                Export PDF
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {/* Filters */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
            <div>
              <label className="text-sm font-medium mb-2 block">Tanggal Mulai</label>
              <input
                type="date"
                value={dateRange.start_date}
                onChange={(e) => setDateRange({...dateRange, start_date: e.target.value})}
                className="w-full border rounded-md px-3 py-2"
              />
            </div>
            <div>
              <label className="text-sm font-medium mb-2 block">Tanggal Akhir</label>
              <input
                type="date"
                value={dateRange.end_date}
                onChange={(e) => setDateRange({...dateRange, end_date: e.target.value})}
                className="w-full border rounded-md px-3 py-2"
              />
            </div>
            <div>
              <label className="text-sm font-medium mb-2 block">Jenis Laporan</label>
              <select
                value={reportType}
                onChange={(e) => setReportType(e.target.value as any)}
                className="w-full border rounded-md px-3 py-2"
              >
                <option value="all">Semua</option>
                <option value="requests">Request</option>
                <option value="issues">Stock Issues</option>
                <option value="receipts">Receipt Stock</option>
              </select>
            </div>
            <div className="flex items-end">
              <Button onClick={fetchCombinedData} className="w-full">
                <Filter className="h-4 w-4 mr-2" />
                Filter
              </Button>
            </div>
          </div>

          {/* Summary Cards */}
          {summaryData && (
            <div className="grid grid-cols-1 md:grid-cols-5 gap-4 mb-6">
              <Card>
                <CardContent className="p-4">
                  <div className="flex items-center">
                    <ClipboardList className="h-8 w-8 text-blue-600 mr-3" />
                    <div>
                      <p className="text-sm font-medium text-muted-foreground">Total Request</p>
                      <p className="text-2xl font-bold">{summaryData.totalRequests}</p>
                      <p className="text-xs text-muted-foreground">
                        {summaryData.totalRequestQuantity} items
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="p-4">
                  <div className="flex items-center">
                    <Package className="h-8 w-8 text-green-600 mr-3" />
                    <div>
                      {/* ✅ TERKELUARKAN DIAMBIL DARI STOCK ISSUES */}
                      <p className="text-sm font-medium text-muted-foreground">Terkeluarkan</p>
                      <p className="text-2xl font-bold">{summaryData.totalIssues}</p>
                      <p className="text-xs text-muted-foreground">
                        {summaryData.totalIssuesQuantity} items
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="p-4">
                  <div className="flex items-center">
                    <Package className="h-8 w-8 text-blue-400 mr-3" />
                    <div>
                      <p className="text-sm font-medium text-muted-foreground">Disetujui</p>
                      <p className="text-2xl font-bold">{summaryData.approvedRequests}</p>
                      <p className="text-xs text-muted-foreground">
                        {summaryData.totalApprovedQuantity} items
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="p-4">
                  <div className="flex items-center">
                    <Upload className="h-8 w-8 text-orange-600 mr-3" />
                    <div>
                      <p className="text-sm font-medium text-muted-foreground">Diterima</p>
                      <p className="text-2xl font-bold">{summaryData.totalReceipts}</p>
                      <p className="text-xs text-muted-foreground">
                        {summaryData.totalReceiptQuantity} items
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="p-4">
                  <div className="flex items-center">
                    <BarChart3 className="h-8 w-8 text-purple-600 mr-3" />
                    <div>
                      <p className="text-sm font-medium text-muted-foreground">Total Nilai</p>
                      <p className="text-lg font-bold">{formatCurrency(summaryData.totalReceiptValue)}</p>
                      <p className="text-xs text-muted-foreground">
                        Nilai penerimaan
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>
          )}

          {/* Status Summary untuk Requests */}
          {summaryData && summaryData.totalRequests > 0 && (
            <div className="mb-6">
              <h4 className="text-md font-semibold mb-3">Ringkasan Status Request</h4>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3">
                  <div className="flex justify-between items-center">
                    <span className="text-sm font-medium text-yellow-800">Menunggu</span>
                    <Badge variant="outline" className="bg-yellow-100 text-yellow-800">
                      {summaryData.pendingRequests}
                    </Badge>
                  </div>
                </div>
                <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
                  <div className="flex justify-between items-center">
                    <span className="text-sm font-medium text-blue-800">Disetujui</span>
                    <Badge variant="outline" className="bg-blue-100 text-blue-800">
                      {summaryData.approvedRequests}
                    </Badge>
                  </div>
                </div>
                <div className="bg-green-50 border border-green-200 rounded-lg p-3">
                  <div className="flex justify-between items-center">
                    <span className="text-sm font-medium text-green-800">Request Issued</span>
                    <Badge variant="outline" className="bg-green-100 text-green-800">
                      {summaryData.issuedRequests}
                    </Badge>
                  </div>
                </div>
                <div className="bg-red-50 border border-red-200 rounded-lg p-3">
                  <div className="flex justify-between items-center">
                    <span className="text-sm font-medium text-red-800">Ditolak</span>
                    <Badge variant="outline" className="bg-red-100 text-red-800">
                      {summaryData.rejectedRequests}
                    </Badge>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Requests Table */}
          {(reportType === 'all' || reportType === 'requests') && (
            <div className="mb-8">
              <h3 className="text-lg font-semibold mb-4 flex items-center">
                <ClipboardList className="h-5 w-5 mr-2" />
                Laporan Request Inventory
                {reportData?.requests && (
                  <Badge variant="secondary" className="ml-2">
                    {reportData.requests.length} data
                  </Badge>
                )}
              </h3>
              <div className="border rounded-lg">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>No. Request</TableHead>
                      <TableHead>Item</TableHead>
                      <TableHead>Pemohon</TableHead>
                      <TableHead>Department</TableHead>
                      <TableHead>Quantity</TableHead>
                      <TableHead>Tujuan</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Tanggal Request</TableHead>
                      <TableHead>Disetujui Oleh</TableHead>
                      <TableHead>Dikeluarkan Oleh</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {loading ? (
                      <TableRow>
                        <TableCell colSpan={10} className="text-center py-4">
                          Loading...
                        </TableCell>
                      </TableRow>
                    ) : reportData?.requests && reportData.requests.length > 0 ? (
                      reportData.requests.map((request) => (
                        <TableRow key={request.id}>
                          <TableCell className="font-medium">{request.request_number}</TableCell>
                          <TableCell>
                            <div>
                              <div className="font-medium">{request.inventory?.name}</div>
                              <div className="text-sm text-muted-foreground">{request.inventory?.code}</div>
                            </div>
                          </TableCell>
                          <TableCell>{request.requested_by}</TableCell>
                          <TableCell>{request.department}</TableCell>
                          <TableCell>
                            {request.quantity} {request.inventory?.unit}
                          </TableCell>
                          <TableCell className="max-w-[200px] truncate" title={request.purpose}>
                            {request.purpose}
                          </TableCell>
                          <TableCell>
                            <Badge className={getStatusBadge(request.status)}>
                              {getStatusText(request.status)}
                            </Badge>
                          </TableCell>
                          <TableCell>{formatDate(request.created_at)}</TableCell>
                          <TableCell>{request.approved_by || '-'}</TableCell>
                          <TableCell>{request.issued_by || '-'}</TableCell>
                        </TableRow>
                      ))
                    ) : (
                      <TableRow>
                        <TableCell colSpan={10} className="text-center py-4">
                          Tidak ada data request
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </div>
            </div>
          )}

          {/* Stock Issues Table */}
          {(reportType === 'all' || reportType === 'issues') && (
            <div className="mb-8">
              <h3 className="text-lg font-semibold mb-4 flex items-center">
                <Package className="h-5 w-5 mr-2" />
                Laporan Stock Issues (Pengeluaran)
                {reportData?.issues && (
                  <Badge variant="secondary" className="ml-2">
                    {reportData.issues.length} data
                  </Badge>
                )}
              </h3>
              <div className="border rounded-lg">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Kode Issue</TableHead>
                      <TableHead>No. Request</TableHead>
                      <TableHead>Item</TableHead>
                      <TableHead>Quantity</TableHead>
                      <TableHead>Dikeluarkan Untuk</TableHead>
                      <TableHead>Department</TableHead>
                      <TableHead>Tujuan</TableHead>
                      <TableHead>Dikeluarkan Oleh</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Tanggal</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {loading ? (
                      <TableRow>
                        <TableCell colSpan={10} className="text-center py-4">
                          Loading...
                        </TableCell>
                      </TableRow>
                    ) : reportData?.issues && reportData.issues.length > 0 ? (
                      reportData.issues.map((issue) => (
                        <TableRow key={issue.id}>
                          <TableCell className="font-medium">{issue.issue_code}</TableCell>
                          <TableCell>
                            {issue.request?.request_number || '-'}
                          </TableCell>
                          <TableCell>
                            <div>
                              <div className="font-medium">{issue.inventory?.name}</div>
                              <div className="text-sm text-muted-foreground">{issue.inventory?.code}</div>
                            </div>
                          </TableCell>
                          <TableCell>
                            {issue.quantity} {issue.inventory?.unit}
                          </TableCell>
                          <TableCell>{issue.issued_to}</TableCell>
                          <TableCell>{issue.department}</TableCell>
                          <TableCell className="max-w-[200px] truncate" title={issue.purpose}>
                            {issue.purpose}
                          </TableCell>
                          <TableCell>{issue.issued_by}</TableCell>
                          <TableCell>
                            <Badge className={getStatusBadge(issue.status)}>
                              {getStatusText(issue.status)}
                            </Badge>
                          </TableCell>
                          <TableCell>{formatDate(issue.issue_date)}</TableCell>
                        </TableRow>
                      ))
                    ) : (
                      <TableRow>
                        <TableCell colSpan={10} className="text-center py-4">
                          Tidak ada data stock issues
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </div>
            </div>
          )}

          {/* Receipts Table */}
          {(reportType === 'all' || reportType === 'receipts') && (
            <div>
              <h3 className="text-lg font-semibold mb-4 flex items-center">
                <Upload className="h-5 w-5 mr-2" />
                Laporan Receipt Stock (Penerimaan)
                {reportData?.receipts && (
                  <Badge variant="secondary" className="ml-2">
                    {reportData.receipts.length} data
                  </Badge>
                )}
              </h3>
              <div className="border rounded-lg">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>No. Receipt</TableHead>
                      <TableHead>Item</TableHead>
                      <TableHead>Supplier</TableHead>
                      <TableHead>Diterima Oleh</TableHead>
                      <TableHead>Quantity</TableHead>
                      <TableHead>Harga Beli</TableHead>
                      <TableHead>Total Harga</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Tanggal</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {loading ? (
                      <TableRow>
                        <TableCell colSpan={9} className="text-center py-4">
                          Loading...
                        </TableCell>
                      </TableRow>
                    ) : reportData?.receipts && reportData.receipts.length > 0 ? (
                      reportData.receipts.map((receipt) => (
                        <TableRow key={receipt.id}>
                          <TableCell className="font-medium">{receipt.receipt_number}</TableCell>
                          <TableCell>
                            <div>
                              <div className="font-medium">{receipt.inventory?.name}</div>
                              <div className="text-sm text-muted-foreground">{receipt.inventory?.code}</div>
                            </div>
                          </TableCell>
                          <TableCell>{receipt.supplier}</TableCell>
                          <TableCell>{receipt.received_by}</TableCell>
                          <TableCell>
                            {receipt.quantity} {receipt.inventory?.unit}
                          </TableCell>
                          <TableCell>{formatCurrency(receipt.purchase_price)}</TableCell>
                          <TableCell>{formatCurrency(receipt.total_price)}</TableCell>
                          <TableCell>
                            <Badge className={getStatusBadge(receipt.status)}>
                              {getStatusText(receipt.status)}
                            </Badge>
                          </TableCell>
                          <TableCell>{formatDate(receipt.receipt_date)}</TableCell>
                        </TableRow>
                      ))
                    ) : (
                      <TableRow>
                        <TableCell colSpan={9} className="text-center py-4">
                          Tidak ada data receipt
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}