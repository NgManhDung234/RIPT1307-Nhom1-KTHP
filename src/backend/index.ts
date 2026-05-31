import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import databaseRoutes from './routes/database.routes';
import authRoutes from './routes/auth.routes';
import adminRoutes from './routes/admin.routes';
import admissionRoutes from './routes/admission.routes';

dotenv.config();

const app = express();
const port = process.env.BACKEND_PORT || 5000;

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use('/uploads', express.static(path.join(process.cwd(), 'src', 'backend', 'uploads')));

app.get('/', (_req, res) => {
	res.json({
		message: 'Backend server đang chạy',
	});
});

app.use('/api/database', databaseRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/admission', admissionRoutes);

app.listen(port, () => {
	console.log(`Backend server đang chạy tại http://localhost:${port}`);
});
