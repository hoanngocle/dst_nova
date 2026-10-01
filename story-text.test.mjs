import test from 'node:test';
import assert from 'node:assert/strict';
import * as textHelpers from './story-text.mjs';

test('paragraphs preserve original speech offsets across emoji, CRLF and dialogue lines', () => {
    assert.equal(typeof textHelpers.paragraphRanges, 'function');
    const text = 'A😀.\r\n \r\n— B.\r\n— C.\n\nD.';
    const ranges = textHelpers.paragraphRanges(text);
    assert.deepEqual(ranges, [{ start: 0, end: 4 }, { start: 9, end: 13 }, { start: 15, end: 19 }, { start: 21, end: 23 }]);
    assert.deepEqual(ranges.map(({ start, end }) => text.slice(start, end)), ['A😀.', '— B.', '— C.', 'D.']);
});

test('unformatted long prose gets readable paragraphs without changing words or speech offsets', () => {
    const sentence = 'Minh bước qua cánh cửa rồi dừng lại, lắng nghe tiếng mưa ngoài hiên. ';
    const text = sentence.repeat(40).trim();
    const ranges = textHelpers.paragraphRanges(text);
    assert.ok(ranges.length > 5);
    assert.ok(ranges.every(r => r.end - r.start <= 600));
    assert.equal(ranges.map(r => text.slice(r.start, r.end)).join(' ').replace(/\s+/gu, ' '), text);
    for (const r of ranges) assert.ok(text.slice(r.start, r.end).endsWith('.'));
});

test('short existing paragraphs and long sentences remain intact', () => {
    const longSentence = 'từ '.repeat(250).trim() + '.';
    const text = `Đoạn đầu.\n\n${longSentence}\n\nĐoạn cuối.`;
    assert.deepEqual(textHelpers.paragraphRanges(text).map(r => text.slice(r.start, r.end)), ['Đoạn đầu.', longSentence, 'Đoạn cuối.']);
});

test('standalone dialogue and system notices become separate paragraphs without splitting inline quotes', () => {
    const text = 'Minh đặt cuốn sách xuống. “Ai đang ở ngoài đó?” [Thông báo: Nhiệm vụ mới.] Cậu nhìn con số "10" trên trang giấy.';
    assert.deepEqual(textHelpers.paragraphRanges(text).map(r => text.slice(r.start, r.end)), [
        'Minh đặt cuốn sách xuống.', '“Ai đang ở ngoài đó?”', '[Thông báo: Nhiệm vụ mới.]', 'Cậu nhìn con số "10" trên trang giấy.',
    ]);
});

test('blank lines do not produce empty paragraphs and a single block is preserved', () => {
    assert.equal(typeof textHelpers.paragraphRanges, 'function');
    assert.deepEqual(textHelpers.paragraphRanges(' \n\n\t'), []);
    assert.deepEqual(textHelpers.paragraphRanges('Một đoạn.'), [{ start: 0, end: 9 }]);
    const text = '\n\nĐoạn một.\n\n\n\nĐoạn hai.\n\n';
    assert.deepEqual(textHelpers.paragraphRanges(text).map(p => text.slice(p.start, p.end)), ['Đoạn một.', 'Đoạn hai.']);
});
