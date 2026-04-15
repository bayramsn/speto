import { useState, type FC } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';

import { useAdminAuth } from '../auth/adminAuth';
import { AdminApiError } from '../lib/adminApi';

export const Login: FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { login } = useAdminAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError('');
    try {
      await login(email, password);
      const nextPath = (location.state as { from?: { pathname?: string } } | null)?.from
        ?.pathname;
      navigate(nextPath || '/', { replace: true });
    } catch (loginError) {
      setError(
        loginError instanceof AdminApiError
          ? loginError.message
          : 'Giriş yapılırken beklenmeyen bir hata oluştu.',
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="bg-surface text-on-surface min-h-screen flex flex-col justify-between selection:bg-primary-container selection:text-on-primary-container">
      {/* Top Navigation */}
      <header className="fixed top-0 w-full z-50 bg-slate-50/80 backdrop-blur-xl">
        <div className="flex justify-between items-center w-full px-8 py-4">
          <div className="text-2xl font-black text-emerald-800 font-headline tracking-tight">
            SepetPro
          </div>
          <div className="hidden md:flex gap-6 items-center">
            <a className="text-slate-600 font-medium hover:text-emerald-600 transition-colors" href="mailto:destek@sepetpro.app">Destek</a>
            <a className="text-slate-600 font-medium hover:text-emerald-600 transition-colors" href="mailto:security@sepetpro.app">Güvenlik</a>
          </div>
        </div>
      </header>

      <main className="flex-grow flex items-center justify-center px-4 pt-20 pb-12 relative overflow-hidden">
        {/* Asymmetric Background Decorative Elements */}
        <div className="absolute inset-0 pointer-events-none">
          <div className="absolute -top-[10%] -left-[5%] w-[40%] h-[40%] bg-primary-container/5 rounded-full blur-[120px]"></div>
          <div className="absolute bottom-[5%] right-[2%] w-[30%] h-[30%] bg-emerald-700/5 rounded-full blur-[100px]"></div>
        </div>

        {/* Login Container */}
        <div className="relative w-full max-w-md">
          {/* Glassmorphism Card Stack */}
          <div className="bg-surface-container-lowest rounded-xl p-8 md:p-12 shadow-[0_24px_48px_-12px_rgba(0,0,0,0.06)] border border-white/20 relative z-10">
            {/* Brand & Header */}
            <div className="text-center mb-10">
              <div className="inline-flex items-center justify-center w-16 h-16 rounded-xl bg-primary-container/10 text-primary mb-6">
                <span className="material-symbols-outlined text-4xl" style={{ fontVariationSettings: '"FILL" 1' }}>admin_panel_settings</span>
              </div>
              <div className="font-headline font-extrabold text-2xl text-emerald-800 tracking-tight mb-2">SepetPro</div>
              <h1 className="text-on-surface-variant font-medium text-lg">Yönetici Girişi</h1>
            </div>

            {/* Form */}
            <form className="space-y-6" onSubmit={handleLogin}>
              <div className="space-y-2">
                <label className="block text-sm font-semibold text-on-surface-variant ml-1" htmlFor="email">E-posta Adresi</label>
                <div className="relative">
                  <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-outline pointer-events-none text-[20px]">mail</span>
                  <input 
                    className="w-full pl-12 pr-4 py-3.5 bg-surface-container-high border-none rounded-lg focus:ring-2 focus:ring-primary-container focus:bg-surface-container-lowest transition-all duration-200 outline-none text-on-surface" 
                    id="email" 
                    name="email" 
                    placeholder="admin@sepetpro.com" 
                    required 
                    type="email"
                    value={email}
                    onChange={(event) => setEmail(event.target.value)}
                  />
                </div>
              </div>
              <div className="space-y-2">
                <div className="flex justify-between items-center ml-1">
                  <label className="block text-sm font-semibold text-on-surface-variant" htmlFor="password">Şifre</label>
                  <span className="text-xs font-bold text-primary">Admin desteğiyle sıfırlanır</span>
                </div>
                <div className="relative">
                  <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-outline pointer-events-none text-[20px]">lock</span>
                  <input 
                    className="w-full pl-12 pr-4 py-3.5 bg-surface-container-high border-none rounded-lg focus:ring-2 focus:ring-primary-container focus:bg-surface-container-lowest transition-all duration-200 outline-none text-on-surface" 
                    id="password" 
                    name="password" 
                    placeholder="••••••••" 
                    required 
                    type="password"
                    value={password}
                    onChange={(event) => setPassword(event.target.value)}
                  />
                </div>
              </div>
              {error ? (
                <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                  {error}
                </div>
              ) : null}
              <div className="pt-2">
                <button 
                  className="w-full py-4 bg-primary text-on-primary font-bold rounded-lg shadow-[0_8px_16px_-4px_rgba(0,109,55,0.3)] hover:shadow-[0_12px_24px_-6px_rgba(0,109,55,0.4)] transition-all duration-300 transform active:scale-95 flex items-center justify-center gap-2 group" 
                  type="submit"
                  disabled={submitting}
                >
                  {submitting ? 'Giriş yapılıyor...' : 'Giriş Yap'}
                  <span className="material-symbols-outlined text-[20px] group-hover:translate-x-1 transition-transform">arrow_forward</span>
                </button>
              </div>
            </form>

            {/* Help Link */}
            <div className="mt-8 pt-8 border-t border-surface-variant flex items-center justify-center">
              <p className="text-sm text-on-surface-variant">
                Yardıma mı ihtiyacınız var? <a className="font-bold text-emerald-700 hover:underline" href="mailto:destek@sepetpro.app">Destek Merkezi</a>
              </p>
            </div>
          </div>
          {/* Visual Accent: Card Layering Effect */}
          <div className="absolute -bottom-4 left-1/2 -translate-x-1/2 w-[92%] h-10 bg-surface-container-low rounded-xl -z-10 opacity-50"></div>
        </div>
      </main>

      {/* Footer Component from Blueprint */}
      <footer className="w-full border-t border-slate-100 bg-slate-50">
        <div className="w-full max-w-7xl mx-auto px-8 py-6 flex flex-col md:flex-row justify-between items-center">
          <div className="text-slate-500 font-body text-sm mb-4 md:mb-0">
            © 2024 SepetPro Editorial Business Management
          </div>
          <div className="flex gap-6 items-center">
            <span className="text-slate-500 font-body text-sm">Gizlilik Politikası</span>
            <span className="text-slate-500 font-body text-sm">Kullanım Koşulları</span>
            <a className="text-slate-500 hover:text-emerald-700 transition-colors opacity-80 hover:opacity-100 font-body text-sm" href="mailto:destek@sepetpro.app">İletişim</a>
          </div>
        </div>
      </footer>
    </div>
  );
};
