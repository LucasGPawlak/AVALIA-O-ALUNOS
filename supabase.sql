-- ============================================================
-- Registro Rápido em Sala de Aula — Schema Supabase (PostgreSQL)
-- Rode este arquivo no SQL Editor do Supabase (na ordem).
-- ============================================================

-- 1) TABELAS --------------------------------------------------
create table if not exists turmas (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  ano int not null default 2026,
  created_at timestamptz not null default now()
);

create table if not exists estudantes (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  turma_id uuid not null references turmas(id) on delete cascade,
  ativo boolean not null default true,
  created_at timestamptz not null default now()
);
create index if not exists idx_estudantes_turma on estudantes(turma_id);

create table if not exists situacoes (
  id uuid primary key default gen_random_uuid(),
  descricao text not null,
  categoria text not null default 'Comportamento',
  ativo boolean not null default true,
  ordem int not null default 99
);

create table if not exists aulas (
  id uuid primary key default gen_random_uuid(),
  turma_id uuid not null references turmas(id) on delete cascade,
  disciplina text not null default '—',
  professor text,
  data date not null default current_date,
  inicio timestamptz not null default now(),
  fim timestamptz,
  created_at timestamptz not null default now()
);
-- Migração para bancos já criados antes da coluna professor:
alter table aulas add column if not exists professor text;
create index if not exists idx_aulas_turma_data on aulas(turma_id, data);

create table if not exists registros (
  id uuid primary key default gen_random_uuid(),
  aula_id uuid not null references aulas(id) on delete cascade,
  estudante_id uuid not null references estudantes(id) on delete cascade,
  situacao_id uuid not null references situacoes(id) on delete restrict,
  observacao text,
  registrado_em timestamptz not null default now()
);
create index if not exists idx_registros_aula on registros(aula_id, registrado_em);

-- 2) AS SITUAÇÕES (fonte de verdade = banco, não o JS) --------
-- Bloco original (15 itens). Rode 1 vez em bancos novos.
insert into situacoes (descricao, categoria, ordem) values
  ('Não realizou a atividade em sala', 'Atividades', 1),
  ('Não realizou a atividade no Classroom', 'Atividades', 2),
  ('Estava fora da atividade proposta', 'Atividades', 3),
  ('Não cumpriu o prazo da atividade', 'Atividades', 4),
  ('Excesso de conversa', 'Comportamento', 5),
  ('Conversa em tom de voz alto, prejudicando a aula', 'Comportamento', 6),
  ('Brincadeiras inadequadas com colegas', 'Comportamento', 7),
  ('Uso constante do celular durante a aula', 'Comportamento', 8),
  ('Saiu da sala sem autorização', 'Comportamento', 9),
  ('Saiu da sala e não retornou', 'Comportamento', 10),
  ('Não foi ao laboratório quando solicitado', 'Comportamento', 11),
  ('Falta de zelo com o laboratório', 'Laboratório e equipamentos', 12),
  ('Falta de cuidado com os equipamentos', 'Laboratório e equipamentos', 13),
  ('Provocação durante intervenção do professor', 'Relação com o docente', 14),
  ('Elevou o tom de voz com o professor', 'Relação com o docente', 15)
on conflict do nothing;

-- 2b) SITUAÇÃO "OUTRO" (observação obrigatória no app) ----------
-- Seguro para bancos já criados: só insere se ainda não existir.
insert into situacoes (descricao, categoria, ordem)
select 'Outro (descrever na observação)', 'Outros', 16
where not exists (select 1 from situacoes where descricao ilike 'Outro%');

-- 3) DADOS REAIS (DS2 + DS3) ---------------------------------
-- Docentes: Luciano, Gabriel, Lucas (seleção no app, coluna aulas.professor).
-- Disciplinas no app: Programação Back-end, Análise e projeto de sistemas,
-- Programação Mobile, Banco de dados II, Ciência de Dados,
-- Programação Front-end, Introdução a computação, Computação Gráfica.
do $$
declare
  t_ds3 uuid; t_ds2 uuid;
  ds3 text[] := array['ADRIAN KURTS PEREIRA DE OLIVEIRA','ANDRE ROBERTO MARQUES GUIMARAES JUNIOR','CARLA KATHIELY DOS SANTOS SOUZA','DÂMARIS MODESTO RIBEIRO','DANIEL ARAUJO DOS SANTOS','DANIEL AUGUSTO MACHADO MARTINS','DANIEL CARVALHO DE PAULO','DANIELY FERNANDES TIXILISKI','DAVI SOUZA DO CARMO','DÉRICK RODOLFO LAGOS TORRES','EDUARDO SZCREPANSKI DE ALMEIDA NIZ','ENZO DOS SANTOS SERAFIM','FELIPE MENDES ALVES','GIOVANNY DA SILVA CABRAL','GUILHERME ALEXANDRE BONAFINI PEREIRA','HENZO HENRIQUE SANTOS PINTO','JHONATAN ALVES BRONDANI','JHONNY LEENDER GONCALVES ALVES','JOÃO PEDRO HENRIQUE BERNARDO','JÔNATAS SOUZA DA SILVA PEREIRA','JULIA ARTIGAS DE CASTRO','JÚLIA DA SILVA VIEIRA','KARINE RODRIGUES DE OLIVEIRA','LARA AMANDA LOPES DO ROSARIO','LARISSA NAGEL ALVES','LETICIA CANDIDO MENDES','LUAN FELIPE RUSSI MACHADO','LUAN GABRIEL DE LIMA BORGES','LUCAS MARINHO DE FREITAS','LUCAS MATEUS DOMINICO','LUKAS EDUARDO ZEMZISKY SIMPLICIO DA SILVA','MELANY NICOLE COSTA','NATHAN RAMOS PINHEIRO DA SILVA','NÍVEA SUZANA DE VRIJ XAVIER','PAULO AFONSO NEUMANN BAPTISTEL ALVES','PIERRE PEREIRA WAZONKOSKI DELPHIM','STEFFANY ELOISE DE SOUZA DIAS','TIAGO MAHMOUD SAID'];
  ds2 text[] := array['AILTON CORADASSI VIEIRA','ANA BEATRIZ PINTO MOREIRA','ANDRE PYETRO GOMES BATISTA','ANDRIELLYN MARTINS OLIVEIRA DOS SANTOS','ANNA BIATRICE PONTES SPANIER POLI','ARTHUR FERNANDES RAMOS','BENICIO DOS SANTOS DA SILVA','DÃ GABRIEL SILVA VIDAL','ELCIO CRUZ DA VEIGA','ENTHONY GABRIEL ALVES DOS SANTOS','FELIPE FELIX MENDES','GABRIEL GIACOMIN SALVADOR','GIOVANA JASCESKI CAVALHEIRO','HENRY MATSUDA','JEAN VICTOR LAGOS MARCIO','JOÃO HENRIQUE BARÃO NASCIMENTO','JOAO PEDRO SANTOS PADILHA DE ANDRADE','JONAS AUGUSTO TREFELES DOS SANTOS','KAUA HENRIQUE FOSSILE RAMOS','LUAN RAFAEL SOUZA DE PAULA','LUCAS PAREDES DE CAMPOS','MARIA EDUARDA RODRIGUES COSTA','MARIA FERNANDA DE GOIS FERREIRA FONTES','MICKAEL VIANA DE CASTRO','MIGUEL DO CARMO LUZ','MIGUEL NASCIMENTO SILVA','MIRELLA FERNANDA BUENO SIQUEIRA','NATHAN CEZAR ALVES SANCHES','NYCOLAS ANDRÉ MENDES SANTANA','PAULO CESAR AMORIM FILHO','RAFAEL NASCIMENTO SILVA','RENATO YUDY AGOSTINHO DE ANDRADE','RUAN PHELIPE BARCELOS ELESIS','RUBYA VITORIA GONCALVES','TEODORO KREMER SERAFIM','THOMAS FELIPE OLIVEIRA THOME','VICTÓRIA CRISTINE DOS SANTOS','VINICIUS SANTANA DOS SANTOS','ALESSANDRO SANTIAGO DOS SANTOS SILVA JUNIOR'];
  n text;
begin
  insert into turmas (nome, ano) values ('DS3', 2026), ('DS2', 2026)
  on conflict do nothing;

  select id into t_ds3 from turmas where nome = 'DS3' limit 1;
  select id into t_ds2 from turmas where nome = 'DS2' limit 1;

  foreach n in array ds3 loop
    if not exists (select 1 from estudantes where nome = n and turma_id = t_ds3) then
      insert into estudantes (nome, turma_id) values (n, t_ds3);
    end if;
  end loop;

  foreach n in array ds2 loop
    if not exists (select 1 from estudantes where nome = n and turma_id = t_ds2) then
      insert into estudantes (nome, turma_id) values (n, t_ds2);
    end if;
  end loop;
end $$;

-- 4) RLS / SEGURANÇA (MVP) -------------------------------------
-- MVP sem login: habilita RLS e libera SELECT/INSERT/UPDATE/DELETE
-- para a role anon APENAS neste protótipo. Em produção, troque por
-- políticas com auth.uid() (um professor = seus registros).
alter table turmas enable row level security;
alter table estudantes enable row level security;
alter table situacoes enable row level security;
alter table aulas enable row level security;
alter table registros enable row level security;

drop policy if exists "mvp_public_all" on turmas;
drop policy if exists "mvp_public_all" on estudantes;
drop policy if exists "mvp_public_all" on situacoes;
drop policy if exists "mvp_public_all" on aulas;
drop policy if exists "mvp_public_all" on registros;

create policy "mvp_public_all" on turmas      for all to anon using (true) with check (true);
create policy "mvp_public_all" on estudantes  for all to anon using (true) with check (true);
create policy "mvp_public_all" on situacoes   for all to anon using (true) with check (true);
create policy "mvp_public_all" on aulas       for all to anon using (true) with check (true);
create policy "mvp_public_all" on registros   for all to anon using (true) with check (true);

-- Relacionamentos (resumo):
-- turmas 1──N estudantes | turmas 1──N aulas
-- aulas 1──N registros | estudantes 1──N registros | situacoes 1──N registros
