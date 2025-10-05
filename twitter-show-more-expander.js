// ==UserScript==
// @name         X Expander for Zotero Snapshots
// @namespace    local.x.expand
// @version      3.0.0
// @description  Expands tweet text and replies across an entire conversation (excluding quote tweets) so Zotero snapshots capture the full thread.
// @match        https://x.com/*/status/*
// @match        https://twitter.com/*/status/*
// @run-at       document-idle
// @grant        GM_registerMenuCommand
// ==/UserScript==

(() => {
  'use strict';

  const LOG_PREFIX = '[X Expander]';
  const SELECTORS = Object.freeze({
    primaryColumn: '[data-testid="primaryColumn"]',
    quoteTweet: '[data-testid="quoteTweet"], [data-testid="quoted_tweet"]',
    showMoreText: 'button[data-testid="tweet-text-show-more-link"]',
    button: 'button'
  });
  const LABEL_RULES = Object.freeze({
    replies: [
      /^\s*(show|view|load)\s+(more\s+)?repl(y|ies)\b.*$/i,
      /^\s*more\s+repl(y|ies)\b.*$/i,
      /^\s*show\s+additional\s+repl(y|ies)\b.*$/i,
      /^\s*show\s+\d+\s+more\s+repl(y|ies)\b.*$/i,
      /^\s*show\s+replies\b.*$/i,
      /^\s*view\s+replies\b.*$/i
    ],
    showMore: [
      /^\s*(show|see|read|view)\s+(more|all)\b.*$/i,
      /^\s*show\s+(entire|complete|full)\b.*$/i,
      /^\s*show\s+(this\s+)?thread\b.*$/i,
      /^\s*show\s+conversation\b.*$/i,
      /^\s*show\s*more\s*$/i
    ],
    forbidden: [
      /quote\s+tweets?/i,
      /quoted\s+reply/i,
      /share\s+tweet/i
    ]
  });
  const CONFIG = Object.freeze({
    idleLimit: 10,
    idleDelayMs: 450,
    safetyLimit: 600,
    scrollDelayMs: 220,
    postClickDelayMs: 180,
    stateChecks: 12,
    stateCheckIntervalMs: 150,
    mutationTimeoutMs: 6500,
    statusFadeDelayMs: 3200
  });

  const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
  const normalize = s => s.replace(/\s+/g, ' ').trim();

  const byIdText = ids => {
    if (!ids) return '';
    let out = '';
    ids.split(/\s+/).forEach(id => {
      const el = document.getElementById(id);
      if (el) out += ' ' + el.textContent;
    });
    return out;
  };

  const getLabel = el => {
    const aria = el.getAttribute('aria-label') || '';
    const titled = el.getAttribute('title') || '';
    const labelledBy = byIdText(el.getAttribute('aria-labelledby') || '');
    const text = el.innerText && el.innerText.trim() ? el.innerText : el.textContent || '';
    return normalize([aria, titled, labelledBy, text].join(' '));
  };

  const visible = (el, requireViewport = true) => {
    if (!el || el.offsetParent === null) return false;
    const style = getComputedStyle(el);
    if (style.visibility !== 'visible' || style.pointerEvents === 'none') return false;
    const rect = el.getBoundingClientRect();
    if (!requireViewport) return rect.width > 0 && rect.height > 0;
    return rect.width > 0 && rect.height > 0 && rect.bottom > 0 && rect.top < innerHeight;
  };

  const inPrimary = el => Boolean(el.closest('article') || el.closest(SELECTORS.primaryColumn));

  const isQuoted = el => {
    if (el.closest(SELECTORS.quoteTweet)) return true;
    const article = el.closest('article');
    return Boolean(article && article.parentElement && article.parentElement.closest('article'));
  };

  const isTweetTextShowMore = el => {
    const dt = (el.getAttribute('data-testid') || '').toLowerCase();
    return dt.includes('tweet-text-show-more') || dt.includes('show-more');
  };

  const status = (() => {
    let node = null;
    let hideTimer = null;

    const ensure = () => {
      if (node) return node;
      node = document.createElement('div');
      node.id = 'x-expander-status';
      node.textContent = 'X Expander: starting…';
      Object.assign(node.style, {
        position: 'fixed',
        bottom: '20px',
        left: '20px',
        padding: '10px 20px',
        borderRadius: '999px',
        backgroundColor: 'rgba(29, 155, 240, 0.92)',
        color: '#fff',
        fontSize: '15px',
        fontWeight: '600',
        fontFamily: '"TwitterChirp", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
        boxShadow: '0 6px 18px rgba(0,0,0,0.18)',
        zIndex: '99999',
        transition: 'opacity 0.4s ease',
        opacity: '0'
      });
      document.body.appendChild(node);
      requestAnimationFrame(() => { if (node) node.style.opacity = '1'; });
      return node;
    };

    const setText = text => {
      const el = ensure();
      clearTimeout(hideTimer);
      el.textContent = text;
      el.style.opacity = '1';
    };

    const scheduleHide = () => {
      clearTimeout(hideTimer);
      hideTimer = setTimeout(() => {
        if (!node) return;
        node.style.opacity = '0';
        setTimeout(() => {
          if (node) node.remove();
          node = null;
        }, 420);
      }, CONFIG.statusFadeDelayMs);
    };

    return {
      show: text => setText(text),
      update: text => setText(text),
      finish: text => { setText(text); scheduleHide(); },
      error: text => { setText(text); scheduleHide(); }
    };
  })();

  const state = { running: false };

  const classifyButton = el => {
    if (!inPrimary(el)) return null;
    if (!visible(el, false)) return null;
    if (el.closest('a[href]')) return null;
    if (isQuoted(el)) return null;

    if (el.matches(SELECTORS.showMoreText) || isTweetTextShowMore(el)) {
      return { element: el, kind: 'text' };
    }

    const label = getLabel(el);
    if (!label) return null;
    if (LABEL_RULES.forbidden.some(re => re.test(label))) return null;
    if (LABEL_RULES.replies.some(re => re.test(label))) return { element: el, kind: 'replies' };
    if (LABEL_RULES.showMore.some(re => re.test(label))) return { element: el, kind: 'text' };
    return null;
  };

  const collectCandidates = processed => {
    const scope = document.querySelector(SELECTORS.primaryColumn) || document;
    const nodes = scope.querySelectorAll(`${SELECTORS.showMoreText}, ${SELECTORS.button}`);
    const seen = new Set();
    const matches = [];

    nodes.forEach(el => {
      if (seen.has(el) || processed.has(el)) return;
      seen.add(el);
      const info = classifyButton(el);
      if (info) {
        const rect = el.getBoundingClientRect();
        matches.push({ ...info, top: rect.top });
      }
    });

    matches.sort((a, b) => a.top - b.top);
    return matches;
  };

  const ensureInView = async el => {
    el.scrollIntoView({ block: 'center', inline: 'nearest' });
    await sleep(CONFIG.scrollDelayMs);
    return visible(el);
  };

  const safeClick = el => {
    try {
      el.click();
    } catch (err) {
      console.debug(LOG_PREFIX, 'click failed', err);
    }
  };

  const waitForStateChange = async (el, baselineLabel) => {
    for (let i = 0; i < CONFIG.stateChecks; i += 1) {
      if (!el.isConnected) return true;
      if (el.disabled) return true;
      if (el.getAttribute('aria-expanded') === 'true') return true;
      if (baselineLabel && getLabel(el) !== baselineLabel) return true;
      await sleep(CONFIG.stateCheckIntervalMs);
    }
    return !el.isConnected;
  };

  const watchMutations = (scope, predicate, onBefore) => {
    const root = scope || document.body;
    return new Promise(resolve => {
      let settled = false;
      const cleanup = result => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        observer.disconnect();
        resolve(result);
      };

      const observer = new MutationObserver(mutations => {
        try {
          if (predicate(mutations)) cleanup(true);
        } catch (err) {
          console.debug(LOG_PREFIX, 'predicate error', err);
          cleanup(false);
        }
      });

      const timer = setTimeout(() => cleanup(false), CONFIG.mutationTimeoutMs);

      try {
        observer.observe(root, { childList: true, subtree: true });
        onBefore();
      } catch (err) {
        console.debug(LOG_PREFIX, 'mutation watch error', err);
        cleanup(false);
      }
    });
  };

  const clickTextExpander = async el => {
    const baseline = getLabel(el);
    safeClick(el);
    const changed = await waitForStateChange(el, baseline);
    if (!changed) await sleep(CONFIG.postClickDelayMs);
    return changed;
  };

  const clickRepliesExpander = async el => {
    const scope =
      el.closest('article')?.parentElement ||
      document.querySelector(SELECTORS.primaryColumn) ||
      document.body;

    const mutated = await watchMutations(
      scope,
      mutations => {
        if (!el.isConnected) return true;
        return mutations.some(mutation =>
          Array.from(mutation.addedNodes).some(node => {
            if (!(node instanceof Element)) return false;
            if (node.tagName === 'ARTICLE') return true;
            if (node.matches?.(SELECTORS.showMoreText)) return true;
            return Boolean(node.querySelector?.(SELECTORS.showMoreText));
          })
        );
      },
      () => safeClick(el)
    );

    if (mutated) return true;
    return waitForStateChange(el, getLabel(el));
  };

  const handleCandidate = async (candidate, processed) => {
    const { element, kind } = candidate;
    const inView = await ensureInView(element);
    if (!inView) {
      processed.delete(element);
      return false;
    }

    const ok = kind === 'replies'
      ? await clickRepliesExpander(element)
      : await clickTextExpander(element);

    if (!ok) {
      processed.delete(element);
      return false;
    }

    await sleep(CONFIG.postClickDelayMs);
    return true;
  };

  const runExpander = async () => {
    if (state.running) return;
    state.running = true;

    status.show('X Expander: starting…');

    const startScroll = { x: window.scrollX, y: window.scrollY };
    window.scrollTo(0, 0);
    await sleep(CONFIG.scrollDelayMs * 2);

    const processed = new Set();
    let idle = 0;
    let safety = 0;
    let successes = 0;
    let failures = 0;
    let message = 'X Expander: finished.';

    try {
      while (idle < CONFIG.idleLimit && safety < CONFIG.safetyLimit) {
        const candidates = collectCandidates(processed);
        if (candidates.length === 0) {
          idle += 1;
          safety += 1;
          status.update(`X Expander: scanning (${idle}/${CONFIG.idleLimit})…`);
          await sleep(CONFIG.idleDelayMs);
          continue;
        }

        idle = 0;
        safety += 1;

        const candidate = candidates[0];
        processed.add(candidate.element);

        const ok = await handleCandidate(candidate, processed);
        if (ok) {
          successes += 1;
          status.update(`X Expander: expanded ${successes} button${successes === 1 ? '' : 's'}…`);
        } else {
          failures += 1;
          status.update(`X Expander: retrying (${failures} slow button${failures === 1 ? '' : 's'})…`);
        }
      }

      if (idle >= CONFIG.idleLimit) {
        message = `X Expander: done. Expanded ${successes} button${successes === 1 ? '' : 's'}.`;
      } else if (safety >= CONFIG.safetyLimit) {
        message = `X Expander: safety stop after ${successes} expansion${successes === 1 ? '' : 's'}.`;
      }
    } catch (err) {
      console.error(LOG_PREFIX, 'unexpected error', err);
      message = 'X Expander: error — see console for details.';
      status.error(message);
    } finally {
      window.scrollTo(startScroll.x, startScroll.y);
      state.running = false;
      if (successes === 0 && failures === 0) {
        status.finish('X Expander: nothing to expand.');
      } else {
        status.finish(message);
      }
    }
  };

  const hotkey = e =>
    e.ctrlKey &&
    e.altKey &&
    !e.shiftKey &&
    !e.metaKey &&
    e.key.toLowerCase() === 'e';

  if (typeof GM_registerMenuCommand === 'function') {
    GM_registerMenuCommand('Expand thread now', runExpander);
  }

  window.addEventListener('keydown', e => {
    if (hotkey(e)) {
      e.preventDefault();
      e.stopPropagation();
      runExpander();
    }
  });
})();

