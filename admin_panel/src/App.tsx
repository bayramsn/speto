import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';

import { AdminAuthProvider } from './auth/AdminAuthContext';
import { ProtectedRoute } from './auth/ProtectedRoute';
import { DashboardLayout } from './layouts/DashboardLayout';

import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
import { Businesses } from './pages/Businesses';
import { Orders } from './pages/Orders';
import { Users } from './pages/Users';
import { Events } from './pages/Events';
import { Finance } from './pages/Finance';
import { Reports } from './pages/Reports';
import { Notifications } from './pages/Notifications';
import { Support } from './pages/Support';
import { Settings } from './pages/Settings';
import { BusinessWorkspace } from './pages/BusinessWorkspace';
import { AuditLogs } from './pages/AuditLogs';

function App() {
  return (
    <AdminAuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />

          <Route element={<ProtectedRoute />}>
            <Route path="/" element={<DashboardLayout />}>
              <Route index element={<Dashboard />} />
              <Route path="businesses" element={<Businesses />} />
              <Route path="businesses/:businessId" element={<Navigate replace to="overview" />} />
              <Route
                path="businesses/:businessId/:tab"
                element={<BusinessWorkspace />}
              />
              <Route path="orders" element={<Orders />} />
              <Route path="users" element={<Users />} />
              <Route path="events" element={<Events />} />
              <Route path="finance" element={<Finance />} />
              <Route path="reports" element={<Reports />} />
              <Route path="notifications" element={<Notifications />} />
              <Route path="support" element={<Support />} />
              <Route path="audit-logs" element={<AuditLogs />} />
              <Route path="settings" element={<Settings />} />
            </Route>
          </Route>

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AdminAuthProvider>
  );
}

export default App;
