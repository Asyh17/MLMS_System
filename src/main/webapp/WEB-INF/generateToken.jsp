<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="com.mycompany.mlms_system.database.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>

<%
    String activeBookingId = request.getParameter("bookingId");
    if (activeBookingId == null || activeBookingId.trim().isEmpty()) {
        activeBookingId = (String) session.getAttribute("currentBookingId");
    }

    String activeLabCode = "";
    String activeLabName = "Main Laboratory Space";
    String sessionDateDisplay = "—";
    String sessionSlotDisplay = "—";
    boolean isSessionActive = false;
    String sessionStatusMessage = "Active Station";

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        
        if (activeBookingId != null && !activeBookingId.trim().isEmpty()) {
            // Check specific booking and evaluate if it is currently ongoing (today + live 2-hour window)
            String query = "SELECT bookingId, labId, DATE_FORMAT(bookingDate, '%d/%m/%Y') AS b_date, timeSlot, "
                         + "(bookingDate = CURRENT_DATE() AND CURRENT_TIME() BETWEEN timeSlot AND ADDTIME(timeSlot, '02:00:00')) AS is_live, "
                         + "(bookingDate < CURRENT_DATE() OR (bookingDate = CURRENT_DATE() AND ADDTIME(timeSlot, '02:00:00') < CURRENT_TIME())) AS is_expired "
                         + "FROM booking WHERE bookingId = ?";
            stmt = conn.prepareStatement(query);
            stmt.setString(1, activeBookingId);
            rs = stmt.executeQuery();
            if (rs.next()) {
                activeLabCode = rs.getString("labId");
                sessionDateDisplay = rs.getString("b_date");
                String rawSlot = rs.getString("timeSlot");
                if ("10:00:00".equals(rawSlot)) sessionSlotDisplay = "10:00 AM - 12:00 PM";
                else if ("14:00:00".equals(rawSlot)) sessionSlotDisplay = "02:00 PM - 04:00 PM";
                else sessionSlotDisplay = rawSlot;

                boolean isLive = rs.getBoolean("is_live");
                boolean isExpired = rs.getBoolean("is_expired");

                if (isLive) {
                    isSessionActive = true;
                    sessionStatusMessage = "STATION ACTIVE • LIVE SYNC";
                } else if (isExpired) {
                    isSessionActive = false;
                    sessionStatusMessage = "SESSION EXPIRED • GATE CLOSED";
                } else {
                    isSessionActive = false;
                    sessionStatusMessage = "SCHEDULED • NOT STARTED";
                }
            }
        } else {
            // Live auto-discovery: Look up ongoing approved session for the current time window
            String liveLookupSQL = "SELECT bookingId, labId, DATE_FORMAT(bookingDate, '%d/%m/%Y') AS b_date, timeSlot "
                                 + "FROM booking WHERE LOWER(status) = 'approved' "
                                 + "AND bookingDate = CURRENT_DATE() "
                                 + "AND CURRENT_TIME() BETWEEN timeSlot AND ADDTIME(timeSlot, '02:00:00') "
                                 + "ORDER BY timeSlot ASC LIMIT 1";
            stmt = conn.prepareStatement(liveLookupSQL);
            rs = stmt.executeQuery();
            if (rs.next()) {
                activeBookingId = rs.getString("bookingId");
                activeLabCode = rs.getString("labId");
                sessionDateDisplay = rs.getString("b_date");
                isSessionActive = true;
                sessionStatusMessage = "STATION ACTIVE • LIVE SYNC";
            } else {
                activeBookingId = "NO_ACTIVE_SESSION";
                activeLabCode = "LAB_NONE";
                isSessionActive = false;
                sessionStatusMessage = "NO ACTIVE LAB SESSION";
            }
        }
    } catch (SQLException e) {
        e.printStackTrace();
        if (activeBookingId == null) activeBookingId = "NO_ACTIVE_SESSION";
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }

    // Format readable room labels
    if ("LAB_CS_04".equalsIgnoreCase(activeLabCode)) activeLabName = "Computer Science Lab (CS 04)";
    else if ("LAB_PHYS_01".equalsIgnoreCase(activeLabCode)) activeLabName = "Physics Lab (Advanced Mechanics)";
    else if ("LAB_CHEM_01".equalsIgnoreCase(activeLabCode)) activeLabName = "Chemistry Lab (Organic Molecular)";
    else if ("LAB_BIO_01".equalsIgnoreCase(activeLabCode)) activeLabName = "Biology Lab (Genetics & Micro)";
    else if (activeLabCode != null && !activeLabCode.isEmpty()) activeLabName = activeLabCode;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Lab Terminal Display | MLMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@500;700&display=swap" rel="stylesheet">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
    <style>
        body { font-family: 'Inter', -apple-system, sans-serif; }
        .font-mono-code { font-family: 'JetBrains Mono', monospace; }
        @keyframes countdownProgress {
            from { width: 100%; }
            to { width: 0%; }
        }
        .animate-progress {
            animation: countdownProgress 15s linear infinite;
        }
    </style>
</head>
<body class="bg-slate-950 text-slate-100 min-h-screen flex flex-col antialiased">

    <!-- Top Status Header -->
    <header class="w-full bg-slate-900/80 backdrop-blur-md border-b border-slate-800 px-4 md:px-6 py-3.5 flex flex-wrap justify-between items-center gap-3">
        <div class="text-lg md:text-xl font-bold tracking-tight text-white flex items-center gap-2">
            <span>MLMS<span class="text-cyan-400">.Terminal-Gate</span></span>
        </div>
        <div class="flex items-center gap-2.5 text-xs font-semibold px-3.5 py-1.5 rounded-full border <%= isSessionActive ? "bg-slate-800/80 text-slate-300 border-slate-700" : "bg-rose-950/60 text-rose-300 border-rose-800" %>">
            <span class="w-2.5 h-2.5 rounded-full <%= isSessionActive ? "bg-emerald-400 animate-pulse shadow-[0_0_10px_#34d399]" : "bg-rose-500 shadow-[0_0_10px_#f43f5e]" %>"></span>
            <span><%= sessionStatusMessage %></span>
        </div>
    </header>

    <main class="flex-1 max-w-7xl w-full mx-auto p-4 md:p-6 lg:p-8 grid grid-cols-1 lg:grid-cols-3 gap-6 items-stretch">
        
        <!-- Left Column: Session Parameters -->
        <div class="bg-slate-900/70 border border-slate-800 backdrop-blur-xl rounded-2xl p-5 md:p-6 flex flex-col justify-between shadow-xl">
            <div>
                <h2 class="text-xs font-bold text-cyan-400 uppercase tracking-wider border-b border-slate-800 pb-3 mb-5">
                    Session Parameters
                </h2>
                <div class="space-y-4 md:space-y-5">
                    <div>
                        <span class="text-xs uppercase text-slate-400 font-semibold block tracking-wider">Active Booking ID</span>
                        <span id="booking-id-val" class="text-lg font-bold text-white font-mono-code"><%= activeBookingId %></span>
                    </div>
                    <div>
                        <span class="text-xs uppercase text-slate-400 font-semibold block tracking-wider">Laboratory Space</span>
                        <span class="text-sm md:text-base font-semibold text-slate-200"><%= activeLabName %></span>
                    </div>
                    <div>
                        <span class="text-xs uppercase text-slate-400 font-semibold block tracking-wider">Allocated Window</span>
                        <span class="text-xs md:text-sm font-mono-code text-slate-300"><%= sessionDateDisplay %> &bull; <%= sessionSlotDisplay %></span>
                    </div>
                    <div>
                        <span class="text-xs uppercase text-slate-400 font-semibold block tracking-wider">Station Security Status</span>
                        <% if (isSessionActive) { %>
                            <span class="text-xs md:text-sm font-semibold text-cyan-400 flex items-center gap-1.5 mt-1">
                                <span class="w-1.5 h-1.5 rounded-full bg-cyan-400"></span> Dynamic Token (15s Auto-Rotate)
                            </span>
                        <% } else { %>
                            <span class="text-xs md:text-sm font-semibold text-rose-400 flex items-center gap-1.5 mt-1">
                                <span class="w-1.5 h-1.5 rounded-full bg-rose-400"></span> Scanner Inactive / Closed
                            </span>
                        <% } %>
                    </div>
                </div>
            </div>

            <div class="mt-6 pt-5 border-t border-slate-800">
                <span class="text-xs uppercase text-slate-400 font-semibold block tracking-wider mb-1">Local Gate Clock</span>
                <span id="live-clock" class="font-mono-code text-2xl md:text-3xl font-bold text-white tracking-tight">00:00:00 AM</span>
            </div>
        </div>

        <!-- Center Column: Live Rotating QR Area -->
        <div class="bg-slate-900/90 border border-slate-800 backdrop-blur-xl rounded-2xl p-6 lg:p-8 flex flex-col items-center justify-center text-center shadow-xl relative overflow-hidden">
            <% if (isSessionActive) { %>
                <h2 class="text-sm font-semibold text-slate-300 mb-5">Scan with Phone to Check In</h2>
                
                <div class="bg-white p-4 md:p-5 rounded-2xl shadow-[0_0_40px_rgba(6,182,212,0.2)] border-4 border-slate-800 flex items-center justify-center">
                    <div id="qrcode"></div>
                </div>

                <div class="mt-5 bg-slate-950/80 border border-slate-800 px-3.5 py-1.5 rounded-xl text-xs font-mono-code text-slate-300 max-w-full truncate">
                    TOKEN: <span id="token-display" class="text-cyan-400 font-bold tracking-wider">INITIALIZING...</span>
                </div>

                <div class="w-56 md:w-64 max-w-full h-1.5 bg-slate-800 rounded-full mt-4 overflow-hidden border border-slate-700/50">
                    <div id="progress-bar" class="h-full bg-gradient-to-r from-blue-500 to-cyan-400 animate-progress"></div>
                </div>
                <span class="text-[11px] text-slate-500 mt-2 font-mono-code">Auto-rotates every 15 seconds</span>
            <% } else { %>
                <div class="p-6 flex flex-col items-center justify-center text-center">
                    <div class="w-16 h-16 rounded-full bg-rose-500/10 border border-rose-500/20 text-rose-400 flex items-center justify-center text-2xl mb-4">
                        ⛔
                    </div>
                    <h2 class="text-lg font-bold text-white mb-2">Gate Scanner Inactive</h2>
                    <p class="text-xs text-slate-400 max-w-xs leading-relaxed">
                        This laboratory session schedule is currently not active or the attendance window has closed.
                    </p>
                </div>
            <% } %>
        </div>

        <!-- Right Column: Real-Time Live Check-in Feed -->
        <div class="bg-slate-900/70 border border-slate-800 backdrop-blur-xl rounded-2xl p-5 md:p-6 flex flex-col shadow-xl">
            <div class="flex justify-between items-center border-b border-slate-800 pb-3 mb-4">
                <h2 class="text-xs font-bold text-cyan-400 uppercase tracking-wider">Live Check-in Feed</h2>
                <span id="attendee-count" class="text-xs font-mono-code bg-cyan-950 text-cyan-400 border border-cyan-800 px-2.5 py-0.5 rounded-full font-bold">0 present</span>
            </div>

            <div id="ticker-box" class="flex-1 overflow-y-auto space-y-2.5 pr-1 max-h-[380px] min-h-[180px]">
                <div class="text-center py-12 text-slate-500 text-xs italic">
                    Waiting for student check-ins...
                </div>
            </div>
        </div>

    </main>

    <script>
        const bookingId = "<%= activeBookingId %>";
        const isSessionActive = <%= isSessionActive %>;
        const contextPath = "<%= request.getContextPath() %>";
        let qrInstance = null;

        function updateClock() {
            const now = new Date();
            let hours = now.getHours();
            const minutes = String(now.getMinutes()).padStart(2, '0');
            const seconds = String(now.getSeconds()).padStart(2, '0');
            const ampm = hours >= 12 ? 'PM' : 'AM';
            hours = hours % 12 || 12;
            document.getElementById("live-clock").textContent = 
                String(hours).padStart(2, '0') + ":" + minutes + ":" + seconds + " " + ampm;
        }
        setInterval(updateClock, 1000);
        updateClock();

        if (isSessionActive) {
            const qrContainer = document.getElementById("qrcode");
            const tokenDisplay = document.getElementById("token-display");
            const progressBar = document.getElementById("progress-bar");

            function generateNewToken() {
                const timestamp = Date.now();
                const randomSalt = Math.random().toString(36).substring(2, 8).toUpperCase();
                const tokenValue = "MLMS_" + randomSalt + "_" + timestamp;
                
                tokenDisplay.textContent = tokenValue;

                const payload = JSON.stringify({
                    bookingId: bookingId,
                    token: tokenValue,
                    t: timestamp
                });

                if (!qrInstance) {
                    qrInstance = new QRCode(qrContainer, {
                        text: payload,
                        width: 190,
                        height: 190,
                        colorDark: "#020617",
                        colorLight: "#ffffff",
                        correctLevel: QRCode.CorrectLevel.H
                    });
                } else {
                    qrInstance.clear();
                    qrInstance.makeCode(payload);
                }

                progressBar.classList.remove("animate-progress");
                void progressBar.offsetWidth;
                progressBar.classList.add("animate-progress");
            }

            generateNewToken();
            setInterval(generateNewToken, 15000);
        }

        function pollAttendance() {
            if (!bookingId || bookingId === "NO_ACTIVE_SESSION") return;

            fetch(contextPath + "/AttendanceServlet?action=LIVE_FEED&bookingId=" + encodeURIComponent(bookingId))
                .then(res => {
                    if (!res.ok) throw new Error("Server status: " + res.status);
                    return res.json();
                })
                .then(data => {
                    const tickerBox = document.getElementById("ticker-box");
                    const countBadge = document.getElementById("attendee-count");

                    if (Array.isArray(data) && data.length > 0) {
                        countBadge.textContent = data.length + " present";
                        
                        let htmlContent = "";
                        for (let i = 0; i < data.length; i++) {
                            const student = data[i];
                            const studentIdentifier = student.name ? (student.name + " (" + student.studentId + ")") : ("Student ID: " + student.studentId);
                            const scanTime = student.scanTime || student.entryTime || "Verified";

                            htmlContent += '<div class="bg-slate-950/70 border border-slate-800 p-3 rounded-xl flex justify-between items-center text-xs border-l-4 border-l-cyan-400 shadow-sm">' +
                                               '<span class="font-semibold text-slate-200">' + studentIdentifier + '</span>' +
                                               '<span class="font-mono-code text-cyan-400 text-[11px] font-bold">' + scanTime + '</span>' +
                                           '</div>';
                        }
                        tickerBox.innerHTML = htmlContent;
                    } else {
                        countBadge.textContent = "0 present";
                        tickerBox.innerHTML = '<div class="text-center py-12 text-slate-500 text-xs italic">Waiting for student check-ins...</div>';
                    }
                })
                .catch(err => {
                    console.warn("Live feed poll idle:", err);
                });
        }

        pollAttendance();
        setInterval(pollAttendance, 3000);
    </script>
</body>
</html>