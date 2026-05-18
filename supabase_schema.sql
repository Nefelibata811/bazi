-- ============================================================
-- 八字排盘 App - Supabase 数据库建表脚本
-- 请在 Supabase Dashboard → SQL Editor 中运行此脚本
-- ============================================================

-- 1. 用户档案表（扩展 Supabase 内置 auth.users）
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nickname TEXT,
  avatar_url TEXT,
  phone TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 头像存储桶（需在 Supabase Dashboard > Storage 中手动创建）
-- 桶名称: avatars
-- 访问权限: public (公开读取)

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '用户可读取自己的档案' AND tablename = 'profiles') THEN
    CREATE POLICY "用户可读取自己的档案" ON public.profiles FOR SELECT USING (auth.uid() = id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '用户可更新自己的档案' AND tablename = 'profiles') THEN
    CREATE POLICY "用户可更新自己的档案" ON public.profiles FOR UPDATE USING (auth.uid() = id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '用户可插入自己的档案' AND tablename = 'profiles') THEN
    CREATE POLICY "用户可插入自己的档案" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
  END IF;
END $$;

-- 如果 profiles 表已存在但缺少 avatar_url / phone 列，则添加
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'avatar_url') THEN
    ALTER TABLE public.profiles ADD COLUMN avatar_url TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'phone') THEN
    ALTER TABLE public.profiles ADD COLUMN phone TEXT;
  END IF;
END $$;

-- 2. 八字排盘记录表（按人名存储，支持多次排盘）
CREATE TABLE IF NOT EXISTS public.bazi_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  person_name TEXT NOT NULL,
  request_json TEXT NOT NULL,
  report_json TEXT NOT NULL,
  idempotency_key TEXT,
  saved_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bazi_records' AND column_name = 'idempotency_key') THEN
    ALTER TABLE public.bazi_records ADD COLUMN idempotency_key TEXT;
  END IF;
END $$;

ALTER TABLE public.bazi_records ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '用户可读取自己的排盘记录' AND tablename = 'bazi_records') THEN
    CREATE POLICY "用户可读取自己的排盘记录" ON public.bazi_records FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '用户可插入自己的排盘记录' AND tablename = 'bazi_records') THEN
    CREATE POLICY "用户可插入自己的排盘记录" ON public.bazi_records FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '用户可删除自己的排盘记录' AND tablename = 'bazi_records') THEN
    CREATE POLICY "用户可删除自己的排盘记录" ON public.bazi_records FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

-- 索引
CREATE INDEX IF NOT EXISTS idx_bazi_records_user_id ON public.bazi_records(user_id);
CREATE INDEX IF NOT EXISTS idx_bazi_records_person ON public.bazi_records(user_id, person_name);
CREATE INDEX IF NOT EXISTS idx_bazi_records_saved_at ON public.bazi_records(user_id, saved_at DESC);

-- 幂等键唯一约束（同一用户相同排盘请求只保留一条记录）
-- 已有部署请单独执行下方迁移块，先清理重复数据再添加约束
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'bazi_records_user_idempotency_key_unique'
  ) THEN
    ALTER TABLE public.bazi_records
      ADD CONSTRAINT bazi_records_user_idempotency_key_unique
      UNIQUE (user_id, idempotency_key);
  END IF;
END $$;

-- 迁移说明（已有 bazi_records 表且存在重复 idempotency_key 时）：
-- 1. 查找重复：SELECT user_id, idempotency_key, COUNT(*) FROM bazi_records
--    WHERE idempotency_key IS NOT NULL GROUP BY user_id, idempotency_key HAVING COUNT(*) > 1;
-- 2. 保留最新一条后删除其余重复行
-- 3. 再执行上方 DO 块添加 UNIQUE 约束

-- 3. 合集表（命盘归类系统）
CREATE TABLE IF NOT EXISTS public.collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '用户可读取自己的合集' AND tablename = 'collections') THEN
    CREATE POLICY "用户可读取自己的合集" ON public.collections FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '用户可插入自己的合集' AND tablename = 'collections') THEN
    CREATE POLICY "用户可插入自己的合集" ON public.collections FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '用户可更新自己的合集' AND tablename = 'collections') THEN
    CREATE POLICY "用户可更新自己的合集" ON public.collections FOR UPDATE USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '用户可删除自己的合集' AND tablename = 'collections') THEN
    CREATE POLICY "用户可删除自己的合集" ON public.collections FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

-- 4. 合集-记录关联表
CREATE TABLE IF NOT EXISTS public.collection_records (
  collection_id UUID NOT NULL REFERENCES public.collections(id) ON DELETE CASCADE,
  record_id UUID NOT NULL REFERENCES public.bazi_records(id) ON DELETE CASCADE,
  PRIMARY KEY (collection_id, record_id)
);

ALTER TABLE public.collection_records ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '用户可读取自己的合集记录关联' AND tablename = 'collection_records') THEN
    CREATE POLICY "用户可读取自己的合集记录关联" ON public.collection_records FOR SELECT
      USING (
        EXISTS (SELECT 1 FROM public.collections c WHERE c.id = collection_id AND c.user_id = auth.uid())
      );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '用户可插入自己的合集记录关联' AND tablename = 'collection_records') THEN
    CREATE POLICY "用户可插入自己的合集记录关联" ON public.collection_records FOR INSERT
      WITH CHECK (
        EXISTS (SELECT 1 FROM public.collections c WHERE c.id = collection_id AND c.user_id = auth.uid())
      );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '用户可删除自己的合集记录关联' AND tablename = 'collection_records') THEN
    CREATE POLICY "用户可删除自己的合集记录关联" ON public.collection_records FOR DELETE
      USING (
        EXISTS (SELECT 1 FROM public.collections c WHERE c.id = collection_id AND c.user_id = auth.uid())
      );
  END IF;
END $$;

-- 5. AI 看盘聊天记录表（按排盘记录关联，登录后跨设备同步）
CREATE TABLE IF NOT EXISTS public.bazi_chat_histories (
  record_id UUID PRIMARY KEY REFERENCES public.bazi_records(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  messages JSONB NOT NULL DEFAULT '[]'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.bazi_chat_histories ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '用户可读取自己的聊天记录' AND tablename = 'bazi_chat_histories') THEN
    CREATE POLICY "用户可读取自己的聊天记录" ON public.bazi_chat_histories FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '用户可插入自己的聊天记录' AND tablename = 'bazi_chat_histories') THEN
    CREATE POLICY "用户可插入自己的聊天记录" ON public.bazi_chat_histories FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '用户可更新自己的聊天记录' AND tablename = 'bazi_chat_histories') THEN
    CREATE POLICY "用户可更新自己的聊天记录" ON public.bazi_chat_histories FOR UPDATE USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '用户可删除自己的聊天记录' AND tablename = 'bazi_chat_histories') THEN
    CREATE POLICY "用户可删除自己的聊天记录" ON public.bazi_chat_histories FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_bazi_chat_histories_user ON public.bazi_chat_histories(user_id, updated_at DESC);

-- 6. 迁移旧数据（如果 saved_charts 表存在且有数据）
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'saved_charts') THEN
    INSERT INTO public.bazi_records (user_id, person_name, request_json, report_json, saved_at)
    SELECT user_id, title, request_json, report_json, saved_at
    FROM public.saved_charts
    ON CONFLICT DO NOTHING;
  END IF;
END $$;
