import test from 'node:test';
import assert from 'node:assert/strict';

async function reader() {
    const { StoryReader } = await import('./story-audio.mjs');
    const synth = { current: null, getVoices: () => [], speak(u) { this.current = u; }, cancel() { this.current?.onerror?.({ error: 'canceled' }); } };
    const positions = [], highlights = [];
    const instance = new StoryReader({ synth, Utterance: class { constructor(text) { this.text = text; } }, onPosition: p => positions.push(p), onHighlight: (s, e) => highlights.push([s, e]) });
    return { instance, synth, positions, highlights };
}

test('pause/resume and rate changes retain absolute offsets, including emoji and literal HTML', async () => {
    const { instance, synth, highlights } = await reader();
    instance.load('Xin 😀 chào <b>bạn</b>.');
    instance.play();
    synth.current.onboundary({ charIndex: 7, charLength: 4 });
    instance.pause();
    assert.equal(instance.position, 7);
    instance.play();
    assert.equal(synth.current.text, 'chào <b>bạn</b>.');
    synth.current.onboundary({ charIndex: 5, charLength: 1 });
    assert.equal(instance.position, 12);
    assert.deepEqual(highlights.at(-1), [12, 13]);
    instance.setRate(1.5);
    assert.equal(synth.current.text, '<b>bạn</b>.');
    assert.equal(synth.current.rate, 1.5);
});

test('cancel callbacks from an old chapter cannot reset or stop the new chapter', async () => {
    const { instance, synth } = await reader();
    instance.load('Chương cũ.'); instance.play();
    const oldEnd = synth.current.onend;
    instance.load('Chương mới.', 3); instance.play();
    oldEnd();
    assert.equal(instance.position, 3);
    assert.equal(instance.playing, true);
    assert.equal(synth.current.text, 'ơng mới.');
});

test('long chapters are chunked and natural completion resets position', async () => {
    const { instance, synth } = await reader();
    const text = 'Một câu chuyện. '.repeat(40);
    instance.load(text); instance.play();
    let spoken = '', count = 0;
    while (instance.playing && count < 100) {
        spoken += synth.current.text;
        assert.ok(synth.current.text.length <= 240);
        synth.current.onend(); count++;
    }
    assert.equal(spoken, text);
    assert.ok(count > 1);
    assert.equal(instance.position, 0);
    assert.equal(instance.playing, false);
});
