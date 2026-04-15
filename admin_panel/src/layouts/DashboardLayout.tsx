import type { FC } from 'react';
import { useState } from 'react';
import { Menu } from 'lucide-react';
import { Outlet } from 'react-router-dom';
import { Sidebar } from '../components/Sidebar';
import { Topbar } from '../components/Topbar';

export const DashboardLayout: FC = () => {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <div className="bg-surface text-on-surface min-h-screen flex">
      <Sidebar mobileOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <main className="flex-1 flex flex-col min-h-screen bg-[radial-gradient(circle_at_top_left,_rgba(46,204,113,0.08),_transparent_28%),linear-gradient(180deg,_#f8f9fa_0%,_#f4f6f8_100%)] lg:ml-64">
        <button
          className="fixed left-4 top-4 z-[60] flex h-10 w-10 items-center justify-center rounded-full bg-white shadow lg:hidden"
          onClick={() => setSidebarOpen(true)}
          type="button"
        >
          <Menu className="h-5 w-5" />
        </button>
        <Topbar />
        <div className="p-4 pt-8 md:p-8 max-w-7xl mx-auto w-full">
          <Outlet />
        </div>
      </main>
    </div>
  );
};
