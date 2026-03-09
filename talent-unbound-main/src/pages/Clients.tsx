"use client";

import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Link } from "react-router-dom";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";
import dayjs from "dayjs";
import { Eye } from "lucide-react";

interface Client {
  uuid: string;
  name: string;
  address: string;
  contact_person: string;
  phone?: string;
  pks_number?: string;
  contract_start?: string;
  contract_end?: string;
  auto_renew?: boolean;
  status?: "active" | "expired" | "pending";
  notes?: string;
  assigned_count?: number;
}

interface Pagination {
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}

const formatDate = (d?: string) => (d ? dayjs(d).format("YYYY-MM-DD") : "-");

const Clients = () => {
  const [clients, setClients] = useState<Client[]>([]);
  const [pagination, setPagination] = useState<Pagination | null>(null);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);

  const fetchClients = async (pageNumber = 1) => {
    try {
      setLoading(true);
      const res = await api_laravel.get(`/api/clients?page=${pageNumber}`);
      setClients(res.data.data || []);
      setPagination(res.data.pagination || null);
      setPage(pageNumber);
    } catch (error: any) {
      Swal.fire(
        "Error",
        error?.response?.data?.message || error.message || "Gagal ambil client",
        "error"
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchClients(page);
  }, []);

  const handlePageChange = (newPage: number) => {
    if (pagination && newPage > 0 && newPage <= pagination.last_page) {
      fetchClients(newPage);
    }
  };

  const handleExtendContract = async (client: Client) => {
    const { value: newEnd } = await Swal.fire({
      title: `Perpanjang kontrak: ${client.name}`,
      input: "text",
      inputLabel: "Masukkan tanggal akhir baru (YYYY-MM-DD)",
      inputPlaceholder: "2026-12-31",
      showCancelButton: true,
      inputValidator: (value) => {
        if (!value) return "Tanggal harus diisi";
        if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return "Gunakan format YYYY-MM-DD";
        return null;
      },
    });

    if (!newEnd) return;

    try {
      await api_laravel.post(`/api/clients/${client.uuid}/extend`, { new_end_date: newEnd });
      Swal.fire({ icon: "success", title: "Berhasil", text: "Tanggal kontrak diperbarui", timer: 1500, showConfirmButton: false });
      fetchClients(page);
    } catch (error: any) {
      Swal.fire("Error", error?.response?.data?.message || error.message || "Gagal perpanjang kontrak", "error");
    }
  };

  const handleDelete = async (client: Client) => {
    const confirm = await Swal.fire({
      title: `Hapus ${client.name}?`,
      text: "Tindakan ini tidak bisa dibatalkan.",
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "Ya, hapus",
    });

    if (!confirm.isConfirmed) return;

    try {
      await api_laravel.delete(`/api/clients/${client.uuid}`);
      Swal.fire({ icon: "success", title: "Terhapus", timer: 1200, showConfirmButton: false });
      fetchClients(page);
    } catch (error: any) {
      Swal.fire("Error", error?.response?.data?.message || error.message || "Gagal hapus client", "error");
    }
  };

 const handleView = async (uuid: string) => {
  try {
    const res = await api_laravel.get(`/api/clients/${uuid}`);
    const client = res.data.data;

    // ambil value dari kolom yang benar
    const rawLoc = client.location_map ?? client.location ?? client.location_map;
    let mapFrame = "<i>Lokasi tidak tersedia</i>";

    if (rawLoc) {
      // pastikan string dan split lat,lng
      const parts = String(rawLoc).split(",").map((s) => s.trim());
      if (parts.length >= 2) {
        const lat = parseFloat(parts[0]);
        const lng = parseFloat(parts[1]);

        if (!isNaN(lat) && !isNaN(lng)) {
          const q = encodeURIComponent(`${lat},${lng}`);
          const src = `https://maps.google.com/maps?q=${q}&z=16&output=embed`;

          mapFrame = `
            <div style="margin-top:10px;">
              <iframe
                width="100%"
                height="300"
                style="border:0; border-radius:8px;"
                loading="lazy"
                src="${src}"
                referrerpolicy="no-referrer-when-downgrade"
                allowfullscreen>
              </iframe>
            </div>
          `;
        }
      }
    }

    Swal.fire({
      title: client.name,
      html: `
        <p><b>Alamat:</b> ${client.address || "-"}</p>
        <p><b>Kontak:</b> ${client.contact_person || "-"} (${client.phone || "-"})</p>
        <p><b>PKS No.:</b> ${client.pks_number || "-"}</p>
        <p><b>Contract:</b> ${formatDate(client.contract_start)} - ${formatDate(client.contract_end)}</p>
        <p><b>Status:</b> ${client.status}</p>
        <hr/>
        ${mapFrame}
      `,
      width: 700,
    });
  } catch (error: any) {
    Swal.fire("Error", error?.response?.data?.message || error.message || "Gagal ambil detail client", "error");
  }
};



  return (
    <Card>
      <CardHeader className="flex justify-between items-center">
        <CardTitle>Clients</CardTitle>
        <div className="flex gap-2">
          <Button asChild>
            <Link to="/clients/add">Tambah Client</Link>
          </Button>
          <Button onClick={() => fetchClients(page)} variant="ghost">Refresh</Button>
        </div>
      </CardHeader>
      <CardContent>
        {loading ? (
          <p>Loading...</p>
        ) : (
          <>
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Nama Client</TableHead>
                    <TableHead>PKS No.</TableHead>
                    <TableHead>Contract Start</TableHead>
                    <TableHead>Contract End</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Assigned</TableHead>
                    <TableHead>Kontak</TableHead>
                    <TableHead>Aksi</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {clients.map((client) => (
                    <TableRow key={client.uuid}>
                     <TableCell className="flex items-center gap-2">
                      <button onClick={() => handleView(client.uuid)} className="text-blue-600 hover:text-blue-800">
                        <Eye size={18} />
                      </button>
                      {client.name}
                    </TableCell>
                      <TableCell>{client.pks_number || "-"}</TableCell>
                      <TableCell>{formatDate(client.contract_start)}</TableCell>
                      <TableCell>{formatDate(client.contract_end)}</TableCell>
                      <TableCell>
                        <span className={
                          client.status === "active" ? "text-green-600" :
                          client.status === "expired" ? "text-red-600" : "text-yellow-600"
                        }>{client.status || "-"}</span>
                      </TableCell>
                      <TableCell>
                        <Link to={`/clients/${client.uuid}`}>
                          <Button size="sm" variant="outline">{client.assigned_count ?? 0} assigned</Button>
                        </Link>
                      </TableCell>
                      <TableCell>
                        {client.contact_person} <br />
                        {client.phone || "-"}
                      </TableCell>
                      <TableCell className="flex gap-2">
                        <Button size="sm" variant="outline" onClick={() => handleExtendContract(client)}>Extend</Button>
                        <Button asChild size="sm">
                          <Link to={`/clients/${client.uuid}/assign`}>Assign</Link>
                        </Button>
                        <Button size="sm" variant="destructive" onClick={() => handleDelete(client)}>Delete</Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>

            {/* Pagination */}
            {pagination && (
              <div className="flex justify-center gap-2 mt-4">
                <Button disabled={page <= 1} onClick={() => handlePageChange(page - 1)}>Prev</Button>
                <span className="flex items-center px-2">Page {page} of {pagination.last_page}</span>
                <Button disabled={page >= pagination.last_page} onClick={() => handlePageChange(page + 1)}>Next</Button>
              </div>
            )}
          </>
        )}
      </CardContent>
    </Card>
  );
};

export default Clients;
