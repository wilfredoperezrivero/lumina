# Background Images

This folder contains background images for different content types and orientations.

## File Naming Convention

### Horizontal Images (1920x1080)
- `video_horizontal.jpg` - For video content
- `image_horizontal.jpg` - For image content  
- `audio_horizontal.jpg` - For audio content
- `text_horizontal.jpg` - For text content

### Vertical Images (1080x1920)
- `video_vertical.jpg` - For video content
- `image_vertical.jpg` - For image content
- `audio_vertical.jpg` - For audio content
- `text_vertical.jpg` - For text content

## Image Requirements

- **Horizontal**: 1920x1080 pixels (Full HD)
- **Vertical**: 1080x1920 pixels (Full HD Portrait)
- **Format**: JPG, PNG, or other common image formats
- **Size**: Keep under 5MB for optimal performance

## How It Works

1. The system looks for background images in this folder
2. If a matching image is found, it uses that image
3. If no image is found, it creates a default gradient background
4. Console logs will show which background is being used

## Adding Custom Backgrounds

Simply add your image files with the correct names to this folder. The system will automatically detect and use them.

## Examples

- `video_horizontal.jpg` - Used for horizontal video content
- `audio_vertical.jpg` - Used for vertical audio content
- `text_horizontal.jpg` - Used for horizontal text content 