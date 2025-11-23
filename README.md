<img width="1920" height="1080" alt="Screenshot (223)" src="https://github.com/user-attachments/assets/154d41fc-f543-40b2-8d2e-98fd2759507c" />

🌐 Three-Tier Architecture Setup (VPC + EC2 + RDS + ALB + Route53)

This guide explains how to deploy a complete Three-Tier Architecture on AWS, including:

Networking (VPC, Subnets, IGW, NAT)

Compute (Bastion, Frontend, Backend EC2)

Database (RDS MySQL)

Load Balancers (Backend & Frontend ALB)

Route53 DNS Mapping

Application Deployment

📌 Architecture Overview
Public Subnets: Bastion + ALB
Private Subnets: Frontend + Backend + RDS
RDS Subnets: DB Subnet Group


Traffic Flow:

Client → Route53 → Frontend ALB → Frontend EC2
Frontend → Backend ALB → Backend EC2
Backend → RDS MySQL (private access)

1. Create VPC
Field	Value
Name	project-vpc
CIDR	10.0.0.0/16
2. Create Internet Gateway
Field	Value
Name	project-ig
Attach To	project-vpc
3. Create Subnets
Public Subnets (Bastion & ALB)
Name	AZ	CIDR
public-subnet-1a	1a	10.0.1.0/24
public-subnet-1b	1b	10.0.2.0/24
Frontend Private Subnets
Name	CIDR
frontend-pvt-subnet-1a	10.0.3.0/24
frontend-pvt-subnet-1b	10.0.4.0/24
Backend Private Subnets
Name	CIDR
backend-pvt-subnet-1a	10.0.5.0/24
backend-pvt-subnet-1b	10.0.6.0/24
RDS Subnets
Name	CIDR
rds-subnet-1a	10.0.7.0/24
rds-subnet-1b	10.0.8.0/24
4. Create Public Route Table
Item	Value
Name	public-rt
VPC	project-vpc

Routes

0.0.0.0/0 → Internet Gateway

Subnet Associations

public-subnet-1a

public-subnet-1b

5. Create NAT Gateway
Field	Value
Name	project-nat
Subnet	public-subnet-1a
Elastic IP	Allocate new
6. Create Private Route Table (NAT Route Table)
Item	Value
Name	private-rt-nat
VPC	project-vpc

Routes

0.0.0.0/0 → NAT Gateway

Subnet Associations

frontend-pvt-subnet-1a

frontend-pvt-subnet-1b

backend-pvt-subnet-1a

backend-pvt-subnet-1b

rds-subnet-1a

rds-subnet-1b

7. Create Security Groups
Public SG (public-sg)

Inbound:

All Traffic → 0.0.0.0/0 (or My IP recommended)

Frontend SG (frontend-sg)

Inbound:

SSH → 0.0.0.0/0

HTTP → ALB SG

Backend SG (backend-sg)

Inbound:

SSH → 22 → 0.0.0.0/0

HTTP → 80 → 0.0.0.0/0

All Traffic → 0.0.0.0/0 (Not recommended but matching your input)

ALB Security Group (alb-sg)

Inbound:

HTTP → 80 → 0.0.0.0/0

HTTPS → 443 → 0.0.0.0/0

All Traffic → 0.0.0.0/0

Database SG (database-sg)

Inbound:

MySQL/Aurora → 3306 → Backend SG only (recommended)
(Your script uses 0.0.0.0/0 — but better assign backend-sg.)

8. Launch EC2 Instances
Server	Subnet	Notes
Bastion	Public	SSH entry point
Frontend	Private	Uses Bastion
Backend	Private	Uses Bastion

SSH to Backend/Frontend via Bastion using private key.

9. Configure RDS MySQL
Create DB Subnet Group

Name: rds-sg

VPC: project-vpc

Subnets:

rds-subnet-1a

rds-subnet-1b

Create RDS Instance

Engine: MySQL

Credentials:

username: admin

password: chandan#1234

VPC: project-vpc

Public Access: NO

Multi-AZ: 1a & 1b

🔧 Backend Setup
10. Connect Backend using Bastion
sudo su -
vi <keypair>.pem
chmod 400 <keypair>.pem
ssh -i <keypair>.pem ec2-user@<backend-private-ip>

Install Dependencies
yum install git -y
git clone https://github.com/CloudTechDevOps/2nd10WeeksofCloudOps-main.git
cd 2nd10WeeksofCloudOps-main/backend

Set environment variables

Edit .env:

DB_HOST=<rds-endpoint>
DB_USERNAME=admin
DB_PASSWORD="chandan#1234"
PORT=3306

Install MariaDB client
yum install mariadb105-server -y

Load test.sql
mysql -h <rds-endpoint> -u admin -p<password> < test.sql

Install Node.js
sudo dnf install -y nodejs
npm install
npm install -g pm2
pm2 start index.js --name node-app


Test backend:

curl http://localhost

11. Create Backend Target Group

Name: backend-tg

Protocol: HTTP

Port: 80

VPC: project-vpc

Register Target: Backend EC2

12. Create Backend Load Balancer

Name: backend-ALB

Subnets: public-subnet-1a, 1b

SG: alb-sg + backend-sg

Target Group: backend-tg

AZ: 1a, 1b

Check Target health.

🔵 Frontend Setup
13. Connect to Frontend via Bastion

Install Apache:

yum install httpd -y
systemctl start httpd
systemctl enable httpd


Install Node.js:

sudo dnf install -y nodejs


Clone repo:

git clone https://github.com/CloudTechDevOps/2nd10WeeksofCloudOps-main.git
cd 2nd10WeeksofCloudOps-main/

Modify API Base URL
vi client/src/pages/config.js


Change:

const API_BASE_URL = "http://backend-loadbalancer-url";

Build frontend
cd client
npm install
npm run build
sudo cp -r build/* /var/www/html

14. Create Frontend Target Group

Name: frontend-tg

Protocol: HTTP

Port: 80

VPC: project-vpc

Register frontend EC2.

15. Create Frontend Load Balancer

Name: frontend-ALB

Subnets: public-subnet-1a, 1b

SG: alb-sg + frontend-sg

Target Group: frontend-tg

Check Target health → should be green.

16. Configure Route53
Frontend Domain

Create Alias →

Type: A

Alias: Yes

Target: Frontend Load Balancer

Backend Domain (optional)

Create Alias → Backend ALB

17. Test Application

Open browser:

https://your-domain.com


Backend API:

https://api.your-domain.com


Add Books → Application should work end-to-end.

✅ Three-Tier Architecture Successfully Completed
