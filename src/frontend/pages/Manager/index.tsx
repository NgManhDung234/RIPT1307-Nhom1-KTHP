import { Button, Card, Typography, message } from 'antd';
import { history } from 'umi';
import { getCurrentUser, logout } from '../../utils/auth';
import styles from './index.less';

const { Title, Text } = Typography;

const ManagerPage: React.FC = () => {
	const user = getCurrentUser();

	if (!user || user.role !== 'manager') {
		message.error('Bạn không có quyền truy cập trang quản lí');
		history.replace('/user/login');
		return null;
	}

	return (
		<div className={styles.container}>
			<Card className={styles.card}>
				<Title level={2}>Trang Quản Lí</Title>
				<Text>Xin chào quản lí: {user.full_name}</Text>
				<div className={styles.actions}>
					<Button
						type="primary"
						onClick={() => {
							logout();
							history.push('/user/login');
						}}
					>
						Đăng xuất
					</Button>
				</div>
			</Card>
		</div>
	);
};

export default ManagerPage;
