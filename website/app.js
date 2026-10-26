/* ═══════════════════════════════════════════════════════════════════════════
   MEZZO • Modern Web App Interactivity & Business Logic
   ═══════════════════════════════════════════════════════════════════════════ */

document.addEventListener('DOMContentLoaded', () => {
  initPersonaSwitcher();
  initPreviewSimulator();
  initRoiCalculator();
  initPricingToggle();
  initFaqAccordion();
  initDownloadModal();
  initMobileNav();
  initQrScannerUrlHandler();
});

/* ─────────────────────────────────────────────────────────────────────────
   1. DUAL PERSONA SWITCHER (MESS OWNERS VS STUDENTS)
   ───────────────────────────────────────────────────────────────────────── */
function initPersonaSwitcher() {
  const ownerBtn = document.getElementById('persona-owner-btn');
  const studentBtn = document.getElementById('persona-student-btn');
  const heroBadge = document.getElementById('hero-badge-text');
  const heroHeading = document.getElementById('hero-main-heading');
  const heroSub = document.getElementById('hero-sub-text');
  const primaryCta = document.getElementById('primary-cta-btn');

  if (!ownerBtn || !studentBtn) return;

  ownerBtn.addEventListener('click', () => {
    ownerBtn.classList.add('active');
    studentBtn.classList.remove('active');

    heroBadge.textContent = '🚀 Built for Mess Owners, Hostels & Independent Canteens';
    heroHeading.innerHTML = 'Zero Fee Leakage. Zero Food Wastage. <span class="highlight">100% In-Hand Profit.</span>';
    heroSub.textContent = 'Track daily sabzi, doodh & ration kharcha in 1 tap, eliminate paper registers, and automate monthly bill collections directly via UPI.';
    primaryCta.innerHTML = '<span>⚡</span> Download Owner App (v1.0.4)';

    // Trigger tab 1 in simulator
    switchPreviewTab('ledger');
  });

  studentBtn.addEventListener('click', () => {
    studentBtn.classList.add('active');
    ownerBtn.classList.remove('active');

    heroBadge.textContent = '🎓 Built for College Students, Hostellers & Daily Diners';
    heroHeading.innerHTML = 'Know Today\'s Menu. Skip Meals in 1-Tap. <span class="highlight">Pay Only for What You Eat.</span>';
    heroSub.textContent = 'Check live breakfast, lunch & dinner menu in real-time, cancel meals with 30-min automated cutoff to save money, and get transparent monthly bills.';
    primaryCta.innerHTML = '<span>⚡</span> Download Student App (v1.0.4)';

    // Trigger tab 2 in simulator
    switchPreviewTab('menu');
  });
}

/* ─────────────────────────────────────────────────────────────────────────
   2. INTERACTIVE APP PREVIEW SIMULATOR
   ───────────────────────────────────────────────────────────────────────── */
function initPreviewSimulator() {
  const tabs = document.querySelectorAll('.preview-tab-btn');
  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      const target = tab.getAttribute('data-target');
      switchPreviewTab(target);
    });
  });
}

function switchPreviewTab(targetId) {
  const tabs = document.querySelectorAll('.preview-tab-btn');
  const views = document.querySelectorAll('.screen-view');

  tabs.forEach(t => {
    if (t.getAttribute('data-target') === targetId) {
      t.classList.add('active');
    } else {
      t.classList.remove('active');
    }
  });

  views.forEach(v => {
    if (v.id === `view-${targetId}`) {
      v.classList.add('active');
    } else {
      v.classList.remove('active');
    }
  });
}

/* ─────────────────────────────────────────────────────────────────────────
   3. DYNAMIC ROI & FOOD WASTE CALCULATOR
   ───────────────────────────────────────────────────────────────────────── */
function initRoiCalculator() {
  const studentsSlider = document.getElementById('slider-students');
  const feeSlider = document.getElementById('slider-fee');
  const studentsVal = document.getElementById('val-students');
  const feeVal = document.getElementById('val-fee');

  const outRation = document.getElementById('out-ration-saved');
  const outLeakage = document.getElementById('out-leakage-saved');
  const outHours = document.getElementById('out-hours-saved');
  const outAnnual = document.getElementById('out-annual-profit');

  if (!studentsSlider || !feeSlider) return;

  function calculate() {
    const students = parseInt(studentsSlider.value, 10);
    const fee = parseInt(feeSlider.value, 10);

    studentsVal.textContent = `${students} Students`;
    feeVal.textContent = `₹${fee.toLocaleString('en-IN')}`;

    // Industry benchmark formulas for messes:
    // 1. Avg ~12% meal absenteeism per month. Without cutoff, food is wasted.
    // 30-min cutoff saves ~9% of monthly food procurement cost (~₹180 per student).
    const monthlyRationSaved = Math.round(students * 190);

    // 2. Fee leakage & ledger disputes: ~4% of total collection typically lost in manual bahi-khata
    const totalCollection = students * fee;
    const monthlyLeakageRecovered = Math.round(totalCollection * 0.045);

    // 3. Admin & calculation hours saved (approx 14 hrs per month for 50 students, scaling logarithmically)
    const hoursSaved = Math.round(10 + (students * 0.16));

    // 4. Annual Net Financial Benefit
    const annualTotal = (monthlyRationSaved + monthlyLeakageRecovered) * 12;

    outRation.textContent = `+₹${monthlyRationSaved.toLocaleString('en-IN')}/mo`;
    outLeakage.textContent = `+₹${monthlyLeakageRecovered.toLocaleString('en-IN')}/mo`;
    outHours.textContent = `${hoursSaved} hrs/mo`;
    outAnnual.textContent = `₹${annualTotal.toLocaleString('en-IN')}`;
  }

  studentsSlider.addEventListener('input', calculate);
  feeSlider.addEventListener('input', calculate);

  // Initial calculation
  calculate();
}

/* ─────────────────────────────────────────────────────────────────────────
   4. PAYWALL PRICING TOGGLE (MONTHLY VS ANNUAL)
   ───────────────────────────────────────────────────────────────────────── */
function initPricingToggle() {
  const toggle = document.getElementById('pricing-billing-toggle');
  const priceStarter = document.getElementById('price-starter');
  const priceGrowth = document.getElementById('price-growth');
  const pricePro = document.getElementById('price-pro');
  const periodEls = document.querySelectorAll('.price-period');
  const billedEls = document.querySelectorAll('.plan-billed');

  if (!toggle) return;

  toggle.addEventListener('change', () => {
    const isAnnual = toggle.checked;

    if (isAnnual) {
      // Annual discounted prices
      priceStarter.textContent = '0';
      priceGrowth.textContent = '399'; // ₹4,788 billed annually (Save 20%)
      pricePro.textContent = '959';    // ₹11,508 billed annually (Save 20%)

      periodEls.forEach(el => el.textContent = '/ month');
      billedEls[0].textContent = 'Free forever for micro messes';
      billedEls[1].textContent = '₹4,788 billed annually (2 months free)';
      billedEls[2].textContent = '₹11,508 billed annually (2 months free)';
    } else {
      // Monthly prices
      priceStarter.textContent = '0';
      priceGrowth.textContent = '499';
      pricePro.textContent = '1,199';

      periodEls.forEach(el => el.textContent = '/ month');
      billedEls[0].textContent = 'Free forever for micro messes';
      billedEls[1].textContent = 'Billed monthly, cancel anytime';
      billedEls[2].textContent = 'Billed monthly, cancel anytime';
    }
  });
}

/* ─────────────────────────────────────────────────────────────────────────
   5. FAQ ACCORDION
   ───────────────────────────────────────────────────────────────────────── */
function initFaqAccordion() {
  const items = document.querySelectorAll('.faq-item');
  items.forEach(item => {
    const q = item.querySelector('.faq-question');
    if (!q) return;

    q.addEventListener('click', () => {
      const isActive = item.classList.contains('active');

      // Close all other items
      items.forEach(i => i.classList.remove('active'));

      // Toggle current item
      if (!isActive) {
        item.classList.add('active');
      }
    });
  });
}

/* ─────────────────────────────────────────────────────────────────────────
   6. APK DOWNLOAD MODAL
   ───────────────────────────────────────────────────────────────────────── */
function initDownloadModal() {
  const modal = document.getElementById('download-modal');
  const openBtns = document.querySelectorAll('.open-download-modal');
  const closeBtn = document.getElementById('modal-close-btn');

  if (!modal) return;

  openBtns.forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      modal.classList.add('active');
      document.body.style.overflow = 'hidden';
    });
  });

  const closeModal = () => {
    modal.classList.remove('active');
    document.body.style.overflow = '';
  };

  if (closeBtn) closeBtn.addEventListener('click', closeModal);

  modal.addEventListener('click', (e) => {
    if (e.target === modal) closeModal();
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && modal.classList.contains('active')) {
      closeModal();
    }
  });
}

/* ─────────────────────────────────────────────────────────────────────────
   7. MOBILE NAVIGATION TOGGLE
   ───────────────────────────────────────────────────────────────────────── */
function initMobileNav() {
  const toggle = document.querySelector('.nav-toggle');
  const links = document.querySelector('.nav-links');

  if (!toggle || !links) return;

  toggle.addEventListener('click', () => {
    links.classList.toggle('open');
    toggle.textContent = links.classList.contains('open') ? '✕' : '☰';
  });

  // Close menu on link click
  links.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
      links.classList.remove('open');
      toggle.textContent = '☰';
    });
  });
}

/* ─────────────────────────────────────────────────────────────────────────
   8. COUNTER STANDEE QR CODE SCAN HANDLER
   ───────────────────────────────────────────────────────────────────────── */
function initQrScannerUrlHandler() {
  const urlParams = new URLSearchParams(window.location.search);
  const messCode = urlParams.get('code');
  const messId = urlParams.get('id');

  if (messCode || messId) {
    // Switch to Student view automatically
    const studentBtn = document.getElementById('persona-student-btn');
    if (studentBtn) studentBtn.click();

    // Show custom welcome modal for the scanned mess
    const modal = document.getElementById('download-modal');
    const modalTitle = document.getElementById('modal-title');
    if (modal && modalTitle) {
      modalTitle.textContent = `Connect to Mess Code: ${messCode || 'Counter Standee'}`;
      modal.classList.add('active');
      document.body.style.overflow = 'hidden';

      const banner = document.createElement('div');
      banner.style.cssText = 'background: #EBF3ED; color: #2B4532; padding: 12px 16px; border-radius: 12px; font-size: 0.86rem; margin-bottom: 16px; font-weight: 600; text-align: center; border: 1px solid #7B9E87;';
      banner.innerHTML = `📍 <strong>Counter QR Scanned!</strong><br>Download Mezzo to view today\'s live menu, track meals & join <strong>${messCode || 'this mess'}</strong>.`;
      
      const modalBody = modal.querySelector('.modal-body');
      if (modalBody && !modalBody.querySelector('.scanned-qr-banner')) {
        banner.className = 'scanned-qr-banner';
        modalBody.insertBefore(banner, modalBody.firstChild);
      }
    }
  }
}

