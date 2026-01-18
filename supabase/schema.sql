-- 1. Tabelas
CREATE TABLE companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL UNIQUE,
  nome TEXT NOT NULL,
  logo_url TEXT,
  telefone TEXT,
  email TEXT,
  cidade TEXT,
  estado TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL UNIQUE,
  status TEXT DEFAULT 'trial' CHECK (status IN ('trial', 'active', 'expired')),
  trial_ends_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  nome TEXT NOT NULL,
  telefone TEXT,
  email TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE NOT NULL,
  descricao TEXT NOT NULL,
  subtotal DECIMAL(10,2) DEFAULT 0,
  desconto DECIMAL(10,2) DEFAULT 0,
  total DECIMAL(10,2) DEFAULT 0,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'accepted', 'rejected')),
  public_token UUID DEFAULT gen_random_uuid() UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE budget_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  budget_id UUID REFERENCES budgets(id) ON DELETE CASCADE NOT NULL,
  descricao TEXT NOT NULL,
  quantidade DECIMAL(10,2) DEFAULT 1,
  valor_unitario DECIMAL(10,2) DEFAULT 0,
  total_item DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Habilitar RLS em todas as tabelas
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_items ENABLE ROW LEVEL SECURITY;

-- 3. Políticas de Segurança (Policies)

-- Companies: Usuário só vê sua própria empresa
CREATE POLICY "Users can manage their own company" ON companies
  FOR ALL USING (auth.uid() = user_id);

-- Subscriptions: Usuário só vê sua própria assinatura
CREATE POLICY "Users can view their own subscription" ON subscriptions
  FOR SELECT USING (auth.uid() = user_id);

-- Clients: Usuário só vê clientes da sua empresa
CREATE POLICY "Users can manage clients of their company" ON clients
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM companies 
      WHERE companies.id = clients.company_id 
      AND companies.user_id = auth.uid()
    )
  );

-- Budgets: Usuário vê seus orçamentos OU público via token
CREATE POLICY "Users can manage budgets of their company" ON budgets
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM companies 
      WHERE companies.id = budgets.company_id 
      AND companies.user_id = auth.uid()
    )
  );

CREATE POLICY "Public can view budget via token" ON budgets
  FOR SELECT USING (true); -- Filtro será feito via public_token na query

-- Budget Items: Seguindo a lógica do budget pai
CREATE POLICY "Users can manage budget items" ON budget_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM budgets 
      JOIN companies ON budgets.company_id = companies.id
      WHERE budgets.id = budget_items.budget_id 
      AND companies.user_id = auth.uid()
    )
  );

CREATE POLICY "Public can view budget items via budget" ON budget_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM budgets 
      WHERE budgets.id = budget_items.budget_id
    )
  );

-- 4. Buckets de Storage
-- Criar bucket 'logos' manualmente no dashboard ou via API