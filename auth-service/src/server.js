const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const app = express();
app.use(express.json());
const PORT = process.env.PORT || 3001;
const JWT_SECRET = process.env.JWT_SECRET || "dev-only-change-me";
const users = new Map();

app.get("/health", (_, res) => res.json({ service: "auth-service", status: "ok" }));
app.post("/auth/register", async (req, res) => {
  const { name, email, password } = req.body;
  if (!name || !email || !password) return res.status(400).json({ message: "name, email and password are required" });
  if (users.has(email)) return res.status(409).json({ message: "User already exists" });
  const user = { id: String(users.size + 1), name, email, passwordHash: await bcrypt.hash(password, 10) };
  users.set(email, user);
  res.status(201).json({ id: user.id, name: user.name, email: user.email });
});
app.post("/auth/login", async (req, res) => {
  const { email, password } = req.body;
  const user = users.get(email);
  if (!user || !(await bcrypt.compare(password || "", user.passwordHash))) return res.status(401).json({ message: "Invalid credentials" });
  const token = jwt.sign({ sub: user.id, email: user.email, name: user.name }, JWT_SECRET, { expiresIn: "2h" });
  res.json({ token, user: { id: user.id, name: user.name, email: user.email } });
});
app.get("/auth/verify", (req, res) => {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) return res.status(401).json({ message: "Missing bearer token" });
  try { res.json({ valid: true, claims: jwt.verify(token, JWT_SECRET) }); }
  catch { res.status(401).json({ valid: false, message: "Invalid token" }); }
});
app.listen(PORT, () => console.log(`auth-service listening on ${PORT}`));
