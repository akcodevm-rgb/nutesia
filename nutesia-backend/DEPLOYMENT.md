# DigitalOcean + MongoDB Atlas Deployment & Local Setup Blueprint

This document contains the complete specification and step-by-step guide for local setup with MongoDB Atlas / local MongoDB and cloud deployment for the Golang backend using **DigitalOcean** and **MongoDB Atlas**.

---

## 1. Local Setup for MongoDB Atlas & Local MongoDB

### Step 1: Configure Environment Variables
Copy `.env.example` to `.env` in the `backend/` directory:

```bash
cp .env.example .env
```

### Step 2: Set your Connection String in `.env`

#### Option A: Cloud MongoDB Atlas
1. Obtain your connection string from MongoDB Atlas (Drivers -> Go).
2. Paste it in `.env` under `MONGO_URI`:
```env
PORT=8080
DATA_DIR=./data
GROQ_API_KEY=your_groq_api_key_here
ALLOWED_ORIGIN=*

# MongoDB Atlas Connection String
MONGO_URI=mongodb+srv://<username>:<password>@cluster0.xxxx.mongodb.net/?retryWrites=true&w=majority
MONGO_DB_NAME=nuto
```

#### Option B: Local MongoDB (Community Edition / Docker)
If running MongoDB locally on port 27017:
```env
MONGO_URI=mongodb://localhost:27017
MONGO_DB_NAME=nuto
```

#### Option C: File Storage Fallback
If `MONGO_URI` is left blank, the server automatically falls back to local JSON file storage inside `./data`.

### Step 3: Run Backend Locally
```bash
go run ./cmd/server
```

You should see log output indicating the database connection:
```text
Connected to MongoDB storage (Database: nuto)
Nuto API listening on :8080
```

---

## 2. Production Deployment Blueprint (DigitalOcean + MongoDB Atlas)

### 2.1 Cost Calculation Breakdown
This setup leverages MongoDB Atlas's free production-ready tier and DigitalOcean's low-cost developer VMs.

| Component | Service & Tier | Monthly Cost (USD) | Monthly Cost (INR Approx.) | Resource Specs |
|---|---|---|---|---|
| **Go Backend** | DigitalOcean Regular Droplet | $6.00 | ~₹500 | 1 vCPU, 1 GB RAM, 25 GB NVMe SSD, 1 TB Transfer |
| **NoSQL DB** | MongoDB Atlas M0 Shared Cluster | $0.00 (Free Forever) | ₹0 | 512 MB Storage, Shared RAM, Automated Failover |
| **Networking** | Data Transfer / VPC | $0.00 | ₹0 | Free incoming bandwidth, 1TB outgoing included |
| **Total Cost** | **Complete Stack** | **$6.00 / month** | **~₹500 / month** | Billed hourly ($0.009/hr), cancel anytime |

---

### 2.2 Full Architecture Requirements
Before starting, ensure you have the following prerequisites ready:

* **Accounts:** A DigitalOcean account (requires a credit card or PayPal for verification) and a MongoDB Cloud Atlas account.
* **Local Machine:** A terminal with `ssh` and `go` installed.
* **Golang Application:** Environment-configurable backend (using `os.Getenv("MONGO_URI")` and `os.Getenv("PORT")`).
* **Port Configuration:** Application binds to port `8080` (or preferred port) behind firewall/systemd.

---

### 2.3 Step-by-Step Setup Guide

#### Phase A: Provisioning the NoSQL Database (MongoDB Atlas)
1. **Create a Cluster:** Log into MongoDB Atlas, click **Deploy a Database**, and select the **M0 Free Tier**.
2. **Select Region:** Choose **AWS / Mumbai (ap-south-1)** (or Bangalore) to minimize latency relative to your DigitalOcean server.
3. **Database Access Security:** Create a database user. Note down the Username and secure Password.
4. **Network Access Security:**
   * *For Initial Setup:* Click "Allow Access from Anywhere" (`0.0.0.0/0`).
   * *Production Note:* Once your DigitalOcean VM is live, replace `0.0.0.0/0` with the exact static Public IP of your Droplet for tight firewall security.
5. **Get Connection String:** Click **Connect -> Drivers -> Go**. Copy the connection string:
   ```text
   mongodb+srv://<username>:<password>@cluster0.xxxx.mongodb.net/?retryWrites=true&w=majority
   ```

---

#### Phase B: Launching the Server (DigitalOcean)
1. **Create Droplet:** Click **Create -> Droplets**.
2. **Region:** Select **Bangalore (BLR1)** to minimize latency.
3. **OS Image:** Choose **Ubuntu 24.04 LTS**.
4. **Droplet Type:** Select **Basic -> Regular CPU -> $6/month tier** (1 GB RAM / 1 vCPU).
5. **Authentication:** Select **SSH Keys** (Highly Recommended) and upload your local machine's public key (`~/.ssh/id_rsa.pub`).
6. **Launch:** Click **Create Droplet**. Copy its public IP address once initialized.

---

#### Phase C: Server Hardening & Go Deployment
Open your terminal and SSH into your server:

```bash
ssh root@your_droplet_ip
```

Execute these steps sequentially to configure the system:

```bash
# 1. Update system packages
apt update && apt upgrade -y

# 2. Configure Firewall (UFW)
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 8080/tcp  # Opens port for Go API
ufw --force enable

# 3. Compile Go app locally for Linux architecture (Run on local development machine):
GOOS=linux GOARCH=amd64 go build -o my-backend-app ./cmd/server

# 4. Upload compiled binary from local machine to server:
scp my-backend-app root@your_droplet_ip:/usr/local/bin/
```

---

#### Phase D: Keeping the Go Backend Running via Systemd
Create a systemd service file on the DigitalOcean server:

```bash
nano /etc/systemd/system/go-backend.service
```

Paste the following configuration (replace placeholders with your real connection string):

```ini
[Unit]
Description=Golang NoSQL Backend API
After=network.target

[Service]
Type=simple
User=root
Environment=MONGO_URI=mongodb+srv://USER:PASSWORD@cluster0.xxxx.mongodb.net/nuto?retryWrites=true&w=majority
Environment=MONGO_DB_NAME=nuto
Environment=PORT=8080
Environment=GROQ_API_KEY=your_production_groq_key
Environment=ALLOWED_ORIGIN=*
ExecStart=/usr/local/bin/my-backend-app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
# Reload systemd
systemctl daemon-reload

# Start service & enable auto-restart on boot
systemctl start go-backend
systemctl enable go-backend

# Check status
systemctl status go-backend
```

Your Golang application is now live on DigitalOcean, connected to MongoDB Atlas!
