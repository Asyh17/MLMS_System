<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Login | MLMS</title>
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
            padding: 16px;
        }

        .auth-container {
            width: 100%;
            max-width: 420px;
            margin: auto;
        }

        .auth-card {
            background-color: var(--white);
            border-radius: 16px;
            border: 1px solid var(--border-color);
            padding: 36px 28px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.04);
            width: 100%;
        }

        .brand-header {
            text-align: center;
            margin-bottom: 28px;
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

        .error-alert {
            background-color: var(--danger-bg);
            border: 1px solid var(--danger-border);
            color: var(--danger-text);
            padding: 12px 16px;
            border-radius: 10px;
            font-size: 13px;
            font-weight: 500;
            margin-bottom: 20px;
            text-align: center;
        }

        .form-group {
            margin-bottom: 20px;
            display: flex;
            flex-direction: column;
            gap: 7px;
        }

        .form-label {
            font-size: 12px;
            font-weight: 600;
            color: #475569;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .form-input {
            width: 100%;
            padding: 13px 16px;
            font-size: 14.5px;
            border-radius: 10px;
            border: 1px solid var(--border-color);
            background-color: #f8fafc;
            color: var(--text-dark);
            outline: none;
            transition: all 0.2s ease;
            font-family: inherit;
        }

        .form-input:focus {
            background-color: var(--white);
            border-color: var(--primary-purple);
            box-shadow: 0 0 0 3.5px rgba(108, 92, 231, 0.15);
        }

        .form-actions-row {
            display: flex;
            justify-content: flex-end;
            align-items: center;
            margin-top: -6px;
            margin-bottom: 22px;
        }

        .link-text {
            font-size: 13px;
            font-weight: 600;
            color: var(--primary-purple);
            text-decoration: none;
            transition: color 0.15s ease;
        }

        .link-text:hover {
            text-decoration: underline;
            color: var(--primary-hover);
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

    
        @media (max-width: 480px) {
            .auth-card {
                padding: 28px 20px;
                border-radius: 14px;
            }
            .brand-logo {
                font-size: 22px;
            }
            .form-input {
                font-size: 16px; 
            }
        }
    </style>
</head>
<body>

    <div class="auth-container">
        <div class="auth-card">
            
            <div class="brand-header">
                <div class="brand-logo">MLMS<span>.System</span></div>
                <p class="brand-subtitle">Sign in to access your laboratory workspace</p>
            </div>

            <% 
                String error = (String) request.getAttribute("loginError");
                if (error != null) { 
            %>
                <div class="error-alert">
                    <%= error %>
                </div>
            <% } %>

            <form action="<%= request.getContextPath() %>/LoginServlet" method="POST">
                
                <div class="form-group">
                    <label class="form-label" for="username">Username / ID</label>
                    <input type="text" id="username" name="username" class="form-input" placeholder="e.g. 2024888123" required autocomplete="username">
                </div>

                <div class="form-group">
                    <label class="form-label" for="password">Password</label>
                    <input type="password" id="password" name="password" class="form-input" placeholder="••••••••" required autocomplete="current-password">
                </div>

                <div class="form-actions-row">
                    <a href="<%= request.getContextPath() %>/forgot-password" class="link-text">Forgot Password?</a>
                </div>

                <button type="submit" class="btn-submit">Sign In to Dashboard</button>
                
            </form>

            <div class="auth-footer">
                Don't have an account yet? 
                <a href="<%= request.getContextPath() %>/register.jsp" class="link-text">Register here</a>
            </div>

        </div>
    </div>

</body>
</html>