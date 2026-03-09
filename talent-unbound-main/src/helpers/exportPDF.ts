// src/utils/exportPDF.ts
import jsPDF from "jspdf";
import autoTable, { RowInput } from "jspdf-autotable"; // ✅ RowInput biar TS paham

// Helper Export PDF
const exportToPDF = (filename: string, rows: any[], title: string) => {
  if (!rows || rows.length === 0) {
    alert("Tidak ada data untuk diexport.");
    return;
  }

  const doc = new jsPDF();
  doc.setFontSize(16);
  doc.text(title, 14, 20);

  // Header (kolom)
  const headers: string[][] = [Object.keys(rows[0])];

  // Body (data baris)
  const data: RowInput[] = rows.map((row) => Object.values(row) as (string | number)[]);

  autoTable(doc, {
    head: headers,
    body: data,
    startY: 30,
    theme: "grid",
    styles: { fontSize: 9 },
    headStyles: { fillColor: [22, 160, 133] },
  });

  doc.save(filename);
};

export default exportToPDF;
