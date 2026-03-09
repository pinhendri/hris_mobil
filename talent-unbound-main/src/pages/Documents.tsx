import { useState, useEffect } from "react";
import { FileText, Upload, Search, Filter, Download, Eye, Edit, Trash2, Plus, X } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";

interface Document {
  id: number;
  name: string;
  type: string;
  category: string;
  format: string;
  size: string;
  upload_date: string;
  version: string;
  access: string;
  file_url : string;
}

export default function Documents() {
  const [documents, setDocuments] = useState<Document[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("All");

  // state modal upload
  const [showUpload, setShowUpload] = useState(false);
  const [file, setFile] = useState<File | null>(null);
  const [category, setCategory] = useState("Policies");
    const [uploadCount, setUploadCount] = useState<number>(0);
  const [uploadPeriod, setUploadPeriod] = useState<string>("");
const [downloadCount, setDownloadCount] = useState<number>(0);
const [downloadPeriod, setDownloadPeriod] = useState<string>("This month");
const STORAGE_LIMIT = 50 * 1024 * 1024 * 1024; // 50 GB dalam bytes

  useEffect(() => {
    fetchDocuments();
  }, []);

   useEffect(() => {
    const fetchUploads = async () => {
      try {
        const res = await api_laravel.get("/api/documents/stats"); 
        // contoh response { count: 5, period: "This week" }
        setUploadCount(res.data.count || 0);
        setUploadPeriod(res.data.period || "This week");
      } catch (err) {
        console.error("Gagal mengambil data uploads", err);
      }
    };

    fetchUploads();
  }, []);

const formatFileSize = (bytes: number) => {
  if (bytes === 0) return "0 Bytes";
  const k = 1024;
  const sizes = ["Bytes", "KB", "MB", "GB", "TB"];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
};

  const fetchDocuments = () => {
    api_laravel.get("/api/documents")
      .then((res) => setDocuments(res.data.data))
      .catch((err) => console.error(err));
  };

const fetchDownloadCount = async () => {
  try {
    const res = await api_laravel.get("/api/documents/downloads");
    setDownloadCount(res.data.downloads || 0);
    setDownloadPeriod(res.data.period || "This month");
  } catch (err) {
    console.error("Gagal mengambil total download", err);
  }
};

// Hitung total storage dari semua dokumen
const getTotalStorageUsed = () => {
  const totalBytes = documents.reduce((sum, doc) => sum + Number(doc.size || 0), 0);
  return totalBytes;
};


useEffect(() => {
  fetchDownloadCount();
}, []);


const handleView = (url: string) => {
  window.open(url, "_blank");
};

// fungsi download
const handleDownload = async (id: number, fileName: string) => {
  try {
    const response = await api_laravel.get(`/api/documents/${id}/download`, {
      responseType: "blob",
    });

    const url = window.URL.createObjectURL(new Blob([response.data]));
    const a = document.createElement("a");
    a.href = url;
    a.download = fileName || "document.pdf";
    document.body.appendChild(a);
    a.click();
    a.remove();
    window.URL.revokeObjectURL(url);

    // update total download setelah berhasil download
    fetchDownloadCount();
  } catch (err) {
    console.error("Download error:", err);
  }
};



  const handleUpload = async () => {
  if (!file) return;

  const formData = new FormData();
  formData.append("document", file);
  formData.append("category", category);
  formData.append("access", "All Employees"); // default
  formData.append("version", "1.0");

  try {
    const res = await api_laravel.post("/api/documents", formData, {
      headers: { "Content-Type": "multipart/form-data" },
    });

    setShowUpload(false);
    setFile(null);
    fetchDocuments();

    Swal.fire({
      icon: "success",
      title: "Berhasil",
      text: res.data.message || "Dokumen berhasil diupload!",
      timer: 2000,
      showConfirmButton: false,
    });
  } catch (err: any) {
    Swal.fire({
      icon: "error",
      title: "Upload Gagal",
      text: err.response?.data?.message || "Terjadi kesalahan saat upload",
    });
    console.error("Upload gagal:", err.response?.data || err);
  }
};

  // daftar kategori
  const categories = ["All", "Policies", "HR Forms", "Contracts", "Security"];

  const filteredDocuments = documents.filter((doc) => {
    const matchesSearch =
      doc.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      doc.type.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory =
      selectedCategory === "All" || doc.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  const getAccessBadge = (access: string) => {
    switch (access) {
      case "All Employees":
        return <Badge className="status-active">All Employees</Badge>;
      case "Managers Only":
        return <Badge className="status-pending">Managers Only</Badge>;
      case "Remote Employees":
        return <Badge variant="outline">Remote Employees</Badge>;
      default:
        return <Badge variant="secondary">{access}</Badge>;
    }
  };

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Document Management</h1>
          <p className="text-muted-foreground">
            Organize and manage company documents, policies, and forms.
          </p>
        </div>
        <Button className="btn-gradient" onClick={() => setShowUpload(true)}>
          <Upload className="h-4 w-4 mr-2" />
          Upload Document
        </Button>
      </div>

      {/* Modal Upload */}
      {showUpload && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-lg p-6 w-[400px]">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-semibold">Upload Document</h2>
              <button onClick={() => setShowUpload(false)}>
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="space-y-4">
              <Input
                type="file"
                onChange={(e) => setFile(e.target.files ? e.target.files[0] : null)}
              />
              <select
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                className="w-full border rounded p-2"
              >
                {categories.map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
              <Button onClick={handleUpload} className="w-full">
                Upload
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Document Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <Card className="card-metric">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Total Documents</p>
                <p className="text-3xl font-bold text-foreground">{documents.length}</p>
                <p className="text-sm text-muted-foreground">Across all categories</p>
              </div>
              <div className="p-3 rounded-lg bg-primary-light">
                <FileText className="h-6 w-6 text-primary" />
              </div>
            </div>
          </CardContent>
        </Card>

         <Card className="card-metric">
      <CardContent className="p-6">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-muted-foreground">
              Recent Uploads
            </p>
            <p className="text-3xl font-bold text-foreground">
              {uploadCount}
            </p>
            <p className="text-sm text-success">{uploadPeriod}</p>
          </div>
          <div className="p-3 rounded-lg bg-success-light">
            <Upload className="h-6 w-6 text-success" />
          </div>
        </div>
      </CardContent>
    </Card>

        <Card className="card-metric">
  <CardContent className="p-6">
    <div className="flex items-center justify-between">
      <div>
        <p className="text-sm font-medium text-muted-foreground">Downloads</p>
        <p className="text-3xl font-bold text-foreground">{downloadCount}</p>
        <p className="text-sm text-muted-foreground">{downloadPeriod}</p>
      </div>
      <div className="p-3 rounded-lg bg-warning-light">
        <Download className="h-6 w-6 text-warning" />
      </div>
    </div>
  </CardContent>
</Card>

        <Card className="card-metric bg-gradient-primary text-white">
  <CardContent className="p-6">
    <div className="flex items-center justify-between">
      <div>
        <p className="text-sm font-medium text-white/80">Storage Used</p>
        <p className="text-3xl font-bold text-white">
          {formatFileSize(getTotalStorageUsed())}
        </p>
        <p className="text-sm text-white/90">
          of {formatFileSize(STORAGE_LIMIT)} limit
        </p>
      </div>
      <div className="p-3 rounded-lg bg-white/20">
        <FileText className="h-6 w-6 text-white" />
      </div>
    </div>
  </CardContent>
</Card>

      </div>

      <Tabs defaultValue="all" className="space-y-6">
        <TabsList>
          <TabsTrigger value="all">All Documents</TabsTrigger>
          <TabsTrigger value="recent">Recent</TabsTrigger>
          <TabsTrigger value="shared">Shared</TabsTrigger>
        </TabsList>

        <TabsContent value="all" className="space-y-6">
          <Card className="card-dashboard">
            <CardHeader>
              <div className="flex justify-between items-center">
                <CardTitle>Document Library</CardTitle>
                <Button variant="outline">
                  <Plus className="h-4 w-4 mr-2" />
                  New Folder
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              {/* Search and Filters */}
              <div className="flex flex-col sm:flex-row gap-4 mb-6">
                <div className="relative flex-1">
                  <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input
                    placeholder="Search documents..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-10"
                  />
                </div>
                <Button variant="outline" className="flex items-center">
                  <Filter className="h-4 w-4 mr-2" />
                  Filter
                </Button>
              </div>

              {/* Document List */}
              <div className="space-y-3">
                {filteredDocuments.map((doc) => (
                  <div
                    key={doc.id}
                    className="flex items-center justify-between p-4 border rounded-lg hover:bg-muted/50 transition-colors"
                  >
                    <div className="flex items-center space-x-4">
                      <div className="p-2 bg-primary-light rounded-lg">
                        <FileText className="h-5 w-5 text-primary" />
                      </div>
                      <div>
                        <h3 className="font-medium">{doc.name}</h3>
                        <div className="flex items-center space-x-3 text-sm text-muted-foreground">
                          <span>{doc.format}</span>
                          <span>•</span>
                          <span>{formatFileSize(Number(doc.size))}</span>
                          <span>•</span>
                          <span>{doc.upload_date}</span>
                          <span>•</span>
                          <span>{doc.version}</span>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center space-x-3">
                      <Badge variant="outline">{doc.category}</Badge>
                      {getAccessBadge(doc.access)}
<DropdownMenu>
  <DropdownMenuTrigger asChild>
    <Button variant="ghost" size="sm">
      <Eye className="h-4 w-4" />
    </Button>
  </DropdownMenuTrigger>
  <DropdownMenuContent align="end">
    <DropdownMenuItem onClick={() => handleView(doc.file_url)}>
      <Eye className="h-4 w-4 mr-2" />
      View
    </DropdownMenuItem>
   <DropdownMenuItem onClick={() => handleDownload(doc.id, doc.name)}>
  <Download className="h-4 w-4 mr-2" />
  Download
</DropdownMenuItem>
    <DropdownMenuItem>
      <Edit className="h-4 w-4 mr-2" />
      Edit Details
    </DropdownMenuItem>
    <DropdownMenuItem className="text-destructive">
      <Trash2 className="h-4 w-4 mr-2" />
      Delete
    </DropdownMenuItem>
  </DropdownMenuContent>
</DropdownMenu>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="recent">
          <Card className="card-dashboard">
            <CardHeader>
              <CardTitle>Recent Documents</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-center py-12">
                <FileText className="h-16 w-16 mx-auto text-muted-foreground mb-4" />
                <p className="text-muted-foreground">Recent documents will appear here</p>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="shared">
          <Card className="card-dashboard">
            <CardHeader>
              <CardTitle>Shared Documents</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-center py-12">
                <FileText className="h-16 w-16 mx-auto text-muted-foreground mb-4" />
                <p className="text-muted-foreground">Shared documents will appear here</p>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
