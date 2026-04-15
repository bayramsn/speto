import { useEffect, useRef } from 'react';

type ReloadFn = () => void | Promise<void>;

type UseLiveReloadOptions = {
  enabled?: boolean;
  intervalMs?: number;
};

export function useLiveReload(
  reload: ReloadFn,
  { enabled = true, intervalMs = 30000 }: UseLiveReloadOptions = {},
) {
  const reloadRef = useRef(reload);

  useEffect(() => {
    reloadRef.current = reload;
  }, [reload]);

  useEffect(() => {
    if (!enabled) {
      return undefined;
    }

    let inFlight = false;

    const runReload = () => {
      if (inFlight) {
        return;
      }
      inFlight = true;
      void Promise.resolve(reloadRef.current()).finally(() => {
        inFlight = false;
      });
    };

    const handleFocus = () => {
      runReload();
    };

    const handleVisibility = () => {
      if (document.visibilityState === 'visible') {
        runReload();
      }
    };

    const intervalId = window.setInterval(() => {
      if (document.visibilityState === 'visible') {
        runReload();
      }
    }, intervalMs);

    window.addEventListener('focus', handleFocus);
    document.addEventListener('visibilitychange', handleVisibility);

    return () => {
      window.clearInterval(intervalId);
      window.removeEventListener('focus', handleFocus);
      document.removeEventListener('visibilitychange', handleVisibility);
    };
  }, [enabled, intervalMs]);
}
