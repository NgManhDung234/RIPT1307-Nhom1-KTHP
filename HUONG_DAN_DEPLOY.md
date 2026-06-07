# Hướng Dẫn Deploy Dự Án lên Render và Netlify

Hướng dẫn này giúp bạn deploy dự án Student Management System lên:
- **Render**: Backend API + PostgreSQL Database
- **Netlify**: Frontend React App

---

## 1. Tổng quan kiến trúc

```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│   Netlify       │         │    Render       │         │  Render PostgreSQL│
│   (Frontend)    │◄────────►│   (Backend)     │◄────────►│   Database      │
│   React App     │  HTTPS   │   Express API   │  TCP    │   Student DB    │
└─────────────────┘         └─────────────────┘         └─────────────────┘
```

- **Frontend**: Static React app deploy trên Netlify
- **Backend**: Express + Socket.IO deploy trên Render
- **Database**: PostgreSQL deploy trên Render

---

## 2. Chuẩn bị trước khi deploy

### 2.1 Tài khoản cần có
- Tài khoản **Render**: https://render.com (Free tier)
- Tài khoản **Netlify**: https://netlify.com (Free tier)
- Tài khoản **GitHub**: Đã push code lên GitHub

### 2.2 File cấu hình đã tạo
- ✅ `render.yaml` - Cấu hình Render
- ✅ `netlify.toml` - Cấu hình Netlify
- ✅ `.env.example` - Mẫu biến môi trường

---

## 3. Deploy Backend lên Render

### 3.1 Cập nhật backend package.json

Đảm bảo file `backend-package.json` có cấu hình đúng:

```json
{
  "main": "dist-backend/index.js",
  "scripts": {
    "build": "tsc -p tsconfig.backend.json",
    "start": "node dist-backend/index.js"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
```

### 3.2 Cập nhật CORS cho production

File `src/backend/index.ts` - Cập nhật origin CORS:

```typescript
const io = new SocketIOServer(httpServer, {
  cors: {
    origin: [
      'http://localhost:8000',
      'http://localhost:3000',
      'https://your-netlify-app.netlify.app' // Thêm domain Netlify của bạn
    ],
    methods: ['GET', 'POST'],
    credentials: true,
  },
});
```

### 3.3 Tạo database trên Render

1. Đăng nhập vào Render: https://dashboard.render.com
2. Click **New +** → **Database**
3. Chọn **PostgreSQL**
4. Đặt tên: `student-management-db`
5. Chọn plan: **Free**
6. Click **Create Database**

**Lưu ý thông tin database:**
- Internal Database URL
- Host
- Port
- User
- Password
- Database Name

### 3.4 Deploy backend service

**Cách 1: Sử dụng render.yaml (Tự động)**

1. Đăng nhập Render Dashboard
2. Click **New +** → **Blueprint**
3. Connect GitHub repository: `hdbn21072006-droid/dang`
4. Render sẽ tự động đọc file `render.yaml`
5. Review cấu hình và click **Apply**

**Cách 2: Tạo thủ công**

1. Click **New +** → **Web Service**
2. Connect GitHub repository
3. Cấu hình:
   - **Name**: `student-management-backend`
   - **Runtime**: `Node`
   - **Build Command**: `cd src/backend && npm install && npm run build`
   - **Start Command**: `node dist-backend/index.js`
   - **Root Directory**: (để trống)
4. Click **Advanced** → **Add Environment Variable**:

| Key | Value |
|-----|-------|
| `NODE_ENV` | `production` |
| `BACKEND_PORT` | `5000` |
| `DB_HOST` | (từ database Render) |
| `DB_PORT` | (từ database Render) |
| `DB_USER` | (từ database Render) |
| `DB_PASSWORD` | (từ database Render) |
| `DB_NAME` | (từ database Render) |
| `JWT_SECRET` | (tạo secret ngẫu nhiên) |
| `GMAIL_EMAIL` | (email của bạn) |
| `GMAIL_APP_PASSWORD` | (app password Gmail) |
| `GEMINI_API_KEY` | (API key Gemini) |
| `LLM_PROVIDER` | `gemini` |
| `GEMINI_MODEL` | `gemini-2.0-flash` |
| `MAX_HISTORY_PAIRS` | `10` |
| `TOP_K_CHUNKS` | `5` |

5. Click **Deploy Web Service**

### 3.5 Chạy migration trên Render

Sau khi backend deploy thành công:

1. Vào Render Dashboard → chọn service backend
2. Click **Shell** (để mở terminal)
3. Chạy lệnh:

```bash
cd src/backend
npm run migrate
```

Hoặc chạy trực tiếp SQL migration qua pgAdmin hoặc psql kết nối đến database Render. Sử dụng file `src/backend/database/init_postgres.sql`.

---

## 4. Deploy Frontend lên Netlify

### 4.1 Cập nhật API URL cho production

File `src/frontend/services/auth.ts` và các service khác:

```typescript
// Thay đổi base URL theo môi trường
const BASE_URL = process.env.NODE_ENV === 'production' 
  ? 'https://your-backend-app.onrender.com' 
  : 'http://localhost:5000';
```

Hoặc sử dụng biến môi trường trong Netlify.

### 4.2 Deploy qua Netlify Dashboard

1. Đăng nhập Netlify: https://app.netlify.com
2. Click **Add new site** → **Import an existing project**
3. Connect GitHub repository: `hdbn21072006-droid/dang`
4. Cấu hình build:
   - **Build command**: `yarn build`
   - **Publish directory**: `dist`
   - **Node version**: `16`
5. Click **Deploy site**

### 4.3 Cấu hình Environment Variables trên Netlify

1. Vào Site settings → **Environment variables**
2. Thêm biến:

| Key | Value |
|-----|-------|
| `REACT_APP_API_URL` | `https://your-backend-app.onrender.com` |
| `REACT_APP_SOCKET_URL` | `https://your-backend-app.onrender.com` |

### 4.4 Cập nhật CORS trên Backend

Sau khi có domain Netlify, cập nhật lại CORS trong `src/backend/index.ts`:

```typescript
const io = new SocketIOServer(httpServer, {
  cors: {
    origin: [
      'http://localhost:8000',
      'http://localhost:3000',
      'https://your-netlify-app.netlify.app' // Domain Netlify của bạn
    ],
    methods: ['GET', 'POST'],
    credentials: true,
  },
});
```

Push code lại và Render sẽ auto-redeploy.

---

## 5. Kiểm tra deployment

### 5.1 Kiểm tra Backend

Truy cập: `https://your-backend-app.onrender.com/health`

Kết quả mong đợi:
```json
{
  "status": "ok",
  "timestamp": "2026-06-07T..."
}
```

### 5.2 Kiểm tra Database

Truy cập: `https://your-backend-app.onrender.com/api/database/health`

### 5.3 Kiểm tra Frontend

Truy cập: `https://your-netlify-app.netlify.app`

Test đăng nhập với tài khoản mẫu:
- Manager: `manager01` / `manager123`
- Student: `student01` / `student123`

---

## 6. Cấu hình DNS tùy chọn (Optional)

Nếu muốn dùng custom domain:

### 6.1 Netlify Custom Domain
1. Site settings → **Domain management**
2. Add custom domain
3. Cập nhật DNS records tại nhà cung cấp domain

### 6.2 Render Custom Domain
1. Service settings → **Custom Domains**
2. Add custom domain
3. Cập nhật DNS records

---

## 7. Troubleshooting

### 7.1 Backend không khởi động
- Kiểm tra logs trên Render Dashboard
- Đảm bảo build command đúng
- Kiểm tra environment variables

### 7.2 Database connection failed
- Kiểm tra thông tin database trong Render
- Đảm bảo database đã được tạo
- Kiểm tra firewall rules

### 7.3 CORS errors
- Cập nhật origin CORS trong backend
- Đảm bảo domain frontend đã được thêm vào whitelist
- Re-deploy backend sau khi cập nhật

### 7.4 Socket.IO không kết nối
- Kiểm tra port và protocol (http/https)
- Đảm bảo CORS cho Socket.IO đúng
- Kiểm tra logs backend

### 7.5 Frontend build failed
- Kiểm tra Node version (phải là 16)
- Xóa `node_modules` và build lại
- Kiểm tra `package.json` scripts

---

## 8. Giới hạn Free Tier

### Render Free Tier
- **Web Service**: 750 giờ/tháng (≈ 1 instance 24/7)
- **Database**: 90 ngày sleep sau 90 ngày không hoạt động
- **Bandwidth**: 100GB/tháng

### Netlify Free Tier
- **Bandwidth**: 100GB/tháng
- **Build minutes**: 300 phút/tháng
- **Sites**: Không giới hạn

---

## 9. Backup và Monitoring

### 9.1 Database Backup
Render tự động backup database hàng ngày (free tier).

### 9.2 Logs
- **Render**: Dashboard → Logs
- **Netlify**: Site → Deploys → Deploy log

### 9.3 Monitoring
Sử dụng Render Dashboard để monitor:
- CPU usage
- Memory usage
- Response time
- Error rate

---

## 10. Cập nhật code sau này

### Quy trình update:
1. Push code lên GitHub
2. Render tự động detect và redeploy backend
3. Netlify tự động detect và redeploy frontend
4. Kiểm tra logs nếu có lỗi

### Force deploy thủ công:
- **Render**: Dashboard → Manual Deploy
- **Netlify**: Site → Deploys → Trigger deploy

---

## 11. Security Notes

- ✅ Không commit file `.env` (đã thêm vào `.gitignore`)
- ✅ Sử dụng environment variables cho sensitive data
- ✅ Enable HTTPS (tự động trên Render & Netlify)
- ✅ Regular update dependencies
- ✅ Monitor logs cho suspicious activity

---

## 12. Chi phí

Với free tier:
- **Render**: $0/tháng (nếu dùng < 750 giờ)
- **Netlify**: $0/tháng (nếu dùng < 100GB bandwidth)
- **GitHub**: $0 (public repository)

Tổng chi phí: **$0/tháng** cho personal project.

---

## 13. Tài liệu tham khảo

- Render Docs: https://render.com/docs
- Netlify Docs: https://docs.netlify.com
- PostgreSQL on Render: https://render.com/docs/databases/postgresql

---

## Hỗ trợ

Nếu gặp vấn đề:
1. Kiểm tra logs trên Render và Netlify
2. Review error messages
3. Tìm kiếm trong documentation
4. Contact support Render/Netlify
