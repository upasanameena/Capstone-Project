import React, { useEffect, useState } from "react";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell, LineChart, Line } from "recharts";

type ApiResult<T> = { ok: true; data: T } | { ok: false; error: string };

async function getJSON<T>(path: string): Promise<ApiResult<T>> {
  try {
    const res = await fetch(path);
    if (!res.ok) return { ok: false, error: `${res.status} ${res.statusText}` };
    return { ok: true, data: (await res.json()) as T };
  } catch (e: any) {
    return { ok: false, error: e?.message ?? "fetch failed" };
  }
}

type GetStats = { goodCount: number; badCount: number };
type PostStats = { benignCount: number; maliciousCount: number };
type NetStats = { allowedCount: number; blockedCount: number };
type TrainingMetrics = { points: Array<{ step: number; goodRate: number; benignRate: number; accuracy: number }> };

const COLORS = {
  good: "#10b981",
  bad: "#ef4444",
  benign: "#3b82f6",
  malicious: "#f59e0b",
  allowed: "#10b981",
  blocked: "#ef4444",
};

export function Dashboard(): JSX.Element {
  const [getStats, setGetStats] = useState<GetStats | null>(null);
  const [postStats, setPostStats] = useState<PostStats | null>(null);
  const [netStats, setNetStats] = useState<NetStats | null>(null);
  const [trainingMetrics, setTrainingMetrics] = useState<TrainingMetrics | null>(null);
  const [err, setErr] = useState<string>("");
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date());

  const load = async () => {
    const [a, b, c, d] = await Promise.all([
      getJSON<GetStats>("/api/stats/get-requests"),
      getJSON<PostStats>("/api/stats/post-payloads"),
      getJSON<NetStats>("/api/stats/network-firewall"),
      getJSON<TrainingMetrics>("/api/metrics/training"),
    ]);
    const errors = [a, b, c, d].filter((r) => !r.ok).map((r: any) => r.error);
    if (errors.length) setErr(errors.join(" | "));
    else setErr("");
    if (a.ok) setGetStats(a.data);
    if (b.ok) setPostStats(b.data);
    if (c.ok) setNetStats(c.data);
    if (d.ok) setTrainingMetrics(d.data);
    setLastUpdate(new Date());
  };

  useEffect(() => {
    load();
    const id = setInterval(load, 5000);
    return () => clearInterval(id);
  }, []);

  const getChartData = getStats ? [
    { name: "Good URLs", value: getStats.goodCount, color: COLORS.good },
    { name: "Bad URLs", value: getStats.badCount, color: COLORS.bad },
  ] : [];

  const postChartData = postStats ? [
    { name: "Benign Payloads", value: postStats.benignCount, color: COLORS.benign },
    { name: "Malicious Payloads", value: postStats.maliciousCount, color: COLORS.malicious },
  ] : [];

  const networkChartData = netStats ? [
    { name: "Allowed Packets", value: netStats.allowedCount, color: COLORS.allowed },
    { name: "Blocked Packets", value: netStats.blockedCount, color: COLORS.blocked },
  ] : [];

  return (
    <div style={{ minHeight: "100vh", background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)", padding: "24px" }}>
      <div style={{ maxWidth: 1400, margin: "0 auto" }}>
        <div style={{ background: "white", borderRadius: "16px", padding: "32px", boxShadow: "0 20px 60px rgba(0,0,0,0.3)" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "32px" }}>
            <div>
              <h1 style={{ fontSize: "36px", fontWeight: "bold", margin: 0, color: "#1f2937" }}>
                ML-Driven Dual-Layer Firewall
              </h1>
              <p style={{ color: "#6b7280", marginTop: "8px" }}>
                Real-time Network & Application Layer Security Monitoring
              </p>
            </div>
            <div style={{ textAlign: "right" }}>
              <div style={{ fontSize: "14px", color: "#6b7280" }}>Last Update</div>
              <div style={{ fontSize: "18px", fontWeight: "bold", color: "#1f2937" }}>
                {lastUpdate.toLocaleTimeString()}
              </div>
            </div>
          </div>

          {err && (
            <div style={{
              background: "#fee2e2",
              border: "1px solid #fca5a5",
              borderRadius: "8px",
              padding: "12px",
              marginBottom: "24px",
              color: "#991b1b"
            }}>
              ⚠️ API Error: {err}
            </div>
          )}

          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(500px, 1fr))", gap: "24px", marginBottom: "32px" }}>
            {/* URL Filter Analysis (GET) */}
            <div style={{ background: "#f9fafb", borderRadius: "12px", padding: "24px", border: "1px solid #e5e7eb" }}>
              <h2 style={{ fontSize: "24px", fontWeight: "bold", marginTop: 0, marginBottom: "20px", color: "#1f2937" }}>
                URL Filter Analysis (GET Requests)
              </h2>
              {getStats ? (
                <>
                  <div style={{ display: "flex", gap: "16px", marginBottom: "20px" }}>
                    <div style={{ flex: 1, background: "white", padding: "16px", borderRadius: "8px", textAlign: "center" }}>
                      <div style={{ fontSize: "32px", fontWeight: "bold", color: COLORS.good }}>{getStats.goodCount}</div>
                      <div style={{ color: "#6b7280" }}>Good URLs</div>
                    </div>
                    <div style={{ flex: 1, background: "white", padding: "16px", borderRadius: "8px", textAlign: "center" }}>
                      <div style={{ fontSize: "32px", fontWeight: "bold", color: COLORS.bad }}>{getStats.badCount}</div>
                      <div style={{ color: "#6b7280" }}>Bad URLs</div>
                    </div>
                  </div>
                  <ResponsiveContainer width="100%" height={250}>
                    <PieChart>
                      <Pie
                        data={getChartData}
                        cx="50%"
                        cy="50%"
                        labelLine={false}
                        label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
                        outerRadius={80}
                        fill="#8884d8"
                        dataKey="value"
                      >
                        {getChartData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={entry.color} />
                        ))}
                      </Pie>
                      <Tooltip />
                    </PieChart>
                  </ResponsiveContainer>
                </>
              ) : (
                <div style={{ textAlign: "center", padding: "40px", color: "#6b7280" }}>Loading...</div>
              )}
            </div>

            {/* Payload Classification (POST) */}
            <div style={{ background: "#f9fafb", borderRadius: "12px", padding: "24px", border: "1px solid #e5e7eb" }}>
              <h2 style={{ fontSize: "24px", fontWeight: "bold", marginTop: 0, marginBottom: "20px", color: "#1f2937" }}>
                Payload Classification (POST Requests)
              </h2>
              {postStats ? (
                <>
                  <div style={{ display: "flex", gap: "16px", marginBottom: "20px" }}>
                    <div style={{ flex: 1, background: "white", padding: "16px", borderRadius: "8px", textAlign: "center" }}>
                      <div style={{ fontSize: "32px", fontWeight: "bold", color: COLORS.benign }}>{postStats.benignCount}</div>
                      <div style={{ color: "#6b7280" }}>Benign Payloads</div>
                    </div>
                    <div style={{ flex: 1, background: "white", padding: "16px", borderRadius: "8px", textAlign: "center" }}>
                      <div style={{ fontSize: "32px", fontWeight: "bold", color: COLORS.malicious }}>{postStats.maliciousCount}</div>
                      <div style={{ color: "#6b7280" }}>Malicious Payloads</div>
                    </div>
                  </div>
                  <ResponsiveContainer width="100%" height={250}>
                    <BarChart data={postChartData}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="name" />
                      <YAxis />
                      <Tooltip />
                      <Bar dataKey="value" fill="#8884d8">
                        {postChartData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={entry.color} />
                        ))}
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                </>
              ) : (
                <div style={{ textAlign: "center", padding: "40px", color: "#6b7280" }}>Loading...</div>
              )}
            </div>
          </div>

          {/* Network Layer Firewall */}
          <div style={{ background: "#f9fafb", borderRadius: "12px", padding: "24px", border: "1px solid #e5e7eb", marginBottom: "32px" }}>
            <h2 style={{ fontSize: "24px", fontWeight: "bold", marginTop: 0, marginBottom: "20px", color: "#1f2937" }}>
              Network Layer Firewall
            </h2>
            {netStats ? (
              <>
                <div style={{ display: "flex", gap: "16px", marginBottom: "20px" }}>
                  <div style={{ flex: 1, background: "white", padding: "16px", borderRadius: "8px", textAlign: "center" }}>
                    <div style={{ fontSize: "32px", fontWeight: "bold", color: COLORS.allowed }}>{netStats.allowedCount}</div>
                    <div style={{ color: "#6b7280" }}>Allowed Packets</div>
                  </div>
                  <div style={{ flex: 1, background: "white", padding: "16px", borderRadius: "8px", textAlign: "center" }}>
                    <div style={{ fontSize: "32px", fontWeight: "bold", color: COLORS.blocked }}>{netStats.blockedCount}</div>
                    <div style={{ color: "#6b7280" }}>Blocked Packets</div>
                  </div>
                  <div style={{ flex: 1, background: "white", padding: "16px", borderRadius: "8px", textAlign: "center" }}>
                    <div style={{ fontSize: "32px", fontWeight: "bold", color: "#6366f1" }}>
                      {netStats.allowedCount + netStats.blockedCount}
                    </div>
                    <div style={{ color: "#6b7280" }}>Total Packets</div>
                  </div>
                </div>
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={networkChartData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#8884d8">
                      {networkChartData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              </>
            ) : (
              <div style={{ textAlign: "center", padding: "40px", color: "#6b7280" }}>
                Network firewall not running or no data yet
              </div>
            )}
          </div>

          {/* ML Model Training Overview */}
          {trainingMetrics && trainingMetrics.points.length > 0 && (
            <div style={{ background: "#f9fafb", borderRadius: "12px", padding: "24px", border: "1px solid #e5e7eb" }}>
              <h2 style={{ fontSize: "24px", fontWeight: "bold", marginTop: 0, marginBottom: "20px", color: "#1f2937" }}>
                ML Model Training Overview
              </h2>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={trainingMetrics.points}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="step" label={{ value: "Training Step", position: "insideBottom", offset: -5 }} />
                  <YAxis label={{ value: "Rate (%)", angle: -90, position: "insideLeft" }} />
                  <Tooltip />
                  <Legend />
                  <Line type="monotone" dataKey="goodRate" stroke={COLORS.good} name="Good URL Rate" strokeWidth={2} />
                  <Line type="monotone" dataKey="benignRate" stroke={COLORS.benign} name="Benign Payload Rate" strokeWidth={2} />
                  <Line type="monotone" dataKey="accuracy" stroke="#6366f1" name="Combined Accuracy (%)" strokeWidth={2} />
                </LineChart>
              </ResponsiveContainer>
            </div>
          )}

          <div style={{ marginTop: "32px", padding: "16px", background: "#eff6ff", borderRadius: "8px", border: "1px solid #bfdbfe" }}>
            <div style={{ fontSize: "14px", color: "#1e40af" }}>
              <strong>ℹ️ Note:</strong> Data auto-refreshes every 5 seconds from CSV files in BACKEND_ROOT. 
              All visualizations are real-time and reflect the current state of the dual-layer firewall system.
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
