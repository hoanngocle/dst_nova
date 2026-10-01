import http from 'node:http';
import { readFile, mkdir, rename, open } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { randomUUID } from 'node:crypto';
import { countWords } from './story-text.mjs';

const ROOT = dirname(fileURLToPath(import.meta.url));
const FIELDS = ['world', 'style', 'character', 'system', 'plot', 'difficulty', 'contribution'];
const emptyState = () => ({ version: 1, settings: Object.fromEntries(FIELDS.map(k => [k, ''])), chapters: [], reading: { chapterId: null, charIndex: 0, rate: 1 } });
const fail = (status, message) => Object.assign(new Error(message), { status });

function settingsPatch(value) {
    if (!value || typeof value !== 'object' || Array.isArray(value)) throw fail(400, 'Cấu hình truyện không hợp lệ.');
    const result = {};
    for (const key of FIELDS) if (Object.hasOwn(value, key)) {
        if (typeof value[key] !== 'string' || value[key].length > 50000) throw fail(400, `Nội dung ${key} phải là văn bản, tối đa 50.000 ký tự.`);
        result[key] = value[key];
    }
    return result;
}

function buildPrompt(state) {
    const labels = { world: 'Bối cảnh thế giới', style: 'Phong cách hành văn', character: 'Nhân vật chính', system: 'Kim thủ chỉ / Hệ thống', plot: 'Cốt truyện chính', difficulty: 'Độ khó', contribution: 'Góp ý ưu tiên cho chương này' };
    const recent = state.chapters.slice(-3);
    return `Bạn là một tiểu thuyết gia chuyên nghiệp viết bằng tiếng Việt. Hãy viết Chương ${state.chapters.length + 1}.
${FIELDS.map(k => `${labels[k]}: ${state.settings[k] || 'Chưa chỉ định, hãy sáng tạo phù hợp với truyện.'}`).join('\n\n')}

CÁC CHƯƠNG GẦN NHẤT (giữ liên tục tình tiết, tính cách và tên nhân vật):
${recent.map((c, i) => `Chương ${state.chapters.length - recent.length + i + 1}: ${c.title}\n${c.content}`).join('\n\n') || 'Đây là chương đầu tiên.'}

Viết nội dung chương dài khoảng 2500 từ, không tính tiêu đề.
Nội dung phải có ít nhất 1500 từ để được lưu.
Quy ước đếm: mỗi đơn vị văn bản phân cách bằng khoảng trắng là một từ; không nhầm số từ với số ký tự hoặc token.
Triển khai khoảng 5 cảnh liên kết, mỗi cảnh khoảng 500 từ: có hành động, đối thoại, bối cảnh và diễn biến mới.
Viết đầy đủ các cảnh, không tóm tắt để kết thúc sớm; không lặp lại chương cũ, nhồi từ hoặc kéo dài độc thoại chỉ để đủ độ dài.
Tiêu đề ngắn, dưới 15 từ, một dòng, không thêm số chương.

TRÌNH BÀY VĂN BẢN:
- Nội dung là văn xuôi được chia đoạn rõ ràng, không dồn cả chương thành một khối chữ. Mỗi đoạn thường 2–5 câu, linh hoạt theo nhịp truyện.
- Ngăn cách các đoạn bằng một dòng trống. Khi đổi cảnh, thời gian, ý chính hoặc người nói, bắt đầu một đoạn mới.
- Mỗi lượt thoại của một nhân vật đặt ở một đoạn riêng, bắt đầu bằng dấu gạch ngang dài (—). Tách lời thoại và đoạn miêu tả khi cần để dễ đọc.
- Mỗi thông báo hệ thống trong ngoặc vuông nằm riêng một đoạn, có dòng trống trước và sau. Ưu tiên các đoạn ngắn 2–4 câu theo một ý hoặc một hành động, không ghép lời thoại và thông báo vào đoạn kể dài.
- Không lặp lại tiêu đề trong nội dung; không thêm mục dàn ý, đánh số đoạn, HTML, Markdown hoặc khối mã.
- Dùng dấu câu tiếng Việt đầy đủ; giữ xuống dòng trong chuỗi content bằng ký tự escape JSON hợp lệ.
Trả về JSON gồm hai trường chuỗi: title (tiêu đề) và content (toàn bộ nội dung chương).`;
}

async function generateChapter({ state, apiKey, model, fetchImpl, timeoutMs }) {
    const contents = [{ role: 'user', parts: [{ text: buildPrompt(state) }] }];
    for (let attempt = 1; attempt <= 3; attempt++) {
        const chapter = await requestGeminiChapter({ contents, apiKey, model, fetchImpl, timeoutMs });
        const words = countWords(chapter.content);
        if (words >= 1500) return { id: randomUUID(), ...chapter, createdAt: Date.now() };
        if (attempt === 3) throw fail(502, `Sau 3 lần thử, chương có ${words} từ, chưa đủ tối thiểu 1500 từ. Chưa lưu chương; tự động tạo đã dừng.`);
        contents.push(
            { role: 'model', parts: [{ text: JSON.stringify(chapter) }] },
            { role: 'user', parts: [{ text: `Bản vừa rồi chỉ có ${words} từ, dưới mức tối thiểu 1500 từ. Hãy viết lại toàn bộ chương khoảng 2500 từ, phát triển thêm các cảnh và đối thoại có ý nghĩa, không nhồi từ hoặc lặp nội dung. Giữ bối cảnh, tình tiết và cách trình bày đã yêu cầu. Trả về JSON title và content chứa toàn bộ chương hoàn chỉnh, không chỉ phần bổ sung.` }] },
        );
    }
}

async function requestGeminiChapter({ contents, apiKey, model, fetchImpl, timeoutMs }) {
    const response = await fetchImpl(`https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
        signal: AbortSignal.timeout(timeoutMs),
        body: JSON.stringify({
            contents,
            safetySettings: [
                { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_NONE' },
                { category: 'HARM_CATEGORY_HATE_SPEECH', threshold: 'BLOCK_NONE' },
                { category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT', threshold: 'BLOCK_NONE' },
                { category: 'HARM_CATEGORY_DANGEROUS_CONTENT', threshold: 'BLOCK_NONE' },
            ],
            generationConfig: {
                responseMimeType: 'application/json', maxOutputTokens: 16384,
                responseSchema: { type: 'OBJECT', properties: { title: { type: 'STRING' }, content: { type: 'STRING' } }, required: ['title', 'content'] },
            },
        }),
    });
    if (!response.ok) {
        const messages = {
            400: 'Gemini từ chối yêu cầu. Kiểm tra API key và model trong .env.',
            401: 'Gemini API key không hợp lệ.', 403: 'API key chưa có quyền dùng model này.',
            404: 'Không tìm thấy model Gemini. Kiểm tra GEMINI_MODEL trong .env.',
            429: 'Gemini hết quota hoặc giới hạn tốc độ. Tự động tạo đã dừng; kiểm tra quota rồi thử lại.',
        };
        throw fail(response.status >= 500 ? 502 : response.status, messages[response.status] || `Gemini báo lỗi HTTP ${response.status}. Vui lòng thử lại sau.`);
    }
    const result = await response.json();
    const candidate = result.candidates?.[0];
    if (!candidate || candidate.finishReason !== 'STOP') {
        throw fail(502, candidate?.finishReason === 'MAX_TOKENS' ? 'Gemini trả về chương bị cắt ngắn. Chưa lưu; hãy thử lại.' : 'Gemini không trả về chương hoàn chỉnh hoặc đã chặn nội dung. Chưa lưu chương.');
    }
    const text = (candidate.content?.parts || []).filter(p => !p.thought && typeof p.text === 'string').map(p => p.text).join('');
    let chapter;
    try { chapter = JSON.parse(text); } catch { throw fail(502, 'Gemini trả về JSON không hợp lệ. Chưa lưu chương.'); }
    if (!chapter || typeof chapter.title !== 'string' || typeof chapter.content !== 'string' || !chapter.title.trim() || !chapter.content.trim()) {
        throw fail(502, 'Gemini trả về tiêu đề hoặc nội dung rỗng. Chưa lưu chương.');
    }
    return { title: chapter.title.trim().replace(/\s+/g, ' '), content: chapter.content.trim() };
}

export async function createStoryServer({ dataDir = join(ROOT, '.story-data'), apiKey = '', model = 'gemini-3.8-flash', fetchImpl = fetch, timeoutMs = 120000 } = {}) {
    await mkdir(dataDir, { recursive: true });
    const dataFile = join(dataDir, 'story.json');
    let state;
    try {
        state = JSON.parse(await readFile(dataFile, 'utf8'));
        if (state.version !== 1 || !state.settings || !Array.isArray(state.chapters) || !state.reading) throw new Error('Cấu trúc dữ liệu không hợp lệ.');
        settingsPatch(state.settings);
        const ids = new Set();
        for (const chapter of state.chapters) {
            if (!chapter || typeof chapter.id !== 'string' || ids.has(chapter.id) || typeof chapter.title !== 'string' || typeof chapter.content !== 'string') throw new Error('Dữ liệu chương không hợp lệ.');
            ids.add(chapter.id);
        }
        if (!Number.isInteger(state.reading.charIndex) || state.reading.charIndex < 0 || (state.reading.chapterId !== null && !ids.has(state.reading.chapterId))) throw new Error('Dữ liệu vị trí đọc không hợp lệ.');
    } catch (error) {
        if (error.code !== 'ENOENT') throw new Error(`Không đọc được dữ liệu ${dataFile}; giữ nguyên file để khôi phục. ${error.message}`);
        state = emptyState();
    }
    let writes = Promise.resolve();
    let generating = false;
    // Serialize read-modify-write operations; publish memory state only after atomic disk replacement.
    function mutate(change) {
        const operation = writes.then(async () => {
            const next = structuredClone(state);
            change(next);
            const temporary = `${dataFile}.tmp`;
            const handle = await open(temporary, 'w');
            try { await handle.writeFile(JSON.stringify(next, null, 2), 'utf8'); await handle.sync(); }
            finally { await handle.close(); }
            await rename(temporary, dataFile);
            state = next;
            return structuredClone(state);
        });
        writes = operation.catch(() => {});
        return operation;
    }
    const staticFiles = {
        '/': ['story.html', 'text/html'], '/story.html': ['story.html', 'text/html'],
        '/story-app.js': ['story-app.js', 'text/javascript'], '/story.css': ['story.css', 'text/css'],
        '/story-audio.mjs': ['story-audio.mjs', 'text/javascript'],
        '/story-text.mjs': ['story-text.mjs', 'text/javascript'],
    };
    return http.createServer(async (req, res) => {
        const json = (status, body) => { res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' }); res.end(JSON.stringify(body)); };
        res.setHeader('Cache-Control', 'no-store');
        res.setHeader('X-Content-Type-Options', 'nosniff');
        res.setHeader('Content-Security-Policy', "default-src 'self'; script-src 'self'; style-src 'self'; connect-src 'self'; img-src 'self' data:; frame-ancestors 'none'; base-uri 'none'; form-action 'self'");
        try {
            const host = req.headers.host || '';
            const port = res.socket.localPort;
            if (![`127.0.0.1:${port}`, `localhost:${port}`].includes(host)) throw fail(403, 'Chỉ chấp nhận truy cập localhost.');
            if (req.headers.origin && req.headers.origin !== `http://${host}`) throw fail(403, 'Nguồn yêu cầu không hợp lệ.');
            if (req.headers['sec-fetch-site'] === 'cross-site') throw fail(403, 'Chỉ chấp nhận yêu cầu từ ứng dụng local.');
            const path = new URL(req.url, `http://${host}`).pathname;
            if (req.method === 'GET' && staticFiles[path]) {
                const [file, type] = staticFiles[path];
                const content = await readFile(join(ROOT, file));
                res.writeHead(200, { 'Content-Type': `${type}; charset=utf-8` }); res.end(content); return;
            }
            if (req.method === 'GET' && path === '/api/config') return json(200, { configured: Boolean(apiKey), model });
            if (req.method === 'GET' && path === '/api/state') { await writes; return json(200, { ...state, generating }); }
            if (req.method === 'GET' && path === '/api/export') {
                await writes;
                res.setHeader('Content-Disposition', 'attachment; filename="story-backup.json"');
                return json(200, state);
            }
            let body;
            if (['PUT', 'POST'].includes(req.method)) {
                if (!req.headers['content-type']?.startsWith('application/json')) throw fail(415, 'Yêu cầu phải là JSON.');
                let length = 0; const chunks = [];
                // Seven 50k-character fields may exceed 512 KB in UTF-8 (or when JSON-escaped).
                for await (const chunk of req) { length += chunk.length; if (length > 3_000_000) throw fail(413, 'Nội dung yêu cầu quá lớn.'); chunks.push(chunk); }
                try { body = JSON.parse(Buffer.concat(chunks).toString('utf8')); } catch { throw fail(400, 'JSON không hợp lệ.'); }
            }
            if (req.method === 'PUT' && path === '/api/settings') {
                const patch = settingsPatch(body);
                const saved = await mutate(s => Object.assign(s.settings, patch));
                return json(200, { settings: saved.settings });
            }
            if (req.method === 'PUT' && path === '/api/reading') {
                if (!body || !Number.isInteger(body.charIndex) || body.charIndex < 0 || (body.rate !== undefined && (!Number.isFinite(body.rate) || body.rate < 0.5 || body.rate > 2))) throw fail(400, 'Vị trí đọc không hợp lệ.');
                const saved = await mutate(s => {
                    const chapter = s.chapters.find(c => c.id === body.chapterId);
                    if (body.chapterId !== null && !chapter) throw fail(400, 'Không tìm thấy chương đang đọc.');
                    s.reading = { chapterId: chapter?.id || null, charIndex: chapter ? Math.min(body.charIndex, chapter.content.length) : 0, rate: body.rate ?? s.reading.rate };
                });
                return json(200, { reading: saved.reading });
            }
            if (req.method === 'POST' && path === '/api/generate') {
                if (generating) throw fail(409, 'Đang tạo chương. Vui lòng chờ.');
                const patch = settingsPatch(body?.settings);
                if (!apiKey) throw fail(503, 'Chưa có Gemini API key. Điền GEMINI_API_KEY trong .env rồi khởi động lại server.');
                generating = true;
                try {
                    const snapshot = await mutate(s => Object.assign(s.settings, patch));
                    const chapter = await generateChapter({ state: snapshot, apiKey, model, fetchImpl, timeoutMs });
                    const saved = await mutate(s => {
                        s.chapters.push(chapter);
                        if (s.settings.contribution === snapshot.settings.contribution) s.settings.contribution = '';
                        s.reading = { ...s.reading, chapterId: chapter.id, charIndex: 0 };
                    });
                    return json(201, { chapter, state: saved });
                } finally { generating = false; }
            }
            if (req.method === 'DELETE' && (path === '/api/story' || path.startsWith('/api/chapters/'))) {
                if (generating) throw fail(409, 'Hãy chờ tạo chương xong rồi xóa.');
                const saved = await mutate(s => {
                    if (path === '/api/story') { Object.assign(s, emptyState()); return; }
                    const index = s.chapters.findIndex(c => c.id === path.slice('/api/chapters/'.length));
                    if (index < 0) throw fail(404, 'Không tìm thấy chương.');
                    const removed = s.chapters.splice(index);
                    if (removed.some(c => c.id === s.reading.chapterId)) s.reading = { ...s.reading, chapterId: s.chapters.at(-1)?.id || null, charIndex: 0 };
                });
                return json(200, saved);
            }
            throw fail(404, 'Không tìm thấy.');
        } catch (error) {
            const timedOut = ['TimeoutError', 'AbortError'].includes(error.name);
            json(error.status || (timedOut ? 504 : 500), { error: timedOut ? 'Gemini phản hồi quá lâu. Chưa lưu chương; tự động tạo đã dừng.' : error.status ? error.message : 'Không thể hoàn tất thao tác. Kiểm tra kết nối mạng và quyền ghi thư mục dữ liệu rồi thử lại.' });
        }
    });
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
    try {
        try { process.loadEnvFile(join(ROOT, '.env')); } catch (error) { if (error.code !== 'ENOENT') throw error; }
        const port = Number(process.env.STORY_PORT || 8766);
        if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('STORY_PORT phải nằm trong khoảng 1–65535.');
        const server = await createStoryServer({ apiKey: process.env.GEMINI_API_KEY?.trim() || '', model: process.env.GEMINI_MODEL?.trim() || 'gemini-3.8-flash' });
        server.on('error', error => { console.error(error.code === 'EADDRINUSE' ? `Cổng ${port} đang được sử dụng. Đổi STORY_PORT trong .env hoặc dừng server cũ.` : error.message); process.exitCode = 1; });
        server.listen(port, '127.0.0.1', () => console.log(`Xưởng Truyện AI: http://127.0.0.1:${port}/story.html\nDữ liệu: ${join(ROOT, '.story-data', 'story.json')}\n${process.env.GEMINI_API_KEY ? 'Đã nạp API key.' : 'Chưa có API key. Điền .env rồi khởi động lại để tạo chương.'}`));
    } catch (error) { console.error(error.message); process.exitCode = 1; }
}
