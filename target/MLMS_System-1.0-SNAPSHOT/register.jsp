<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Register Account | MLMS</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary-purple: #6c5ce7;
            --primary-hover: #5b4bc4;
            --main-bg: #f8f9fd;
            --text-dark: #2d3436;
            --text-muted: #64748b;
            --border-color: #e2e8f0;
            --white: #ffffff;
            --uitm-blue: #3498db;
            --danger-bg: #fef2f2;
            --danger-border: #fecaca;
            --danger-text: #ef4444;
            --success-bg: #f0fdf4;
            --success-border: #bbf7d0;
            --success-text: #16a34a;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #f8f9fd 0%, #eef2f6 100%);
            color: var(--text-dark);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px 16px;
        }

        .auth-container {
            width: 100%;
            max-width: 480px;
            margin: auto;
        }

        .auth-card {
            background-color: var(--white);
            border-radius: 16px;
            border: 1px solid var(--border-color);
            padding: 36px 30px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.04);
            width: 100%;
        }

        .brand-header {
            text-align: center;
            margin-bottom: 26px;
        }

        .brand-logo {
            font-size: 24px;
            font-weight: 800;
            color: var(--text-dark);
            letter-spacing: -0.5px;
            margin-bottom: 6px;
        }

        .brand-logo span {
            color: var(--primary-purple);
        }

        .brand-subtitle {
            font-size: 13.5px;
            color: var(--text-muted);
            line-height: 1.4;
        }

        .alert-box {
            padding: 12px 16px;
            border-radius: 10px;
            font-size: 13px;
            font-weight: 500;
            margin-bottom: 20px;
            text-align: center;
        }

        .alert-error {
            background-color: var(--danger-bg);
            border: 1px solid var(--danger-border);
            color: var(--danger-text);
        }

        .alert-success {
            background-color: var(--success-bg);
            border: 1px solid var(--success-border);
            color: var(--success-text);
        }

        .form-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 16px;
            margin-bottom: 22px;
        }

        .form-group {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .form-label {
            font-size: 12px;
            font-weight: 600;
            color: #475569;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .form-input, .form-select {
            width: 100%;
            padding: 12px 15px;
            font-size: 14px;
            border-radius: 10px;
            border: 1px solid var(--border-color);
            background-color: #f8fafc;
            color: var(--text-dark);
            outline: none;
            transition: all 0.2s ease;
            font-family: inherit;
        }

        .form-input:focus, .form-select:focus {
            background-color: var(--white);
            border-color: var(--primary-purple);
            box-shadow: 0 0 0 3.5px rgba(108, 92, 231, 0.15);
        }

        .btn-submit {
            width: 100%;
            background: linear-gradient(135deg, var(--primary-purple), #4834d4);
            color: var(--white);
            border: none;
            padding: 14px 20px;
            font-size: 15px;
            font-weight: 600;
            border-radius: 10px;
            cursor: pointer;
            box-shadow: 0 4px 14px rgba(108, 92, 231, 0.28);
            transition: transform 0.15s ease, opacity 0.15s ease;
        }

        .btn-submit:hover {
            opacity: 0.95;
            transform: translateY(-1px);
        }

        .btn-submit:active {
            transform: translateY(0);
        }

        .auth-footer {
            margin-top: 24px;
            padding-top: 20px;
            border-top: 1px solid #f1f5f9;
            text-align: center;
            font-size: 13.5px;
            color: var(--text-muted);
        }

        .link-text {
            font-weight: 600;
            color: var(--primary-purple);
            text-decoration: none;
        }

        .link-text:hover {
            text-decoration: underline;
        }

        @media (min-width: 480px) {
            .form-grid-2 {
                grid-template-columns: 1fr 1fr;
            }
        }

        /* Mobile specific spacing */
        @media (max-width: 480px) {
            .auth-card {
                padding: 26px 18px;
                border-radius: 14px;
            }
            .form-input, .form-select {
                font-size: 16px; 
            }
        }
    </style>
</head>
<body>

    <div class="auth-container">
        <div class="auth-card">
            
            <div class="brand-header">
                <div class="brand-logo">MLMS<span>.Register</span></div>
                <p class="brand-subtitle">Create your student or faculty account</p>
            </div>

            <% 
                String error = (String) request.getAttribute("registerError");
                String success = (String) request.getAttribute("registerSuccess");
                if (error != null) { 
            %>
                <div class="alert-box alert-error"><%= error %></div>
            <% } else if (success != null) { %>
                <div class="alert-box alert-success"><%= success %></div>
            <% } %>

            <form action="<%= request.getContextPath() %>/RegisterServlet" method="POST">
                
                <div class="form-grid">
                    
                    <div class="form-group">
                        <label class="form-label" for="fullName">Full Name</label>
                        <input type="text" id="fullName" name="fullName" class="form-input" placeholder="e.g. Ahmad Asyraf" required autocomplete="name">
                    </div>

                    <div class="form-grid form-grid-2">
                        <div class="form-group">
                            <label class="form-label" for="username">User ID / Username</label>
                            <input type="text" id="username" name="username" class="form-input" placeholder="e.g. 2024889911" required autocomplete="username">
                        </div>

                        <div class="form-group">
                            <label class="form-label" for="role">Account Role</label>
                            <select id="role" name="role" class="form-select" required onchange="toggleStudentStream(this.value)">
                                <option value="STUDENT">Student</option>
                                <option value="LECTURER">Lecturer</option>
                                <option value="TECHNICIAN">Technician</option>
                            </select>
                        </div>
                    </div>

                    <div class="form-group" id="stream-group">
                        <label class="form-label" for="studentStream">Academic Stream</label>
                        <select id="studentStream" name="studentStream" class="form-select">
                            <option value="Computer Science Student">Computer Science (CS)</option>
                            <option value="Science Stream">Science Stream</option>
                            <option value="Engineering Stream">Engineering Stream</option>
                        </select>
                    </div>

                    <div class="form-grid form-grid-2">
                        <div class="form-group">
                            <label class="form-label" for="password">Password</label>
                            <input type="password" id="password" name="password" class="form-input" placeholder="••••••••" required autocomplete="new-password">
                        </div>

                        <div class="form-group">
                            <label class="form-label" for="confirmPassword">Confirm Password</label>
                            <input type="password" id="confirmPassword" name="confirmPassword" class="form-input" placeholder="••••••••" required autocomplete="new-password">
                        </div>
                    </div>

                </div>

                <button type="submit" class="btn-submit">Register Account</button>
                
            </form>

            <div class="auth-footer">
                Already registered? 
                <a href="<%= request.getContextPath() %>/login.jsp" class="link-text">Sign In</a>
            </div>

        </div>
    </div>

    <script>
        function toggleStudentStream(role) {
            const streamGroup = document.getElementById("stream-group");
            if (role === "STUDENT") {
                streamGroup.style.display = "flex";
            } else {
                streamGroup.style.display = "none";
            }
        }
    </script>
</body>
</html>