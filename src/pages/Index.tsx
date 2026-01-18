import React, { useEffect, useState } from 'react';
import { DashboardLayout } from '@/components/layout/DashboardLayout';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { FileText, Users, DollarSign, Clock } from 'lucide-react';
import { supabase } from '@/lib/supabase';
import { useAuth } from '@/contexts/AuthContext';

const Index = () => {
  const { user } = useAuth();
  const [stats, setStats] = useState({
    budgetsCount: 0,
    clientsCount: 0,
    totalValue: 0,
    pendingCount: 0
  });

  useEffect(() => {
    if (!user) return;

    const fetchStats = async () => {
      const { data: company } = await supabase
        .from('companies')
        .select('id')
        .eq('user_id', user.id)
        .single();

      if (!company) return;

      const [budgetsRes, clientsRes] = await Promise.all([
        supabase.from('budgets').select('total, status').eq('company_id', company.id),
        supabase.from('clients').select('id', { count: 'exact' }).eq('company_id', company.id)
      ]);

      if (budgetsRes.data) {
        const total = budgetsRes.data.reduce((acc, curr) => acc + Number(curr.total), 0);
        const pending = budgetsRes.data.filter(b => b.status === 'sent').length;
        setStats({
          budgetsCount: budgetsRes.data.length,
          clientsCount: clientsRes.count || 0,
          totalValue: total,
          pendingCount: pending
        });
      }
    };

    fetchStats();
  }, [user]);

  const cards = [
    { title: 'Orçamentos', value: stats.budgetsCount, icon: FileText, color: 'text-blue-600' },
    { title: 'Clientes', value: stats.clientsCount, icon: Users, color: 'text-green-600' },
    { title: 'Valor Total', value: `R$ ${stats.totalValue.toFixed(2)}`, icon: DollarSign, color: 'text-purple-600' },
    { title: 'Pendentes', value: stats.pendingCount, icon: Clock, color: 'text-amber-600' },
  ];

  return (
    <DashboardLayout>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">Bem-vindo ao ProBudget</h1>
        <p className="text-gray-600">Aqui está o resumo do seu negócio hoje.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {cards.map((card, index) => (
          <Card key={index}>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-gray-500">{card.title}</CardTitle>
              <card.icon className={`h-5 w-5 ${card.color}`} />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{card.value}</div>
            </CardContent>
          </Card>
        ))}
      </div>
    </DashboardLayout>
  );
};

export default Index;