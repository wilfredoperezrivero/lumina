import dotenv from "dotenv";
dotenv.config();
import { createClient } from "@supabase/supabase-js";
import ffmpegPath from "ffmpeg-static";
import ffmpeg from "fluent-ffmpeg";
import axios from "axios";
import { tmpdir } from "os";
import { v4 as uuidv4 } from "uuid";
import fs from "fs/promises";
import path from "path";
import tmp from "tmp";
import { exec } from "child_process";

ffmpeg.setFfmpegPath(ffmpegPath);

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
const BUCKET = "media";

// --- Utility Functions ---
async function downloadToFile(url) {
  const temp = tmp.fileSync();
  const writer = await fs.open(temp.name, 'w');
  const response = await axios({ url, method: 'GET', responseType: 'stream' });
  await new Promise((resolve, reject) => {
    response.data.pipe(writer.createWriteStream());
    response.data.on('end', resolve);
    response.data.on('error', reject);
  });
  await writer.close();
  return temp.name;
}

// --- Media Detection Functions ---
async function getMediaDimensions(filePath) {
  return new Promise((resolve, reject) => {
    // Check if ffprobe is available
    exec('which ffprobe', (err) => {
      if (err) {
        console.warn("ffprobe not found, using default dimensions");
        resolve({ width: 1920, height: 1080, isVertical: false });
        return;
      }
      
      ffmpeg.ffprobe(filePath, (err, metadata) => {
        if (err) {
          console.warn("Could not detect video dimensions, using defaults:", err.message);
          resolve({ width: 1920, height: 1080, isVertical: false });
          return;
        }
        const videoStream = metadata.streams.find(s => s.codec_type === 'video');
        if (videoStream) {
          resolve({
            width: videoStream.width,
            height: videoStream.height,
            isVertical: videoStream.height > videoStream.width
          });
        } else {
          // For images, try to get dimensions
          const imageStream = metadata.streams.find(s => s.codec_type === 'image');
          if (imageStream) {
            resolve({
              width: imageStream.width,
              height: imageStream.height,
              isVertical: imageStream.height > imageStream.width
            });
          } else {
            // Default to horizontal Full HD if we can't detect
            resolve({ width: 1920, height: 1080, isVertical: false });
          }
        }
      });
    });
  });
}

// --- Background Music Functions ---
async function getBackgroundMusic() {
  const audioDir = path.join(process.cwd(), 'audio');
  
  try {
    const audioFiles = await fs.readdir(audioDir);
    const mp3Files = audioFiles.filter(file => file.endsWith('.mp3'));
    
    if (mp3Files.length === 0) {
      console.warn("No MP3 files found in audio folder");
      return null;
    }
    
    // Select a random background music file
    const randomFile = mp3Files[Math.floor(Math.random() * mp3Files.length)];
    const musicPath = path.join(audioDir, randomFile);
    
    console.log(`Using background music: ${musicPath}`);
    return musicPath;
  } catch (err) {
    console.warn("Could not access audio folder:", err.message);
    return null;
  }
}

// --- Background Image Functions ---
async function createBackgroundImage() {
  const backgroundsDir = path.join(process.cwd(), 'backgrounds');
  const bgFileName = 'text_horizontal.jpg';
  const bgPath = path.join(backgroundsDir, bgFileName);
  
  // Check if the background image exists
  try {
    await fs.access(bgPath);
    console.log(`Using background image: ${bgPath}`);
    return bgPath;
  } catch (err) {
    throw new Error(`Background image not found: ${bgPath}. Please add the required background image to the backgrounds/ folder.`);
  }
}

async function fetchCapsuleInfo(capsule_id) {
  const { data: capsule, error } = await supabase
    .from("capsules")
    .select("name, image, admin_id")
    .eq("id", capsule_id)
    .single();
  if (error) throw new Error(error.message);
  
  // Fetch admin information if admin_id exists
  let adminInfo = null;
  if (capsule?.admin_id) {
    const { data: admin, error: adminError } = await supabase
      .from("admins")
      .select("name, logo_image")
      .eq("admin_id", capsule.admin_id)
      .single();
    if (!adminError && admin) {
      adminInfo = admin;
    }
  }
  
  return { ...capsule, adminInfo };
}

async function createTextSlide(text, name, capsuleInfo, contentType = 'text', isVertical = false) {
  const fileName = path.join(tmpdir(), `${uuidv4()}.png`);
  const safeText = text ? text.replace(/"/g, '\"') : '';
  const safeName = name ? name.replace(/"/g, '\"') : '';
  const safeCapsuleName = capsuleInfo?.name ? capsuleInfo.name.replace(/"/g, '\"') : '';
  const safeAdminName = capsuleInfo?.adminInfo?.name ? capsuleInfo.adminInfo.name.replace(/"/g, '\"') : '';
  
  // Create background image
  const bgImage = await createBackgroundImage();
  
  // Always use horizontal layout for output - Full HD resolution with background
  const size = '1920x1080';
  const fontSize = '64';
  const capsuleFontSize = '48';
  const nameFontSize = '48';
  const adminFontSize = '32';
  
  let cmd;
  
  // Always use horizontal layout: content takes 70% of width (left portion), capsule info on the top
  if (capsuleInfo?.image) {
    // Download capsule image
    const capsuleImageFile = await downloadToFile(capsuleInfo.image);
    const capsuleImageResized = path.join(tmpdir(), `capsule_img_${uuidv4()}.jpg`);
    
    // Resize capsule image for horizontal layout
    await new Promise((resolve, reject) => {
      exec(`convert "${capsuleImageFile}" -resize 300x300! "${capsuleImageResized}"`, (err) => err ? reject(err) : resolve());
    });
    
    cmd = `convert "${bgImage}" -resize ${size} \
      -fill white -gravity west -pointsize ${fontSize} -annotate +150+324 "${safeText}" \
      -gravity west -pointsize ${nameFontSize} -annotate +150+424 "${safeName}" \
      -gravity north -pointsize ${capsuleFontSize} -annotate +0+50 "${safeCapsuleName}" \
      "${capsuleImageResized}" -gravity northwest -geometry +50+50 -composite \
      "${fileName}"`;
    
    // Clean up capsule image files
    await fs.unlink(capsuleImageFile).catch(() => {});
    await fs.unlink(capsuleImageResized).catch(() => {});
  } else {
    cmd = `convert "${bgImage}" -resize ${size} \
      -fill white -gravity west -pointsize ${fontSize} -annotate +150+324 "${safeText}" \
      -gravity west -pointsize ${nameFontSize} -annotate +150+424 "${safeName}" \
      -gravity north -pointsize ${capsuleFontSize} -annotate +0+50 "${safeCapsuleName}" \
      "${fileName}"`;
  }
  
  await new Promise((resolve, reject) => {
    exec(cmd, (err) => err ? reject(err) : resolve());
  });
  
  // Add admin info at the bottom for horizontal layout
  if (capsuleInfo?.adminInfo?.logo_image) {
    // Download admin logo
    const adminLogoFile = await downloadToFile(capsuleInfo.adminInfo.logo_image);
    const adminLogoResized = path.join(tmpdir(), `admin_logo_${uuidv4()}.jpg`);
    
    // Resize admin logo for horizontal layout
    await new Promise((resolve, reject) => {
      exec(`convert "${adminLogoFile}" -resize 150x150! "${adminLogoResized}"`, (err) => err ? reject(err) : resolve());
    });
    
    const tempFile = path.join(tmpdir(), `temp_${uuidv4()}.png`);
    await fs.copyFile(fileName, tempFile);
    
    cmd = `convert "${tempFile}" \
      -fill white -gravity southwest -pointsize ${adminFontSize} -annotate +50+50 "${safeAdminName}" \
      "${adminLogoResized}" -gravity southeast -geometry +50+50 -composite \
      "${fileName}"`;
    
    await new Promise((resolve, reject) => {
      exec(cmd, (err) => err ? reject(err) : resolve());
    });
    
    // Clean up admin logo files
    await fs.unlink(adminLogoFile).catch(() => {});
    await fs.unlink(adminLogoResized).catch(() => {});
    await fs.unlink(tempFile).catch(() => {});
  } else if (safeAdminName) {
    // Add just admin name if no logo
    const tempFile = path.join(tmpdir(), `temp_${uuidv4()}.png`);
    await fs.copyFile(fileName, tempFile);
    
    cmd = `convert "${tempFile}" \
      -fill white -gravity southwest -pointsize ${adminFontSize} -annotate +50+50 "${safeAdminName}" \
      "${fileName}"`;
    
    await new Promise((resolve, reject) => {
      exec(cmd, (err) => err ? reject(err) : resolve());
    });
    
    await fs.unlink(tempFile).catch(() => {});
  }
  
  return fileName;
}

async function createInitialSlide(capsuleInfo) {
  const fileName = path.join(tmpdir(), `${uuidv4()}.png`);
  const safeCapsuleName = capsuleInfo?.name ? capsuleInfo.name.replace(/"/g, '\"') : '';
  const safeAdminName = capsuleInfo?.adminInfo?.name ? capsuleInfo.adminInfo.name.replace(/"/g, '\"') : '';
  
  // Create background image
  const bgImage = await createBackgroundImage();
  
  // Use horizontal layout for initial slide
  const size = '1920x1080';
  const titleFontSize = '72';
  const adminFontSize = '32';
  
  let cmd;
  
  if (capsuleInfo?.image) {
    // Download capsule image
    const capsuleImageFile = await downloadToFile(capsuleInfo.image);
    const capsuleImageResized = path.join(tmpdir(), `capsule_img_${uuidv4()}.jpg`);
    
    // Resize capsule image for initial slide
    await new Promise((resolve, reject) => {
      exec(`convert "${capsuleImageFile}" -resize 400x400! "${capsuleImageResized}"`, (err) => err ? reject(err) : resolve());
    });
    
    cmd = `convert "${bgImage}" -resize ${size} \
      -fill white -gravity center -pointsize ${titleFontSize} -annotate +0-100 "${safeCapsuleName}" \
      "${capsuleImageResized}" -gravity center -geometry +0+200 -composite \
      "${fileName}"`;
    
    // Clean up capsule image files
    await fs.unlink(capsuleImageFile).catch(() => {});
    await fs.unlink(capsuleImageResized).catch(() => {});
  } else {
    cmd = `convert "${bgImage}" -resize ${size} \
      -fill white -gravity center -pointsize ${titleFontSize} -annotate +0+0 "${safeCapsuleName}" \
      "${fileName}"`;
  }
  
  await new Promise((resolve, reject) => {
    exec(cmd, (err) => err ? reject(err) : resolve());
  });
  
  // Add admin info at the bottom
  if (capsuleInfo?.adminInfo?.logo_image) {
    // Download admin logo
    const adminLogoFile = await downloadToFile(capsuleInfo.adminInfo.logo_image);
    const adminLogoResized = path.join(tmpdir(), `admin_logo_${uuidv4()}.jpg`);
    
    // Resize admin logo for initial slide
    await new Promise((resolve, reject) => {
      exec(`convert "${adminLogoFile}" -resize 150x150! "${adminLogoResized}"`, (err) => err ? reject(err) : resolve());
    });
    
    const tempFile = path.join(tmpdir(), `temp_${uuidv4()}.png`);
    await fs.copyFile(fileName, tempFile);
    
    cmd = `convert "${tempFile}" \
      -fill white -gravity southwest -pointsize ${adminFontSize} -annotate +50+50 "${safeAdminName}" \
      "${adminLogoResized}" -gravity southeast -geometry +50+50 -composite \
      "${fileName}"`;
    
    await new Promise((resolve, reject) => {
      exec(cmd, (err) => err ? reject(err) : resolve());
    });
    
    // Clean up admin logo files
    await fs.unlink(adminLogoFile).catch(() => {});
    await fs.unlink(adminLogoResized).catch(() => {});
    await fs.unlink(tempFile).catch(() => {});
  } else if (safeAdminName) {
    // Add just admin name if no logo
    const tempFile = path.join(tmpdir(), `temp_${uuidv4()}.png`);
    await fs.copyFile(fileName, tempFile);
    
    cmd = `convert "${tempFile}" \
      -fill white -gravity southwest -pointsize ${adminFontSize} -annotate +50+50 "${safeAdminName}" \
      "${fileName}"`;
    
    await new Promise((resolve, reject) => {
      exec(cmd, (err) => err ? reject(err) : resolve());
    });
    
    await fs.unlink(tempFile).catch(() => {});
  }
  
  return fileName;
}

async function uploadToSupabaseStorage(filePath, key) {
  const fileBuffer = await fs.readFile(filePath);
  const { data, error } = await supabase.storage.from(BUCKET).upload(key, fileBuffer, {
    contentType: 'video/mp4',
    upsert: true,
  });
  if (error) throw new Error(error.message);
  return supabase.storage.from(BUCKET).getPublicUrl(key).data.publicUrl;
}

// --- Job Processing Functions ---
async function fetchNextJob() {
  const { data, error } = await supabase.rpc('pgmq_read', {
    queue_name: 'video_jobs_queue',
    vt: 30,
    limit: 1
  });
  if (error) throw new Error(error.message);
  if (!data || data.length === 0) return null;
  return data[0];
}

async function fetchCapsuleMessages(capsule_id) {
  const { data: messages, error } = await supabase
    .from("messages")
    .select("id, content_text, content_audio_url, content_video_url, contributor_name, submitted_at")
    .eq("capsule_id", capsule_id)
    .eq("hidden", false)
    .order("submitted_at", { ascending: true });
  if (error) throw new Error(error.message);
  if (!messages || messages.length === 0) throw new Error("No messages");
  return messages;
}

async function prepareMediaParts(messages, capsuleInfo) {
  const parts = [];
  for (const msg of messages) {
    if (msg.content_video_url) {
      const videoFile = await downloadToFile(msg.content_video_url);
      // Detect original video orientation
      let isOriginalVertical = false;
      try {
        const dimensions = await getMediaDimensions(videoFile);
        isOriginalVertical = dimensions.isVertical;
        console.log(`Original video dimensions: ${dimensions.width}x${dimensions.height}, isVertical: ${isOriginalVertical}`);
      } catch (err) {
        console.warn("Could not detect video dimensions, assuming horizontal:", err.message);
      }
      parts.push({ 
        type: "video", 
        file: videoFile, 
        isOriginalVertical, 
        contentType: 'video',
        contributor_name: msg.contributor_name,
        capsuleInfo: capsuleInfo
      });
    } else if (msg.content_audio_url) {
      const audioFile = await downloadToFile(msg.content_audio_url);
      const slideText = msg.content_text || "Audio Tribute";
      // Always use horizontal layout
      const slideImage = await createTextSlide(slideText, msg.contributor_name, capsuleInfo, 'audio', false);
      parts.push({ type: "audio", image: slideImage, audio: audioFile, isVertical: false, contentType: 'audio' });
    } else if (msg.content_text) {
      // Always use horizontal layout
      const slideImage = await createTextSlide(msg.content_text, msg.contributor_name, capsuleInfo, 'text', false);
      parts.push({ type: "text", image: slideImage, isVertical: false, contentType: 'text' });
    }
  }
  return parts;
}

async function createVideoSegment(part, tempDir, idx) {
  const outPath = path.join(tempDir, `segment_${idx}.mp4`);
  
  // Use the original video orientation information
  const isOriginalVertical = part.isOriginalVertical || false;
  
  if (isOriginalVertical) {
    // For vertical videos: create a layout with video on right 50%, info on left 50%
    const videoSegment = await createVerticalVideoLayout(part, tempDir, idx);
    return videoSegment;
  } else {
    // For horizontal videos: create a layout with video at bottom 90% width, info on top
    const videoSegment = await createHorizontalVideoLayout(part, tempDir, idx);
    return videoSegment;
  }
}

async function createVerticalVideoLayout(part, tempDir, idx) {
  const outPath = path.join(tempDir, `segment_${idx}.mp4`);
  
  // Create a 1920x1080 canvas with video on right 50%
  const videoScaleFilter = "scale=960:1080";
  const videoPosition = "overlay=960:0"; // Position video on the right half
  
  // Simplified approach - just use original video audio without background music for now
  await new Promise((resolve, reject) => {
    ffmpeg()
      .addInput(part.file)
      .addInput(part.image) // Background/info image
      .complexFilter([
        `[0:v]${videoScaleFilter}[scaled_video]`,
        `[1:v]scale=1920:1080[bg]`,
        `[bg][scaled_video]${videoPosition}[out]`
      ])
      .outputOptions([
        "-map", "[out]",
        "-map", "0:a",
        "-shortest",
        "-pix_fmt", "yuv420p"
      ])
      .save(outPath)
      .on('end', resolve)
      .on('error', reject);
  });
  
  return outPath;
}

async function createHorizontalVideoLayout(part, tempDir, idx) {
  const outPath = path.join(tempDir, `segment_${idx}.mp4`);
  
  // Create a 1920x1080 canvas with video at bottom 70% width
  const videoScaleFilter = "scale=1344:756"; // 70% of 1920x1080
  const videoPosition = "overlay=288:250"; // Center the video horizontally (1920-1344)/2 = 288, position at bottom
  
  // Simplified approach - just use original video audio without background music for now
  await new Promise((resolve, reject) => {
    ffmpeg()
      .addInput(part.file)
      .addInput(part.image) // Background/info image
      .complexFilter([
        `[0:v]${videoScaleFilter}[scaled_video]`,
        `[1:v]scale=1920:1080[bg]`,
        `[bg][scaled_video]${videoPosition}[out]`
      ])
      .outputOptions([
        "-map", "[out]",
        "-map", "0:a",
        "-shortest",
        "-pix_fmt", "yuv420p"
      ])
      .save(outPath)
      .on('end', resolve)
      .on('error', reject);
  });
  
  return outPath;
}

async function createTextSegment(part, tempDir, idx) {
  const outPath = path.join(tempDir, `segment_${idx}.mp4`);
  
  // Always use horizontal output format
  const scaleFilter = "scale=1920:1080";
  
  // Simplified approach - no background music for now
  await new Promise((resolve, reject) => {
    ffmpeg()
      .addInput(part.image)
      .loop(5)
      .outputOptions([
        "-t", "5",
        "-vf", scaleFilter,
        "-pix_fmt", "yuv420p"
      ])
      .save(outPath)
      .on('end', resolve)
      .on('error', reject);
  });
  
  return outPath;
}

async function createVideoSegments(parts, tempDir) {
  const videoSegments = [];
  let idx = 0;
  
  // Create initial slide with capsule title and admin info
  if (parts.length > 0 && parts[0].capsuleInfo) {
    const initialSlide = await createInitialSlide(parts[0].capsuleInfo);
    const initialSegment = await createTextSegment({ type: "text", image: initialSlide }, tempDir, idx++);
    videoSegments.push(initialSegment);
  }
  
  for (const part of parts) {
    if (part.type === "video") {
      // For videos, we need to create an info slide and then combine with video
      const infoSlide = await createTextSlide("Video Content", part.contributor_name, part.capsuleInfo, 'video', false);
      part.image = infoSlide; // Add the info slide to the part
      const outPath = await createVideoSegment(part, tempDir, idx++);
      videoSegments.push(outPath);
    } else if (part.type === "audio") {
      const outPath = await createVideoSegment(part, tempDir, idx++);
      videoSegments.push(outPath);
    } else if (part.type === "text") {
      const outPath = await createTextSegment(part, tempDir, idx++);
      videoSegments.push(outPath);
    }
  }
  return videoSegments;
}

async function concatenateSegments(videoSegments, tempDir, capsule_id) {
  const concatFile = path.join(tempDir, "concat.txt");
  await fs.writeFile(concatFile, videoSegments.map(f => `file '${f}'`).join('\n'));
  const finalVideo = path.join(tempDir, `capsule_${capsule_id}.mp4`);
  await new Promise((resolve, reject) => {
    ffmpeg()
      .input(concatFile)
      .inputOptions(['-f', 'concat', '-safe', '0'])
      .outputOptions(['-c', 'copy'])
      .save(finalVideo)
      .on('end', resolve)
      .on('error', reject);
  });
  return finalVideo;
}

async function updateCapsuleWithVideo(capsule_id, videoUrl) {
  await supabase
    .from("capsules")
    .update({ final_video_url: videoUrl })
    .eq("id", capsule_id);
}

async function acknowledgeJob(message_id) {
  await supabase.rpc('pgmq_delete', {
    queue_name: 'video_jobs_queue',
    message_id
  });
}

// --- Debug Functions ---
async function saveLocalVideo(finalVideo, capsule_id) {
  const debugDir = path.join(process.cwd(), 'debug_videos');
  
  // Create debug directory if it doesn't exist
  try {
    await fs.mkdir(debugDir, { recursive: true });
  } catch (err) {
    // Directory might already exist
  }
  
  const localPath = path.join(debugDir, `capsule_${capsule_id}.mp4`);
  await fs.copyFile(finalVideo, localPath);
  console.log(`Debug video saved locally: ${localPath}`);
  return localPath;
}

// --- Main Worker Logic ---
async function processPgmqQueue() {
  try {
    /*
    const job = await fetchNextJob();
    if (!job) {
      console.log("No jobs in queue.");
      return;
    }
    const message_id = job.message_id;
    const payload = job.message;
    const capsule_id = payload.capsule_id;
    */

    const capsule_id = "fc82a55e-30de-4458-8bcd-c6f5c44c2a61"


    console.log("Processing job for capsule:", capsule_id);
    try {
      const messages = await fetchCapsuleMessages(capsule_id);
      const capsuleInfo = await fetchCapsuleInfo(capsule_id);
      const parts = await prepareMediaParts(messages, capsuleInfo);
      const tempDir = tmp.dirSync().name;
      const videoSegments = await createVideoSegments(parts, tempDir);
      const finalVideo = await concatenateSegments(videoSegments, tempDir, capsule_id);
      
      // Save local copy for debugging
      await saveLocalVideo(finalVideo, capsule_id);
 /*     
      const key = `capsules/${capsule_id}/final_video.mp4`;
      const videoUrl = await uploadToSupabaseStorage(finalVideo, key);
      await updateCapsuleWithVideo(capsule_id, videoUrl);
      await acknowledgeJob(message_id);
      console.log("Job completed and removed from queue.");
*/
    } catch (err) {
      console.error("Job failed:", err);
      // (Don't ACK - will retry after VT)
    }
  } catch (e) {
    console.error("Worker error:", e);
  }
}

async function startWorker() {
  console.log("Lumina worker started.");
  while (true) {
    await processPgmqQueue();
    await new Promise(resolve => setTimeout(resolve, 30 * 1000)); // 30 seconds
  }
}

//startWorker();

await processPgmqQueue();