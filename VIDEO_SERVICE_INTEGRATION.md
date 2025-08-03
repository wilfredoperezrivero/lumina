# Video Service Integration Guide

## Overview

The video generation is handled by an external service that reads from a PGMQ queue. This document explains how the external video service should integrate with the queue system.

## Queue Details

- **Queue Name**: `video_jobs_queue`
- **Database**: Supabase PostgreSQL with PGMQ extension
- **Message Format**: JSON

## Message Structure

When a capsule is closed and video generation is triggered, a message is added to the queue with the following structure:

```json
{
  "capsule_id": "uuid-of-capsule",
  "job_type": "generate_video",
  "created_at": "2024-01-01T00:00:00Z",
  "status": "pending",
  "priority": 1,
  "retry_count": 0
}
```

## External Video Service Requirements

### 1. Queue Reading
The external service should:
- Connect to the Supabase PostgreSQL database
- Read messages from `video_jobs_queue` using PGMQ
- Process messages in FIFO order
- Handle message acknowledgment

### 2. Message Processing
For each message:
1. Extract `capsule_id` from the message
2. Fetch capsule details and associated messages from the database
3. Generate video using the capsule data
4. Upload the generated video to Supabase Storage
5. Update the capsule with the video URL
6. Acknowledge the message (remove from queue)

### 3. Database Updates
After video generation:
- Update `capsules.final_video_url` with the video URL
- Update `capsules.status` to `completed`

### 4. Error Handling
- Implement retry logic for failed video generation
- Log errors for debugging
- Consider dead letter queue for permanently failed jobs

## Database Schema

### Capsules Table
```sql
-- Key fields for video generation
id UUID PRIMARY KEY,
status TEXT, -- 'active', 'closed', 'completed'
final_video_url TEXT,
created_at TIMESTAMP
```

### Messages Table
```sql
-- Messages to include in video
id UUID PRIMARY KEY,
capsule_id UUID REFERENCES capsules(id),
content_text TEXT,
content_audio_url TEXT,
content_video_url TEXT,
content_image_url TEXT,
contributor_name TEXT,
submitted_at TIMESTAMP
```

## API Endpoints

The external service should use these Supabase endpoints:

### Read Queue
```sql
SELECT pgmq.receive('video_jobs_queue', 1, 30);
```

### Update Capsule
```sql
UPDATE capsules 
SET 
    final_video_url = 'https://storage.supabase.com/videos/capsule-id.mp4',
    status = 'completed'
WHERE id = 'capsule-uuid';
```

### Get Capsule Data
```sql
SELECT * FROM capsules WHERE id = 'capsule-uuid';
SELECT * FROM messages WHERE capsule_id = 'capsule-uuid' ORDER BY submitted_at;
```

## Storage Requirements

- **Video Storage**: Supabase Storage bucket for videos
- **Video Path**: `/videos/{capsule_id}.mp4`
- **Video Format**: MP4 (recommended)
- **Video Quality**: High quality for memorial purposes

## Security

- Use Supabase service role key for database access
- Implement proper authentication for storage uploads
- Validate all input data before processing

## Monitoring

Use the `get_video_queue_status()` function to monitor queue health:

```sql
SELECT * FROM get_video_queue_status();
```

This returns:
- Queue name
- Number of pending messages
- Queue status information

## Example Integration Code

```python
# Example Python integration (pseudo-code)
import supabase
import pgmq

# Connect to Supabase
client = supabase.create_client(url, key)

# Read from queue
messages = client.rpc('pgmq.receive', {
    'queue_name': 'video_jobs_queue',
    'count': 1,
    'timeout': 30
})

for message in messages:
    capsule_id = message['capsule_id']
    
    # Get capsule data
    capsule = client.table('capsules').select('*').eq('id', capsule_id).single()
    messages = client.table('messages').select('*').eq('capsule_id', capsule_id).execute()
    
    # Generate video
    video_url = generate_video(capsule, messages)
    
    # Update capsule
    client.table('capsules').update({
        'final_video_url': video_url,
        'status': 'completed'
    }).eq('id', capsule_id).execute()
```

## Queue Management

### Manual Queue Operations
```sql
-- Check queue size
SELECT pgmq.size('video_jobs_queue');

-- Purge queue (emergency only)
SELECT pgmq.purge('video_jobs_queue');
```

### Monitoring Queries
```sql
-- Check for stuck capsules
SELECT * FROM capsules 
WHERE status = 'closed' 
AND final_video_url IS NULL;
``` 