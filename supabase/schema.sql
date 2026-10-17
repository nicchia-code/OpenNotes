-- ==============================================================================
-- OpenNotes - Supabase Database Schema & Policies
-- Progettato per Apple Notes Clone con autenticazione e sincronizzazione Realtime
-- Schema completo risultante dalle migrazioni in supabase/migrations/.
-- ==============================================================================

-- 1. Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Folders Table
CREATE TABLE IF NOT EXISTS public.folders (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    parent_id TEXT REFERENCES public.folders(id) ON DELETE SET NULL,
    icon TEXT NOT NULL DEFAULT 'folder',
    is_system BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revision BIGINT NOT NULL,
    purged_at TIMESTAMPTZ
);

-- 3. Notes Table
CREATE TABLE IF NOT EXISTS public.notes (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT 'Nuova nota',
    content TEXT NOT NULL DEFAULT '',
    folder_id TEXT DEFAULT 'notes',
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    is_pinned BOOLEAN NOT NULL DEFAULT FALSE,
    is_locked BOOLEAN NOT NULL DEFAULT FALSE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revision BIGINT NOT NULL,
    purged_at TIMESTAMPTZ
);

-- 4. Revisions: one sequence for both tables, assigned by the database on every write
CREATE SEQUENCE IF NOT EXISTS public.sync_revision_seq;

CREATE OR REPLACE FUNCTION public.assign_sync_revision()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.revision := nextval('public.sync_revision_seq');
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_folders_revision ON public.folders;
CREATE TRIGGER trg_folders_revision
    BEFORE INSERT OR UPDATE ON public.folders
    FOR EACH ROW EXECUTE FUNCTION public.assign_sync_revision();

DROP TRIGGER IF EXISTS trg_notes_revision ON public.notes;
CREATE TRIGGER trg_notes_revision
    BEFORE INSERT OR UPDATE ON public.notes
    FOR EACH ROW EXECUTE FUNCTION public.assign_sync_revision();

CREATE INDEX IF NOT EXISTS notes_user_id_revision_idx ON public.notes (user_id, revision);
CREATE INDEX IF NOT EXISTS folders_user_id_revision_idx ON public.folders (user_id, revision);

-- 5. Row Level Security (RLS): read own rows only; writes go through the functions below
ALTER TABLE public.folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own folders" ON public.folders;
CREATE POLICY "Users can view own folders"
    ON public.folders FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own notes" ON public.notes;
CREATE POLICY "Users can view own notes"
    ON public.notes FOR SELECT
    USING (auth.uid() = user_id);

REVOKE ALL ON public.notes, public.folders FROM anon;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.notes, public.folders FROM authenticated;
GRANT SELECT ON public.notes, public.folders TO authenticated;

-- 6. Compare-and-set writes
CREATE OR REPLACE FUNCTION public.push_note(p_note jsonb, p_base_revision bigint)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_id TEXT := p_note->>'id';
    v_current public.notes%ROWTYPE;
    v_exists BOOLEAN;
    v_revision BIGINT;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
    END IF;

    -- Pushes of the same note are serialised, so the check and the write cannot interleave.
    PERFORM pg_advisory_xact_lock(hashtextextended('notes:' || v_id, 0));

    SELECT * INTO v_current FROM public.notes WHERE id = v_id;
    v_exists := FOUND;

    IF v_exists AND v_current.user_id <> v_uid THEN
        RAISE EXCEPTION 'note belongs to another user' USING ERRCODE = '42501';
    END IF;

    -- Written only when the base matches: the current revision, or no revision when the row does not exist.
    IF p_base_revision IS DISTINCT FROM (CASE WHEN v_exists THEN v_current.revision END) THEN
        RETURN jsonb_build_object(
            'status', 'conflict',
            'row', CASE WHEN v_exists THEN to_jsonb(v_current) END
        );
    END IF;

    INSERT INTO public.notes (
        id, user_id, title, content, folder_id, tags, is_pinned, is_locked, is_deleted,
        deleted_at, created_at, updated_at, purged_at
    ) VALUES (
        v_id,
        v_uid,
        COALESCE(p_note->>'title', 'Nuova nota'),
        COALESCE(p_note->>'content', ''),
        COALESCE(p_note->>'folder_id', 'notes'),
        ARRAY(SELECT jsonb_array_elements_text(COALESCE(p_note->'tags', '[]'::jsonb))),
        COALESCE((p_note->>'is_pinned')::BOOLEAN, FALSE),
        COALESCE((p_note->>'is_locked')::BOOLEAN, FALSE),
        COALESCE((p_note->>'is_deleted')::BOOLEAN, FALSE),
        (p_note->>'deleted_at')::TIMESTAMPTZ,
        COALESCE((p_note->>'created_at')::TIMESTAMPTZ, NOW()),
        COALESCE((p_note->>'updated_at')::TIMESTAMPTZ, NOW()),
        (p_note->>'purged_at')::TIMESTAMPTZ
    )
    ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        content = EXCLUDED.content,
        folder_id = EXCLUDED.folder_id,
        tags = EXCLUDED.tags,
        is_pinned = EXCLUDED.is_pinned,
        is_locked = EXCLUDED.is_locked,
        is_deleted = EXCLUDED.is_deleted,
        deleted_at = EXCLUDED.deleted_at,
        created_at = EXCLUDED.created_at,
        updated_at = EXCLUDED.updated_at,
        purged_at = EXCLUDED.purged_at
    RETURNING revision INTO v_revision;

    RETURN jsonb_build_object('status', 'accepted', 'revision', v_revision);
END;
$$;

CREATE OR REPLACE FUNCTION public.push_folder(p_folder jsonb, p_base_revision bigint)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_id TEXT := p_folder->>'id';
    v_current public.folders%ROWTYPE;
    v_exists BOOLEAN;
    v_revision BIGINT;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
    END IF;

    PERFORM pg_advisory_xact_lock(hashtextextended('folders:' || v_id, 0));

    SELECT * INTO v_current FROM public.folders WHERE id = v_id;
    v_exists := FOUND;

    IF v_exists AND v_current.user_id <> v_uid THEN
        RAISE EXCEPTION 'folder belongs to another user' USING ERRCODE = '42501';
    END IF;

    IF p_base_revision IS DISTINCT FROM (CASE WHEN v_exists THEN v_current.revision END) THEN
        RETURN jsonb_build_object(
            'status', 'conflict',
            'row', CASE WHEN v_exists THEN to_jsonb(v_current) END
        );
    END IF;

    INSERT INTO public.folders (
        id, user_id, name, parent_id, icon, is_system, created_at, updated_at, purged_at
    ) VALUES (
        v_id,
        v_uid,
        p_folder->>'name',
        p_folder->>'parent_id',
        COALESCE(p_folder->>'icon', 'folder'),
        COALESCE((p_folder->>'is_system')::BOOLEAN, FALSE),
        COALESCE((p_folder->>'created_at')::TIMESTAMPTZ, NOW()),
        COALESCE((p_folder->>'updated_at')::TIMESTAMPTZ, NOW()),
        (p_folder->>'purged_at')::TIMESTAMPTZ
    )
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        parent_id = EXCLUDED.parent_id,
        icon = EXCLUDED.icon,
        is_system = EXCLUDED.is_system,
        created_at = EXCLUDED.created_at,
        updated_at = EXCLUDED.updated_at,
        purged_at = EXCLUDED.purged_at
    RETURNING revision INTO v_revision;

    -- A deleted folder is no longer the parent of its subfolders; each one gets a new revision.
    IF (p_folder->>'purged_at') IS NOT NULL THEN
        UPDATE public.folders SET parent_id = NULL
        WHERE user_id = v_uid AND parent_id = v_id;
    END IF;

    RETURN jsonb_build_object('status', 'accepted', 'revision', v_revision);
END;
$$;

REVOKE ALL ON FUNCTION public.push_note(jsonb, bigint) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.push_note(jsonb, bigint) TO authenticated;
REVOKE ALL ON FUNCTION public.push_folder(jsonb, bigint) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.push_folder(jsonb, bigint) TO authenticated;

-- 7. Storage Bucket for Attachments (images, drawings)
INSERT INTO storage.buckets (id, name, public)
VALUES ('note-attachments', 'note-attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: writes only in the user's own folder; reads for everyone on the bucket
DROP POLICY IF EXISTS "Users can upload their own attachments" ON storage.objects;
CREATE POLICY "Users can upload their own attachments"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'note-attachments' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Users can overwrite their own attachments" ON storage.objects;
CREATE POLICY "Users can overwrite their own attachments"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'note-attachments' AND auth.uid()::text = (storage.foldername(name))[1])
    WITH CHECK (bucket_id = 'note-attachments' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Users can delete their own attachments" ON storage.objects;
CREATE POLICY "Users can delete their own attachments"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'note-attachments' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Users can view attachments" ON storage.objects;
CREATE POLICY "Users can view attachments"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'note-attachments');

-- 8. Realtime Publication
ALTER PUBLICATION supabase_realtime ADD TABLE public.notes;
ALTER PUBLICATION supabase_realtime ADD TABLE public.folders;

-- Deletes are placeholder updates, and the realtime filter on user_id needs the full row
ALTER TABLE public.notes REPLICA IDENTITY FULL;
ALTER TABLE public.folders REPLICA IDENTITY FULL;
