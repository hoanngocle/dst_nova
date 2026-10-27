import { StoryReader } from './story-audio.mjs';
import { countWords, renderStoryText } from './story-text.mjs';

const $ = id => document.getElementById(id);
const fields = ['world', 'style', 'character', 'system', 'plot', 'difficulty', 'contribution'];
const inputs = Object.fromEntries(fields.map(k => [k, $(`${k}-input`)]));
const DRAFT_KEY = 'story-local-unsaved-settings-v1';
let state = { chapters: [], settings: {}, reading: { chapterId: null, charIndex: 0, rate: 1 } };
let ready = false, configured = false, generating = false, deleting = false;
let editVersion = 0, savedVersion = 0, saveTimer, readingTimer, autoTimer, toastTimer;
let queue = Promise.resolve();
let confirmAction;

function toast(message, error = false) {
    clearTimeout(toastTimer);
    $('toast').textContent = message; $('toast').className = error ? 'error' : ''; $('toast').hidden = false;
    toastTimer = setTimeout(() => { $('toast').hidden = true; }, error ? 8000 : 3500);
}
async function api(path, method = 'GET', body, keepalive = false) {
    let response;
    try { response = await fetch(path, { method, headers: { 'Content-Type': 'application/json' }, body: body === undefined ? undefined : JSON.stringify(body), keepalive }); }
    catch { throw new Error('Không kết nối được server local. Chạy lại node story-server.mjs rồi thử lại.'); }
    let result;
    try { result = await response.json(); } catch { throw new Error('Server phản hồi không hợp lệ. Hãy mở trang qua server Node local.'); }
    if (!response.ok) throw new Error(result.error || `Lỗi HTTP ${response.status}`);
    return result;
}
function enqueue(action) {
    const operation = queue.then(action);
    queue = operation.catch(() => {});
    return operation;
}
const formSettings = () => Object.fromEntries(fields.map(k => [k, inputs[k].value]));
function rememberDraft() { try { localStorage.setItem(DRAFT_KEY, JSON.stringify(formSettings())); } catch { /* Disk autosave remains available. */ } }
function removeDraft() { try { localStorage.removeItem(DRAFT_KEY); } catch { /* Storage may be disabled. */ } }
function changed() {
    editVersion++; rememberDraft(); $('save-status').textContent = 'Chưa lưu…';
    clearTimeout(saveTimer); saveTimer = setTimeout(() => saveSettings().catch(reportSaveError), 500);
}
function reportSaveError(error) { $('save-status').textContent = 'Chưa lưu — bấm để thử lại'; toast(error.message, true); }
function saveSettings() {
    clearTimeout(saveTimer);
    if (!ready || savedVersion === editVersion) return queue;
    const version = editVersion, settings = formSettings();
    $('save-status').textContent = 'Đang lưu…';
    return enqueue(async () => {
        await api('/api/settings', 'PUT', settings);
        savedVersion = version;
        if (editVersion === version) { removeDraft(); $('save-status').textContent = 'Đã lưu trên máy'; }
    });
}
function saveReading(keepalive = false) {
    clearTimeout(readingTimer); readingTimer = null;
    if (!ready || deleting) return Promise.resolve();
    const reading = { chapterId: state.reading.chapterId, charIndex: reader.position, rate: reader.rate };
    return enqueue(() => api('/api/reading', 'PUT', reading, keepalive));
}

const reader = new StoryReader({
    synth: window.speechSynthesis, Utterance: window.SpeechSynthesisUtterance,
    onPosition: position => {
        state.reading.charIndex = position;
        // Throttle instead of debounce: continuous speech still persists progress.
        if (!readingTimer) readingTimer = setTimeout(() => { readingTimer = null; saveReading().catch(reportSaveError); }, 1500);
    },
    onHighlight: (start, end) => {
        const content = currentChapter()?.content || '';
        renderStoryText($('chapter-text'), content, { start, end })?.scrollIntoView({ block: 'nearest' });
    },
    onStatus: playing => {
        $('play-pause-btn').textContent = playing ? 'Ⅱ' : '▶';
        $('play-pause-btn').setAttribute('aria-label', playing ? 'Tạm dừng đọc' : 'Bắt đầu đọc');
        if (!playing && currentChapter()) renderStoryText($('chapter-text'), currentChapter().content);
    },
    onError: message => toast(message, true),
});
function currentChapter() { return state.chapters.find(c => c.id === state.reading.chapterId); }
function controls() {
    const index = state.chapters.findIndex(c => c.id === state.reading.chapterId);
    $('auto-generate-btn').disabled = !ready || !configured || generating || deleting;
    $('auto-generate-btn').textContent = generating ? 'Đang sáng tạo…' : '✦ Tạo Chương Thủ Công';
    $('auto-gen-toggle').disabled = !ready || !configured || deleting;
    $('delete-data-btn').disabled = !ready || generating || deleting;
    $('delete-chapters-btn').disabled = !ready || generating || deleting || !state.chapters.length;
    $('delete-chapter-select').disabled = !state.chapters.length || generating || deleting;
    $('prev-chapter-btn').disabled = index <= 0 || deleting;
    $('next-chapter-btn').disabled = index < 0 || index >= state.chapters.length - 1 || deleting;
    $('play-pause-btn').disabled = !currentChapter() || !window.speechSynthesis || deleting;
    for (const input of Object.values(inputs)) input.disabled = !ready || deleting;
}
function render() {
    $('chapter-count').textContent = state.chapters.length;
    $('empty-list').hidden = state.chapters.length > 0;
    $('chapter-list').replaceChildren(); $('delete-chapter-select').replaceChildren();
    state.chapters.forEach((chapter, index) => {
        const li = document.createElement('li'), button = document.createElement('button');
        button.textContent = `Chương ${index + 1}: ${chapter.title}`;
        if (chapter.id === state.reading.chapterId) { button.className = 'active-chapter'; button.setAttribute('aria-current', 'true'); }
        button.onclick = () => selectChapter(chapter.id);
        li.append(button); $('chapter-list').append(li);
        const option = document.createElement('option'); option.value = chapter.id; option.textContent = `${index + 1}: ${chapter.title}`;
        $('delete-chapter-select').append(option);
    });
    const chapter = currentChapter();
    const index = state.chapters.indexOf(chapter);
    $('chapter-title').textContent = chapter ? `Chương ${index + 1}: ${chapter.title}` : 'Bắt đầu câu chuyện';
    const words = chapter ? countWords(chapter.content) : 0;
    $('chapter-meta').textContent = chapter ? `${words.toLocaleString('vi-VN')} từ` : '';
    renderStoryText($('chapter-text'), chapter?.content || 'Hãy điền thông tin câu chuyện ở cột bên trái, sau đó tạo chương đầu tiên bằng Gemini.');
    controls();
}
function selectChapter(id) {
    if (deleting) return;
    clearTimeout(readingTimer); readingTimer = null;
    state.reading = { ...state.reading, chapterId: id, charIndex: 0 };
    reader.load(currentChapter()?.content || ''); render(); $('chapter-text-wrapper').scrollTop = 0;
    saveReading().catch(reportSaveError);
}
function stopAuto() { clearTimeout(autoTimer); autoTimer = null; $('auto-gen-toggle').checked = false; }
async function generate() {
    if (!ready || generating || deleting || !configured) return;
    clearTimeout(autoTimer); autoTimer = null;
    generating = true; controls();
    const submitted = formSettings();
    try {
        await saveSettings();
        const result = await api('/api/generate', 'POST', { settings: submitted });
        clearTimeout(readingTimer); readingTimer = null;
        state.chapters = result.state.chapters; state.reading = result.state.reading;
        if (inputs.contribution.value === submitted.contribution) { inputs.contribution.value = ''; changed(); }
        reader.load(currentChapter()?.content || ''); render(); $('chapter-text-wrapper').scrollTop = 0;
        await saveReading();
        await saveSettings();
        toast(`Đã lưu Chương ${state.chapters.length} · ${countWords(result.chapter.content).toLocaleString('vi-VN')} từ trên máy.`);
    } catch (error) { stopAuto(); toast(error.message, true); }
    finally {
        generating = false; controls();
        if ($('auto-gen-toggle').checked) autoTimer = setTimeout(generate, 10000);
    }
}
function showConfirmation(title, text, action) {
    $('modal-title').textContent = title; $('modal-text').textContent = text; confirmAction = action;
    $('confirmation-modal').showModal(); $('modal-cancel-btn').focus();
}
async function deleteData(path) {
    if (generating || deleting) return;
    stopAuto(); reader.pause(); clearTimeout(readingTimer); readingTimer = null;
    deleting = true; controls();
    try {
        await saveSettings(); await queue;
        state = await api(path, 'DELETE');
        if (path === '/api/story') {
            for (const key of fields) inputs[key].value = state.settings[key];
            editVersion++; savedVersion = editVersion; removeDraft();
            reader.rate = 1; $('speed-control').value = '1';
        }
        reader.load(currentChapter()?.content || '', state.reading.charIndex); render(); toast('Đã xóa dữ liệu được chọn.');
    } catch (error) { toast(error.message, true); }
    finally { deleting = false; controls(); }
}

for (const input of Object.values(inputs)) input.addEventListener('input', changed);
$('save-status').addEventListener('click', () => saveSettings().catch(reportSaveError));
$('auto-generate-btn').onclick = generate;
$('auto-gen-toggle').onchange = () => { if ($('auto-gen-toggle').checked) generate(); else { stopAuto(); toast(generating ? 'Đã tắt tự động. Chương đang tạo vẫn sẽ được lưu.' : 'Đã tắt tự động tạo chương.'); } };
$('play-pause-btn').onclick = () => { if (reader.playing) { reader.pause(); saveReading().catch(reportSaveError); } else reader.play(); };
$('speed-control').onchange = () => { reader.setRate(Number($('speed-control').value)); saveReading().catch(reportSaveError); };
for (const [id, direction] of [['prev-chapter-btn', -1], ['next-chapter-btn', 1]]) $(id).onclick = () => {
    const next = state.chapters[state.chapters.findIndex(c => c.id === state.reading.chapterId) + direction]; if (next) selectChapter(next.id);
};
$('delete-data-btn').onclick = () => showConfirmation('Xóa toàn bộ truyện?', 'Toàn bộ chương và cấu hình trên máy sẽ bị xóa. Hãy sao lưu JSON trước nếu cần. Không thể hoàn tác trong ứng dụng.', () => deleteData('/api/story'));
$('delete-chapters-btn').onclick = () => {
    const id = $('delete-chapter-select').value, index = state.chapters.findIndex(c => c.id === id);
    if (index >= 0) showConfirmation(`Xóa ${state.chapters.length - index} chương?`, `Xóa từ Chương ${index + 1} đến cuối. Không thể hoàn tác trong ứng dụng.`, () => deleteData(`/api/chapters/${encodeURIComponent(id)}`));
};
$('modal-cancel-btn').onclick = () => $('confirmation-modal').close();
$('modal-confirm-btn').onclick = () => { $('confirmation-modal').close(); confirmAction?.(); };
window.addEventListener('beforeunload', event => {
    if (editVersion !== savedVersion) { rememberDraft(); event.preventDefault(); event.returnValue = ''; }
});
document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'hidden') { saveSettings().catch(() => {}); saveReading(true).catch(() => {}); }
});
window.addEventListener('pagehide', () => {
    if (!ready) return;
    // Keepalive bypasses the JS queue, which might never resume after tab teardown.
    api('/api/reading', 'PUT', { chapterId: state.reading.chapterId, charIndex: reader.position, rate: reader.rate }, true).catch(() => {});
    reader.cancel();
});

async function init() {
    try {
        const [loaded, config] = await Promise.all([api('/api/state'), api('/api/config')]);
        state = loaded; configured = config.configured;
        for (const key of fields) inputs[key].value = state.settings[key] || '';
        reader.rate = state.reading.rate || 1; $('speed-control').value = String(reader.rate);
        reader.load(currentChapter()?.content || '', state.reading.charIndex);
        ready = true; render(); $('save-status').textContent = 'Đã tải từ máy';
        $('connection-notice').textContent = configured ? `Lưu local · ${config.model} · Chỉ gửi nội dung tới Gemini khi tạo chương.` : 'Chưa có Gemini API key. Điền GEMINI_API_KEY trong file .env rồi khởi động lại server. Bạn vẫn có thể lưu cấu hình và đọc truyện đã có.';
        $('connection-notice').classList.toggle('ready', configured);
        if (!window.speechSynthesis) $('audio-hint').textContent = 'Trình duyệt này chưa hỗ trợ đọc văn bản. Hãy mở bằng Chrome hoặc Edge.';
        let draft;
        try { draft = JSON.parse(localStorage.getItem(DRAFT_KEY)); } catch { /* Ignore invalid draft. */ }
        if (draft && fields.every(k => typeof draft[k] === 'string') && JSON.stringify(draft) !== JSON.stringify(formSettings())) {
            for (const key of fields) inputs[key].value = draft[key];
            changed(); toast('Đã khôi phục cấu hình chưa lưu từ lần mở trước.');
        }
        if (loaded.generating) toast('Server đang tạo chương từ lần trước. Tải lại trang sau khi hoàn tất để xem chương mới.');
    } catch (error) { $('connection-notice').textContent = error.message; $('save-status').textContent = 'Chưa kết nối'; toast(error.message, true); }
}
init();
