import type { FC } from 'react';
import { NavLink } from 'react-router-dom';
import { 
  BarChart, 
  Bell, 
  LayoutDashboard, 
  Receipt, 
  Settings, 
  Store, 
  Users, 
  Headset, 
  Wallet, 
  Star,
  ShieldCheck,
} from 'lucide-react';

import { useAdminAuth } from '../auth/adminAuth';

const navItems = [
  { path: '/', label: 'Dashboard', icon: LayoutDashboard },
  { path: '/businesses', label: 'İşletmeler', icon: Store },
  { path: '/orders', label: 'Siparişler', icon: Receipt },
  // { path: '/campaigns', label: 'Kampanyalar', icon: Megaphone },
  { path: '/users', label: 'Kullanıcılar', icon: Users },
  { path: '/events', label: 'Etkinlik & Puan', icon: Star },
  { path: '/finance', label: 'Finans', icon: Wallet },
  { path: '/reports', label: 'Raporlar', icon: BarChart },
  { path: '/notifications', label: 'Bildirimler', icon: Bell },
  { path: '/support', label: 'Destek', icon: Headset },
  { path: '/audit-logs', label: 'Audit Logs', icon: ShieldCheck },
  { path: '/settings', label: 'Ayarlar', icon: Settings },
];

type SidebarProps = {
  mobileOpen?: boolean;
  onClose?: () => void;
};

export const Sidebar: FC<SidebarProps> = ({ mobileOpen = false, onClose }) => {
  const { session, logout } = useAdminAuth();

  return (
    <>
      <div
        className={`fixed inset-0 z-40 bg-slate-950/40 lg:hidden ${mobileOpen ? 'block' : 'hidden'}`}
        onClick={onClose}
      />
      <aside
        className={`h-screen w-64 fixed left-0 top-0 overflow-y-auto bg-slate-50 flex flex-col py-6 px-4 gap-2 z-50 transition-transform lg:translate-x-0 ${
          mobileOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
        }`}
      >
      <div className="mb-8 px-4">
        <h1 className="text-2xl font-bold text-primary tracking-tight font-headline">SepetPro</h1>
        <p className="text-xs text-slate-500 font-medium">God Mode Admin</p>
      </div>
      
      <nav className="flex flex-col gap-1">
        {navItems.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.path}
              to={item.path}
              onClick={onClose}
              className={({ isActive }) =>
                `flex items-center gap-3 py-3 px-4 rounded-xl font-headline font-medium text-sm transition-colors duration-200 ${
                  isActive
                    ? 'text-primary font-bold border-r-4 border-primary bg-primary/10'
                    : 'text-slate-600 hover:bg-emerald-50'
                }`
              }
            >
              <Icon className="w-5 h-5" />
              <span>{item.label}</span>
            </NavLink>
          );
        })}
      </nav>

      <div className="mt-auto pt-6 border-t border-slate-200 px-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-emerald-100 flex items-center justify-center text-primary font-bold overflow-hidden">
            {session?.user.avatarUrl ? (
              <img
                className="w-full h-full object-cover"
                src={session.user.avatarUrl}
                alt={session.user.displayName}
              />
            ) : (
              <span>{session?.user.displayName.slice(0, 1).toUpperCase()}</span>
            )}
          </div>
          <div>
            <p className="text-xs font-bold text-on-surface">{session?.user.displayName}</p>
            <p className="text-[10px] text-slate-500">{session?.user.email}</p>
          </div>
        </div>
        <button
          className="mt-4 w-full rounded-2xl bg-slate-900 text-white py-3 text-sm font-bold hover:bg-slate-800 transition-colors"
          onClick={() => {
            void logout();
          }}
          type="button"
        >
          Güvenli Çıkış
        </button>
      </div>
      </aside>
    </>
  );
};
