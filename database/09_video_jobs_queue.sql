-- Create PGMQ queue for video jobs
-- This requires the pgmq extension to be enabled in Supabase
-- External video generation service will read from this queue

-- Create the video_jobs_queue
SELECT pgmq.create('video_jobs_queue');

-- Function to add a video generation job to the queue
CREATE OR REPLACE FUNCTION add_video_generation_job(capsule_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Add job to the video_jobs_queue for external video service
    PERFORM pgmq.send(
        'video_jobs_queue',
        json_build_object(
            'capsule_id', capsule_id,
            'job_type', 'generate_video',
            'created_at', NOW(),
            'status', 'pending',
            'priority', 1,
            'retry_count', 0
        )::text
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to close capsule and generate video
-- This function closes the capsule and adds a job to the queue for external processing
CREATE OR REPLACE FUNCTION close_capsule_and_generate_video(capsule_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Update capsule status to 'closed' - no more messages can be added
    UPDATE capsules 
    SET status = 'closed'
    WHERE id = capsule_id;
    
    -- Add video generation job to queue for external video service
    PERFORM add_video_generation_job(capsule_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check queue status (for monitoring)
CREATE OR REPLACE FUNCTION get_video_queue_status()
RETURNS TABLE(
    queue_name TEXT,
    message_count BIGINT,
    oldest_message TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'video_jobs_queue'::TEXT as queue_name,
        pgmq.size('video_jobs_queue') as message_count,
        NULL::TIMESTAMP as oldest_message; -- PGMQ doesn't provide this info directly
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION add_video_generation_job(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION close_capsule_and_generate_video(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_video_queue_status() TO authenticated; 