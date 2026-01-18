import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { useAuth } from '@/contexts/AuthContext';

export function useSubscription() {
  const { user } = useAuth();
  const [status, setStatus] = useState<'trial' | 'active' | 'expired' | 'loading'>('loading');
  const [trialEndsAt, setTrialEndsAt] = useState<string | null>(null);

  useEffect(() => {
    if (!user) return;

    const checkSubscription = async () => {
      const { data, error } = await supabase
        .from('subscriptions')
        .select('*')
        .eq('user_id', user.id)
        .single();

      if (error || !data) {
        setStatus('expired');
        return;
      }

      const endsAt = new Date(data.trial_ends_at);
      const now = new Date();

      if (data.status === 'trial' && now > endsAt) {
        setStatus('expired');
      } else {
        setStatus(data.status);
      }
      setTrialEndsAt(data.trial_ends_at);
    };

    checkSubscription();
  }, [user]);

  return { status, trialEndsAt, isExpired: status === 'expired' };
}