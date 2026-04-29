const cloudinary = require('cloudinary').v2;
const multer = require('multer');

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key:    process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Upload a buffer returned by multer memoryStorage to Cloudinary
function uploadBuffer(buffer, folder = 'chefit') {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      { folder, transformation: [{ width: 1080, crop: 'limit', quality: 'auto' }] },
      (error, result) => (error ? reject(error) : resolve(result))
    );
    stream.end(buffer);
  });
}

// multer instance — stores files in memory so we can pipe to Cloudinary
const upload = multer({ storage: multer.memoryStorage() });

module.exports = { upload, uploadBuffer };
