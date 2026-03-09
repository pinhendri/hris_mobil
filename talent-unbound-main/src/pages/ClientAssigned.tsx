"use client";

import { useState, useEffect } from "react";
import { useParams, Link } from "react-router-dom";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";
import dayjs from "dayjs";

interface AssignedEmployee {
  uuid: string;
  name: string;
  shift_date: string;
  role?: string;
}

interface Pagination {
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}

const formatDate = (d?: string) => (d ? dayjs(d).format("YYYY-MM-DD") : "-");

const ClientAssigned = () => {
  const { uuid: clientUuid } = useParams<{ uuid: string }>();
  const [employees, setEmployees] = useState<AssignedEmployee[]>([]);
  const [loading, setLoading] = useState(false);
  const [pagination, setPagination] = useState<Pagination | null>(null);
  const [page, setPage] = useState(1);

  const fetchAssigned = async (pageNumber: number = 1) => {
    if (!clientUuid) return;
    try {
      setLoading(true);
      const res = await api_laravel.get(`/api/clients/${clientUuid}/employees?page=${pageNumber}`);
      setEmployees(res.data.data || []);
      setPagination(res.data.pagination || null);
      setPage(pageNumber);
    } catch (error: any) {
      Swal.fire("Error", error?.response?.data?.message || error.message || "Gagal ambil data assigned", "error");
    } finally {
      setLoading(false);
    }
  };

  const handlePageChange = (newPage: number) => {
    if (!pagination) return;
    if (newPage < 1 || newPage > pagination.last_page) return;
    fetchAssigned(newPage);
  };

  const handleRemove = async (uuid: string, name: string) => {
    const confirm = await Swal.fire({
      title: `Remove ${name}?`,
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "Yes",
    });
    if (!confirm.isConfirmed) return;

    try {
      await api_laravel.delete(`/api/clients/${clientUuid}/employees/${uuid}`);
      Swal.fire({ icon: "success", title: "Removed", timer: 1200, showConfirmButton: false });
      fetchAssigned(page);
    } catch (err: any) {
      Swal.fire("Error", err?.response?.data?.message || err.message, "error");
    }
  };

  useEffect(() => {
    fetchAssigned();
  }, [clientUuid]);

  if (!clientUuid) return <p>Client UUID not found in URL</p>;

  return (
    <Card>
      <CardHeader className="flex justify-between items-center">
        <CardTitle>Assigned Employees</CardTitle>
        <Button onClick={() => fetchAssigned(page)} variant="ghost">Refresh111</Button>
      </CardHeader>
      <CardContent>
        {loading ? (
          <p>Loading...</p>
        ) : employees.length === 0 ? (
          <p>No assigned employees yet.</p>
        ) : (
          <>
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Name</TableHead>
                    <TableHead>Shift Date</TableHead>
                    <TableHead>Role</TableHead>
                    <TableHead>Aksi</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {employees.map(emp => (
                    <TableRow key={emp.uuid}>
                      <TableCell>{emp.name}</TableCell>
                      <TableCell>{formatDate(emp.shift_date)}</TableCell>
                      <TableCell>{emp.role || "-"}</TableCell>
                      <TableCell>
                        <Button
                          size="sm"
                          variant="destructive"
                          onClick={() => handleRemove(emp.uuid, emp.name)}
                        >
                          Remove
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>

            {pagination && (
              <div className="flex justify-center gap-2 mt-4">
                <Button disabled={page <= 1} onClick={() => handlePageChange(page - 1)}>Prev</Button>
                <span className="flex items-center px-2">Page {page} of {pagination.last_page}</span>
                <Button disabled={page >= pagination.last_page} onClick={() => handlePageChange(page + 1)}>Next</Button>
              </div>
            )}
          </>
        )}
        <div className="mt-4">
          <Link to="/clients">
            <Button variant="outline">Back to Clients</Button>
          </Link>
        </div>
      </CardContent>
    </Card>
  );
};

export default ClientAssigned;
