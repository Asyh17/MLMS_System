\# Multidisciplinary Laboratory Management System (MLMS)



A robust, enterprise-grade, role-based web application designed to streamline laboratory scheduling, real-time QR code attendance verification, system-wide resource monitoring, and automated compliance reporting across multi-faculty academic streams.



\## 🚀 Tech Stack

\* \*\*Architecture:\*\* Jakarta EE, Model-View-Controller (MVC) Pattern

\* \*\*Backend:\*\* Java Servlets, JDBC, RESTful configurations

\* \*\*Frontend:\*\* JSP (JavaServer Pages), HTML5, CSS3, JavaScript, Chart.js

\* \*\*Database:\*\* MySQL

\* \*\*Server Container:\*\* Eclipse GlassFish



\---



\## 👥 Role-Based Access Control (RBAC) \& Portals

The system features a granular authorization architecture separating user capabilities into four distinct portals:



1\. \*\*Administrator Portal (`/admin`)\*\*

&#x20;  \* Manages lecturer accounts, system-wide access, and overarching configurations.

&#x20;  \* Oversees centralized usage metrics and audit logs.

2\. \*\*Lecturer Portal (`/lecturer`)\*\*

&#x20;  \* Handles laboratory slot bookings and tracks active reservation statuses.

&#x20;  \* \*\*Live QR Projection Station:\*\* Launches a secure, dynamic token generation gateway for real-time student check-ins.

&#x20;  \* Visualizes attendance distributions using interactive \*\*Chart.js\*\* analytics dashboards.

3\. \*\*Student Portal (`/student`)\*\*

&#x20;  \* Features a dedicated check-in module to scan active session tokens for instantaneous attendance logging.

&#x20;  \* Tracks personal attendance history and academic stream standing.

4\. \*\*Technician Portal (`/technician`)\*\*

&#x20;  \* Manages physical laboratory asset profiles and verifies lab status conditions.

&#x20;  \* Oversees and maintains active schedule entries.



\---



\## ✨ Core Technical Highlights

\* \*\*Dynamic QR Token Engine:\*\* Generates secure, time-sensitive session tokens mapped through clean servlet routing to manage instant attendance check-ins.

\* \*\*Secure Database Layer:\*\* Implements a centralized `DBConnection` module designed with environment variable fallback support (`DB\_URL`, `DB\_USER`, `DB\_PASSWORD`) for secure deployment readiness.

\* \*\*Automated Compliance Reporting:\*\* Custom query-filtering engine that aggregates student presence logs against stream allocations to output actionable utilization metrics.

\* \*\*Responsive Layouts:\*\* Tailored dashboard designs optimized for both desktop management and mobile accessibility.



\---



\## 📦 Setup and Installation Instructions



1\. \*\*Clone the Repository:\*\*

&#x20;  ```bash

&#x20;  git clone \[https://github.com/Asyh17/MLMS\_System.git](https://github.com/Asyh17/MLMS\_System.git)

