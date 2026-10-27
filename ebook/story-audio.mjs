// Keep offsets in the original text: stripping symbols changes highlight positions.
export class StoryReader {
    constructor({ synth, Utterance, onPosition = () => {}, onHighlight = () => {}, onStatus = () => {}, onError = () => {} }) {
        Object.assign(this, { synth, Utterance, onPosition, onHighlight, onStatus, onError });
        this.text = ''; this.position = 0; this.rate = 1; this.playing = false; this.token = 0;
    }
    cancel() {
        this.token++;
        if (this.utterance) this.utterance.onend = this.utterance.onerror = this.utterance.onboundary = null;
        this.synth?.cancel(); this.utterance = null; this.playing = false;
    }
    load(text, position = 0) {
        this.cancel(); this.text = text;
        this.position = Math.max(0, Math.min(position, text.length));
        this.onStatus(false);
    }
    play() {
        if (this.playing || !this.text || !this.synth || !this.Utterance) return;
        if (this.position >= this.text.length) this.position = 0;
        this.playing = true; this.onStatus(true); this.speakChunk();
    }
    speakChunk() {
        const start = this.position;
        let end = Math.min(start + 240, this.text.length);
        if (end < this.text.length) {
            const lastSpace = this.text.lastIndexOf(' ', end - 1);
            if (lastSpace > start) end = lastSpace + 1;
            else if (/[\uD800-\uDBFF]/.test(this.text[end - 1])) end--;
        }
        const utterance = new this.Utterance(this.text.slice(start, end));
        this.utterance = utterance;
        utterance.lang = 'vi-VN'; utterance.rate = this.rate;
        const voices = this.synth.getVoices().filter(v => v.lang.toLowerCase().startsWith('vi'));
        utterance.voice = voices.find(v => v.localService) || voices[0] || null;
        const token = ++this.token;
        utterance.onboundary = event => {
            if (token !== this.token || !Number.isFinite(event.charIndex)) return;
            this.position = Math.max(start, Math.min(start + event.charIndex, end));
            const length = event.charLength || this.text.slice(this.position).match(/^\S+/)?.[0].length || 1;
            this.onHighlight(this.position, Math.min(this.position + length, end));
            this.onPosition(this.position);
        };
        utterance.onend = () => {
            if (token !== this.token) return;
            this.position = end;
            if (end < this.text.length) { this.onPosition(end); this.speakChunk(); }
            else { this.cancel(); this.position = 0; this.onPosition(0); this.onStatus(false); }
        };
        utterance.onerror = event => {
            if (token !== this.token) return;
            this.cancel(); this.onPosition(this.position); this.onStatus(false);
            if (!['canceled', 'interrupted'].includes(event.error)) this.onError('Không đọc được truyện. Kiểm tra giọng đọc tiếng Việt của trình duyệt/máy.');
        };
        this.synth.speak(utterance);
    }
    pause() { this.cancel(); this.onPosition(this.position); this.onStatus(false); }
    setRate(rate) {
        const wasPlaying = this.playing;
        this.pause(); this.rate = rate;
        if (wasPlaying) this.play();
    }
}
