import express from 'express';
import { createServer } from 'http';
import { Server as SocketIOServer } from 'socket.io';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import databaseRoutes from './routes/database.routes';
import authRoutes from './routes/auth.routes';
import adminRoutes from './routes/admin.routes';
import admissionRoutes from './routes/admission.routes';
import aiRoutes from './routes/ai.routes';
import cutoffRoutes from './routes/cutoff.routes';
import newsRoutes from './routes/news.routes';

dotenv.config();

const app = express();
const httpServer = createServer(app);
const allowedOrigins = process.env.ALLOWED_ORIGINS
	? process.env.ALLOWED_ORIGINS.split(',')
	: ['http://localhost:8000', 'http://localhost:3000', 'http://127.0.0.1:8000'];

const io = new SocketIOServer(httpServer, {
	cors: {
		origin: allowedOrigins,
		methods: ['GET', 'POST'],
		credentials: true,
	},
});

const port = process.env.PORT || process.env.BACKEND_PORT || 5000;

// ──────────────────────────────────────────────
// Middleware
// ──────────────────────────────────────────────
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use('/uploads', express.static(path.join(process.cwd(), 'src', 'backend', 'uploads')));

// ──────────────────────────────────────────────
// Các Route REST
// ──────────────────────────────────────────────
app.get('/', (_req, res) => {
	res.json({
		message: 'Backend server đang chạy',
		modules: ['auth', 'admin', 'admission', 'ai'],
	});
});

app.use('/api/database', databaseRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/admission', admissionRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/cutoff', cutoffRoutes);
app.use('/api/news', newsRoutes);

// ──────────────────────────────────────────────
// Kiểm tra sức khỏe server
// ──────────────────────────────────────────────
app.get('/health', (_req, res) => {
	res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ──────────────────────────────────────────────
// Các sự kiện Socket.IO
// ──────────────────────────────────────────────
interface ConnectedUser {
	socketId: string;
	userId?: number;
	role: 'student' | 'admin';
	sessionId?: string;
}

const connectedUsers = new Map<string, ConnectedUser>();
const adminSockets = new Set<string>();

// Hàm helper: gửi số admin online tới tất cả client
const broadcastOnlineAdmins = () => {
	io.emit('admin_count_update', { count: adminSockets.size });
};

// Helper: tìm các socket của admin
const getAdminSockets = () => Array.from(adminSockets);

io.on('connection', (socket) => {
	console.log(`[Socket.IO] Client connected: ${socket.id}`);

	// ── Đăng ký làm admin ──────────────────────
	socket.on('register_admin', (data: { userId: number }) => {
		connectedUsers.set(socket.id, {
			socketId: socket.id,
			userId: data.userId,
			role: 'admin',
		});
		adminSockets.add(socket.id);
		broadcastOnlineAdmins();
		console.log(`[Socket.IO] Admin registered: userId=${data.userId}, totalAdmins=${adminSockets.size}`);
		socket.emit('registered_admin', { success: true });
	});

	// ── Đăng ký làm sinh viên ───────────────────
	socket.on('register_student', (data: { userId?: number; sessionId: string }) => {
		connectedUsers.set(socket.id, {
			socketId: socket.id,
			userId: data.userId,
			role: 'student',
			sessionId: data.sessionId,
		});
		console.log(`[Socket.IO] Student registered: userId=${data.userId}, sessionId=${data.sessionId}`);
		socket.emit('registered_student', { success: true });
	});

	// ── Admin alert (chuyển giao từ AI) ───────────
	socket.on('admin_alert', (payload: {
		session_id: string;
		user_id?: number;
		student_name?: string;
		score?: number;
		subject_group?: string;
		target_major?: string;
		chat_history: Array<{ role: string; content: string; timestamp: string }>;
	}) => {
		console.log(`[Socket.IO] Handoff alert: session=${payload.session_id}`);

		// Gửi cho tất cả admin online
