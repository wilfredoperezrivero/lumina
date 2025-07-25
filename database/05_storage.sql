-- Storage bucket configuration for admin assets (logos)
-- Note: This needs to be run in Supabase dashboard or via API
-- INSERT INTO storage.buckets (id, name, public) VALUES ('admin-assets', 'admin-assets', true);

-- Create storage policies for admin-assets bucket
-- Users can upload to their own folder
-- CREATE POLICY "Users can upload own logos" ON storage.objects
--     FOR INSERT WITH CHECK (
--         bucket_id = 'admin-assets' AND 
--         auth.uid()::text = (storage.foldername(name))[1]
--     );

-- Users can view their own logos
-- CREATE POLICY "Users can view own logos" ON storage.objects
--     FOR SELECT USING (
--         bucket_id = 'admin-assets' AND 
--         auth.uid()::text = (storage.foldername(name))[1]
--     );

-- Users can update their own logos
-- CREATE POLICY "Users can update own logos" ON storage.objects
--     FOR UPDATE USING (
--         bucket_id = 'admin-assets' AND 
--         auth.uid()::text = (storage.foldername(name))[1]
--     );

-- Users can delete their own logos
-- CREATE POLICY "Users can delete own logos" ON storage.objects
--     FOR DELETE USING (
--         bucket_id = 'admin-assets' AND 
--         auth.uid()::text = (storage.foldername(name))[1]
--     ); 