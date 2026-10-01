import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, writeFile, rm, mkdir } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import http from 'node:http';

async function fixture(t, options = {}) {
    const { createStoryServer } = await import('./story-server.mjs');
    const dataDir = await mkdtemp(join(tmpdir(), 'story-test-'));
    const server = await createStoryServer({ dataDir, apiKey: '', ...options });
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
    const base = `http://127.0.0.1:${server.address().port}`;
    t.after(async () => {
        await new Promise(resolve => server.close(resolve));
        await rm(dataDir, { recursive: true, force: true });
    });
    const request = (path, method = 'GET', body, headers = {}) => fetch(base + path, {
        method, headers: { 'Content-Type': 'application/json', ...headers },
        body: body === undefined ? undefined : JSON.stringify(body),
    });
    return { request, server, dataDir };
}

function geminiResponse(title = 'Cánh cửa', content = 'Một chương truyện tiếng Việt. '.repeat(400).trim()) {
    return Response.json({ candidates: [{ finishReason: 'STOP', content: {
        role: 'model', parts: [{ text: JSON.stringify({ title, content }) }],
    } }] });
}

test('settings survive a server restart; reading updates do not overwrite settings', async t => {
    const f = await fixture(t);
    assert.equal((await f.request('/api/settings', 'PUT', { world: 'Tiên giới', contribution: 'Gặp đồng minh' })).status, 200);
    assert.equal((await f.request('/api/reading', 'PUT', { chapterId: null, charIndex: 0, rate: 1.5 })).status, 200);
    const { createStoryServer } = await import('./story-server.mjs');
    const second = await createStoryServer({ dataDir: f.dataDir, apiKey: '' });
    await new Promise(resolve => second.listen(0, '127.0.0.1', resolve));
    try {
        const state = await (await fetch(`http://127.0.0.1:${second.address().port}/api/state`)).json();
        assert.equal(state.settings.world, 'Tiên giới');
        assert.equal(state.settings.contribution, 'Gặp đồng minh');
        assert.equal(state.reading.rate, 1.5);
    } finally { await new Promise(resolve => second.close(resolve)); }
});

test('chapters of at least 1500 words are saved without extra Gemini requests or an upper limit', async t => {
    for (const words of [1500, 1638, 2600]) {
        let calls = 0;
        const content = 'từ '.repeat(words).trim();
        const f = await fixture(t, { apiKey: 'test', fetchImpl: async () => {
            calls++; return geminiResponse('Chương hoàn chỉnh', content);
        } });
        const response = await f.request('/api/generate', 'POST', { settings: { contribution: 'Góp ý' } });
        assert.equal(response.status, 201);
        const state = await (await f.request('/api/state')).json();
        assert.equal(state.chapters.length, 1);
        assert.equal(state.chapters[0].content, content);
        assert.equal(state.settings.contribution, '');
        assert.equal(calls, 1);
    }
});

test('short chapters are rewritten and only the qualifying version is saved', async t => {
    const requests = [];
    const content = 'từ '.repeat(1500).trim();
    const f = await fixture(t, { apiKey: 'test', fetchImpl: async (url, options) => {
        requests.push(JSON.parse(options.body));
        return geminiResponse('Bản viết lại', requests.length === 1 ? 'từ '.repeat(1499).trim() : content);
    } });
    assert.equal((await f.request('/api/generate', 'POST', { settings: { contribution: 'Giữ tình tiết' } })).status, 201);
    const state = await (await f.request('/api/state')).json();
    assert.equal(state.chapters.length, 1);
    assert.equal(state.chapters[0].content, content);
    assert.equal(requests.length, 2);
    assert.match(requests[1].contents.at(-1).parts[0].text, /1499/);
    assert.match(requests[1].contents.at(-1).parts[0].text, /1500/);
});

test('three short attempts leave chapters and contribution intact and release the generation lock', async t => {
    let calls = 0;
    const f = await fixture(t, { apiKey: 'test', fetchImpl: async () => {
        calls++;
        return calls <= 3 ? geminiResponse('Ngắn', 'từ '.repeat(1499).trim()) : geminiResponse();
    } });
    const response = await f.request('/api/generate', 'POST', { settings: { contribution: 'Góp ý còn lại' } });
    assert.equal(response.status, 502);
    assert.equal(calls, 3);
    const state = JSON.parse(await readFile(join(f.dataDir, 'story.json'), 'utf8'));
    assert.equal(state.chapters.length, 0);
    assert.equal(state.settings.contribution, 'Góp ý còn lại');
    assert.equal((await f.request('/api/generate', 'POST', { settings: {} })).status, 201);
});

test('generation uses current settings, saves a chapter, and retains edits made during the API call', async t => {
    let release, signalStarted;
    const started = new Promise(resolve => signalStarted = resolve);
    const gate = new Promise(resolve => release = resolve);
    let sent;
    const f = await fixture(t, { apiKey: 'test-secret', fetchImpl: async (url, options) => {
        sent = { url, ...options }; signalStarted(); await gate; return geminiResponse();
    } });
    const pending = f.request('/api/generate', 'POST', { settings: { world: 'Sao Hỏa', contribution: 'Góp ý đầu' } });
    await started;
    assert.equal((await f.request('/api/generate', 'POST', { settings: {} })).status, 409);
    assert.equal((await f.request('/api/story', 'DELETE')).status, 409);
    await f.request('/api/settings', 'PUT', { contribution: 'Góp ý mới' });
    release();
    assert.equal((await pending).status, 201);
    const state = await (await f.request('/api/state')).json();
    assert.equal(state.chapters.length, 1);
    assert.equal(state.chapters[0].title, 'Cánh cửa');
    assert.equal(state.settings.contribution, 'Góp ý mới');
    assert.match(JSON.parse(sent.body).contents[0].parts[0].text, /Sao Hỏa/);
    assert.match(JSON.parse(sent.body).contents[0].parts[0].text, /Chương 1/);
    assert.equal(sent.headers['x-goog-api-key'], 'test-secret');
    assert.ok(!sent.url.includes('test-secret'));
    assert.ok(!(await (await f.request('/api/config')).text()).includes('test-secret'));
    const disk = JSON.parse(await readFile(join(f.dataDir, 'story.json'), 'utf8'));
    assert.equal(disk.chapters.length, 1);
});

test('missing key and Gemini errors do not create chapters; a later request can succeed', async t => {
    const noKey = await fixture(t);
    assert.equal((await noKey.request('/api/generate', 'POST', { settings: {} })).status, 503);
    let attempts = 0;
    const f = await fixture(t, { apiKey: 'test-secret', fetchImpl: async () => {
        attempts++;
        return attempts === 1 ? Response.json({ error: { message: 'quota' } }, { status: 429 }) : geminiResponse();
    } });
    assert.equal((await f.request('/api/generate', 'POST', { settings: {} })).status, 429);
    assert.equal((await (await f.request('/api/state')).json()).chapters.length, 0);
    assert.equal((await f.request('/api/generate', 'POST', { settings: {} })).status, 201);
});

test('rejects malformed, blocked and truncated AI responses without saving partial chapters', async t => {
    for (const response of [
        { candidates: [] },
        { promptFeedback: { blockReason: 'SAFETY' } },
        { candidates: [{ finishReason: 'MAX_TOKENS', content: { parts: [{ text: '{"title":"A","content":"B"}' }] } }] },
        { candidates: [{ finishReason: 'STOP', content: { parts: [{ text: 'not JSON' }] } }] },
        { candidates: [{ finishReason: 'STOP', content: { parts: [{ text: '{"title":"","content":""}' }] } }] },
    ]) {
        const f = await fixture(t, { apiKey: 'test', fetchImpl: async () => Response.json(response) });
        assert.equal((await f.request('/api/generate', 'POST', { settings: {} })).status, 502);
        assert.equal((await (await f.request('/api/state')).json()).chapters.length, 0);
    }
});

test('deleting from a chapter retains earlier chapters and repairs the saved reading position', async t => {
    let count = 0;
    const f = await fixture(t, { apiKey: 'test', fetchImpl: async () => geminiResponse(`Chương ${++count}`) });
    for (let i = 0; i < 3; i++) await f.request('/api/generate', 'POST', { settings: {} });
    const before = await (await f.request('/api/state')).json();
    assert.equal((await f.request(`/api/chapters/${before.chapters[1].id}`, 'DELETE')).status, 200);
    const after = await (await f.request('/api/state')).json();
    assert.deepEqual(after.chapters.map(c => c.title), ['Chương 1']);
    assert.equal(after.reading.chapterId, after.chapters[0].id);
    assert.equal(after.reading.charIndex, 0);
    assert.equal((await f.request('/api/story', 'DELETE')).status, 200);
    assert.equal((await (await f.request('/api/state')).json()).chapters.length, 0);
});

test('local server blocks other origins and never serves secrets or repository files', async t => {
    const f = await fixture(t);
    assert.equal((await f.request('/api/settings', 'PUT', { world: 'changed' }, { Origin: 'https://example.com' })).status, 403);
    const invalidHostStatus = await new Promise((resolve, reject) => {
        const req = http.get({ hostname: '127.0.0.1', port: f.server.address().port, path: '/api/state', headers: { Host: 'example.com' } }, res => { res.resume(); resolve(res.statusCode); });
        req.on('error', reject);
    });
    assert.equal(invalidHostStatus, 403);
    for (const path of ['/.env', '/.git/config', '/.story-data/story.json', '/story-server.mjs']) {
        assert.equal((await f.request(path)).status, 404);
    }
    assert.equal((await f.request('/story.html')).status, 200);
    assert.equal((await f.request('/api/settings', 'PUT', { world: 123 })).status, 400);
    assert.equal((await f.request('/api/reading', 'PUT', { chapterId: 'missing', charIndex: -1 })).status, 400);
});

test('corrupt existing storage is not silently replaced', async t => {
    const f = await fixture(t);
    await writeFile(join(f.dataDir, 'story.json'), '{broken', 'utf8');
    const { createStoryServer } = await import('./story-server.mjs');
    await assert.rejects(createStoryServer({ dataDir: f.dataDir }), /dữ liệu|JSON/i);
    assert.equal(await readFile(join(f.dataDir, 'story.json'), 'utf8'), '{broken');
});

test('a timed out Gemini request releases the generation lock without saving a chapter', async t => {
    let attempts = 0;
    const f = await fixture(t, { apiKey: 'test', timeoutMs: 20, fetchImpl: async (url, { signal }) => {
        if (++attempts > 1) return geminiResponse();
        return new Promise((resolve, reject) => signal.addEventListener('abort', () => reject(signal.reason), { once: true }));
    } });
    assert.equal((await f.request('/api/generate', 'POST', { settings: {} })).status, 504);
    assert.equal((await (await f.request('/api/state')).json()).chapters.length, 0);
    assert.equal((await f.request('/api/generate', 'POST', { settings: {} })).status, 201);
});

test('failed disk writes preserve the previous in-memory and on-disk story', async t => {
    const f = await fixture(t);
    await f.request('/api/settings', 'PUT', { world: 'Bản đã lưu' });
    await mkdir(join(f.dataDir, 'story.json.tmp'));
    assert.equal((await f.request('/api/settings', 'PUT', { world: 'Bản chưa ghi được' })).status, 500);
    assert.equal((await (await f.request('/api/state')).json()).settings.world, 'Bản đã lưu');
    assert.equal(JSON.parse(await readFile(join(f.dataDir, 'story.json'), 'utf8')).settings.world, 'Bản đã lưu');
});

test('all seven fields accept their advertised limit even with multibyte Vietnamese text', async t => {
    const f = await fixture(t);
    const settings = Object.fromEntries(['world', 'style', 'character', 'system', 'plot', 'difficulty', 'contribution'].map(key => [key, 'ư'.repeat(50000)]));
    assert.equal((await f.request('/api/settings', 'PUT', settings)).status, 200);
    assert.deepEqual((await (await f.request('/api/state')).json()).settings, settings);
});
