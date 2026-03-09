import { 
  LayoutDashboard, 
  Users, 
  UserPlus, 
  Calendar, 
  TrendingUp, 
  Clock, 
  Settings,
  Building2,
  FileText,
  BarChart3,
  CalendarClock,
  Handshake,
  Wallet,
  ChevronDown,
  ChevronRight
} from "lucide-react";
import { NavLink } from "react-router-dom";
import { useState, useEffect } from "react";
import api_laravel from "@/lib/utils";
import NotificationBadge from "@/components/NotificationBadge";

import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarHeader,
  useSidebar,
} from "@/components/ui/sidebar";

interface MenuItem {
  title: string;
  url?: string;
  icon?: any;
  permission?: string;
  children?: MenuItem[];
}

const navigationItems: MenuItem[] = [
  { 
    title: "Dashboard", 
    url: "/", 
    icon: LayoutDashboard, 
    permission: "view-dashboard" 
  },
  { 
    title: "Employees", 
    url: "/employees", 
    icon: Users, 
    permission: "view-employee" 
  },
    { 
    title: "EmployeesOne", 
    url: "/employees-one", 
    icon: Users, 
    permission: "view-employeeOne" 
  },
  { 
    title: "Attendance", 
    url: "/attendance", 
    icon: CalendarClock, 
    permission: "view-attendance" 
  },


  { 
    title: "Corection", 
    icon: BarChart3, 
    permission: "view-settings",
    children: [
      { 
        title: "Attendance Corection", 
        url: "/Corection/Attendance", 
        permission: "view-settings" 
      },
      { 
        title: "Allowance Corection", 
        url: "/Corection/allowanceCorection", 
        permission: "view-settings" 
      },
      { 
        title: "Payroll Corection", 
        url: "/Corection/PayrollCorection", 
        permission: "view-settings" 
      },
       { 
        title: "Leave Balance Corection", 
        url: "/Corection/LeaveBalancePage", 
        permission: "view-settings" 
      },
    ],
  },

  { 
    title: "Vendor Management", 
    url: "/clients", 
    icon: Handshake, 
    permission: "view-client" 
  },
  { 
    title: "Recruitment", 
    url: "/recruitment", 
    icon: UserPlus, 
    permission: "view-recruitment" 
  },
  { 
    title: "Applications", 
    url: "/ApplicationsPage", 
    icon: UserPlus, 
    permission: "view-recruitment" 
  },
  { 
    title: "Leave Management", 
    url: "/leave", 
    icon: Calendar, 
    permission: "view-leave" 
  },
  
  { 
    title: "Broadcast", 
    url: "/Broadcast", 
    icon: UserPlus, 
    permission: "view-recruitment" 
  },

  { 
    title: "Payroll", 
    url: "/payroll", 
    icon: Wallet, 
    permission: "view-payroll" 
  },
   { 
    title: "PPh Report", 
    url: "/Report/pph", 
    icon: Users, 
    permission: "view-pphreport" 
  },
  { 
    title: "Payroll Settings", 
    url: "/payroll-settings", 
    icon: Settings, 
    permission: "edit-payroll-settings" 
  },
  // { 
  //   title: "Performance", 
  //   url: "/performance", 
  //   icon: TrendingUp, 
  //   permission: "view-performance" 
  // },
  { 
    title: "KPI", 
    icon: BarChart3, 
    permission: "view-kpi",
    children: [

  
        { 
        title: "KPI List", 
        url: "/kpi/kpi-list", 
        permission: "view-department-goals" 
      },
       { 
        title: "List Evaluation", 
        url: "/kpi/kpi-evaluation-list", 
        permission: "view-department-goals" 
      },
      //   { 
      //   title: "KPI Evaluation", 
      //   url: "/kpi/kpi-evaluasi", 
      //   permission: "view-department-goals" 
      // },
      // { 
      //   title: "Department/Project Goals", 
      //   url: "/kpi/department-goals", 
      //   permission: "view-department-goals" 
      // },
      // { 
      //   title: "Employee Goals", 
      //   url: "/kpi/employee-goals", 
      //   permission: "view-employee-goals" 
      // },
    ],
  },
  { 
    title: "Time Tracking", 
    url: "/time-tracking", 
    icon: Clock, 
    permission: "view-time-tracking" 
  },
  { 
    title: "Departments", 
    url: "/departments", 
    icon: Building2, 
    permission: "view-department" 
  },
  { 
    title: "Org Structure", 
    url: "/org-structure", 
    icon: Building2, 
    permission: "view-employee"
  },
  { 
    title: "Reports", 
    url: "/reports", 
    icon: BarChart3, 
    permission: "view-reports" 
  },
  { 
    title: "Documents", 
    url: "/documents", 
    icon: FileText, 
    permission: "view-documents" 
  },
  { 
    title: "Settings", 
    url: "/settings", 
    icon: Settings, 
    permission: "view-settings" 
  },
    { 
    title: "Common Master File", 
    icon: Settings, 
    permission: "view-settings" ,

     children: [
      { 
        title: "Company Master File", 
        url: "/master/company-master", 
        permission: "assign-roles" 
      },

        { 
        title: "Permission Master File", 
        url: "/master/permission", 
        permission: "assign-roles" 
      },

       { 
        title: "User Group", 
        url: "/master/company-assign", 
        permission: "assign-roles" 
      },
           
    ],
  },
  { 
    title: "User Management", 
    icon: Users, 
    permission: "assign-roles",
    children: [
      // { 
      //   title: "Assign Roles", 
      //   url: "/master/assign-user", 
      //   permission: "assign-roles" 
      // },
      { 
        title: "Role Master", 
        url: "/master/role-management", 
        permission: "view-roles" 
      },

        { 
        title: "Group Assign Roles", 
        url: "/master/role-group", 
        permission: "view-roles" 
      },

         { 
        title: "User Assign Group", 
        url: "/master/role-user", 
        permission: "view-roles" 
      },
      // { 
      //   title: "Permission Management", 
      //   url: "/master/permission-management", 
      //   permission: "view-roles" 
      // },

      
    ],
  },

   { 
    title: "Inventory", 
    icon: BarChart3, 
    permission: "view-inventory",
    children: [
      { 
        title: "Inventory Master", 
        url: "/inventory/master", 
        permission: "view-inventory-master" 
      },
      { 
        title: "Request For Issued", 
        url: "/inventory/request-stock", 
        permission: "view-inventory-request" 
      },
       { 
        title: "Receipt Stock", 
        url: "/inventory/Receipt-stock", 
        permission: "view-inventory-receipt" 
      },
      // { 
      //   title: "Issued Stock", 
      //   url: "/inventory/issue-stock", 
      //   permission: "view-inventory-issued" 
      // },
      { 
        title: "Inventory Report", 
        url: "/inventory/report-stock", 
        permission: "view-inventory-report" 
      },

    ],
  },
];

export function AppSidebar() {
  const { state } = useSidebar();
  const collapsed = state === "collapsed";
  const [openMenu, setOpenMenu] = useState<string | null>(null);
  const [userPermissions, setUserPermissions] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);

  // Ambil permissions user yang login
  useEffect(() => {
    const fetchUserPermissions = async () => {
      try {
        const res = await api_laravel.get("/api/me");
        console.log("User data from /api/me:", res.data); // Debug log
        
        const userData = res.data.data?.user || res.data.data;
        const permissions = userData?.permissions || [];
        
        console.log("User permissions:", permissions); // Debug log
        setUserPermissions(permissions);
      } catch (error) {
        console.error("Gagal mengambil permissions user:", error);
        setUserPermissions([]);
      } finally {
        setLoading(false);
      }
    };

    fetchUserPermissions();
  }, []);

  // ✅ FIX: Check permission dengan handling yang lebih baik
  const hasPermission = (permission?: string): boolean => {
    // Jika tidak ada permission requirement, selalu tampilkan
    if (!permission) return true;
    
    // Jika user tidak punya permissions sama sekali, sembunyikan menu yang butuh permission
    if (userPermissions.length === 0) return false;
    
    // Jika user punya wildcard permission, izinkan semua
    if (userPermissions.includes('*')) return true;
    
    // Check permission spesifik
    return userPermissions.includes(permission);
  };

  // ✅ FIX: Filter menu items dengan logic yang benar
  const filteredNavigationItems = navigationItems
    .map(item => {
      // Jika item punya children
      if (item.children) {
        const filteredChildren = item.children.filter(child => 
          hasPermission(child.permission)
        );
        
        // Hanya tampilkan parent jika ada children yang visible ATAU jika parent punya URL sendiri
        const shouldShowParent = filteredChildren.length > 0 || item.url;
        
        return shouldShowParent ? {
          ...item,
          children: filteredChildren.length > 0 ? filteredChildren : undefined
        } : null;
      }
      
      // Jika item tanpa children, tampilkan hanya jika punya permission
      return hasPermission(item.permission) ? item : null;
    })
    .filter((item): item is MenuItem => item !== null);

  const toggleMenu = (title: string) => {
    setOpenMenu(openMenu === title ? null : title);
  };

  // Jika loading, tampilkan skeleton
  if (loading) {
    return (
      <Sidebar className={collapsed ? "w-16" : "w-64"} collapsible="icon">
        <SidebarContent>
          <div className="p-4 text-center text-muted-foreground">Loading menu...</div>
        </SidebarContent>
      </Sidebar>
    );
  }

  // Jika user tidak punya permissions sama sekali, tampilkan minimal menu
  if (userPermissions.length === 0) {
    return (
      <Sidebar className={collapsed ? "w-16" : "w-64"} collapsible="icon">
        <SidebarHeader className="border-b border-sidebar-border p-4">
          <div className="flex items-center space-x-2">
            <div className="w-8 h-8 bg-gradient-primary rounded-lg flex items-center justify-center">
              <Building2 className="h-5 w-5 text-white" />
            </div>
            {!collapsed && (
              <div>
                <h2 className="text-lg font-semibold text-sidebar-foreground">TalentVis</h2>
                <p className="text-xs text-sidebar-foreground/70">HR Management</p>
              </div>
            )}
          </div>
        </SidebarHeader>

        <SidebarContent>
          <SidebarGroup>
            <SidebarGroupLabel>Navigation</SidebarGroupLabel>
            <SidebarGroupContent>
              <SidebarMenu>
                <SidebarMenuItem>
                  <SidebarMenuButton asChild>
                    <NavLink
                      to="/"
                      className={({ isActive }) =>
                        `flex items-center space-x-3 px-3 py-2 rounded-lg transition-colors ${
                          isActive
                            ? "bg-sidebar-accent text-sidebar-primary font-medium"
                            : "text-sidebar-foreground hover:bg-sidebar-accent/50"
                        }`
                      }
                    >
                      <LayoutDashboard className="h-5 w-5" />
                      {!collapsed && <span>Dashboard</span>}
                    </NavLink>
                  </SidebarMenuButton>
                </SidebarMenuItem>
                <SidebarMenuItem>
                  <div className="px-3 py-2 text-sm text-muted-foreground text-center">
                    {!collapsed && "No additional access"}
                  </div>
                </SidebarMenuItem>
              </SidebarMenu>
            </SidebarGroupContent>
          </SidebarGroup>
        </SidebarContent>
      </Sidebar>
    );
  }

  return (
    <Sidebar className={collapsed ? "w-16" : "w-64"} collapsible="icon">
      <SidebarHeader className="border-b border-sidebar-border p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <div className="w-8 h-8 bg-gradient-primary rounded-lg flex items-center justify-center">
              <Building2 className="h-5 w-5 text-white" />
            </div>
            {!collapsed && (
              <div>
                <h2 className="text-lg font-semibold text-sidebar-foreground">TalentVis</h2>
                <p className="text-xs text-sidebar-foreground/70">HR Management</p>
              </div>
            )}
          </div>
          <NotificationBadge />
        </div>
      </SidebarHeader>


      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>Navigation</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {filteredNavigationItems.map((item) => (
                <SidebarMenuItem key={item.title}>
                  {item.children ? (
                    <div>
                      {/* Parent Menu dengan Children */}
                      <button
                        onClick={() => toggleMenu(item.title)}
                        className="flex items-center justify-between w-full px-3 py-2 rounded-lg text-sidebar-foreground hover:text-white hover:bg-sidebar-accent/50 transition-colors"
                      >
                        <div className="flex items-center space-x-3">
                          {item.icon && <item.icon className="h-5 w-5" />}
                          {!collapsed && <span>{item.title}</span>}
                        </div>
                        {!collapsed && item.children && (
                          openMenu === item.title ? (
                            <ChevronDown className="h-4 w-4" />
                          ) : (
                            <ChevronRight className="h-4 w-4" />
                          )
                        )}
                      </button>

                      {/* Children muncul hanya kalau open dan tidak collapsed */}
                      {!collapsed && openMenu === item.title && item.children && (
                        <div className="ml-6 mt-1 space-y-1">
                          {item.children.map((child) => (
                            <NavLink
                              key={child.title}
                              to={child.url!}
                              className={({ isActive }) =>
                                `block px-3 py-2 rounded-md text-sm transition-colors ${
                                  isActive
                                    ? "bg-sidebar-accent text-sidebar-primary font-medium"
                                    : "text-sidebar-foreground hover:text-white hover:bg-sidebar-accent/50"
                                }`
                              }
                            >
                              {child.title}
                            </NavLink>
                          ))}
                        </div>
                      )}
                    </div>
                  ) : (
                    <SidebarMenuButton asChild>
                      <NavLink
                        to={item.url!}
                        end
                        className={({ isActive }) =>
                          `flex items-center space-x-3 px-3 py-2 rounded-lg transition-colors ${
                            isActive
                              ? "bg-sidebar-accent text-sidebar-primary font-medium"
                              : "text-sidebar-foreground hover:bg-sidebar-accent/50"
                          }`
                        }
                      >
                        {item.icon && <item.icon className="h-5 w-5" />}
                        {!collapsed && <span>{item.title}</span>}
                      </NavLink>
                    </SidebarMenuButton>
                  )}
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>

        {/* Debug Info - Hanya di development */}
        {process.env.NODE_ENV === 'development' && !collapsed && (
          <SidebarGroup>
            <SidebarGroupLabel>Debug Info</SidebarGroupLabel>
            <SidebarGroupContent>
              <div className="p-2 text-xs text-muted-foreground space-y-1">
                <div>User Permissions: {userPermissions.length}</div>
                <div>Permissions: {userPermissions.join(', ') || 'None'}</div>
                <div>Visible Menus: {filteredNavigationItems.length}</div>
                <div className="max-h-20 overflow-y-auto">
                  {filteredNavigationItems.map(item => item.title).join(', ')}
                </div>
              </div>
            </SidebarGroupContent>
          </SidebarGroup>
        )}
      </SidebarContent>
    </Sidebar>
  );
}