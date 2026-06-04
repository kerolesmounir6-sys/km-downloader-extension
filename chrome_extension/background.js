const NATIVE_HOST = 'com.km.downloader';

function postNativeMessage(payload) {
  return new Promise((resolve) => {
    chrome.runtime.sendNativeMessage(NATIVE_HOST, payload, (response) => {
      if (chrome.runtime.lastError) {
        resolve({ success: false, error: chrome.runtime.lastError.message });
        return;
      }
      resolve(response || { success: false, error: 'Empty response' });
    });
  });
}

async function checkConnection() {
  try {
    const response = await postNativeMessage({ action: 'ping' });
    if (response && response.ok === true) {
      return { connected: true };
    }
  } catch (e) { /* ignore */ }
  return { connected: false };
}

async function sendDownload(url, options = {}) {
  const connection = await checkConnection();
  if (!connection.connected) {
    return { success: false, error: 'KM Downloader is not running.' };
  }
  return await postNativeMessage({
    action: 'download',
    url: url,
    source: options.source || 'extension',
    intercept: options.intercept || false,
    quality: options.quality || 'best',
    audio_only: options.audio_only || false,
    file_type: options.file_type || 'general',
  });
}

chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: 'km-download-link',
    title: 'Download with KM Downloader',
    contexts: ['link', 'page', 'video', 'audio'],
  });
});

chrome.contextMenus.onClicked.addListener(async (info) => {
  if (info.menuItemId === 'km-download-link') {
    await sendDownload(info.linkUrl || info.srcUrl || info.pageUrl, {
      source: 'context_menu', quality: 'best', intercept: true,
    });
  }
});

chrome.action.onClicked.addListener(async (tab) => {
  if (tab && tab.url) {
    const result = await sendDownload(tab.url, { source: 'toolbar', intercept: true });
    if (!result.success) {
      chrome.notifications.create({
        type: 'basic',
        iconUrl: 'icons/icon128.png',
        title: 'KM Downloader',
        message: result.error || 'تعذر الإرسال',
      });
    }
  }
});

chrome.downloads.onCreated.addListener(async (downloadItem) => {
  if (downloadItem.byExtensionId === chrome.runtime.id) return;
  const url = downloadItem.url || downloadItem.finalUrl;
  if (!url) return;

  const INTERCEPT = ['.exe','.msi','.zip','.rar','.7z','.iso','.pdf','.mp3','.mp4','.webm','.mkv','.avi','.mov','.dmg','.apk'];

  const lower = url.toLowerCase();
  if (!INTERCEPT.some(ext => lower.includes(ext))) return;

  const connection = await checkConnection();
  if (!connection.connected) return;

  try {
    await chrome.downloads.cancel(downloadItem.id);
    await chrome.downloads.erase({ id: downloadItem.id });
    await sendDownload(url, { source: 'interceptor', intercept: true, quality: 'best' });
  } catch (e) { /* ignore */ }
});

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  switch (message.type) {
    case 'DOWNLOAD_URL':
      sendDownload(message.url, {
        quality: message.quality || 'best',
        intercept: message.intercept === true,
        source: 'content_script'
      }).then(r => sendResponse(r));
      return true;
    case 'CHECK_CONNECTION':
      checkConnection().then(c => sendResponse(c));
      return true;
    case 'FETCH_VIDEO_INFO':
      sendResponse({ success: false, error: 'Unsupported' });
      return true;
    case 'GET_EXTENSION_ID':
      sendResponse({ extensionId: chrome.runtime.id });
      return true;
    case 'OPEN_APP':
      postNativeMessage({ action: 'open_app' }).then(() => sendResponse({}));
      return true;
  }
});
