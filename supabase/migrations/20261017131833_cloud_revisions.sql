-- ==============================================================================
-- Cloud revisions: versioned rows, compare-and-set writes through database
-- functions, deletion placeholders, direct client writes revoked.
-- Applies to an existing project with data.
-- ==============================================================================

-- 1. Server no longer rewrites updated_at: the device writes its own time.
DROP TRIGGER IF EXISTS trg_folders_updated_at ON public.folders;
DROP TRIGGER IF EXISTS trg_notes_updated_at ON public.notes;
DROP FUNCTION IF EXISTS public.update_updated_at_column();

-- 2. One sequence for both tables: revisions are unique and increasing across the project.
CREATE SEQUENCE IF NOT EXISTS public.sync_revision_seq;

-- 3. New columns.
ALTER TABLE public.notes ADD COLUMN IF NOT EXISTS revision BIGINT;
ALTER TABLE public.notes ADD COLUMN IF NOT EXISTS purged_at TIMESTAMPTZ;
ALTER TABLE public.folders ADD COLUMN IF NOT EXISTS revision BIGINT;
ALTER TABLE public.folders ADD COLUMN IF NOT EXISTS purged_at TIMESTAMPTZ;

-- 4. Existing rows get a revision (done before the trigger exists, so no other column changes).
UPDATE public.notes SET revision = nextval('public.sync_revision_seq') WHERE revision IS NULL;
UPDATE public.folders SET revision = nextval('public.sync_revision_seq') WHERE revision IS NULL;
ALTER TABLE public.notes ALTER COLUMN revision SET NOT NULL;
ALTER TABLE public.folders ALTER COLUMN revision SET NOT NULL;

-- 5. The database assigns the revision on every insert and update; the client never sends one.
CREATE OR REPLACE FUNCTION public.assign_sync_revision()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.revision := nextval('public.sync_revision_seq');
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notes_revision ON public.notes;
CREATE TRIGGER trg_notes_revision
    BEFORE INSERT OR UPDATE ON public.notes
    FOR EACH ROW EXECUTE FUNCTION public.assign_sync_revision();

DROP TRIGGER IF EXISTS trg_folders_revision ON public.folders;
CREATE TRIGGER trg_folders_revision
    BEFORE INSERT OR UPDATE ON public.folders
    FOR EACH ROW EXECUTE FUNCTION public.assign_sync_revision();

-- 6. Indexes for the pull of changes since a revision.
CREATE INDEX IF NOT EXISTS notes_user_id_revision_idx ON public.notes (user_id, revision);
CREATE INDEX IF NOT EXISTS folders_user_id_revision_idx ON public.folders (user_id, revision);

-- 7. Compare-and-set write for a note.
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

-- 8. Compare-and-set write for a folder. A deletion placeholder detaches its subfolders.
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

-- 9. Only the functions write; authenticated users keep read access to their own rows.
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.notes, public.folders FROM authenticated, anon;
REVOKE ALL ON public.notes, public.folders FROM anon;
GRANT SELECT ON public.notes, public.folders TO authenticated;

REVOKE ALL ON FUNCTION public.push_note(jsonb, bigint) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.push_note(jsonb, bigint) TO authenticated;
REVOKE ALL ON FUNCTION public.push_folder(jsonb, bigint) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.push_folder(jsonb, bigint) TO authenticated;

DROP POLICY IF EXISTS "Users can insert own folders" ON public.folders;
DROP POLICY IF EXISTS "Users can update own folders" ON public.folders;
DROP POLICY IF EXISTS "Users can delete own folders" ON public.folders;
DROP POLICY IF EXISTS "Users can insert own notes" ON public.notes;
DROP POLICY IF EXISTS "Users can update own notes" ON public.notes;
DROP POLICY IF EXISTS "Users can delete own notes" ON public.notes;

-- 10. Attachments: the user's folder is writable (upload, overwrite, delete); the bucket stays readable.
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

-- 11. Deletes become placeholder updates, so the realtime filter on user_id sees the full row.
ALTER TABLE public.notes REPLICA IDENTITY FULL;
ALTER TABLE public.folders REPLICA IDENTITY FULL;
