import { useEffect, useMemo, useRef, useState } from 'react';
import {
  ArrowDownRight,
  ArrowRight,
  ArrowUpRight,
  BadgePercent,
  BarChart3,
  CalendarDays,
  Check,
  CheckCircle2,
  ChevronDown,
  ChevronRight,
  CircleDollarSign,
  Gift,
  Heart,
  LayoutDashboard,
  Menu,
  PiggyBank,
  Plus,
  Receipt,
  Search,
  Sparkles,
  Store,
  Target,
  Trash2,
  TrendingUp,
  Wallet,
  X,
} from 'lucide-react';

const STORAGE_KEY = 'sparschwein-dashboard-v1';
const LEGACY_STORAGE_KEY = 'sparfuchs-dashboard-v1';
const STORES = ['REWE', 'Lidl', 'ALDI SÜD', 'dm', 'Rossmann', 'Kaufland', 'EDEKA', 'Sonstiges'];
const ENTRY_TYPES = ['Cashback', 'Rabatt', 'Gratisartikel', 'Fundstück', 'Sonstiges'];
const ENTRY_FILTERS = [
  { label: 'Alle', value: 'Alle' },
  { label: 'Cashback', value: 'Cashback' },
  { label: 'Rabatte', value: 'Rabatt' },
  { label: 'Gratis', value: 'Gratisartikel' },
  { label: 'Fundstücke', value: 'Fundstück' },
];

const moneyFormatter = new Intl.NumberFormat('de-DE', {
  style: 'currency',
  currency: 'EUR',
});

function toISODate(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function loadInitialData() {
  try {
    const saved = localStorage.getItem(STORAGE_KEY) || localStorage.getItem(LEGACY_STORAGE_KEY);
    if (saved) {
      const parsed = JSON.parse(saved);
      const storedEntries = Array.isArray(parsed.entries) ? parsed.entries : [];
      const entries = storedEntries.filter((entry) => !String(entry?.id ?? '').startsWith('demo-'));
      const savedGoal = Number(parsed.goalTarget);
      return {
        entries,
        goalTarget: entries.length === 0 && savedGoal === 100 ? 0 : (savedGoal > 0 ? savedGoal : 0),
      };
    }
  } catch {
  }
  return { entries: [], goalTarget: 0 };
}

function formatMoney(amount) {
  return moneyFormatter.format(Number(amount) || 0);
}

function formatShortMoney(amount) {
  return `${new Intl.NumberFormat('de-DE', { maximumFractionDigits: 0 }).format(Math.round(amount || 0))} €`;
}

function formatMonthKey(date) {
  return date.toLocaleDateString('de-DE', { month: 'long', year: 'numeric' });
}

function getGreeting(hour) {
  if (hour >= 5 && hour < 11) return 'Guten Morgen';
  if (hour >= 11 && hour < 14) return 'Guten Mittag';
  if (hour >= 14 && hour < 18) return 'Guten Nachmittag';
  return 'Guten Abend';
}

function getEntryDateLabel(dateString, now = new Date()) {
  if (!dateString) return '';
  const today = toISODate(now);
  const yesterdayDate = new Date(now);
  yesterdayDate.setDate(yesterdayDate.getDate() - 1);
  const yesterday = toISODate(yesterdayDate);
  if (dateString === today) return 'Heute';
  if (dateString === yesterday) return 'Gestern';
  const [year, month, day] = dateString.split('-').map(Number);
  const date = new Date(year, month - 1, day, 12);
  return date.toLocaleDateString('de-DE', { day: 'numeric', month: 'short' }).replace('.', '.');
}

function getSixMonthTotals(entries, now) {
  const months = [];
  const first = new Date(now.getFullYear(), now.getMonth() - 5, 1, 12);
  for (let offset = 0; offset < 6; offset += 1) {
    const date = new Date(first.getFullYear(), first.getMonth() + offset, 1, 12);
    const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
    const value = entries.reduce((sum, entry) => (entry.date?.startsWith(key) ? sum + Number(entry.amount || 0) : sum), 0);
    months.push({
      key,
      label: date.toLocaleDateString('de-DE', { month: 'short' }).replace('.', ''),
      fullLabel: formatMonthKey(date),
      value: Math.round(value * 100) / 100,
      current: offset === 5,
    });
  }
  return months;
}

function makeId() {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) return crypto.randomUUID();
  return `entry-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

function getTypeIcon(type) {
  switch (type) {
    case 'Cashback':
      return CircleDollarSign;
    case 'Rabatt':
      return BadgePercent;
    case 'Gratisartikel':
      return Gift;
    case 'Fundstück':
      return Sparkles;
    default:
      return Wallet;
  }
}

function getTypeClass(type) {
  switch (type) {
    case 'Cashback':
      return 'cashback';
    case 'Rabatt':
      return 'discount';
    case 'Gratisartikel':
      return 'freebie';
    case 'Fundstück':
      return 'found';
    default:
      return 'other';
  }
}

function App() {
  const [initialData] = useState(() => loadInitialData());
  const [entries, setEntries] = useState(initialData.entries);
  const [goalTarget, setGoalTarget] = useState(initialData.goalTarget);
  const [page, setPage] = useState('dashboard');
  const [now, setNow] = useState(() => new Date());
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const mobileMenuToggleRef = useRef(null);
  const [entryModalOpen, setEntryModalOpen] = useState(false);
  const [entryDraft, setEntryDraft] = useState(null);
  const [entryTypeFilter, setEntryTypeFilter] = useState('Alle');
  const [entryStoreFilter, setEntryStoreFilter] = useState('Alle Läden');
  const [entrySearch, setEntrySearch] = useState('');
  const [toast, setToast] = useState('');

  useEffect(() => {
    const timer = window.setInterval(() => setNow(new Date()), 60_000);
    return () => window.clearInterval(timer);
  }, []);

  useEffect(() => {
    if (!mobileMenuOpen) return undefined;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    const focusFrame = window.requestAnimationFrame(() => {
      document.querySelector('.mobile-drawer-link')?.focus({ preventScroll: true });
    });
    const handleKeyDown = (event) => {
      if (event.key === 'Escape') {
        setMobileMenuOpen(false);
        return;
      }
      if (event.key === 'Tab') {
        const focusable = document.querySelectorAll('#mobile-drawer button:not([tabindex="-1"])');
        const first = focusable[0];
        const last = focusable[focusable.length - 1];
        if (event.shiftKey && document.activeElement === first) {
          event.preventDefault();
          last?.focus();
        } else if (!event.shiftKey && document.activeElement === last) {
          event.preventDefault();
          first?.focus();
        }
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => {
      window.cancelAnimationFrame(focusFrame);
      window.removeEventListener('keydown', handleKeyDown);
      document.body.style.overflow = previousOverflow;
      mobileMenuToggleRef.current?.focus({ preventScroll: true });
    };
  }, [mobileMenuOpen]);

  useEffect(() => {
    try {
      localStorage.setItem(
        STORAGE_KEY,
        JSON.stringify({ entries, goalTarget }),
      );
    } catch {
    }
  }, [entries, goalTarget]);

  useEffect(() => {
    if (!toast) return undefined;
    const timer = window.setTimeout(() => setToast(''), 2600);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const totals = useMemo(() => {
    const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    const previousDate = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const previousMonth = `${previousDate.getFullYear()}-${String(previousDate.getMonth() + 1).padStart(2, '0')}`;
    const currentYear = String(now.getFullYear());
    const total = entries.reduce((sum, entry) => sum + (Number(entry.amount) || 0), 0);
    const month = entries.reduce((sum, entry) => (entry.date?.startsWith(currentMonth) ? sum + (Number(entry.amount) || 0) : sum), 0);
    const previous = entries.reduce((sum, entry) => (entry.date?.startsWith(previousMonth) ? sum + (Number(entry.amount) || 0) : sum), 0);
    const year = entries.reduce((sum, entry) => (entry.date?.startsWith(currentYear) ? sum + (Number(entry.amount) || 0) : sum), 0);
    const yearCount = entries.filter((entry) => entry.date?.startsWith(currentYear)).length;
    return {
      total: Math.round(total * 100) / 100,
      month: Math.round(month * 100) / 100,
      previous: Math.round(previous * 100) / 100,
      year: Math.round(year * 100) / 100,
      yearCount,
    };
  }, [entries, now]);

  const sixMonths = useMemo(() => getSixMonthTotals(entries, now), [entries, now]);
  const progress = goalTarget > 0 ? Math.min(100, Math.round((totals.month / goalTarget) * 100)) : 0;
  const monthName = now.toLocaleDateString('de-DE', { month: 'long' });
  function showToast(message) {
    setToast(message);
  }

  function openEntryModal(draft = null) {
    setMobileMenuOpen(false);
    setEntryDraft(draft);
    setEntryModalOpen(true);
  }

  function navigate(nextPage) {
    setPage(nextPage);
    setMobileMenuOpen(false);
    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    window.scrollTo({ top: 0, behavior: prefersReducedMotion ? 'auto' : 'smooth' });
  }

  function saveEntry(values) {
    const newEntry = {
      ...values,
      id: makeId(),
      amount: Math.round(Number(values.amount) * 100) / 100,
    };
    setEntries((current) => [newEntry, ...current].sort((a, b) => b.date.localeCompare(a.date)));
    setEntryModalOpen(false);
    showToast(`${formatMoney(newEntry.amount)} ist in deinem Sparbuch gelandet.`);
  }

  function deleteEntry(id) {
    setEntries((current) => current.filter((entry) => entry.id !== id));
    showToast('Eintrag entfernt.');
  }


  return (
    <div className="app-shell">
      <Sidebar page={page} onNavigate={navigate} />
      <div className="app-main">
        <div className="mobile-brand-row">
          <div className="mobile-brand-leading">
            <button
              ref={mobileMenuToggleRef}
              className={`mobile-menu-toggle ${mobileMenuOpen ? 'is-open' : ''}`}
              aria-label={mobileMenuOpen ? 'Menü schließen' : 'Menü öffnen'}
              aria-expanded={mobileMenuOpen}
              aria-controls="mobile-drawer"
              onClick={() => setMobileMenuOpen((open) => !open)}
            >
              <span className="mobile-menu-icon">{mobileMenuOpen ? <X size={19} /> : <Menu size={19} />}</span>
            </button>
            <Brand />
          </div>
          <div className="mobile-avatar" aria-label="Sparschwein-Profil">S</div>
        </div>

        <main className="main-content">
          <header className="page-header">
            <div className="page-header-copy">
              <div className="eyebrow"><span className="eyebrow-dot" /> DEIN PERSÖNLICHES SPAR-COCKPIT</div>
              <h1>{getGreeting(now.getHours())}, <span>Sparschwein!</span></h1>
              <p>Deine Ersparnisse im Überblick.</p>
            </div>
            <div className="header-actions">
              <div className="today-pill">
                <CalendarDays size={16} strokeWidth={1.8} />
                <span>{now.toLocaleDateString('de-DE', { weekday: 'long', day: 'numeric', month: 'long' })}</span>
              </div>
              <button className="button-primary header-add" onClick={() => openEntryModal()}>
                <Plus size={18} strokeWidth={2.3} />
                <span>Sparbetrag eintragen</span>
              </button>
            </div>
          </header>


          <div key={page} className="page-view">
            {page === 'dashboard' && (
            <DashboardPage
              entries={entries}
              now={now}
              totals={totals}
              sixMonths={sixMonths}
              progress={progress}
              goalTarget={goalTarget}
              monthName={monthName}
              onNavigate={navigate}
              onOpenEntry={openEntryModal}
              onDeleteEntry={deleteEntry}
              entryTypeFilter={entryTypeFilter}
              setEntryTypeFilter={setEntryTypeFilter}
              entryStoreFilter={entryStoreFilter}
              setEntryStoreFilter={setEntryStoreFilter}
              entrySearch={entrySearch}
              setEntrySearch={setEntrySearch}
            />
          )}

          {page === 'entries' && (
            <section className="page-section">
              <SectionIntro
                icon={Receipt}
                label="DEIN SPARBUCH"
                title="Alle Einträge auf einen Blick."
                description="Hier findest du alle Fundstücke, Rabatte und Rückzahlungen an einem Ort."
              />
              <ActivityPanel
                entries={entries}
                now={now}
                full
                onNavigate={navigate}
                onDeleteEntry={deleteEntry}
                typeFilter={entryTypeFilter}
                setTypeFilter={setEntryTypeFilter}
                storeFilter={entryStoreFilter}
                setStoreFilter={setEntryStoreFilter}
                search={entrySearch}
                setSearch={setEntrySearch}
              />
            </section>
          )}

          {page === 'goals' && (
            <section className="page-section">
              <SectionIntro
                icon={Target}
                label="MONATSZIEL & FORTSCHRITT"
                title="Dein Sparziel im Überblick."
                description={`Monatssumme, Zielbetrag und Meilensteine für ${monthName}.`}
              />
              <GoalsPage
                now={now}
                monthName={monthName}
                monthTotal={totals.month}
                goalTarget={goalTarget}
                onGoalTargetChange={(value) => setGoalTarget(value)}
                entries={entries}
                progress={progress}
              />
            </section>
            )}
          </div>

          <footer className="page-footer">
            <span>Sparschwein · Dein persönliches Sparbuch</span>
          </footer>
        </main>
      </div>

      <MobileDrawer
        page={page}
        isOpen={mobileMenuOpen}
        onNavigate={navigate}
        onClose={() => setMobileMenuOpen(false)}
      />

      {entryModalOpen && (
        <EntryModal
          draft={entryDraft}
          onClose={() => setEntryModalOpen(false)}
          onSave={saveEntry}
        />
      )}
      {toast && <div className="toast-message" role="status"><CheckCircle2 size={18} />{toast}</div>}
    </div>
  );
}

function Brand() {
  return (
    <div className="brand-lockup">
      <div className="brand-mark"><PiggyBank size={22} strokeWidth={1.9} /></div>
      <div className="brand-wordmark"><strong>sparschwein<span>.</span></strong><small>DEIN SPAR-COCKPIT</small></div>
    </div>
  );
}

const NAV_ITEMS = [
  { id: 'dashboard', label: 'Übersicht', icon: LayoutDashboard },
  { id: 'entries', label: 'Meine Einträge', icon: Receipt },
  { id: 'goals', label: 'Sparziele', icon: Target },
];

function Sidebar({ page, onNavigate }) {
  return (
    <aside className="sidebar">
      <Brand />
      <div className="sidebar-section-label">MENÜ</div>
      <nav className="sidebar-nav" aria-label="Hauptnavigation">
        {NAV_ITEMS.map(({ id, label, icon: Icon }) => (
          <button key={id} className={`nav-link ${page === id ? 'active' : ''}`} onClick={() => onNavigate(id)}>
            <Icon size={19} strokeWidth={1.9} />
            <span>{label}</span>
          </button>
        ))}
      </nav>

      <div className="sidebar-spacer" />
      <div className="sidebar-profile">
        <div className="profile-avatar">S</div>
        <div className="profile-copy"><strong>Dein Sparbuch</strong><span>Persönliche Übersicht</span></div>
        <Sparkles className="profile-sparkle" size={16} />
      </div>
    </aside>
  );
}

function MobileDrawer({ page, isOpen, onNavigate, onClose }) {
  return (
    <div className={`mobile-drawer-layer ${isOpen ? 'is-open' : ''}`} aria-hidden={!isOpen}>
      <button className="mobile-drawer-backdrop" onClick={onClose} aria-label="Menü schließen" tabIndex={-1} />
      <nav id="mobile-drawer" className="mobile-drawer" role={isOpen ? 'dialog' : undefined} aria-modal={isOpen ? 'true' : undefined} aria-label="Seitennavigation">
        <div className="mobile-drawer-head">
          <Brand />
          <button className="drawer-close-button" onClick={onClose} aria-label="Menü schließen" tabIndex={isOpen ? 0 : -1}>
            <X size={18} />
          </button>
        </div>
        <span className="drawer-section-label">MENÜ</span>
        <div className="mobile-drawer-links">
          {NAV_ITEMS.map(({ id, label, icon: Icon }, index) => (
            <button
              key={id}
              className={`mobile-drawer-link ${page === id ? 'active' : ''}`}
              onClick={() => onNavigate(id)}
              tabIndex={isOpen ? 0 : -1}
              style={{ '--drawer-delay': `${index * 45}ms` }}
            >
              <span className="mobile-drawer-link-icon"><Icon size={19} strokeWidth={1.9} /></span>
              <span>{label}</span>
              {page === id && <span className="drawer-active-indicator" />}
            </button>
          ))}
        </div>
      </nav>
    </div>
  );
}

function DashboardPage(props) {
  const {
    entries,
    now,
    totals,
    sixMonths,
    progress,
    goalTarget,
    monthName,
    onNavigate,
    onOpenEntry,
    onDeleteEntry,
    entryTypeFilter,
    setEntryTypeFilter,
    entryStoreFilter,
    setEntryStoreFilter,
    entrySearch,
    setEntrySearch,
  } = props;
  const monthChange = totals.previous > 0
    ? Math.round(((totals.month - totals.previous) / totals.previous) * 100)
    : null;
  const recentDescription = monthChange === null
    ? (totals.month > 0 ? 'Dein erster Sparmonat' : 'Dein Sparmonat startet hier')
    : `${monthChange >= 0 ? '+' : ''}${monthChange}% zum Vormonat`;

  return (
    <>
      <div className="summary-grid">
        <section className="total-card">
          <div className="total-card-orb orb-one" />
          <div className="total-card-orb orb-two" />
          <div className="total-card-topline">
            <div className="total-label-wrap">
              <div className="total-icon"><Wallet size={19} strokeWidth={1.8} /></div>
              <div><span className="total-eyebrow">DEIN GESAMTERSPARTES</span><span className="total-caption">Seit deinem ersten Eintrag</span></div>
            </div>
            <div className="total-chip"><Sparkles size={14} /> Alle Einträge</div>
          </div>
          <div className="total-amount">{formatMoney(totals.total)}</div>
          <div className="total-bottomline">
            <span className="total-description">Summe aller eingetragenen Ersparnisse.</span>
            <div className="total-mini-chart"><Sparkline values={sixMonths.map((month) => month.value)} /></div>
          </div>
          <div className="total-decoration"><span /><span /><span /><span /><span /><span /><span /><span /></div>
        </section>

        <div className="stat-stack">
          <StatCard
            icon={CalendarDays}
            label={`DIESEN ${now.toLocaleDateString('de-DE', { month: 'long' }).toUpperCase()}`}
            value={formatMoney(totals.month)}
            note={recentDescription}
            notePositive={monthChange === null || monthChange >= 0}
            progress={progress}
            kind="month"
          />
          <StatCard
            icon={TrendingUp}
            label="SEIT JAHRESBEGINN"
            value={formatMoney(totals.year)}
            note={`${totals.yearCount} ${totals.yearCount === 1 ? 'Eintrag' : 'Einträge'} in ${now.getFullYear()}`}
            kind="year"
          />
        </div>
      </div>

      <div className="insight-grid">
        <section className="panel chart-panel">
          <PanelHeading
            eyebrow="DEIN SPARVERLAUF"
            title="Monatsverlauf"
            description="Deine Ersparnisse der letzten sechs Monate"
            icon={BarChart3}
          >
            <div className="chart-period"><span className="period-dot" /> Letzte 6 Monate</div>
          </PanelHeading>
          <SavingsChart months={sixMonths} />
        </section>

        <section className="panel goal-panel">
          <PanelHeading eyebrow="MONATSZIEL" title="Dein Monatsziel" icon={Target} />
          <div className="goal-progress-row">
            <div className="goal-ring" style={{ background: `conic-gradient(#bd416f ${progress}%, #f8e8ef ${progress}% 100%)` }}>
              <div className="goal-ring-inner"><strong>{progress}%</strong><span>geschafft</span></div>
            </div>
            <div className="goal-progress-copy">
              <span className="goal-this-month">{monthName} bisher</span>
              <strong>{formatMoney(totals.month)}</strong>
              <span className="goal-target-copy">{goalTarget > 0 ? `von ${formatMoney(goalTarget)}` : 'Noch kein Ziel gesetzt'}</span>
            </div>
          </div>
          <div className="goal-progress-track"><span style={{ width: `${progress}%` }} /></div>
          <p className="goal-encouragement">
            <span className="goal-encouragement-icon"><Sparkles size={15} /></span>
            {goalTarget > 0 ? (progress >= 100 ? 'Geschafft! Du hast dein Monatsziel erreicht.' : `Noch ${formatMoney(Math.max(0, goalTarget - totals.month))} bis zu deinem Ziel.`) : 'Lege ein Monatsziel fest.'}
          </p>
          <button className="text-link goal-edit-link" onClick={() => onNavigate('goals')}>Sparziel ansehen <ArrowRight size={15} /></button>
        </section>
      </div>

      <div className="dashboard-activity-wrap">
        <ActivityPanel
          entries={entries}
          now={now}
          onNavigate={onNavigate}
          onDeleteEntry={onDeleteEntry}
          typeFilter={entryTypeFilter}
          setTypeFilter={setEntryTypeFilter}
          storeFilter={entryStoreFilter}
          setStoreFilter={setEntryStoreFilter}
          search={entrySearch}
          setSearch={setEntrySearch}
        />
      </div>
      <div className="dashboard-bottom-cta">
        <div className="bottom-cta-icon"><Plus size={18} /></div>
        <span>Neue Ersparnis</span>
        <button className="button-soft" onClick={() => onOpenEntry()}><Plus size={16} /> Sparbetrag eintragen</button>
      </div>
    </>
  );
}

function StatCard({ icon: Icon, label, value, note, notePositive, progress, kind }) {
  return (
    <section className={`stat-card stat-card-${kind}`}>
      <div className="stat-topline">
        <div className={`stat-icon ${kind}`}><Icon size={18} strokeWidth={1.9} /></div>
        <span className="stat-label">{label}</span>
        <span className={`stat-top-arrow ${notePositive === false ? 'negative' : ''}`}>
          {notePositive === false ? <ArrowDownRight size={16} /> : <ArrowUpRight size={16} />}
        </span>
      </div>
      <strong className="stat-value">{value}</strong>
      <div className="stat-card-bottom">
        <span className={`stat-note ${notePositive === false ? 'negative' : ''}`}>{note}</span>
        {typeof progress === 'number' && <div className="stat-progress"><span style={{ width: `${progress}%` }} /></div>}
      </div>
    </section>
  );
}

function PanelHeading({ eyebrow, title, description, icon: Icon, children }) {
  return (
    <div className="panel-heading">
      <div className="panel-heading-left">
        <div className="panel-heading-icon"><Icon size={18} strokeWidth={1.8} /></div>
        <div>
          {eyebrow && <span className="panel-eyebrow">{eyebrow}</span>}
          <h2>{title}</h2>
          {description && <p>{description}</p>}
        </div>
      </div>
      {children}
    </div>
  );
}

function Sparkline({ values }) {
  const width = 122;
  const height = 38;
  const max = Math.max(...values, 1);
  const min = Math.min(...values, 0);
  const range = max - min || 1;
  const points = values.map((value, index) => {
    const x = (index / Math.max(values.length - 1, 1)) * (width - 6) + 3;
    const y = height - 4 - ((value - min) / range) * (height - 11);
    return `${x},${y}`;
  });
  const path = points.map((point, index) => `${index === 0 ? 'M' : 'L'} ${point}`).join(' ');
  const last = points[points.length - 1]?.split(',') || ['0', '0'];
  return (
    <svg viewBox={`0 0 ${width} ${height}`} role="img" aria-label="Sparverlauf der letzten Monate" className="sparkline">
      <path d={`${path} L ${width - 3} ${height - 1} L 3 ${height - 1} Z`} fill="rgba(255,255,255,0.1)" />
      <path d={path} fill="none" stroke="#f4c7d8" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
      <circle cx={last[0]} cy={last[1]} r="3" fill="#f8e5ed" stroke="#96385c" strokeWidth="1.5" />
    </svg>
  );
}

function SavingsChart({ months }) {
  const maxValue = Math.max(...months.map((month) => month.value), 1);
  return (
    <div className="chart-wrap">
      <div className="chart-bars" role="img" aria-label="Ersparnisse der letzten sechs Monate">
        <div className="chart-grid-lines"><span /><span /><span /></div>
        {months.map((month, index) => {
          const height = month.value > 0 ? Math.max(7, (month.value / maxValue) * 100) : 3;
          return (
            <div className={`chart-column ${month.current ? 'current' : ''}`} key={month.key} title={`${month.fullLabel}: ${formatMoney(month.value)}`}>
              <span className="chart-value-label">{formatShortMoney(month.value)}</span>
              <div className="chart-bar-track"><span className="chart-bar" style={{ height: `${height}%`, animationDelay: `${index * 55}ms` }} /></div>
              <span className="chart-month-label">{month.label}</span>
            </div>
          );
        })}
      </div>
      <div className="chart-legend"><span><i /> Im Monat gespart</span><span>Werte der letzten sechs Monate</span></div>
    </div>
  );
}

function SectionIntro({ icon: Icon, label, title, description }) {
  return (
    <div className="section-intro">
      <div className="section-intro-icon"><Icon size={19} /></div>
      <div><span className="section-intro-label">{label}</span><h2>{title}</h2><p>{description}</p></div>
    </div>
  );
}

function ActivityPanel({
  entries,
  now,
  full = false,
  onNavigate,
  onDeleteEntry,
  typeFilter,
  setTypeFilter,
  storeFilter,
  setStoreFilter,
  search,
  setSearch,
}) {
  const filteredEntries = useMemo(() => {
    const normalizedSearch = search.trim().toLocaleLowerCase('de-DE');
    return [...entries]
      .filter((entry) => typeFilter === 'Alle' || entry.type === typeFilter)
      .filter((entry) => storeFilter === 'Alle Läden' || entry.store === storeFilter)
      .filter((entry) => !normalizedSearch || `${entry.title} ${entry.store} ${entry.type}`.toLocaleLowerCase('de-DE').includes(normalizedSearch))
      .sort((a, b) => b.date.localeCompare(a.date));
  }, [entries, typeFilter, storeFilter, search]);
  const visibleEntries = full ? filteredEntries : filteredEntries.slice(0, 5);
  const availableStores = [...new Set(entries.map((entry) => entry.store).filter(Boolean))].sort((a, b) => a.localeCompare(b, 'de'));

  return (
    <section className={`panel activity-panel ${full ? 'activity-panel-full' : ''}`}>
      <div className="activity-panel-heading">
        <PanelHeading
          eyebrow={full ? 'ALLE SPAR-MOMENTE' : 'DEINE LETZTEN SPAR-MOMENTE'}
          title={full ? 'Dein Sparbuch' : 'Zuletzt gespart'}
          description={full ? `${entries.length} ${entries.length === 1 ? 'Eintrag' : 'Einträge'} in deiner Übersicht` : undefined}
          icon={Receipt}
        >
          {!full && <button className="text-link" onClick={() => onNavigate('entries')}>Alle ansehen <ChevronRight size={15} /></button>}
        </PanelHeading>
      </div>
      <div className="activity-toolbar">
        <div className="filter-chips" aria-label="Nach Sparart filtern">
          {ENTRY_FILTERS.map((filter) => (
            <button
              className={`filter-chip ${typeFilter === filter.value ? 'selected' : ''}`}
              key={filter.value}
              onClick={() => setTypeFilter(filter.value)}
            >{filter.label}</button>          ))}
        </div>
        <div className="activity-selects">
          {full && (
            <label className="search-field">
              <Search size={16} />
              <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Einträge suchen" aria-label="Einträge suchen" />
              {search && <button aria-label="Suche leeren" onClick={() => setSearch('')}><X size={14} /></button>}
            </label>
          )}
          <label className="store-select-wrap">
            <Store size={15} />
            <select aria-label="Nach Laden filtern" value={storeFilter} onChange={(event) => setStoreFilter(event.target.value)}>
              <option>Alle Läden</option>
              {availableStores.map((store) => <option key={store}>{store}</option>)}
            </select>
            <ChevronDown size={14} className="select-chevron" />
          </label>
        </div>
      </div>

      {visibleEntries.length ? (
        <div className="activity-list">
          {visibleEntries.map((entry) => (
            <ActivityRow key={entry.id} entry={entry} now={now} full={full} onDelete={() => onDeleteEntry(entry.id)} />
          ))}
        </div>
      ) : (
        <div className="empty-state">
          <div className="empty-state-icon"><Search size={20} /></div>
          <strong>{entries.length ? 'Nichts gefunden' : 'Noch ist dein Sparbuch leer'}</strong>
          <span>{entries.length ? 'Passe deine Filter an und versuch es noch einmal.' : 'Dein erster Eintrag ist nur einen kleinen Moment entfernt.'}</span>
        </div>
      )}
      {!full && filteredEntries.length > 5 && (
        <button className="activity-more" onClick={() => onNavigate('entries')}>Alle {filteredEntries.length} Einträge ansehen <ArrowRight size={15} /></button>
      )}
    </section>
  );
}

function ActivityRow({ entry, now, full, onDelete }) {
  const Icon = getTypeIcon(entry.type);
  return (
    <div className="activity-row">
      <div className={`activity-row-icon ${getTypeClass(entry.type)}`}><Icon size={18} strokeWidth={1.9} /></div>
      <div className="activity-row-copy">
        <strong>{entry.title}</strong>
        <span>{getEntryDateLabel(entry.date, now)} <i /> {entry.store || 'Sonstiges'} <i /> {entry.type}</span>
      </div>
      <strong className="activity-amount">+{formatMoney(entry.amount)}</strong>
      {full && (
        <button className="delete-entry-button" aria-label={`${entry.title} entfernen`} onClick={onDelete} title="Eintrag entfernen">
          <Trash2 size={15} />
        </button>
      )}
    </div>
  );
}

function GoalsPage({ now, monthName, monthTotal, goalTarget, onGoalTargetChange, entries, progress }) {
  const [targetInput, setTargetInput] = useState(goalTarget > 0 ? String(goalTarget) : '');
  useEffect(() => setTargetInput(goalTarget > 0 ? String(goalTarget) : ''), [goalTarget]);
  const milestones = [
    { value: 10, label: 'Erster Zehner', icon: Sparkles },
    { value: 50, label: 'Kleine Schritte', icon: Wallet },
    { value: 100, label: 'Sparschwein-Monat', icon: Target },
    { value: 250, label: 'Richtig stark', icon: Gift },
  ];
  const monthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  const monthCount = entries.filter((entry) => entry.date?.startsWith(monthKey)).length;

  return (
    <div className="goals-page-grid">
      <section className="panel goal-detail-panel">
        <div className="goal-detail-top">
          <div>
            <span className="panel-eyebrow">DEIN FOKUS FÜR {monthName.toUpperCase()}</span>
            <h2>Monatsziel festlegen</h2>
            <p>Lege einen Betrag fest und verfolge den Fortschritt im Monatsverlauf.</p>
          </div>
          <div className="goal-detail-stamp"><Target size={22} /><span>Monats-<br />ziel</span></div>
        </div>
        <div className="goal-detail-progress-area">
          <div className="goal-detail-numbers"><div><span>Bisher gespart</span><strong>{formatMoney(monthTotal)}</strong></div><span className="goal-detail-separator">von</span><div><span>Dein Monatsziel</span><strong>{goalTarget > 0 ? formatMoney(goalTarget) : 'Noch offen'}</strong></div></div>
          <div className="large-progress-track"><span style={{ width: `${progress}%` }} /></div>
          <div className="large-progress-labels"><span>{progress}% geschafft</span><span>{monthCount} {monthCount === 1 ? 'Spar-Moment' : 'Spar-Momente'} in {monthName}</span></div>
        </div>
        <label className="goal-input-label" htmlFor="goal-target-input">{goalTarget > 0 ? 'Dein Monatsziel anpassen' : 'Monatsziel festlegen'}</label>
        <div className="goal-input-wrap"><span>€</span><input id="goal-target-input" type="number" min="1" step="5" value={targetInput} onChange={(event) => setTargetInput(event.target.value)} onBlur={() => { const nextTarget = Number(targetInput); if (Number.isFinite(nextTarget) && nextTarget > 0) onGoalTargetChange(nextTarget); else setTargetInput(goalTarget > 0 ? String(goalTarget) : ''); }} /><span className="goal-input-hint">pro Monat</span></div>
      </section>

      <section className="panel milestones-panel">
        <PanelHeading eyebrow="MONATSZIEL" title="Meilensteine" description="Beträge im aktuellen Monat." icon={Sparkles} />
        <div className="milestone-list">
          {milestones.map(({ value, label, icon: Icon }) => {
            const reached = monthTotal >= value;
            return (
              <div className={`milestone-row ${reached ? 'reached' : ''}`} key={value}>
                <div className="milestone-icon"><Icon size={17} /></div>
                <div className="milestone-copy"><strong>{label}</strong><span>{formatMoney(value)} in einem Monat</span></div>
                {reached ? <span className="milestone-complete"><Check size={14} /> Geschafft</span> : <span className="milestone-pending">{formatMoney(value - monthTotal)} übrig</span>}
              </div>
            );
          })}
        </div>
        <div className="milestone-bottom"><div className="milestone-bottom-icon"><Heart size={16} /></div><p>Die Meilensteine orientieren sich an deinen Einträgen im aktuellen Monat.</p></div>
      </section>
    </div>
  );
}

function EntryModal({ draft, onClose, onSave }) {
  const [amount, setAmount] = useState(draft?.amount ? String(draft.amount).replace('.', ',') : '');
  const [title, setTitle] = useState(draft?.title || '');
  const [store, setStore] = useState(STORES.includes(draft?.store) ? draft.store : 'Sonstiges');
  const [type, setType] = useState(ENTRY_TYPES.includes(draft?.type) ? draft.type : 'Cashback');
  const [date, setDate] = useState(toISODate(new Date()));
  const [note, setNote] = useState('');
  const [amountError, setAmountError] = useState('');

  useEffect(() => {
    function onKeyDown(event) {
      if (event.key === 'Escape') onClose();
    }
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [onClose]);

  function submit(event) {
    event.preventDefault();
    const parsedAmount = Number(String(amount).trim().replace(',', '.'));
    if (!Number.isFinite(parsedAmount) || parsedAmount <= 0) {
      setAmountError('Bitte gib einen Betrag größer als 0 € ein.');
      return;
    }
    setAmountError('');
    onSave({ amount: parsedAmount, title: title.trim(), store, type, date, note: note.trim() });
  }

  return (
    <div className="modal-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose(); }}>
      <section className="modal-card entry-modal" role="dialog" aria-modal="true" aria-labelledby="entry-modal-title">
        <div className="modal-topline">
          <div className="modal-icon"><Wallet size={20} /></div>
          <button className="modal-close" onClick={onClose} aria-label="Dialog schließen"><X size={19} /></button>
        </div>
        <span className="modal-eyebrow">EIN NEUER SPAR-MOMENT</span>
        <h2 id="entry-modal-title">Was hast du gespart?</h2>
        <p className="modal-intro">Betrag, Laden und Datum für dein Sparbuch eintragen.</p>
        <form onSubmit={submit}>
          <label className="form-label" htmlFor="entry-amount">Betrag</label>
          <div className={`amount-input-wrap ${amountError ? 'has-error' : ''}`}>
            <span className="amount-prefix">€</span>
            <input id="entry-amount" value={amount} onChange={(event) => { setAmount(event.target.value); setAmountError(''); }} inputMode="decimal" autoComplete="off" placeholder="0,00" required aria-describedby={amountError ? 'amount-error' : undefined} />
            <span className="amount-suffix">EUR</span>
          </div>
          {amountError && <span className="field-error" id="amount-error">{amountError}</span>}
          <label className="form-label" htmlFor="entry-title">Wofür hast du gespart?</label>
          <input className="form-input" id="entry-title" value={title} onChange={(event) => setTitle(event.target.value)} placeholder="Eintrag benennen" required maxLength={80} />

          <div className="form-two-columns">
            <div>
              <label className="form-label" htmlFor="entry-store">Laden / Ort</label>
              <div className="form-select-wrap"><select className="form-input" id="entry-store" value={store} onChange={(event) => setStore(event.target.value)}>{STORES.map((item) => <option key={item}>{item}</option>)}</select><ChevronDown size={15} /></div>
            </div>
            <div>
              <label className="form-label" htmlFor="entry-type">Art</label>
              <div className="form-select-wrap"><select className="form-input" id="entry-type" value={type} onChange={(event) => setType(event.target.value)}>{ENTRY_TYPES.map((item) => <option key={item}>{item}</option>)}</select><ChevronDown size={15} /></div>
            </div>
          </div>

          <div className="form-two-columns form-date-note">
            <div>
              <label className="form-label" htmlFor="entry-date">Datum</label>
              <input className="form-input" id="entry-date" type="date" value={date} onChange={(event) => setDate(event.target.value)} required />
            </div>
            <div>
              <label className="form-label" htmlFor="entry-note">Notiz <span>(optional)</span></label>
              <input className="form-input" id="entry-note" value={note} onChange={(event) => setNote(event.target.value)} placeholder="Noch ein Detail …" maxLength={70} />
            </div>
          </div>
          <button className="button-primary modal-submit" type="submit"><Plus size={17} /> Betrag ins Sparbuch legen</button>
        </form>
      </section>
    </div>
  );
}

export default App;
