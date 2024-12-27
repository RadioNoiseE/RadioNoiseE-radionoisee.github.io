const fonts = [
    "/static/font/IBMPlexMath-Regular.woff2",
    "/static/font/IBMPlexMono-Bold.woff2",
    "/static/font/IBMPlexMono-BoldItalic.woff2",
    "/static/font/IBMPlexMono-Italic.woff2",
    "/static/font/IBMPlexMono-Regular.woff2",
    "/static/font/IBMPlexSans-Bold.woff2",
    "/static/font/IBMPlexSans-BoldItalic.woff2",
    "/static/font/IBMPlexSans-Italic.woff2",
    "/static/font/IBMPlexSans-Regular.woff2",
    "/static/font/IBMPlexSerif-Bold.woff2",
    "/static/font/IBMPlexSerif-BoldItalic.woff2",
    "/static/font/IBMPlexSerif-Italic.woff2",
    "/static/font/IBMPlexSerif-Regular.woff2",
    "/static/font/SourceHanSansSC-Bold.woff2",
    "/static/font/SourceHanSansSC-Regular.woff2",
    "/static/font/SourceHanSerifSC-Bold.woff2",
    "/static/font/SourceHanSerifSC-Regular.woff2"
];

const addResourcesToCache = async (resources) => {
    const cache = await caches.open("font-cache-v1");
    await cache.addAll(resources);
};

const putInCache = async (request, response) => {
    const cache = await caches.open("font-cache-v1");
    await cache.put(request, response);
};

const cacheFirst = async ({ request, preloadResponsePromise }) => {
    const responseFromCache = await caches.match(request);
    if (responseFromCache) {
        console.log(`Cache hit for: ${request.url}.`);
        return responseFromCache;
    }

    const preloadResponse = await preloadResponsePromise;
    if (preloadResponse) {
        console.log(`Using preload response: ${preloadResponse}.`);
        putInCache(request, preloadResponse.clone());
        return preloadResponse;
    }

    try {
        const responseFromNetwork = await fetch(request);
        putInCache(request, responseFromNetwork.clone());
        return responseFromNetwork;
    } catch (error) {
        console.error(`Network error occurred: ${error}.`);
        return new Response("Network error.", {
            status: 408,
            headers: { "Content-Type": "text/plain" },
        });
    }
};

const enableNavigationPreload = async () => {
    if (self.registration.navigationPreload) {
        await self.registration.navigationPreload.enable();
    }
};

self.addEventListener("activate", (event) => {
    event.waitUntil(enableNavigationPreload());
});

self.addEventListener("install", (event) => {
    event.waitUntil(addResourcesToCache(fonts));
});

self.addEventListener("fetch", (event) => {
    if (fonts.includes(new URL(event.request.url).pathname)) {
        event.respondWith(
            cacheFirst({
                request: event.request,
                preloadResponsePromise: event.preloadResponse,
            })
        );
    } else {
        event.respondWith(fetch(event.request));
    }
});
