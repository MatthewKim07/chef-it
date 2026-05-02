const jwt = require('jsonwebtoken');

module.exports = function optionalAuth(req, _res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) return next();

  const token = header.slice(7);
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.user = { id: payload.id, email: payload.email };
  } catch {
    // Ignore invalid tokens — caller treated as anonymous.
  }
  next();
};
