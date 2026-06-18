const SHEET_LOGS = "RemoteLogs";
const SHEET_USERS = "Users";
const SHEET_ADMIN = "Admin";
const SHEET_PENDING = "Pending";

const ADMIN_KEY = "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918";

function nowMs() { return new Date().getTime(); }
function pad(n) { return String(n).padStart(2, "0"); }
function fmtTs(ms) {
  const d = new Date(ms);
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}_${pad(d.getHours())}-${pad(d.getMinutes())}-${pad(d.getSeconds())}`;
}
function sh(name) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  return ss.getSheetByName(name) || ss.insertSheet(name);
}
function json(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
function requireAdminKey(p) {
  return String(p.admin_key || "") === ADMIN_KEY;
}
function randToken(n) {
  const size = n || 40;
  const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  let s = "";
  for (let i = 0; i < size; i++) s += chars[Math.floor(Math.random() * chars.length)];
  return s;
}
function randSessionId() {
  const d = new Date();
  const base = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}_${pad(d.getHours())}-${pad(d.getMinutes())}-${pad(d.getSeconds())}`;
  const r = Math.random().toString(36).slice(2, 6).toUpperCase();
  return `${base}-${r}`;
}

function setAdminOnlineUntil(ms) {
  sh(SHEET_ADMIN).getRange(1, 1).setValue(ms);
}
function getAdminOnlineUntil() {
  return Number(sh(SHEET_ADMIN).getRange(1, 1).getValue() || 0);
}
function setCurrentSessionId(sid) {
  sh(SHEET_ADMIN).getRange(1, 2).setValue(String(sid || ""));
}
function getCurrentSessionId() {
  return String(sh(SHEET_ADMIN).getRange(1, 2).getValue() || "");
}

function appendLogs(sessionId, lines) {
  const logs = Array.isArray(lines) ? lines : [lines];
  if (!logs.length) return 0;
  const lg = sh(SHEET_LOGS);
  const rows = logs.map((line) => [String(sessionId || ""), String(line || "")]);
  const startRow = lg.getLastRow() + 1;
  lg.getRange(startRow, 1, rows.length, 2).setValues(rows);
  return rows.length;
}
function appendLog(sessionId, line) {
  return appendLogs(sessionId, [line]);
}
function appendDevConnected(sessionId, userId) {
  appendLog(sessionId, `[${fmtTs(nowMs())}] [DEV] *${userId}* connected!`);
}
function appendDevDisconnected(sessionId, userId) {
  appendLog(sessionId, `[${fmtTs(nowMs())}] [DEV] *${userId}* disconnected!`);
}
function appendDevSessionStarted(sessionId) {
  appendLog(sessionId, `[${fmtTs(nowMs())}] [DEV] session started id=${sessionId}`);
}

function verifyUser(userId, passHash) {
  const data = sh(SHEET_USERS).getDataRange().getValues();
  for (let i = 0; i < data.length; i++) {
    const id = String(data[i][0] || "");
    const ph = String(data[i][1] || "");
    const en = String(data[i][2] || "1");
    if (id === userId) {
      if (en !== "1") return { ok: false, reason: "DISABLED" };
      if (ph !== passHash) return { ok: false, reason: "BADPASS" };
      return { ok: true };
    }
  }
  return { ok: false, reason: "NOUSER" };
}

function addPending(userId, host, sessionId) {
  const reqId = Utilities.getUuid();
  sh(SHEET_PENDING).appendRow([reqId, nowMs(), userId, host, "PENDING", "", "", String(sessionId || "")]);
  return reqId;
}
function findPendingRow(reqId) {
  const p = sh(SHEET_PENDING);
  const last = p.getLastRow();
  if (last < 1) return -1;
  const vals = p.getRange(1, 1, last, 1).getValues();
  for (let i = 0; i < vals.length; i++) {
    if (String(vals[i][0]) === reqId) return i + 1;
  }
  return -1;
}
function getApprovedSessionByToken(token) {
  if (!token) return null;
  const data = sh(SHEET_PENDING).getDataRange().getValues();
  const t = String(token);
  const now = nowMs();
  for (let i = 0; i < data.length; i++) {
    const status = String(data[i][4] || "");
    const tok = String(data[i][5] || "");
    const exp = Number(data[i][6] || 0);
    if (status === "APPROVED" && tok === t && now <= exp) {
      return {
        userId: String(data[i][2] || ""),
        host: String(data[i][3] || ""),
        sessionId: String(data[i][7] || "")
      };
    }
  }
  return null;
}
function revokeByUserId(userId) {
  const p = sh(SHEET_PENDING);
  const data = p.getDataRange().getValues();
  let changed = 0;
  for (let i = 0; i < data.length; i++) {
    const uid = String(data[i][2] || "");
    const status = String(data[i][4] || "");
    if (uid === userId && status === "APPROVED") {
      p.getRange(i + 1, 5).setValue("REVOKED");
      p.getRange(i + 1, 6).setValue("");
      p.getRange(i + 1, 7).setValue(0);
      changed++;
    }
  }
  return changed;
}

function doPost(e) {
  const p = (e && e.parameter) ? e.parameter : {};
  const action = String(p.action || "");

  if (!action) {
    appendLog("legacy", String(p.log || ""));
    return ContentService.createTextOutput("OK");
  }

  if (action === "admin_heartbeat") {
    if (!requireAdminKey(p)) return json({ ok: false, reason: "BAD_ADMIN_KEY" });
    setAdminOnlineUntil(nowMs() + 30000);
    return json({ ok: true, online_until: getAdminOnlineUntil(), session_id: getCurrentSessionId() });
  }

  if (action === "start_session") {
    if (!requireAdminKey(p)) return json({ ok: false, reason: "BAD_ADMIN_KEY" });
    const sid = randSessionId();
    setCurrentSessionId(sid);
    setAdminOnlineUntil(nowMs() + 30000);
    appendDevSessionStarted(sid);
    return json({ ok: true, session_id: sid });
  }

  if (action === "request_join") {
    const userId = String(p.user_id || "");
    const passHash = String(p.pass_hash || "");
    const host = String(p.host || "");

    if (nowMs() > getAdminOnlineUntil()) return json({ ok: false, reason: "ADMIN_OFFLINE" });
    const verified = verifyUser(userId, passHash);
    if (!verified.ok) return json({ ok: false, reason: verified.reason });

    const sid = getCurrentSessionId();
    if (!sid) return json({ ok: false, reason: "NO_ACTIVE_SESSION" });

    return json({ ok: true, req_id: addPending(userId, host, sid) });
  }

  if (action === "approve" || action === "deny") {
    if (!requireAdminKey(p)) return json({ ok: false, reason: "BAD_ADMIN_KEY" });
    const reqId = String(p.req_id || "");
    const row = findPendingRow(reqId);
    if (row < 0) return json({ ok: false, reason: "NO_REQ" });

    const sheet = sh(SHEET_PENDING);
    const status = String(sheet.getRange(row, 5).getValue() || "");
    if (status !== "PENDING") return json({ ok: false, reason: "ALREADY_" + status });

    if (action === "deny") {
      sheet.getRange(row, 5).setValue("DENIED");
      return json({ ok: true });
    }

    const token = randToken(40);
    const expires = nowMs() + 60 * 60 * 1000;
    sheet.getRange(row, 5).setValue("APPROVED");
    sheet.getRange(row, 6).setValue(token);
    sheet.getRange(row, 7).setValue(expires);

    const userId = String(sheet.getRange(row, 3).getValue() || "");
    const sid = String(sheet.getRange(row, 8).getValue() || "");
    appendDevConnected(sid, userId);

    return json({ ok: true, session_token: token, expires_ms: expires, session_id: sid });
  }

  if (action === "revoke") {
    if (!requireAdminKey(p)) return json({ ok: false, reason: "BAD_ADMIN_KEY" });
    const userId = String(p.user_id || "");
    if (!userId) return json({ ok: false, reason: "NO_USER_ID" });

    const sid = getCurrentSessionId() || "unknown";
    const n = revokeByUserId(userId);
    if (n > 0) appendDevDisconnected(sid, userId);
    return json({ ok: true, revoked: n });
  }

  if (action === "post_log") {
    const approved = getApprovedSessionByToken(String(p.session_token || ""));
    if (!approved) return json({ ok: false, reason: "BAD_SESSION" });
    appendLog(approved.sessionId || getCurrentSessionId() || "unknown", String(p.log || ""));
    return json({ ok: true });
  }

  if (action === "post_log_batch") {
    const approved = getApprovedSessionByToken(String(p.session_token || ""));
    if (!approved) return json({ ok: false, reason: "BAD_SESSION" });

    let logs = [];
    try {
      logs = JSON.parse(String(p.logs_json || "[]"));
      if (!Array.isArray(logs)) logs = [];
    } catch (err) {
      return json({ ok: false, reason: "BAD_LOGS_JSON" });
    }

    const sanitized = logs
      .map((x) => String(x || ""))
      .filter((x) => x !== "");

    if (!sanitized.length) return json({ ok: true, appended: 0 });

    const sessionId = approved.sessionId || getCurrentSessionId() || "unknown";
    const appended = appendLogs(sessionId, sanitized);
    return json({ ok: true, appended: appended });
  }

  if (action === "end_session") {
    if (!requireAdminKey(p)) return json({ ok: false, reason: "BAD_ADMIN_KEY" });

    const sid = getCurrentSessionId();
    if (!sid) return json({ ok: false, reason: "NO_ACTIVE_SESSION" });

    const admin = String(p.admin || "");
    appendLog(sid, `[${fmtTs(nowMs())}] [DEV] session ended id=${sid} reason=admin_quit admin=${admin}`);
    setCurrentSessionId("");
    setAdminOnlineUntil(0);
    return json({ ok: true });
  }

  return json({ ok: false, reason: "UNKNOWN_ACTION" });
}

function doGet(e) {
  const p = (e && e.parameter) ? e.parameter : {};
  const action = String(p.action || "");

  if (!action) {
    const sheet = sh(SHEET_LOGS);
    const lastRow = sheet.getLastRow();
    let since = 0;
    if (p.since) {
      since = parseInt(p.since, 10);
      if (isNaN(since) || since < 0) since = 0;
    }
    const sessionId = String(p.session_id || "");
    const startRow = since + 1;
    if (startRow > lastRow) return json({ lastRow: lastRow, logs: [] });

    const numRows = lastRow - startRow + 1;
    const values = sheet.getRange(startRow, 1, numRows, 2).getValues();
    const logs = [];
    for (let i = 0; i < values.length; i++) {
      const sid = String(values[i][0] || "");
      if (sessionId && sid !== sessionId) continue;
      logs.push({ row: startRow + i, session_id: sid, message: String(values[i][1] || "") });
    }
    return json({ lastRow: lastRow, logs: logs });
  }

  if (action === "get_pending") {
    const data = sh(SHEET_PENDING).getDataRange().getValues();
    const out = [];
    for (let i = 0; i < data.length; i++) {
      if (String(data[i][4] || "") === "PENDING") {
        out.push({
          req_id: data[i][0],
          ts: data[i][1],
          user_id: data[i][2],
          host: data[i][3],
          session_id: data[i][7]
        });
      }
    }
    return json({ ok: true, pending: out });
  }

  if (action === "join_status") {
    const reqId = String(p.req_id || "");
    const row = findPendingRow(reqId);
    if (row < 0) return json({ ok: false, reason: "NO_REQ" });

    const sheet = sh(SHEET_PENDING);
    return json({
      ok: true,
      status: String(sheet.getRange(row, 5).getValue() || ""),
      session_token: String(sheet.getRange(row, 6).getValue() || ""),
      expires_ms: Number(sheet.getRange(row, 7).getValue() || 0),
      session_id: String(sheet.getRange(row, 8).getValue() || "")
    });
  }

  if (action === "list_clients") {
    const data = sh(SHEET_PENDING).getDataRange().getValues();
    const now = nowMs();
    const clients = [];
    for (let i = 0; i < data.length; i++) {
      const status = String(data[i][4] || "");
      const exp = Number(data[i][6] || 0);
      if (status === "APPROVED" && exp > now) {
        clients.push({
          user_id: String(data[i][2] || ""),
          host: String(data[i][3] || ""),
          expires_ms: exp,
          session_id: String(data[i][7] || "")
        });
      }
    }
    return json({ ok: true, clients: clients });
  }

  if (action === "current_session") {
    return json({ ok: true, session_id: getCurrentSessionId(), online_until: getAdminOnlineUntil() });
  }

  return json({ ok: false, reason: "UNKNOWN_ACTION" });
}
