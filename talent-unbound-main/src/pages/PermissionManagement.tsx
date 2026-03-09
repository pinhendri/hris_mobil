"use client";

import { useState, useEffect, FormEvent } from "react";
import { api_laravel } from "@/lib/utils"; // Import api_laravel dari utils
import { 
  Search, 
  Plus, 
  Edit, 
  Trash2,
  AlertCircle,
  CheckCircle,
  XCircle,
  RefreshCw,
  Eye,
  Key,
  Database,
  Shield,
  ChevronLeft,
  ChevronRight
} from "lucide-react";

interface Permission {
  id: number;
  name: string;
  guard_name: string;
  created_at?: string;
  updated_at?: string;
}

export default function PermissionManagementPage() {
  const [permissions, setPermissions] = useState<Permission[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<{ type: 'success' | 'error' | 'info', text: string } | null>(null);
  
  // Modal states
  const [showModal, setShowModal] = useState<boolean>(false);
  const [modalType, setModalType] = useState<'create' | 'edit'>('create');
  const [selectedPermission, setSelectedPermission] = useState<Permission | null>(null);
  
  // Form states
  const [formData, setFormData] = useState({
    name: '',
    guard_name: 'api'
  });
  const [formErrors, setFormErrors] = useState<Record<string, string>>({});
  
  // Search & Pagination
  const [search, setSearch] = useState<string>('');
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [itemsPerPage, setItemsPerPage] = useState<number>(20);

  // ✅ Gunakan api_laravel dari utils
  const fetchPermissions = async () => {
    setLoading(true);
    setError(null);
    
    try {
      console.log("Fetching permissions using api_laravel...");
      
      // Gunakan api_laravel dengan endpoint yang benar
      const response = await api_laravel.get('/api/permission-management/permissions');
      
      console.log("Response status:", response.status);
      console.log("Response data:", response.data);
      
      if (response.data.success) {
        const permissionsData = response.data.data || [];
        console.log("Received permissions:", permissionsData.length, "items");
        
        // Sort by ID descending
        const sortedData = [...permissionsData].sort((a: Permission, b: Permission) => b.id - a.id);
        setPermissions(sortedData);
        
        if (permissionsData.length === 0) {
          setMessage({ type: 'info', text: 'Tidak ada data permission ditemukan.' });
        } else {
          setMessage({ type: 'success', text: `Berhasil memuat ${permissionsData.length} permissions` });
        }
      } else {
        setError(`API Error: ${response.data.message || 'Unknown error'}`);
      }
    } catch (err: any) {
      console.error("Error fetching permissions:", err);
      
      let errorMessage = 'Terjadi kesalahan saat mengambil data. ';
      
      if (err.response) {
        const status = err.response.status;
        const data = err.response.data;
        
        if (status === 401) {
          errorMessage += 'Status: 401 Unauthorized. Silakan login kembali.';
        } else if (status === 403) {
          errorMessage += 'Status: 403 Forbidden. Anda tidak memiliki izin.';
        } else if (status === 404) {
          errorMessage += `Status: 404 Not Found. Endpoint tidak ditemukan: ${err.config?.url}`;
        } else if (status === 500) {
          errorMessage += 'Status: 500 Server Error.';
        } else if (data && data.message) {
          errorMessage += `Server: ${data.message}`;
        } else {
          errorMessage += `Status: ${status}`;
        }
      } else if (err.request) {
        errorMessage += 'Tidak ada response dari server. Periksa: ';
        errorMessage += '1. Laravel server berjalan di http://localhost:8000\n';
        errorMessage += '2. CORS sudah dikonfigurasi\n';
        errorMessage += '3. Endpoint benar: /api/permission-management/permissions';
      } else {
        errorMessage += err.message || 'Unknown error';
      }
      
      setError(errorMessage);
      
      // Jika error, load hardcoded data
      loadHardcodedPermissions();
    } finally {
      setLoading(false);
    }
  };

  // Hardcoded data untuk fallback
  const loadHardcodedPermissions = () => {
    const hardcodedData: Permission[] = [
      {
        "id": 1038,
        "name": "view-dashboard",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1039,
        "name": "view-employee",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1040,
        "name": "create-employee",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1041,
        "name": "edit-employee",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1042,
        "name": "delete-employee",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1043,
        "name": "view-attendance",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1044,
        "name": "create-attendance",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1045,
        "name": "edit-attendance",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1046,
        "name": "view-client",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1047,
        "name": "create-client",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1048,
        "name": "edit-client",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1049,
        "name": "delete-client",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1050,
        "name": "view-recruitment",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1051,
        "name": "create-recruitment",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1052,
        "name": "edit-recruitment",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1053,
        "name": "view-leave",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1054,
        "name": "create-leave",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1055,
        "name": "edit-leave",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1056,
        "name": "view-payroll",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1057,
        "name": "create-payroll",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1058,
        "name": "edit-payroll",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1059,
        "name": "edit-payroll-settings",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1060,
        "name": "view-performance",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1061,
        "name": "create-performance",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1062,
        "name": "edit-performance",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1063,
        "name": "view-kpi",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1064,
        "name": "view-department-goals",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1065,
        "name": "view-employee-goals",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1066,
        "name": "create-department-goals",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1067,
        "name": "create-employee-goals",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1068,
        "name": "edit-department-goals",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1069,
        "name": "edit-employee-goals",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1070,
        "name": "view-time-tracking",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1071,
        "name": "create-time-tracking",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1072,
        "name": "view-department",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1073,
        "name": "create-department",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1074,
        "name": "edit-department",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1075,
        "name": "delete-department",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1076,
        "name": "view-reports",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1077,
        "name": "view-documents",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1078,
        "name": "create-documents",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1079,
        "name": "edit-documents",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1080,
        "name": "delete-documents",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1081,
        "name": "view-settings",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1082,
        "name": "edit-settings",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1083,
        "name": "assign-roles",
        "guard_name": "api",
        "created_at": "2025-10-09T07:15:58.000000Z",
        "updated_at": "2025-10-09T07:15:58.000000Z"
      },
      {
        "id": 1084,
        "name": "edit-kpi",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1085,
        "name": "view-roles",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1086,
        "name": "create-roles",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1087,
        "name": "edit-roles",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1088,
        "name": "view-inventory",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1089,
        "name": "view-inventory-master",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1090,
        "name": "view-inventory-request",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1091,
        "name": "view-inventory-receipt",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1092,
        "name": "view-inventory-issued",
        "guard_name": "api",
        "created_at": "2025-10-17T20:31:28.000000Z",
        "updated_at": null
      },
      {
        "id": 1093,
        "name": "view-inventory-report",
        "guard_name": "api",
        "created_at": "2025-10-17T20:31:44.000000Z",
        "updated_at": null
      },
      {
        "id": 1094,
        "name": "approve-requests-stock",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1095,
        "name": "manage-inventory",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1096,
        "name": "issue-stock",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      },
      {
        "id": 1097,
        "name": "view-permissions",
        "guard_name": "api",
        "created_at": null,
        "updated_at": null
      }
    ];
    
    const sortedData = [...hardcodedData].sort((a, b) => b.id - a.id);
    setPermissions(sortedData);
    setMessage({ type: 'success', text: `Berhasil memuat ${hardcodedData.length} permissions (data sample)` });
  };

  // Initial load
  useEffect(() => {
    fetchPermissions();
  }, []);

  const showMessage = (type: 'success' | 'error' | 'info', text: string) => {
    setMessage({ type, text });
    setTimeout(() => setMessage(null), 5000);
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    
    if (formErrors[name]) {
      setFormErrors(prev => {
        const newErrors = { ...prev };
        delete newErrors[name];
        return newErrors;
      });
    }
  };

  const openCreateModal = () => {
    setModalType('create');
    setFormData({ name: '', guard_name: 'api' });
    setFormErrors({});
    setSelectedPermission(null);
    setShowModal(true);
  };

  const openEditModal = (permission: Permission) => {
    setModalType('edit');
    setFormData({
      name: permission.name,
      guard_name: permission.guard_name
    });
    setFormErrors({});
    setSelectedPermission(permission);
    setShowModal(true);
  };

  const closeModal = () => {
    setShowModal(false);
    setFormData({ name: '', guard_name: 'api' });
    setFormErrors({});
    setSelectedPermission(null);
  };

  const validateForm = () => {
    const errors: Record<string, string> = {};

    if (!formData.name.trim()) {
      errors.name = 'Nama permission wajib diisi';
    }

    if (!formData.guard_name.trim()) {
      errors.guard_name = 'Guard name wajib diisi';
    }

    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) return;

    try {
      let response;
      
      if (modalType === 'create') {
        response = await api_laravel.post('/api/permission-management/permissions', formData);
      } else {
        response = await api_laravel.put(`/api/permission-management/permissions/${selectedPermission?.id}`, formData);
      }

      if (response.data.success) {
        showMessage('success', response.data.message || 'Permission berhasil disimpan');
        closeModal();
        fetchPermissions(); // Refresh data
      } else {
        if (response.data.errors) {
          const errorMessages: Record<string, string> = {};
          Object.entries(response.data.errors).forEach(([key, value]: [string, any]) => {
            errorMessages[key] = Array.isArray(value) ? value[0] : value;
          });
          setFormErrors(errorMessages);
        }
        showMessage('error', response.data.message || 'Gagal menyimpan permission');
      }
    } catch (error: any) {
      console.error('Submit error:', error);
      showMessage('error', error.response?.data?.message || 'Terjadi kesalahan');
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm('Apakah Anda yakin ingin menghapus permission ini?')) return;

    try {
      const response = await api_laravel.delete(`/api/permission-management/permissions/${id}`);
      
      if (response.data.success) {
        showMessage('success', response.data.message || 'Permission berhasil dihapus');
        fetchPermissions(); // Refresh data
      } else {
        showMessage('error', response.data.message || 'Gagal menghapus permission');
      }
    } catch (error: any) {
      console.error('Delete error:', error);
      showMessage('error', error.response?.data?.message || 'Terjadi kesalahan');
    }
  };

  // Filter permissions berdasarkan search
  const filteredPermissions = permissions.filter(permission =>
    permission.name.toLowerCase().includes(search.toLowerCase()) ||
    permission.guard_name.toLowerCase().includes(search.toLowerCase())
  );

  // Pagination logic
  const totalPages = Math.ceil(filteredPermissions.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentPermissions = filteredPermissions.slice(startIndex, endIndex);

  const goToPage = (page: number) => {
    if (page >= 1 && page <= totalPages) {
      setCurrentPage(page);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };

  const formatDate = (dateString?: string) => {
    if (!dateString) return '-';
    try {
      const date = new Date(dateString);
      return date.toLocaleDateString('id-ID', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
      });
    } catch {
      return dateString;
    }
  };

  // Calculate statistics
  const viewPermissions = permissions.filter(p => p.name.includes('view')).length;
  const createPermissions = permissions.filter(p => p.name.includes('create')).length;
  const editPermissions = permissions.filter(p => p.name.includes('edit')).length;
  const deletePermissions = permissions.filter(p => p.name.includes('delete')).length;

  return (
    <div className="min-h-screen bg-gray-50 p-4 md:p-6">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-6">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <h1 className="text-2xl md:text-3xl font-bold text-gray-800 flex items-center gap-2">
                <Key className="w-8 h-8 text-blue-600" />
                Permission Management
              </h1>
              <p className="text-gray-600 mt-1">Kelola {permissions.length} permissions untuk sistem Anda</p>
            </div>
            <div className="flex flex-wrap gap-3">
              <button
                onClick={fetchPermissions}
                disabled={loading}
                className={`flex items-center gap-2 px-4 py-2 rounded-lg transition-colors ${
                  loading 
                    ? 'bg-gray-400 text-white cursor-not-allowed' 
                    : 'bg-gray-600 text-white hover:bg-gray-700'
                }`}
              >
                <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
                {loading ? 'Memuat...' : 'Refresh Data'}
              </button>
              <button
                onClick={openCreateModal}
                className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                <Plus className="w-4 h-4" />
                Tambah Permission
              </button>
            </div>
          </div>
        </div>

        {/* Debug Info */}
        <div className="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-lg">
          <div className="flex items-center gap-2">
            <AlertCircle className="w-4 h-4 text-blue-600" />
            <span className="text-sm text-blue-700">
              Menggunakan: <code className="bg-blue-100 px-2 py-1 rounded text-xs">api_laravel</code>
            </span>
            <span className="text-xs text-blue-600 ml-2">
              BaseURL: http://localhost:8000
            </span>
          </div>
        </div>

        {/* Message Alert */}
        {message && (
          <div className={`mb-6 p-4 rounded-lg flex items-center gap-3 ${
            message.type === 'success' ? 'bg-green-50 text-green-800 border border-green-200' :
            message.type === 'error' ? 'bg-red-50 text-red-800 border border-red-200' :
            'bg-blue-50 text-blue-800 border border-blue-200'
          }`}>
            {message.type === 'success' ? (
              <CheckCircle className="w-5 h-5" />
            ) : message.type === 'error' ? (
              <XCircle className="w-5 h-5" />
            ) : (
              <AlertCircle className="w-5 h-5" />
            )}
            <span>{message.text}</span>
          </div>
        )}

        {/* Error Alert */}
        {error && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-xl">
            <div className="flex items-start gap-3">
              <AlertCircle className="w-5 h-5 text-red-600 mt-0.5 flex-shrink-0" />
              <div className="flex-1">
                <h3 className="font-medium text-red-800">Error</h3>
                <p className="text-red-700 text-sm mt-1 whitespace-pre-line">{error}</p>
                <div className="mt-3 flex gap-2">
                  <button
                    onClick={fetchPermissions}
                    className="px-3 py-1 bg-red-600 text-white text-sm rounded hover:bg-red-700"
                  >
                    Coba Lagi
                  </button>
                  <button
                    onClick={() => setError(null)}
                    className="px-3 py-1 border border-red-300 text-red-700 text-sm rounded hover:bg-red-50"
                  >
                    Tutup
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Search & Controls */}
        <div className="bg-white rounded-xl shadow-sm p-4 mb-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {/* Search */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                <div className="flex items-center gap-2">
                  <Search className="w-4 h-4" />
                  Cari Permission
                </div>
              </label>
              <input
                type="text"
                placeholder="Cari berdasarkan nama permission..."
                value={search}
                onChange={(e) => {
                  setSearch(e.target.value);
                  setCurrentPage(1);
                }}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                disabled={loading}
              />
            </div>

            {/* Items Per Page */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Items per Halaman
              </label>
              <select
                value={itemsPerPage}
                onChange={(e) => {
                  setItemsPerPage(Number(e.target.value));
                  setCurrentPage(1);
                }}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                disabled={loading}
              >
                <option value={10}>10</option>
                <option value={20}>20</option>
                <option value={50}>50</option>
                <option value={100}>100</option>
              </select>
            </div>

            {/* Stats */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Informasi
              </label>
              <div className="text-sm text-gray-600">
                <div>Total: <span className="font-medium">{permissions.length}</span> permissions</div>
                <div>Tertampilkan: <span className="font-medium">{filteredPermissions.length}</span></div>
                <div>Halaman: <span className="font-medium">{currentPage}</span> dari <span className="font-medium">{totalPages}</span></div>
              </div>
            </div>
          </div>
        </div>

        {/* Permissions Table */}
        <div className="bg-white rounded-xl shadow-sm overflow-hidden">
          {loading ? (
            <div className="p-8 text-center">
              <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
              <p className="mt-2 text-gray-600">Memuat data permission...</p>
              <p className="mt-1 text-sm text-gray-500">Mohon tunggu sebentar</p>
            </div>
          ) : currentPermissions.length === 0 ? (
            <div className="p-8 text-center">
              <Database className="w-12 h-12 text-gray-400 mx-auto mb-3" />
              <div className="text-gray-400 mb-2">
                {search ? 'Tidak ditemukan permission yang sesuai dengan pencarian' : 'Tidak ada data permission'}
              </div>
              {search ? (
                <button
                  onClick={() => setSearch('')}
                  className="text-blue-600 hover:text-blue-700 font-medium"
                >
                  Reset pencarian
                </button>
              ) : (
                <button
                  onClick={openCreateModal}
                  className="text-blue-600 hover:text-blue-700 font-medium"
                >
                  Tambah permission pertama
                </button>
              )}
            </div>
          ) : (
            <>
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        ID
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Nama Permission
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Guard
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Dibuat
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Diupdate
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Aksi
                      </th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {currentPermissions.map((permission) => (
                      <tr key={permission.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4 text-sm text-gray-500">
                          <span className="font-mono">#{permission.id}</span>
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-2">
                            <div className={`p-1 rounded ${
                              permission.name.includes('view') ? 'bg-blue-100 text-blue-800' :
                              permission.name.includes('create') ? 'bg-green-100 text-green-800' :
                              permission.name.includes('edit') ? 'bg-yellow-100 text-yellow-800' :
                              permission.name.includes('delete') ? 'bg-red-100 text-red-800' :
                              'bg-gray-100 text-gray-800'
                            }`}>
                              <Key className="w-3 h-3" />
                            </div>
                            <div>
                              <div className="font-medium text-gray-900">{permission.name}</div>
                              <div className="text-xs text-gray-500">
                                {permission.name.split('-')[0].toUpperCase()} permission
                              </div>
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                            <Shield className="w-3 h-3 mr-1" />
                            {permission.guard_name}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-500">
                          {formatDate(permission.created_at)}
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-500">
                          {formatDate(permission.updated_at)}
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-2">
                            <button
                              onClick={() => openEditModal(permission)}
                              className="text-blue-600 hover:text-blue-800 p-1 rounded hover:bg-blue-50 transition-colors"
                              title="Edit"
                            >
                              <Edit className="w-4 h-4" />
                            </button>
                            <button
                              onClick={() => handleDelete(permission.id)}
                              className="text-red-600 hover:text-red-800 p-1 rounded hover:bg-red-50 transition-colors"
                              title="Hapus"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              
              {/* Pagination */}
              <div className="px-6 py-4 border-t border-gray-200 bg-gray-50">
                <div className="flex flex-col md:flex-row items-center justify-between gap-4">
                  <div className="text-sm text-gray-600">
                    Menampilkan <span className="font-medium">{startIndex + 1}</span> - <span className="font-medium">{Math.min(endIndex, filteredPermissions.length)}</span> dari <span className="font-medium">{filteredPermissions.length}</span> permissions
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => goToPage(currentPage - 1)}
                      disabled={currentPage === 1}
                      className={`p-2 rounded ${
                        currentPage === 1 
                          ? 'text-gray-400 cursor-not-allowed' 
                          : 'text-gray-600 hover:bg-gray-100'
                      }`}
                    >
                      <ChevronLeft className="w-5 h-5" />
                    </button>
                    
                    <div className="flex items-center gap-1">
                      {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                        let pageNum;
                        if (totalPages <= 5) {
                          pageNum = i + 1;
                        } else if (currentPage <= 3) {
                          pageNum = i + 1;
                        } else if (currentPage >= totalPages - 2) {
                          pageNum = totalPages - 4 + i;
                        } else {
                          pageNum = currentPage - 2 + i;
                        }
                        
                        return (
                          <button
                            key={pageNum}
                            onClick={() => goToPage(pageNum)}
                            className={`w-8 h-8 rounded flex items-center justify-center ${
                              currentPage === pageNum
                                ? 'bg-blue-600 text-white'
                                : 'text-gray-600 hover:bg-gray-100'
                            }`}
                          >
                            {pageNum}
                          </button>
                        );
                      })}
                    </div>
                    
                    <button
                      onClick={() => goToPage(currentPage + 1)}
                      disabled={currentPage === totalPages}
                      className={`p-2 rounded ${
                        currentPage === totalPages
                          ? 'text-gray-400 cursor-not-allowed'
                          : 'text-gray-600 hover:bg-gray-100'
                      }`}
                    >
                      <ChevronRight className="w-5 h-5" />
                    </button>
                  </div>
                </div>
              </div>
            </>
          )}
        </div>

        {/* Statistics */}
        <div className="mt-6 grid grid-cols-1 md:grid-cols-5 gap-4">
          <div className="bg-white rounded-xl shadow-sm p-5">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-sm text-gray-500">Total</div>
                <div className="text-2xl font-bold text-gray-800">{permissions.length}</div>
              </div>
              <div className="p-3 bg-blue-100 rounded-lg">
                <Key className="w-6 h-6 text-blue-600" />
              </div>
            </div>
          </div>
          
          <div className="bg-white rounded-xl shadow-sm p-5">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-sm text-gray-500">View</div>
                <div className="text-2xl font-bold text-gray-800">
                  {viewPermissions}
                </div>
              </div>
              <div className="p-3 bg-green-100 rounded-lg">
                <Eye className="w-6 h-6 text-green-600" />
              </div>
            </div>
          </div>
          
          <div className="bg-white rounded-xl shadow-sm p-5">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-sm text-gray-500">Create</div>
                <div className="text-2xl font-bold text-gray-800">
                  {createPermissions}
                </div>
              </div>
              <div className="p-3 bg-yellow-100 rounded-lg">
                <Plus className="w-6 h-6 text-yellow-600" />
              </div>
            </div>
          </div>
          
          <div className="bg-white rounded-xl shadow-sm p-5">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-sm text-gray-500">Edit</div>
                <div className="text-2xl font-bold text-gray-800">
                  {editPermissions}
                </div>
              </div>
              <div className="p-3 bg-purple-100 rounded-lg">
                <Edit className="w-6 h-6 text-purple-600" />
              </div>
            </div>
          </div>
          
          <div className="bg-white rounded-xl shadow-sm p-5">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-sm text-gray-500">Delete</div>
                <div className="text-2xl font-bold text-gray-800">
                  {deletePermissions}
                </div>
              </div>
              <div className="p-3 bg-red-100 rounded-lg">
                <Trash2 className="w-6 h-6 text-red-600" />
              </div>
            </div>
          </div>
        </div>

        {/* Create/Edit Permission Modal */}
        {showModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
            <div className="bg-white rounded-xl shadow-2xl w-full max-w-md">
              <div className="p-6">
                <h2 className="text-2xl font-bold text-gray-800 mb-4">
                  {modalType === 'create' ? 'Tambah Permission Baru' : 'Edit Permission'}
                </h2>
                
                <form onSubmit={handleSubmit}>
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Nama Permission *
                      </label>
                      <input
                        type="text"
                        name="name"
                        value={formData.name}
                        onChange={handleInputChange}
                        className={`w-full border rounded-lg px-3 py-2 focus:outline-none focus:ring-2 ${
                          formErrors.name
                            ? 'border-red-500 focus:ring-red-500'
                            : 'border-gray-300 focus:ring-blue-500'
                        }`}
                        placeholder="contoh: view-users"
                      />
                      {formErrors.name && (
                        <p className="mt-1 text-sm text-red-600">{formErrors.name}</p>
                      )}
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Guard Name *
                      </label>
                      <select
                        name="guard_name"
                        value={formData.guard_name}
                        onChange={handleInputChange}
                        className={`w-full border rounded-lg px-3 py-2 focus:outline-none focus:ring-2 ${
                          formErrors.guard_name
                            ? 'border-red-500 focus:ring-red-500'
                            : 'border-gray-300 focus:ring-blue-500'
                        }`}
                      >
                        <option value="api">api (default)</option>
                        <option value="web">web</option>
                      </select>
                      {formErrors.guard_name && (
                        <p className="mt-1 text-sm text-red-600">{formErrors.guard_name}</p>
                      )}
                    </div>
                  </div>

                  <div className="mt-8 flex justify-end gap-3">
                    <button
                      type="button"
                      onClick={closeModal}
                      className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors"
                    >
                      Batal
                    </button>
                    <button
                      type="submit"
                      className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                    >
                      {modalType === 'create' ? 'Simpan' : 'Update'}
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}