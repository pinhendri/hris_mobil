import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { MainLayout } from "@/components/Layout/MainLayout";

import Dashboard from "./pages/Dashboard";
import Employees from "./pages/Employees";
import Recruitment from "./pages/Recruitment";
import Leave from "./pages/Leave";
import Performance from "./pages/Performance";
import TimeTracking from "./pages/TimeTracking";
import Departments from "./pages/Departments";
import Reports from "./pages/Reports";
import Documents from "./pages/Documents";
import Settings from "./pages/Settings";
import NotFound from "./pages/NotFound";
import Login from "./pages/Login";
import AddEmployeePage from "./pages/AddEmployee";
import EmployeeDetail from "./pages/EmployeeDetail";
import EditEmployeePage from "./pages/EditEmployee";
import Attendance from "./pages/Attendance";
import Clients from "./pages/Clients";
import AssignEmployee from "./pages/AssignEmployee";
import AddClientPage from "./pages/AddClient";
import EditClientPage from "./pages/EditClient";
import ClientAssigned from "./pages/ClientAssigned";
import Payroll from "./pages/Payroll";
import PayrollSettings from "./pages/PayrollSettings";
import OrgStructure from "@/components/OrgStructure";
import ApplicationsPage from "./pages/ApplicationsPage";
import DepartmentGoals from "./pages/DepartmentGoals";
import EmplooyeeGoals from "./pages/employee-goals";
import UserAssign from "./pages/AssignRolePage";
import ProfilePage from "./pages/ProfilePage"; // ✅ Profile page
import ChangePassword from "./pages/ChangePassword"; // ✅ Change password page
import EmployeeAttendanceHistory from "@/pages/EmployeeAttendanceHistory";
import RoleManagement from "./pages/role-management";
import RoleGroup from "./pages/role-group";
import RoleUser from "./pages/role-user";
import Corection from "./pages/Corection";
import AllowanceCorection from "./pages/allowanceCorection";
import PayrollCorection from "./pages/PayrollCorection";
import InventoryMaster from "./pages/InventoryMaster";
import IssueStock from "./pages/IssueStock";
import RequestStock from "./pages/RequestStock";
import ReceiptStock from "./pages/ReceiptStock";
import ReportStock from "./pages/ReportStock";
import LeaveBalancePage from "./pages/LeaveBalancePage"
import CompanyMasterFile from "./pages/CompanyMasterFile"
import CompanyAssign from "./pages/CompanyAssign"
import KpiForm from "./pages/KpiForm"
import MasterKpiList from "./pages/MasterKpiList"
import KpiMasterCreate from "./pages/KpiMasterCreate"
import KpiMasterEdit from "./pages/KpiMasterEdit"
import KpiAssign from "./pages/KpiAssign"
import AssignKpi from "./pages/AssignKpi"
import KpiEvaluasi from "./pages/KpiEvaluation"
import KpiList from "./pages/EvaluationList"
import KpiListDetail from "./pages/EvaluationListDetails"
import EmployeeListOne from "@/components/Employees/EmployeeListOne";
import Broadcasts from "@/pages/BroadcastPage";
import PphReport from "@/pages/PphReportPage";
import PermissionManagement from "@/pages/PermissionManagement";



const queryClient = new QueryClient();

// ✅ ProtectedRoute wrapper
const ProtectedRoute = ({ children }: { children: JSX.Element }) => {
  const token = localStorage.getItem("token");
  if (!token) return <Navigate to="/login" replace />;
  return children;
};

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <Routes>
          {/* Public route */}
          <Route path="/login" element={<Login />} />

          {/* Protected routes (with MainLayout) */}
          <Route
            path="/*"
            element={
              <ProtectedRoute>
                <MainLayout>
                  <Routes>
                    {/* DASHBOARD */}
                    <Route path="/" element={<Dashboard />} />

                    {/* EMPLOYEES */}
                    <Route path="/employees" element={<Employees />} />
                   <Route path="/employees-one" element={<EmployeeListOne />} />
                    <Route path="/employees/add" element={<AddEmployeePage />} />
                    <Route path="/employees/:uuid" element={<EmployeeDetail />} />
                    <Route path="/employees/edit/:uuid" element={<EditEmployeePage />} />
                     {/* ✅ Attendance History */}
                    <Route path="/employees/:uuid/attendance-history" element={<EmployeeAttendanceHistory />}  />

                    {/* OTHER PAGES */}
                    <Route path="/recruitment" element={<Recruitment />} />
                    <Route path="/leave" element={<Leave />} />
                    <Route path="/performance" element={<Performance />} />
                    <Route path="/time-tracking" element={<TimeTracking />} />
                    <Route path="/departments" element={<Departments />} />
                    <Route path="/reports" element={<Reports />} />
                    <Route path="/documents" element={<Documents />} />
                    <Route path="/attendance" element={<Attendance />} />
                    <Route path="/clients" element={<Clients />} />
                    <Route path="/clients/add" element={<AddClientPage />} />
                    <Route path="/clients/edit/:uuid" element={<EditClientPage />} />
                    <Route path="/clients/:uuid" element={<ClientAssigned />} />
                    <Route path="/clients/:uuid/assign" element={<AssignEmployee />} />
                    <Route path="/payroll" element={<Payroll />} />
                    <Route path="/Payroll-Settings" element={<PayrollSettings />} />
                    <Route path="/org-structure" element={<OrgStructure />} />
                    <Route path="/ApplicationsPage" element={<ApplicationsPage />} />
                    <Route path="/kpi/department-goals" element={<DepartmentGoals />} />
                    <Route path="/kpi/employee-goals" element={<EmplooyeeGoals />} />
                    <Route path="/master/assign-user" element={<UserAssign />} />
                    <Route path="/master/role-management" element={<RoleManagement />} />
                    <Route path="/master/role-group" element={<RoleGroup />} />
                    <Route path="/master/role-user" element={<RoleUser />} />
                    <Route path="/Corection/LeaveBalancePage" element={<LeaveBalancePage />} />
                    <Route path="/Corection/Attendance" element={<Corection />} />
                    <Route path="/Corection/allowanceCorection" element={<AllowanceCorection />} />
                    <Route path="/Corection/PayrollCorection" element={<PayrollCorection />} />
                    <Route path="/inventory/master" element={<InventoryMaster />} />
                    <Route path="/inventory/issue-stock" element={<IssueStock />} />
                    <Route path="/inventory/request-stock" element={<RequestStock />} />
                    <Route path="/inventory/receipt-stock" element={<ReceiptStock />} />
                    <Route path="/inventory/report-stock" element={<ReportStock />} />
                    <Route path="/master/company-master" element={<CompanyMasterFile />} />  
                    <Route path="/master/company-assign" element={<CompanyAssign />} />  
                    <Route path="/kpi/master" element={<KpiForm />} />  
                    <Route path="/kpi/kpi-list" element={<MasterKpiList />} />  
                    <Route path="/kpi/master-kpi/create" element={<KpiMasterCreate />} />  
                    <Route path="/kpi/master-kpi/edit/:id" element={<KpiMasterEdit />} />  
                    <Route path="/kpi/master-kpi/assign/:masterKpiId" element={<KpiAssign />} />
                    <Route path="/kpi/master-kpi/assign" element={<AssignKpi />} />  
                    <Route path="/kpi/kpi-evaluasi" element={<KpiEvaluasi />} />  
                    <Route path="/kpi/kpi-evaluation-list" element={<KpiList />} />  
                    <Route path="/kpi/kpi-evaluation/:evaluationId" element={<KpiListDetail />} />  
                    <Route path="/Broadcast" element={<Broadcasts />} />  
                     <Route path="/Report/pph" element={<PphReport />} />  
                    <Route path="/master/permission" element={<PermissionManagement />} />  
                    

                    {/* ✅ USER ACCOUNT PAGES */}
                    <Route path="/profile" element={<ProfilePage />} />
                    <Route path="/change-password" element={<ChangePassword />} />

                    {/* SETTINGS & FALLBACK */}
                    <Route path="/settings" element={<Settings />} />
                    <Route path="*" element={<NotFound />} />
                  </Routes>
                </MainLayout>
              </ProtectedRoute>
            }
          />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
