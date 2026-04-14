import type { FC } from 'react';
import { Outlet } from 'react-router-dom';
import { Sidebar } from '../components/Sidebar';
import { Topbar } from '../components/Topbar';

export const DashboardLayout: FC = () => {
  return (
    <div className="bg-surface text-on-surface min-h-screen flex">
      <Sidebar />
      <main className="ml-64 flex-1 flex flex-col min-h-screen bg-[radial-gradient(circle_at_top_left,_rgba(46,204,113,0.08),_transparent_28%),linear-gradient(180deg,_#f8f9fa_0%,_#f4f6f8_100%)]">
        <Topbar />
        <div className="p-8 max-w-7xl mx-auto w-full">
          <Outlet />
        </div>
      </main>
    </div>
  );
};
