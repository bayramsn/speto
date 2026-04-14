import type { FC } from 'react';
import { Search, Bell, Settings } from 'lucide-react';
import { useLocation } from 'react-router-dom';

import { useAdminAuth } from '../auth/AdminAuthContext';

const pathTitles: Record<string, string> = {
  '/': 'Genel Bakış',
  '/businesses': 'İşletmeler',
  '/orders': 'Siparişler',
  '/users': 'Kullanıcılar',
  '/events': 'Etkinlik & Puan',
  '/finance': 'Finans',
  '/reports': 'Raporlar',
  '/notifications': 'Bildirimler',
  '/support': 'Destek',
  '/settings': 'Ayarlar',
};

export const Topbar: FC = () => {
  const location = useLocation();
  const { session } = useAdminAuth();
  const title =
    pathTitles[location.pathname] ||
    (location.pathname.startsWith('/businesses/')
      ? 'İşletme Çalışma Alanı'
      : 'Dashboard');

  return (
    <header className="w-full h-16 sticky top-0 z-40 bg-white/80 dark:bg-gray-900/80 backdrop-blur-md shadow-sm flex justify-between items-center px-8 border-b border-surface-container">
      <div className="flex items-center gap-6">
        <h1 className="text-xl font-bold tracking-tight text-on-surface font-headline">{title}</h1>
        <div className="relative group hidden md:block">
          <span className="absolute inset-y-0 left-0 pl-3 flex items-center text-slate-400">
            <Search className="w-4 h-4" />
          </span>
          <input 
            className="bg-surface-container-low border-none rounded-full py-2 pl-10 pr-4 text-xs w-64 focus:ring-2 focus:ring-primary-container focus:bg-white transition-all outline-none" 
            placeholder="Arama yap..." 
            type="text"
          />
        </div>
      </div>
      <div className="flex items-center gap-4">
        <button className="w-10 h-10 flex items-center justify-center rounded-full text-slate-500 hover:bg-slate-50 transition-colors">
          <Bell className="w-5 h-5" />
        </button>
        <button className="w-10 h-10 flex items-center justify-center rounded-full text-slate-500 hover:bg-slate-50 transition-colors">
          <Settings className="w-5 h-5" />
        </button>
        <div className="h-8 w-px bg-slate-200 mx-2"></div>
        <div className="flex items-center gap-3">
          <div className="text-right hidden sm:block">
            <p className="text-xs font-bold text-on-surface">{session?.user.displayName}</p>
            <p className="text-[10px] text-primary font-semibold">Super Admin Oturumu</p>
          </div>
          <div className="w-10 h-10 rounded-full border-2 border-primary-container overflow-hidden bg-emerald-50 flex items-center justify-center font-bold text-primary">
            {session?.user.avatarUrl ? (
              <img
                alt="Super Admin Profile"
                className="w-full h-full object-cover"
                src={session.user.avatarUrl}
              />
            ) : (
              session?.user.displayName.slice(0, 1).toUpperCase()
            )}
          </div>
        </div>
      </div>
    </header>
  );
};
