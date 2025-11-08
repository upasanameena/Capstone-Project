import express from "express";
import fs from "fs";
import path from "path";
import url from "url";
import { execSync } from "child_process";

const __filename = url.fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const port = process.env.PORT || 5174;

// Allow local access from the Vite dev server
app.use((req, res, next) => {
	res.header("Access-Control-Allow-Origin", "*");
	res.header("Access-Control-Allow-Methods", "GET");
	res.header("Access-Control-Allow-Headers", "Content-Type");
	next();
});

// Paths to CSVs in the backend WAF project (read-only)
const backendRoot = process.env.BACKEND_ROOT
	? path.resolve(process.env.BACKEND_ROOT)
	: path.resolve(process.env.HOME || process.env.USERPROFILE || __dirname, "Documents/projects/Web_Application_Firewall");

// Try to find CSV files with flexible naming
function findCsvFile(basePath, possibleNames) {
	for (const name of possibleNames) {
		const fullPath = path.join(basePath, name);
		if (fs.existsSync(fullPath)) {
			return fullPath;
		}
	}
	return null;
}

// Auto-create symlinks for missing GET CSVs
function ensureGetCsvLinks() {
	const dataCollectionPath = path.join(backendRoot, "Data_Collection");
	const goodWordsPath = path.join(backendRoot, "good_words.csv");
	const badWordsPath = path.join(backendRoot, "bad_words.csv");
	const goodReqPath = path.join(dataCollectionPath, "Good_req.csv");
	const badReqPath = path.join(dataCollectionPath, "Bad_req.csv");

	// Create Data_Collection directory if it doesn't exist
	if (!fs.existsSync(dataCollectionPath)) {
		fs.mkdirSync(dataCollectionPath, { recursive: true });
	}

	// If Good_req.csv doesn't exist but good_words.csv does, create symlink
	if (!fs.existsSync(goodReqPath) && fs.existsSync(goodWordsPath)) {
		try {
			if (process.platform === "win32") {
				// Windows: use junction or copy
				fs.copyFileSync(goodWordsPath, goodReqPath);
			} else {
				// Unix: create symlink
				fs.symlinkSync(goodWordsPath, goodReqPath);
			}
			console.log(`Created symlink: ${goodReqPath} -> ${goodWordsPath}`);
		} catch (e) {
			console.warn(`Could not create symlink for Good_req.csv: ${e.message}`);
		}
	}

	// If Bad_req.csv doesn't exist but bad_words.csv does, create symlink
	if (!fs.existsSync(badReqPath) && fs.existsSync(badWordsPath)) {
		try {
			if (process.platform === "win32") {
				fs.copyFileSync(badWordsPath, badReqPath);
			} else {
				fs.symlinkSync(badWordsPath, badReqPath);
			}
			console.log(`Created symlink: ${badReqPath} -> ${badWordsPath}`);
		} catch (e) {
			console.warn(`Could not create symlink for Bad_req.csv: ${e.message}`);
		}
	}
}

const dataCollectionPath = path.join(backendRoot, "Data_Collection");

// search across both Data_Collection and backendRoot with flexible names
function searchAcrossDirs(names) {
	const candidates = [
		...names.map((n) => path.join(dataCollectionPath, n)),
		...names.map((n) => path.join(backendRoot, n)),
	];
	for (const p of candidates) {
		if (fs.existsSync(p)) return p;
	}
	return candidates[0];
}

// Ensure symlinks exist before setting paths
ensureGetCsvLinks();

const paths = {
	goodReq: searchAcrossDirs(["Good_req.csv", "good_req.csv", "good_words.csv", "Good_req.CSV"]),
	badReq: searchAcrossDirs(["Bad_req.csv", "bad_req.csv", "bad_words.csv", "Bad_req.CSV"]),
	benignPayloads: searchAcrossDirs(["benign_payloads.csv", "Benign_payloads.csv"]),
	maliciousPayloads: searchAcrossDirs(["malicious_payloads.csv", "Malicious_payloads.csv"]),
	networkBlocked: searchAcrossDirs(["network_blocked.csv", "Network_blocked.csv"]),
	networkAllowed: searchAcrossDirs(["network_allowed.csv", "Network_allowed.csv"]),
};

function safeReadFileSync(filePath) {
	try {
		if (!fs.existsSync(filePath)) {
			return "";
		}
		const content = fs.readFileSync(filePath, "utf8");
		return content;
	} catch (e) {
		console.error(`Error reading ${filePath}:`, e.message);
		return "";
	}
}

function countCsvRows(csvText, hasHeader) {
	if (!csvText || csvText.trim().length === 0) return 0;
	const lines = csvText.split(/\r?\n/).filter((l) => l.trim().length > 0);
	if (lines.length === 0) return 0;
	return hasHeader ? Math.max(lines.length - 1, 0) : lines.length;
}

// Debug endpoint to check file paths
app.get("/api/debug/paths", (req, res) => {
	const result = {};
	for (const [key, filePath] of Object.entries(paths)) {
		result[key] = {
			path: filePath,
			exists: fs.existsSync(filePath),
			size: fs.existsSync(filePath) ? fs.statSync(filePath).size : 0,
		};
	}
	res.json({ backendRoot, paths: result });
});

// GET: URL Filter Analysis (from Good_req.csv vs Bad_req.csv)
app.get("/api/stats/get-requests", (req, res) => {
	const goodCsv = safeReadFileSync(paths.goodReq);
	const badCsv = safeReadFileSync(paths.badReq);
	const goodCount = countCsvRows(goodCsv, true);
	const badCount = countCsvRows(badCsv, true);
	console.log(`[${new Date().toISOString()}] GET stats: good=${goodCount}, bad=${badCount}`);
	console.log(`  Good file: ${paths.goodReq} (exists: ${fs.existsSync(paths.goodReq)})`);
	console.log(`  Bad file: ${paths.badReq} (exists: ${fs.existsSync(paths.badReq)})`);
	res.json({ goodCount, badCount });
});

// POST: Payload Classification (from benign_payloads.csv vs malicious_payloads.csv)
app.get("/api/stats/post-payloads", (req, res) => {
	const benignCsv = safeReadFileSync(paths.benignPayloads);
	const maliciousCsv = safeReadFileSync(paths.maliciousPayloads);
	const benignCount = countCsvRows(benignCsv, false);
	const maliciousCount = countCsvRows(maliciousCsv, false);
	console.log(`POST stats: benign=${benignCount}, malicious=${maliciousCount}`);
	res.json({ benignCount, maliciousCount });
});

// Network Layer Firewall Stats (from network_blocked.csv vs network_allowed.csv)
app.get("/api/stats/network-firewall", (req, res) => {
	const blockedCsv = safeReadFileSync(paths.networkBlocked);
	const allowedCsv = safeReadFileSync(paths.networkAllowed);
	const blockedCount = countCsvRows(blockedCsv, true);
	const allowedCount = countCsvRows(allowedCsv, true);
	console.log(`[${new Date().toISOString()}] Network stats: blocked=${blockedCount}, allowed=${allowedCount}`);
	console.log(`  Blocked file: ${paths.networkBlocked} (exists: ${fs.existsSync(paths.networkBlocked)})`);
	console.log(`  Allowed file: ${paths.networkAllowed} (exists: ${fs.existsSync(paths.networkAllowed)})`);
	res.json({ allowedCount, blockedCount });
});

// ML Model Training Overview (derived time-series from combined CSVs)
app.get("/api/metrics/training", (req, res) => {
	const chunkSize = Number(req.query.chunkSize) || 200;
	const goodCsv = safeReadFileSync(paths.goodReq);
	const badCsv = safeReadFileSync(paths.badReq);
	const benignCsv = safeReadFileSync(paths.benignPayloads);
	const maliciousCsv = safeReadFileSync(paths.maliciousPayloads);

	const goodLines = goodCsv.split(/\r?\n/).filter((l) => l.trim().length > 0);
	const badLines = badCsv.split(/\r?\n/).filter((l) => l.trim().length > 0);
	
	// Remove headers
	if (goodLines.length && (goodLines[0].toLowerCase().includes("method,") || goodLines[0].toLowerCase().includes("path,"))) {
		goodLines.shift();
	}
	if (badLines.length && (badLines[0].toLowerCase().includes("method,") || badLines[0].toLowerCase().includes("path,"))) {
		badLines.shift();
	}

	const benignLines = benignCsv.split(/\r?\n/).filter((l) => l.trim().length > 0);
	const maliciousLines = maliciousCsv.split(/\r?\n/).filter((l) => l.trim().length > 0);

	const totalPoints = Math.max(
		Math.ceil(goodLines.length / chunkSize),
		Math.ceil(badLines.length / chunkSize),
		Math.ceil(benignLines.length / chunkSize),
		Math.ceil(maliciousLines.length / chunkSize)
	);

	const points = [];
	let cumGood = 0, cumBad = 0, cumBenign = 0, cumMalicious = 0;

	for (let i = 0; i < totalPoints; i++) {
		const giStart = i * chunkSize;
		const giEnd = Math.min(giStart + chunkSize, goodLines.length);
		const biStart = i * chunkSize;
		const biEnd = Math.min(biStart + chunkSize, badLines.length);
		const peiStart = i * chunkSize;
		const peiEnd = Math.min(peiStart + chunkSize, benignLines.length);
		const meiStart = i * chunkSize;
		const meiEnd = Math.min(meiStart + chunkSize, maliciousLines.length);

		cumGood += Math.max(giEnd - giStart, 0);
		cumBad += Math.max(biEnd - biStart, 0);
		cumBenign += Math.max(peiEnd - peiStart, 0);
		cumMalicious += Math.max(meiEnd - meiStart, 0);

		const urlTotal = cumGood + cumBad;
		const payloadTotal = cumBenign + cumMalicious;
		const goodRate = urlTotal > 0 ? cumGood / urlTotal : 0;
		const benignRate = payloadTotal > 0 ? cumBenign / payloadTotal : 0;
		const accuracy = urlTotal + payloadTotal > 0 ? (goodRate + benignRate) / 2 : 0;

		points.push({ 
			step: i + 1, 
			goodRate: Math.round(goodRate * 1000) / 10, 
			benignRate: Math.round(benignRate * 1000) / 10, 
			accuracy: Math.round(accuracy * 1000) / 10 
		});
	}

	res.json({ points });
});

app.listen(port, () => {
	console.log(`\n╔══════════════════════════════════════════════════════════╗`);
	console.log(`║  CSV read-only API listening on http://localhost:${port}  ║`);
	console.log(`╚══════════════════════════════════════════════════════════╝\n`);
	console.log(`Backend root: ${backendRoot}`);
	console.log(`Backend root exists: ${fs.existsSync(backendRoot) ? '✓' : '✗ (NOT FOUND)'}`);
	console.log(`\nCSV file status:`);
	let allFound = true;
	for (const [key, filePath] of Object.entries(paths)) {
		const exists = fs.existsSync(filePath);
		if (!exists) allFound = false;
		const status = exists ? '✓ FOUND' : '✗ NOT FOUND';
		const size = exists ? ` (${(fs.statSync(filePath).size / 1024).toFixed(2)} KB)` : '';
		console.log(`  ${key.padEnd(18)}: ${status}${size}`);
		console.log(`    Path: ${filePath}`);
	}
	
	if (!allFound) {
		console.log(`\n⚠️  WARNING: Some CSV files are missing!`);
		console.log(`   Set BACKEND_ROOT environment variable to point to your WAF project:`);
		console.log(`   export BACKEND_ROOT=${backendRoot}`);
		console.log(`   Then restart: npm run api\n`);
	} else {
		console.log(`\n✅ All CSV files found! Ready to serve data.\n`);
	}
	
	console.log(`Debug endpoint: http://localhost:${port}/api/debug/paths`);
	console.log(`\n`);
});
