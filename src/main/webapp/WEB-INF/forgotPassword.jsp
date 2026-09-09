<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Password Recovery | MLMS</title>
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
            --danger-bg: #fef2f2;
            --danger-border: #fecaca;
            --danger-text: #ef4444;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #f8f9fd 0%, #eef2f6 100%);
            color: var(--text-dark);
            display: flex; align-items: center; justify-content: center;
            min-height: 100vh;
            padding: 16px;
        }

        .recovery-container {
            background-color: var(--white);
            border-radius: 16px;
            border: 1px solid var(--border-color);
            padding: 36px 28px;
            max-width: 420px; width: 100%;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.04);
        }

        .brand-logo { font-size: 24px; font-weight: 800; text-align: center; margin-bottom: 4px; letter-spacing: -0.5px; }
        .brand-logo span { color: var(--primary-purple); }

        .form-title { font-size: 13.5px; font-weight: 500; text-align: center; color: var(--text-muted); margin-bottom: 24px; }

        .form-group { margin-bottom: 18px; display: flex; flex-direction: column; gap: 6px; }
        .form-group label { font-size: 12px; font-weight: 700; color: #475569; text-transform: uppercase; letter-spacing: 0.5px; }

        .form-input {
            width: 100%; padding: 12px 14px; font-size: 14.5px; border-radius: 10px;
            border: 1px solid var(--border-color); outline: none;
            background-color: #f8fafc; color: var(--text-dark); font-family: inherit;
            transition: all 0.2s ease;
        }
        .form-input:focus {
            background-color: var(--white);
            border-color: var(--primary-purple);
            box-shadow: 0 0 0 3.5px rgba(108, 92, 231, 0.15);
        }

        .btn-submit {
            width: 100%; background: linear-gradient(135deg, #6c5ce7, #4834d4);
            color: var(--white); border: none; padding: 14px 20px; font-size: 15px;
            font-weight: 600; border-radius: 10px; cursor: pointer; margin-top: 10px;
            box-shadow: 0 4px 14px rgba(108, 92, 231, 0.28);
            transition: transform 0.15s ease, opacity 0.15s ease;
        }
        .btn-submit:hover { opacity: 0.95; transform: translateY(-1px); }

        .alert-danger {
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

        .login-link { text-align: center; margin-top: 22px; font-size: 13.5px; color: var(--text-muted); }
        .login-link a { color: var(--primary-purple); text-decoration: none; font-weight: 600; }
        .login-link a:hover { text-decoration: underline; }

        @media (max-width: 480px) {
            .recovery-container { padding: 28px 20px; }
            .form-input { font-size: 16px; }
        }
    </style>
</head>
<body>

    <div class="recovery-container">
        <div class="brand-logo">MLMS<span>.System</span></div>
        <div class="form-title">Account Password Reset</div>

        <% if (request.getAttribute("errorMessage") != null) { %>
            <div class="alert-danger">
                ⚠️ <%= request.getAttribute("errorMessage") %>
            </div>
        <% } %>

        <form action="<%= request.getContextPath() %>/ForgotPasswordServlet" method="POST">
            <div class="form-group">
                <label for="username">Username / ID</label>
                <input type="text" id="username" name="username" class="form-input" placeholder="e.g. 2024888123" required autocomplete="username">
            </div>

            <div class="form-group">
                <label for="securityAnswer">Security Key</label>
                <input type="text" id="securityAnswer" name="securityAnswer" class="form-input" placeholder="Default key: mlms123" required>
            </div>

            <div class="form-group">
                <label for="newPassword">New Password</label>
                <input type="password" id="newPassword" name="newPassword" class="form-input" placeholder="••••••••" required autocomplete="new-password">
            </div>

            <button type="submit" class="btn-submit">Update Password</button>
        </form>

        <div class="login-link">
            Remembered your password? <a href="<%= request.getContextPath() %>/login.jsp">Sign In</a>
        </div>
    </div>

</body>
</html>