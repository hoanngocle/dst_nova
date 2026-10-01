// Vietnamese word segmentation is ambiguous; match the editor's whitespace-based count.
export function countWords(text) {
    return text.trim().match(/\S+/gu)?.length || 0;
}

// Return ranges into the original text, keeping Speech Synthesis offsets unchanged.
const sentenceSegmenter = new Intl.Segmenter('vi', { granularity: 'sentence' });
export function paragraphRanges(text) {
    const paragraphs = [];
    function appendProse(raw, base, standalone = false) {
        const content = raw.trim();
        if (!content) return;
        const offset = base + raw.length - raw.trimStart().length;
        if (standalone || content.length <= 600) {
            paragraphs.push({ start: offset, end: offset + content.length });
            return;
        }
        // Gemini sometimes omits all line breaks. Group complete sentences locally
        // without rewriting the story or inserting characters into the speech text.
        let start = null, end = 0, sentences = 0;
        for (const part of sentenceSegmenter.segment(content)) {
            const sentence = part.segment.trimEnd();
            const nextEnd = offset + part.index + sentence.length;
            if (start !== null && (nextEnd - start > 450 || sentences >= 3)) {
                paragraphs.push({ start, end });
                start = null; sentences = 0;
            }
            start ??= offset + part.index;
            end = nextEnd; sentences++;
        }
        if (start !== null) paragraphs.push({ start, end });
    }
    for (const line of text.matchAll(/[^\r\n]+/gu)) {
        let cursor = 0;
        for (const special of line[0].matchAll(/(?:“[^”\r\n]+”|"[^"\r\n]+"|\[[^\]\r\n]+\])[.!?…]*/gu)) {
            const before = line[0].slice(cursor, special.index);
            // Keep inline quoted words/numbers in the surrounding sentence.
            if (!special[0].startsWith('[') && before.trim() && !/[.!?…:]$/u.test(before.trimEnd())) continue;
            appendProse(before, line.index + cursor);
            appendProse(special[0], line.index + special.index, true);
            cursor = special.index + special[0].length;
        }
        appendProse(line[0].slice(cursor), line.index + cursor);
    }
    return paragraphs;
}

export function renderStoryText(container, text, highlight) {
    const document = container.ownerDocument;
    const fragment = document.createDocumentFragment();
    let firstHighlight;
    for (const { start, end } of paragraphRanges(text)) {
        const paragraph = document.createElement('p');
        const highlightStart = Math.max(start, highlight?.start ?? end);
        const highlightEnd = Math.min(end, highlight?.end ?? start);
        if (highlightStart < highlightEnd) {
            const mark = document.createElement('span');
            mark.className = 'reading-highlight'; mark.textContent = text.slice(highlightStart, highlightEnd);
            paragraph.append(document.createTextNode(text.slice(start, highlightStart)), mark, document.createTextNode(text.slice(highlightEnd, end)));
            firstHighlight ||= mark;
        } else paragraph.textContent = text.slice(start, end);
        fragment.append(paragraph);
    }
    container.replaceChildren(fragment);
    return firstHighlight;
}
