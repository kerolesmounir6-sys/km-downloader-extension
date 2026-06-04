(function() {
    'use strict';

    if (window.__kmMediaDetectorInjected) return;
    window.__kmMediaDetectorInjected = true;

    const MEDIA_EXTENSIONS = [
        '.mp4', '.webm', '.mkv', '.avi', '.mov', '.flv', '.m3u8',
        '.mp3', '.m4a', '.wav', '.aac', '.ogg', '.flac',
        '.pdf', '.zip', '.rar', '.7z', '.tar', '.gz',
        '.exe', '.dmg', '.pkg', '.deb', '.rpm',
        '.iso', '.img'
    ];

    const VIDEO_PATTERNS = [
        /youtube\.com\/watch\?v=/i, /youtu\.be\//i,
        /vimeo\.com\/\d+/i, /dailymotion\.com\/video/i,
        /tiktok\.com\/.+\/video/i, /instagram\.com\/.+/i,
        /facebook\.com\/.+\/videos/i, /twitter\.com\/.+\/status/i,
        /x\.com\/.+\/status/i
    ];

    function isMediaUrl(url) {
        if (!url || typeof url !== 'string') return false;
        const lowerUrl = url.toLowerCase();
        for (const ext of MEDIA_EXTENSIONS) {
            if (lowerUrl.includes(ext)) return true;
        }
        for (const pattern of VIDEO_PATTERNS) {
            if (pattern.test(url)) return true;
        }
        return false;
    }

    function extractUrlsFromElement(element) {
        const urls = new Set();
        const attributes = ['src', 'href', 'data-src', 'data-url', 'poster', 'data-video', 'data-audio'];
        for (const attr of attributes) {
            const value = element.getAttribute(attr);
            if (value && isMediaUrl(value)) {
                try { urls.add(new URL(value, window.location.href).href); } catch (e) {}
            }
        }
        return urls;
    }

    function scanMediaElements() {
        const urls = new Set();
        document.querySelectorAll('video').forEach(video => {
            extractUrlsFromElement(video).forEach(url => urls.add(url));
            video.querySelectorAll('source').forEach(source => {
                extractUrlsFromElement(source).forEach(url => urls.add(url));
            });
        });
        document.querySelectorAll('audio').forEach(audio => {
            extractUrlsFromElement(audio).forEach(url => urls.add(url));
            audio.querySelectorAll('source').forEach(source => {
                extractUrlsFromElement(source).forEach(url => urls.add(url));
            });
        });
        document.querySelectorAll('a[href]').forEach(link => {
            extractUrlsFromElement(link).forEach(url => urls.add(url));
        });
        return Array.from(urls);
    }

    chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
        if (request.type === 'SCAN_PAGE') {
            const urls = scanMediaElements();
            sendResponse({ urls, count: urls.length });
            return true;
        }
        if (request.type === 'GET_PAGE_URL') {
            sendResponse({ url: window.location.href });
            return true;
        }
    });

    // Scan once on load
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', scanMediaElements);
    } else {
        scanMediaElements();
    }
})();
