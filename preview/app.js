const PAGE_SIZE = 18;
const FAV_KEY = "ugc-emote-favorites-v1";

const ROBUX_SVG = `<svg class="robux" viewBox="0 0 16 16" aria-hidden="true">
  <path fill="currentColor" d="M8.1 1.2 14.7 5v6.1L8.1 14.8 1.4 11.1V5L8.1 1.2zm0 1.8L3.1 5.7v4.6L8.1 13l5-2.7V5.7L8.1 3z"/>
  <path fill="currentColor" d="M8.1 5.1 11.4 7v2.1L8.1 11 4.8 9.1V7L8.1 5.1z"/>
</svg>`;

const STAR_SVG = `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 3.6l2.3 4.7 5.2.8-3.8 3.6.9 5.2L12 15.6 7.4 17.9l.9-5.2-3.8-3.6 5.2-.8L12 3.6z"/></svg>`;

const state = {
  all: [],
  filtered: [],
  rendered: 0,
  selectedId: null,
  favorites: new Set(),
  showFavorites: false,
  showPopular: false,
  query: "",
};

const els = {
  panel: document.getElementById("panel"),
  grid: document.getElementById("grid"),
  wrap: document.getElementById("gridWrap"),
  empty: document.getElementById("emptyState"),
  sentinel: document.getElementById("sentinel"),
  search: document.getElementById("searchInput"),
  refresh: document.getElementById("refreshBtn"),
  fav: document.getElementById("favBtn"),
  popular: document.getElementById("popularBtn"),
  close: document.getElementById("closeBtn"),
  reopen: document.getElementById("reopenBtn"),
  details: document.getElementById("details"),
  detailsName: document.getElementById("detailsName"),
  detailsId: document.getElementById("detailsId"),
  detailsPrice: document.getElementById("detailsPrice"),
  copy: document.getElementById("copyBtn"),
  toast: document.getElementById("toast"),
};

function loadFavorites() {
  try {
    const raw = JSON.parse(localStorage.getItem(FAV_KEY) || "[]");
    state.favorites = new Set(raw.map(Number));
  } catch {
    state.favorites = new Set();
  }
}

function saveFavorites() {
  localStorage.setItem(FAV_KEY, JSON.stringify([...state.favorites]));
}

function formatPrice(item) {
  if (item.priceStatus === "Free" || item.price === 0) return `${ROBUX_SVG}<span>Gratis</span>`;
  if (item.price == null) return `${ROBUX_SVG}<span>—</span>`;
  return `${ROBUX_SVG}<span>${item.price}</span>`;
}

function thumbSrc(item) {
  if (item.imageUrl) return item.imageUrl;
  return `https://www.roblox.com/asset-thumbnail/image?assetId=${item.id}&width=150&height=150&format=png`;
}

function applyFilters() {
  const q = state.query.trim().toLowerCase();
  let list = state.all.slice();

  if (state.showPopular) {
    list = list.slice().sort((a, b) => (b.favoriteCount || 0) - (a.favoriteCount || 0));
  }
  if (state.showFavorites) {
    list = list.filter((item) => state.favorites.has(item.id));
  }
  if (q) {
    list = list.filter((item) => {
      const name = String(item.name || "").toLowerCase();
      const id = String(item.id);
      const creator = String(item.creatorName || "").toLowerCase();
      return name.includes(q) || id.includes(q) || creator.includes(q);
    });
  }

  state.filtered = list;
  state.rendered = 0;
  els.grid.innerHTML = "";
  renderMore();
}

function renderMore() {
  const next = state.filtered.slice(state.rendered, state.rendered + PAGE_SIZE);
  next.forEach((item) => els.grid.appendChild(createCard(item)));
  state.rendered += next.length;
  els.empty.hidden = state.filtered.length !== 0;
}

function createCard(item) {
  const card = document.createElement("article");
  card.className = "card" + (state.selectedId === item.id ? " selected" : "");
  card.dataset.id = String(item.id);

  const favOn = state.favorites.has(item.id);
  card.innerHTML = `
    <button class="card-fav${favOn ? " on" : ""}" title="Favorito" aria-label="Favorito">${STAR_SVG}</button>
    <div class="thumb"><img alt="" loading="lazy" src="${thumbSrc(item)}" /></div>
    <div class="card-name">${escapeHtml(item.name)}</div>
    <div class="card-price">${formatPrice(item)}</div>
  `;

  const img = card.querySelector("img");
  img.addEventListener("error", () => {
    if (img.dataset.fallback) return;
    img.dataset.fallback = "1";
    img.src = `https://www.roblox.com/asset-thumbnail/image?assetId=${item.id}&width=150&height=150&format=png`;
  });

  card.addEventListener("click", (ev) => {
    if (ev.target.closest(".card-fav")) return;
    selectItem(item);
  });

  card.querySelector(".card-fav").addEventListener("click", (ev) => {
    ev.stopPropagation();
    toggleFavorite(item.id);
  });

  return card;
}

function selectItem(item) {
  state.selectedId = item.id;
  for (const node of els.grid.querySelectorAll(".card")) {
    node.classList.toggle("selected", Number(node.dataset.id) === item.id);
  }
  els.details.hidden = false;
  els.detailsName.textContent = item.name;
  els.detailsId.value = String(item.id);
  els.detailsPrice.innerHTML = formatPrice(item);
}

function toggleFavorite(id) {
  if (state.favorites.has(id)) state.favorites.delete(id);
  else state.favorites.add(id);
  saveFavorites();
  els.fav.classList.toggle("active", state.showFavorites);
  if (state.showFavorites) applyFilters();
  else {
    for (const node of els.grid.querySelectorAll(".card")) {
      const star = node.querySelector(".card-fav");
      star.classList.toggle("on", state.favorites.has(Number(node.dataset.id)));
    }
  }
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function toast(message) {
  els.toast.textContent = message;
  els.toast.hidden = false;
  clearTimeout(toast._t);
  toast._t = setTimeout(() => { els.toast.hidden = true; }, 1600);
}

function setOpen(open) {
  els.panel.classList.toggle("is-closed", !open);
  els.reopen.hidden = open;
}

async function loadCatalog() {
  const res = await fetch("data/emotes.json", { cache: "no-store" });
  if (!res.ok) throw new Error("No se pudo leer el catálogo");
  const payload = await res.json();
  const data = Array.isArray(payload) ? payload : payload.data;
  state.all = data.filter((item) => item && item.id && item.name);
}

els.search.addEventListener("input", () => {
  state.query = els.search.value;
  applyFilters();
});

els.refresh.addEventListener("click", async () => {
  els.refresh.classList.add("spin");
  try {
    await loadCatalog();
    applyFilters();
    toast("Catálogo actualizado");
  } catch {
    toast("No se pudo actualizar");
  } finally {
    setTimeout(() => els.refresh.classList.remove("spin"), 700);
  }
});

els.fav.addEventListener("click", () => {
  state.showFavorites = !state.showFavorites;
  els.fav.classList.toggle("active", state.showFavorites);
  applyFilters();
});

els.popular.addEventListener("click", () => {
  state.showPopular = !state.showPopular;
  els.popular.classList.toggle("active", state.showPopular);
  applyFilters();
});

els.close.addEventListener("click", () => setOpen(false));
els.reopen.addEventListener("click", () => setOpen(true));

els.copy.addEventListener("click", async () => {
  const id = els.detailsId.value;
  if (!id) return;
  try {
    await navigator.clipboard.writeText(id);
    toast("ID copiado");
  } catch {
    els.detailsId.select();
    document.execCommand("copy");
    toast("ID copiado");
  }
});

els.detailsId.addEventListener("focus", () => els.detailsId.select());

new IntersectionObserver((entries) => {
  if (entries.some((e) => e.isIntersecting) && state.rendered < state.filtered.length) {
    renderMore();
  }
}, { root: els.wrap, rootMargin: "80px" }).observe(els.sentinel);

document.addEventListener("keydown", (ev) => {
  if (ev.key === "Escape") setOpen(false);
});

(async function init() {
  loadFavorites();
  try {
    await loadCatalog();
    applyFilters();
  } catch (err) {
    els.empty.hidden = false;
    els.empty.textContent = "No se pudo cargar el catálogo de Roblox.";
    console.error(err);
  }
})();
