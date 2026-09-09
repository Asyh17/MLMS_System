<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    // Session Protection Gate Check
    if (session.getAttribute("userToken") == null || !"STUDENT".equalsIgnoreCase((String) session.getAttribute("userRole"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp"); 
        return;
    }
    String currentStudentName = (String) session.getAttribute("userName");
    if (currentStudentName == null) currentStudentName = "Student";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Live QR Attendance Scanner | MLMS</title>
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <!-- HTML5 Live Camera QR Scanner -->
    <script src="https://unpkg.com/html5-qrcode"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Inter', -apple-system, sans-serif; }
    </style>
</head>
<body class="bg-slate-50 text-slate-900 min-h-screen flex flex-col justify-between pb-24 antialiased selection:bg-indigo-500 selection:text-white">

    <!-- Top Header (Light Dashboard Style) -->
    <header class="bg-white border-b border-slate-200 px-5 py-3.5 flex justify-between items-center sticky top-0 z-40 shadow-sm">
        <div class="text-xl font-extrabold tracking-tight text-slate-900">
            MLMS<span class="text-indigo-600">.Scanner</span>
        </div>
        <div class="flex items-center gap-2.5">
            <span class="text-xs bg-slate-100 text-slate-700 px-3.5 py-1.5 rounded-full border border-slate-200 font-semibold truncate max-w-[150px] flex items-center gap-1.5">
                👤 <span><%= currentStudentName %></span>
            </span>
            <a href="<%= request.getContextPath() %>/login.jsp" 
               class="text-xs text-rose-600 bg-rose-50 border border-rose-200 px-3.5 py-1.5 rounded-full font-bold hover:bg-rose-100 transition"
               onclick="return confirm('Are you sure you want to sign out?');">
                Sign Out
            </a>
        </div>
    </header>

    <!-- Main Scanner Viewport Container -->
    <main class="max-w-md w-full mx-auto p-4 flex-1 flex flex-col justify-center">
        <div class="bg-white border border-slate-200 rounded-3xl p-6 md:p-8 shadow-sm text-center">
            
            <div class="inline-flex p-3.5 bg-indigo-50 text-indigo-600 rounded-2xl mb-3">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z"/>
                </svg>
            </div>
            
            <h1 class="text-xl font-bold text-slate-900 tracking-tight mb-1">Scan Station QR Code</h1>
            <p class="text-xs text-slate-500 mb-6">Aim your smartphone lens at the dynamic QR code projected in your lab room.</p>

            <!-- Camera Frame -->
            <div class="relative w-full aspect-square bg-slate-900 rounded-2xl overflow-hidden border border-slate-300 shadow-inner flex items-center justify-center">
                <div id="reader" class="w-full h-full"></div>
                <div id="camera-placeholder" class="flex flex-col items-center justify-center text-slate-400 p-4">
                    <svg class="w-12 h-12 mb-3 stroke-slate-500 animate-pulse" fill="none" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                    <span class="text-xs font-mono font-medium text-slate-400 tracking-wider">CAMERA STANDBY</span>
                </div>
            </div>

            <!-- Real-time Verification Status Message -->
            <div id="status-box" class="hidden p-3.5 rounded-xl text-xs font-semibold mt-4 text-left leading-relaxed"></div>

            <!-- Action Controls -->
            <div class="mt-6 space-y-3">
                <button type="button" id="toggle-camera-btn" onclick="toggleScanner()" 
                        class="w-full py-3.5 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-2xl text-sm shadow-md shadow-indigo-600/20 transition transform active:scale-[0.98]">
                    📷 Open Camera Scanner
                </button>
            </div>

        </div>
    </main>

    <!-- Bottom Navigation Bar -->
    <nav class="fixed bottom-0 left-0 right-0 h-16 bg-white border-t border-slate-200 flex justify-around items-center z-50 px-4 shadow-[0_-2px_10px_rgba(0,0,0,0.03)]">
        <a href="<%= request.getContextPath() %>/student/dashboard" class="flex flex-col items-center text-slate-500 hover:text-indigo-600 text-[11px] font-medium transition">
            <svg class="w-5 h-5 mb-0.5" fill="currentColor" viewBox="0 0 20 20">
                <path d="M10.707 2.293a1 1 0 00-1.414 0l-7 7a1 1 0 001.414 1.414L4 10.414V17a1 1 0 001 1h2a1 1 0 001-1v-2a1 1 0 011-1h2a1 1 0 011 1v2a1 1 0 001 1h2a1 1 0 001-1v-6.586l.293.293a1 1 0 001.414-1.414l-7-7z"/>
            </svg>
            Workspace
        </a>
        <a href="<%= request.getContextPath() %>/student/scan" class="flex flex-col items-center text-indigo-600 text-[11px] font-bold">
            <div class="-mt-7 p-3.5 bg-indigo-600 rounded-full border-4 border-slate-50 text-white shadow-md shadow-indigo-600/30">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z"/>
                </svg>
            </div>
            Scan QR
        </a>
        <a href="<%= request.getContextPath() %>/student/my-attendance" class="flex flex-col items-center text-slate-500 hover:text-indigo-600 text-[11px] font-medium transition">
            <svg class="w-5 h-5 mb-0.5" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clip-rule="evenodd"/>
            </svg>
            History Logs
        </a>
    </nav>

    <script>
        let html5QrCode = null;
        let isScanning = false;
        const statusBox = document.getElementById("status-box");
        const placeholder = document.getElementById("camera-placeholder");
        const toggleBtn = document.getElementById("toggle-camera-btn");

        function showStatus(text, bgClass) {
            statusBox.className = "p-3.5 rounded-xl text-xs font-semibold mt-4 text-left leading-relaxed " + bgClass;
            statusBox.textContent = text;
            statusBox.classList.remove("hidden");
        }

        function toggleScanner() {
            if (isScanning) {
                stopScanner();
            } else {
                startScanner();
            }
        }

        function startScanner() {
            if (!html5QrCode) {
                html5QrCode = new Html5Qrcode("reader");
            }
            
            placeholder.classList.add("hidden");
            statusBox.classList.add("hidden");

            html5QrCode.start(
                { facingMode: "environment" },
                { fps: 15, qrbox: { width: 240, height: 240 } },
                onScanSuccess
            ).then(() => {
                isScanning = true;
                toggleBtn.textContent = "🛑 Stop Camera";
                toggleBtn.className = "w-full py-3.5 bg-rose-600 hover:bg-rose-700 text-white font-semibold rounded-2xl text-sm transition";
            }).catch(err => {
                placeholder.classList.remove("hidden");
                showStatus("Camera access denied or unavailable. Please ensure camera permissions are allowed in your browser.", "bg-rose-50 text-rose-700 border border-rose-200");
            });
        }

        function stopScanner() {
            if (html5QrCode && isScanning) {
                html5QrCode.stop().then(() => {
                    isScanning = false;
                    placeholder.classList.remove("hidden");
                    toggleBtn.textContent = "📷 Open Camera Scanner";
                    toggleBtn.className = "w-full py-3.5 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-2xl text-sm shadow-md shadow-indigo-600/20 transition";
                });
            }
        }

        function onScanSuccess(decodedText) {
            stopScanner();
            showStatus("⏳ QR Detected! Validating curriculum clearance and reservation window...", "bg-indigo-50 text-indigo-700 border border-indigo-200");

            let bookingId = decodedText;
            let token = "";

            try {
                const parsed = JSON.parse(decodedText);
                bookingId = parsed.bookingId || decodedText;
                token = parsed.token || "";
            } catch (e) {
                bookingId = decodedText;
            }

            const params = new URLSearchParams();
            params.append("action", "SCAN_QR");
            params.append("bookingId", bookingId);
            params.append("token", token);

            fetch("<%= request.getContextPath() %>/AttendanceServlet", {
                method: "POST",
                headers: { 
                    "Content-Type": "application/x-www-form-urlencoded",
                    "Accept": "application/json",
                    "X-Requested-With": "XMLHttpRequest"
                },
                body: params.toString()
            })
            .then(async res => {
                const data = await res.json().catch(() => ({}));
                if (!res.ok || data.success === false) {
                    const errorMsg = data.message || "Attendance verification failed.";
                    throw new Error(errorMsg);
                }
                return data;
            })
            .then(data => {
                showStatus("✅ Attendance Verified & Recorded Successfully!", "bg-emerald-50 text-emerald-700 border border-emerald-200");
                setTimeout(() => { 
                    window.location.href = data.redirect || "<%= request.getContextPath() %>/student/my-attendance"; 
                }, 1400);
            })
            .catch(err => {
                showStatus("⚠️ " + err.message, "bg-rose-50 text-rose-700 border border-rose-200");
                toggleBtn.textContent = "🔄 Try Scanning Again";
                toggleBtn.className = "w-full py-3.5 bg-amber-600 hover:bg-amber-700 text-white font-semibold rounded-2xl text-sm transition shadow-md shadow-amber-600/20";
            });
        }
    </script>
</body>
</html>