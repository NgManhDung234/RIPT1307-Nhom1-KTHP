import { dbPool } from '../config/database';

async function migrate() {
	try {
		console.log('Ensuring admission workflow tables exist...');

		await dbPool.query(`
			CREATE TABLE IF NOT EXISTS password_reset_tokens (
				id INT AUTO_INCREMENT PRIMARY KEY,
				user_id INT NOT NULL,
				token VARCHAR(255) NOT NULL UNIQUE,
				expires_at TIMESTAMP NOT NULL,
				created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
				CONSTRAINT fk_password_reset_tokens_users
					FOREIGN KEY (user_id)
					REFERENCES users(id)
					ON DELETE CASCADE
					ON UPDATE CASCADE
			) ENGINE = InnoDB
			DEFAULT CHARSET = utf8mb4
			COLLATE = utf8mb4_unicode_ci
		`);

		await dbPool.query(`
			CREATE TABLE IF NOT EXISTS admission_applications (
				id INT AUTO_INCREMENT PRIMARY KEY,
				user_id INT NOT NULL UNIQUE,
				status ENUM('draft', 'submitted', 'reviewing', 'approved', 'rejected', 'needs_revision') NOT NULL DEFAULT 'draft',
				personal_info JSON NULL,
				academic_info JSON NULL,
				documents_info JSON NULL,
				confirmation_checked BOOLEAN DEFAULT FALSE,
				submitted_at TIMESTAMP NULL DEFAULT NULL,
				reviewed_at TIMESTAMP NULL DEFAULT NULL,
				rejection_reason TEXT NULL,
				created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
				updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
				CONSTRAINT fk_admission_applications_users
					FOREIGN KEY (user_id)
					REFERENCES users(id)
					ON DELETE CASCADE
					ON UPDATE CASCADE
			) ENGINE = InnoDB
			DEFAULT CHARSET = utf8mb4
			COLLATE = utf8mb4_unicode_ci
		`);

		await dbPool.query(`
			CREATE TABLE IF NOT EXISTS admission_wishes (
				id INT AUTO_INCREMENT PRIMARY KEY,
				application_id INT NOT NULL,
				priority_order INT NOT NULL,
				school_name VARCHAR(255) NOT NULL,
				major_name VARCHAR(255) NOT NULL,
				subject_group VARCHAR(255) NOT NULL,
				created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
				updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
				CONSTRAINT fk_admission_wishes_applications
					FOREIGN KEY (application_id)
					REFERENCES admission_applications(id)
					ON DELETE CASCADE
					ON UPDATE CASCADE,
				UNIQUE KEY uq_admission_wishes_application_priority (application_id, priority_order)
			) ENGINE = InnoDB
			DEFAULT CHARSET = utf8mb4
			COLLATE = utf8mb4_unicode_ci
		`);

		console.log('Admission workflow tables are ready.');
		process.exit(0);
	} catch (error) {
		console.error('Migration failed:', error);
		process.exit(1);
	}
}

migrate();
