(function() {
    'use strict';

    if (window.__kmContentInjected) return;
    window.__kmContentInjected = true;

    const INTERCEPT_EXTENSIONS = ['.exe', '.msi', '.zip', '.rar', '.7z', '.iso', '.pdf', '.mp3', '.mp4', '.webm', '.mkv', '.dmg'];

    const style = document.createElement('style');
    style.textContent = `
        #km-download-btn-wrapper {
            position: absolute; top: 15px; right: 15px;
            z-index: 2147483647 !important;
            display: flex; flex-direction: column; align-items: flex-end;
            font-family: 'Segoe UI', Tahoma, sans-serif !important;
            pointer-events: auto !important;
        }
        #km-download-btn {
            background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%) !important;
            color: white !important; padding: 8px 16px !important;
            border-radius: 10px !important; font-size: 13px !important;
            font-weight: 600 !important; cursor: pointer !important;
            box-shadow: 0 10px 20px rgba(0,0,0,0.3) !important;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1) !important;
            border: 1px solid rgba(255,255,255,0.2) !important;
            display: flex !important; align-items: center !important;
            gap: 8px !important; user-select: none !important;
            backdrop-filter: blur(5px) !important;
        }
        #km-download-btn:hover {
            transform: translateY(-2px) scale(1.02) !important;
            box-shadow: 0 15px 25px rgba(0,0,0,0.4) !important;
            filter: brightness(1.1) !important;
        }
        #km-quality-menu {
            margin-top: 8px !important;
            background: rgba(15, 23, 42, 0.9) !important;
            border: 1px solid rgba(255, 255, 255, 0.1) !important;
            border-radius: 12px !important; width: 220px !important;
            max-height: 300px !important; display: none;
            flex-direction: column !important; overflow-y: auto !important;
            box-shadow: 0 20px 50px rgba(0,0,0,0.5) !important;
            backdrop-filter: blur(20px) !important;
            animation: kmPopIn 0.2s ease-out !important;
            padding: 5px !important; direction: rtl !important;
        }
        @keyframes kmPopIn {
            from { opacity: 0; transform: scale(0.95); }
            to { opacity: 1; transform: scale(1); }
        }
        .km-quality-item {
            padding: 10px 12px !important; font-size: 12px !important;
            color: #94a3b8 !important; transition: all 0.2s !important;
            display: flex !important; justify-content: space-between !important;
            align-items: center !important; cursor: pointer !important;
            border-radius: 8px !important; margin-bottom: 2px !important;
        }
        .km-quality-item:hover {
            background: rgba(59, 130, 246, 0.2) !important;
            color: #60a5fa !important;
        }
        .km-quality-item b {
            color: #3b82f6 !important; font-size: 10px !important;
            background: rgba(59, 130, 246, 0.1) !important;
            padding: 2px 6px !important; border-radius: 4px !important;
        }
        #km-toast {
            position: fixed !important; bottom: 40px !important;
            left: 50% !important; transform: translateX(-50%) !important;
            background: rgba(15, 23, 42, 0.95) !important;
            color: white !important; padding: 12px 24px !important;
            border-radius: 50px !important; z-index: 2147483647 !important;
            box-shadow: 0 10px 30px rgba(0,0,0,0.5) !important;
            display: none; backdrop-filter: blur(10px) !important;
            border: 1px solid rgba(255,255,255,0.1) !important;
            font-family: 'Segoe UI', sans-serif !important;
            font-size: 13px !important; direction: rtl !important;
        }
    `;
    document.head.appendChild(style);

    const toast = document.createElement('div');
    toast.id = 'km-toast';
    document.body.appendChild(toast);

    function showToast(msg, isError = false) {
        toast.innerHTML = msg;
        toast.style.display = 'block';
        toast.style.color = isError ? '#f87171' : '#4ade80';
        setTimeout(() => toast.style.display = 'none', 3000);
    }

    async function sendToApp(url, quality, intercept = false) {
        if (!chrome?.runtime?.sendMessage) return;
        chrome.runtime.sendMessage({
            type: 'DOWNLOAD_URL', url, quality, intercept
        }, (response) => {
            if (chrome.runtime.lastError) {
                showToast('❌ فشل الاتصال بالبرنامج', true);
            } else if (response?.ok) {
                showToast('🚀 تم إرسال الطلب للبرنامج');
            } else {
                showToast('❌ البرنامج غير شغال', true);
            }
        });
    }

    function createMenu() {
        const menu = document.createElement('div');
        menu.id = 'km-quality-menu';
        const qualities = [
            { label: 'أفضل جودة متاحة', q: 'best', icon: '💎' },
            { label: 'دقة 4K فائقة', q: '2160', icon: '🔥' },
            { label: 'دقة 1440p عالية', q: '1440', icon: '✨' },
            { label: 'دقة Full HD 1080p', q: '1080', icon: '📺' },
            { label: 'دقة HD 720p', q: '720', icon: '📽️' },
            { label: 'دقة 480p متوسطة', q: '480', icon: '📱' },
            { label: 'دقة 360p منخفضة', q: '360', icon: '💾' },
            { label: 'تحميل كملف صوتي فقط', q: 'audio', icon: '🎵' }
        ];
        qualities.forEach(item => {
            const div = document.createElement('div');
            div.className = 'km-quality-item';
            div.innerHTML = `<span>${item.icon} ${item.label}</span> <b>${item.q}</b>`;
            div.onclick = (e) => {
                e.stopPropagation();
                const pageUrl = window.location.href;
                sendToApp(pageUrl, item.q, true);
                menu.style.display = 'none';
            };
            menu.appendChild(div);
        });
        return menu;
    }

    function injectButton(video) {
        if (video.dataset.kmInjected === 'true') return;
        let container = video.parentElement;
        if (window.location.host.includes('youtube.com')) {
            const ytPlayer = video.closest('#movie_player') || video.closest('.html5-video-player');
            if (ytPlayer) { container = ytPlayer; container.style.overflow = 'visible'; }
        }
        if (!container) return;

        const wrapper = document.createElement('div');
        wrapper.id = 'km-download-btn-wrapper';
        const btn = document.createElement('div');
        btn.id = 'km-download-btn';
        btn.innerHTML = '<span>📥</span> تحميل بواسطة KM';
        const menu = createMenu();

        btn.onclick = (e) => {
            e.stopPropagation();
            menu.style.display = menu.style.display === 'flex' ? 'none' : 'flex';
        };

        wrapper.appendChild(btn);
        wrapper.appendChild(menu);
        container.appendChild(wrapper);
        video.dataset.kmInjected = 'true';
    }

    function scanVideos() {
        const videos = document.querySelectorAll('video');
        videos.forEach(v => {
            if (v.src || v.querySelector('source') || window.location.host.includes('youtube.com')) {
                injectButton(v);
            }
        });
    }

    document.addEventListener('click', (e) => {
        const target = e.target.closest('a') || e.target;
        const url = target.href || (target.getAttribute && target.getAttribute('href'));
        if (url) {
            let absoluteUrl = url;
            try { absoluteUrl = new URL(url, window.location.href).href; } catch (_) {}
            const lower = absoluteUrl.toLowerCase();
            if (INTERCEPT_EXTENSIONS.some(ext => lower.endsWith(ext) || lower.includes(ext + '?'))) {
                e.preventDefault(); e.stopPropagation();
                sendToApp(absoluteUrl, 'best', true);
            }
        }
    }, true);

    // Scan once on load
    scanVideos();

    // Watch for dynamically added videos (YouTube SPA etc.)
    const observer = new MutationObserver(() => {
        const videos = document.querySelectorAll('video:not([data-km-injected])');
        videos.forEach(v => {
            if (v.src || v.querySelector('source') || window.location.host.includes('youtube.com')) {
                injectButton(v);
            }
        });
    });
    observer.observe(document.body, { childList: true, subtree: true });
})();
