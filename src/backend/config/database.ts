import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

export const dbPool = new Pool({
	host: process.env.DB_HOST || 'localhost',
	port: Number(process.env.DB_PORT) || 5432,
	user: process.env.DB_USER || 'postgres',
	password: process.env.DB_PASSWORD || '',
	database: process.env.DB_NAME || 'student_management',
	max: 10,
	idleTimeoutMillis: 30000,
	connectionTimeoutMillis: 2000,
});

export const testDatabaseConnection = async () => {
	try {
		const client = await dbPool.connect();
		await client.query('SELECT NOW()');
		client.release();
		return true;
	} catch (error) {
		console.error('Database connection failed:', error);
		return false;
	}
};
