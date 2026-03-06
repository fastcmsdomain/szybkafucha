/**
 * Szybka Fucha - Promo Popup
 * Standalone script for the promotional popup banner.
 * Shows after 5 seconds, collects name + email for promo list.
 * Remembers dismissal via localStorage.
 *
 * Dependencies: Relies on globals from script.js:
 *   - getPageLanguage(), getMessages(), CONFIG, trackEvent()
 */

// ========================================
// Promo Popup Translations
// ========================================

const PROMO_MESSAGES = {
  pl: {
    badge: 'OFERTA LIMITOWANA',
    title: 'Pierwsze 100 osób dostaje 2 zlecenia gratis!',
    subtitle: 'Dołącz do Szybka Fucha jako jeden z pierwszych i odbierz swój bonus powitalny.',
    dealLine1: '2 zlecenia o wartości',
    dealAmount: '20 PLN',
    dealLine2: 'Całkowicie za darmo',
    spotsLeft: 'Zostało tylko 100 miejsc!',
    nameLabel: 'Imię',
    namePlaceholder: 'Twoje imię',
    emailLabel: 'E-mail',
    emailPlaceholder: 'twoj@email.com',
    consentText: 'Wyrażam zgodę na przetwarzanie danych w celach marketingowych.',
    cta: 'Odbierz bonus — Zapisz się!',
    dismiss: 'Nie, dziękuję',
    successTitle: 'Gotowe!',
    successText: 'Twój bonus został zarezerwowany. Powiadomimy Cię, gdy aplikacja będzie gotowa!',
    nameRequired: 'Proszę podać imię',
    emailRequired: 'Proszę podać adres e-mail',
    emailInvalid: 'Proszę podać poprawny adres e-mail',
    consentRequired: 'Wymagana jest zgoda',
    submitError: 'Wystąpił błąd. Spróbuj ponownie później.',
  },
  en: {
    badge: 'LIMITED OFFER',
    title: 'First 100 users get 2 free tasks!',
    subtitle: 'Join Szybka Fucha as one of the first members and claim your welcome bonus.',
    dealLine1: '2 tasks worth',
    dealAmount: '20 PLN',
    dealLine2: 'Completely free of charge',
    spotsLeft: 'Only 100 spots available!',
    nameLabel: 'Name',
    namePlaceholder: 'Your name',
    emailLabel: 'Email',
    emailPlaceholder: 'your@email.com',
    consentText: 'I consent to data processing for marketing purposes.',
    cta: 'Claim my bonus — Sign up!',
    dismiss: 'No, thank you',
    successTitle: 'Done!',
    successText: 'Your bonus has been reserved. We\'ll notify you when the app is ready!',
    nameRequired: 'Please enter your name',
    emailRequired: 'Please enter your email address',
    emailInvalid: 'Please enter a valid email address',
    consentRequired: 'Consent is required',
    submitError: 'An error occurred. Please try again later.',
  },
  uk: {
    badge: 'ОБМЕЖЕНА ПРОПОЗИЦІЯ',
    title: 'Перші 100 користувачів отримують 2 завдання безкоштовно!',
    subtitle: 'Приєднуйтесь до Szybka Fucha одними з перших і отримайте стартовий бонус.',
    dealLine1: '2 завдання вартістю',
    dealAmount: '20 PLN',
    dealLine2: 'Абсолютно безкоштовно',
    spotsLeft: 'Залишилось лише 100 місць!',
    nameLabel: "Ім'я",
    namePlaceholder: "Ваше ім'я",
    emailLabel: 'Електронна пошта',
    emailPlaceholder: 'ваш@email.com',
    consentText: 'Я даю згоду на обробку даних у маркетингових цілях.',
    cta: 'Отримати бонус — Зареєструватись!',
    dismiss: 'Ні, дякую',
    successTitle: 'Готово!',
    successText: 'Ваш бонус зарезервовано. Ми повідомимо вас, коли додаток буде готовий!',
    nameRequired: "Будь ласка, введіть ім'я",
    emailRequired: 'Будь ласка, введіть адресу електронної пошти',
    emailInvalid: 'Будь ласка, введіть дійсну адресу електронної пошти',
    consentRequired: 'Потрібна згода на обробку даних',
    submitError: 'Сталася помилка. Спробуйте пізніше.',
  },
};

/**
 * Get promo messages for current page language.
 * Uses getPageLanguage() from script.js.
 */
function getPromoMessages() {
  const lang = typeof getPageLanguage === 'function' ? getPageLanguage() : 'pl';
  return PROMO_MESSAGES[lang] || PROMO_MESSAGES.pl;
}

// ========================================
// Promo Popup Initialization
// ========================================

function initPromoPopup() {
  const STORAGE_KEY = 'sf_promo_dismissed';
  const DELAY_MS = 5000;
  const EMAIL_PATTERN = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

  // Don't show if already dismissed
  if (localStorage.getItem(STORAGE_KEY)) {
    return;
  }

  const t = getPromoMessages();

  // Resolve API endpoint (reuse from script.js if available, else auto-detect)
  const apiEndpoint = (typeof CONFIG !== 'undefined' && CONFIG.apiEndpoint)
    ? CONFIG.apiEndpoint
    : (function() {
        const h = window.location.hostname;
        const p = window.location.protocol;
        if (h === 'localhost' || h === '127.0.0.1') return 'http://localhost:8000/api/subscribe.php';
        return p + '//' + h + '/api/subscribe.php';
      })();

  // Build popup DOM
  const overlay = document.createElement('div');
  overlay.id = 'promo-popup-overlay';
  overlay.setAttribute('role', 'dialog');
  overlay.setAttribute('aria-modal', 'true');
  overlay.setAttribute('aria-labelledby', 'promo-popup-title');

  overlay.innerHTML = `
    <div id="promo-popup">
      <div class="promo-popup__rainbow-bar" aria-hidden="true"></div>

      <div class="promo-popup__header">
        <span class="promo-popup__badge">${t.badge}</span>
        <button id="promo-popup-close" type="button" aria-label="Close">
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
            <path d="M2 2L14 14M14 2L2 14" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
          </svg>
        </button>
      </div>

      <div class="promo-popup__body">
        <div class="promo-popup__emoji-row" aria-hidden="true">🎁</div>

        <h2 class="promo-popup__title" id="promo-popup-title">${t.title}</h2>
        <p class="promo-popup__subtitle">${t.subtitle}</p>

        <div class="promo-popup__deal-card">
          <div class="promo-popup__deal-row">
            <span>${t.dealLine1}</span>
            <strong class="promo-popup__deal-amount">${t.dealAmount}</strong>
          </div>
          <div class="promo-popup__deal-row promo-popup__deal-row--free">
            <span>${t.dealLine2}</span>
            <span class="promo-popup__checkmark" aria-hidden="true">✓</span>
          </div>
        </div>

        <p class="promo-popup__spots">
          <span class="promo-popup__spots-pulse" aria-hidden="true"></span>
          ${t.spotsLeft}
        </p>

        <form id="promo-popup-form" class="promo-popup__form" novalidate>
          <div class="promo-popup__form-group">
            <label for="promo-name">${t.nameLabel}</label>
            <input type="text" id="promo-name" name="name" class="promo-popup__form-input" placeholder="${t.namePlaceholder}" required autocomplete="name">
          </div>
          <div class="promo-popup__form-group">
            <label for="promo-email">${t.emailLabel}</label>
            <input type="email" id="promo-email" name="email" class="promo-popup__form-input" placeholder="${t.emailPlaceholder}" required autocomplete="email">
          </div>
          <div class="promo-popup__consent">
            <input type="checkbox" id="promo-consent" name="consent" checked>
            <label for="promo-consent">${t.consentText}</label>
          </div>
          <div class="form-field-website" aria-hidden="true">
            <label for="promo-website">Website</label>
            <input type="text" id="promo-website" name="website" tabindex="-1" autocomplete="off">
          </div>
        </form>
      </div>

      <div class="promo-popup__footer">
        <button type="submit" form="promo-popup-form" class="btn btn--primary btn--large btn--full" id="promo-popup-cta">
          <span class="btn__text">${t.cta}</span>
          <span class="btn__loader" aria-hidden="true"></span>
        </button>
        <button type="button" class="promo-popup__dismiss" id="promo-popup-dismiss">
          ${t.dismiss}
        </button>
      </div>

      <div class="promo-popup__success" id="promo-popup-success" style="display:none">
        <span class="promo-popup__success-icon" aria-hidden="true">🎉</span>
        <h3 class="promo-popup__success-title">${t.successTitle}</h3>
        <p class="promo-popup__success-text">${t.successText}</p>
      </div>
    </div>
  `;

  document.body.appendChild(overlay);

  // --- Helpers ---
  function closePopup() {
    overlay.classList.remove('is-visible');
    overlay.classList.add('is-hiding');
    const onEnd = () => overlay.remove();
    overlay.addEventListener('transitionend', onEnd, { once: true });
    setTimeout(onEnd, 500); // fallback
    localStorage.setItem(STORAGE_KEY, '1');
    if (typeof trackEvent === 'function') {
      trackEvent('promo_popup_dismissed', { lang: getPromoLang() });
    }
  }

  function getPromoLang() {
    return typeof getPageLanguage === 'function' ? getPageLanguage() : 'pl';
  }

  function openPopup() {
    overlay.getBoundingClientRect(); // force reflow
    overlay.classList.add('is-visible');
    const nameInput = overlay.querySelector('#promo-name');
    if (nameInput) nameInput.focus();
    if (typeof trackEvent === 'function') {
      trackEvent('promo_popup_shown', { lang: getPromoLang() });
    }
  }

  // --- Close handlers ---
  overlay.querySelector('#promo-popup-close').addEventListener('click', closePopup);
  overlay.querySelector('#promo-popup-dismiss').addEventListener('click', closePopup);
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) closePopup();
  });

  const escHandler = (e) => {
    if (e.key === 'Escape' && overlay.classList.contains('is-visible')) {
      closePopup();
      document.removeEventListener('keydown', escHandler);
    }
  };
  document.addEventListener('keydown', escHandler);

  // --- Form submission ---
  const form = overlay.querySelector('#promo-popup-form');
  const ctaBtn = overlay.querySelector('#promo-popup-cta');

  form.addEventListener('submit', async (e) => {
    e.preventDefault();

    const nameInput = form.querySelector('#promo-name');
    const emailInput = form.querySelector('#promo-email');
    const consentInput = form.querySelector('#promo-consent');

    // Clear previous errors
    form.querySelectorAll('.promo-popup__form-error').forEach(el => el.remove());
    nameInput.classList.remove('error');
    emailInput.classList.remove('error');

    let valid = true;

    // Validate name
    if (!nameInput.value.trim() || nameInput.value.trim().length < 2) {
      nameInput.classList.add('error');
      const err = document.createElement('div');
      err.className = 'promo-popup__form-error';
      err.textContent = t.nameRequired;
      nameInput.parentNode.appendChild(err);
      valid = false;
    }

    // Validate email
    if (!emailInput.value.trim() || !EMAIL_PATTERN.test(emailInput.value.trim())) {
      emailInput.classList.add('error');
      const err = document.createElement('div');
      err.className = 'promo-popup__form-error';
      err.textContent = emailInput.value.trim() ? t.emailInvalid : t.emailRequired;
      emailInput.parentNode.appendChild(err);
      valid = false;
    }

    // Validate consent
    if (!consentInput.checked) {
      const err = document.createElement('div');
      err.className = 'promo-popup__form-error';
      err.textContent = t.consentRequired;
      consentInput.parentNode.parentNode.appendChild(err);
      valid = false;
    }

    if (!valid) return;

    // Loading state
    ctaBtn.classList.add('loading');
    ctaBtn.disabled = true;

    const payload = {
      name: nameInput.value.trim(),
      email: emailInput.value.trim(),
      consent: true,
      source: 'promo',
      website: (form.querySelector('input[name="website"]') || {}).value || '',
    };

    try {
      const response = await fetch(apiEndpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      const contentType = response.headers.get('content-type');
      let result;

      if (contentType && contentType.includes('application/json')) {
        result = await response.json();
      } else {
        throw new Error(t.submitError);
      }

      if (!response.ok) {
        throw new Error(result.message || t.submitError);
      }

      // Success — show confirmation
      const popupBody = overlay.querySelector('.promo-popup__body');
      const popupFooter = overlay.querySelector('.promo-popup__footer');
      const successEl = overlay.querySelector('#promo-popup-success');

      popupBody.style.display = 'none';
      popupFooter.style.display = 'none';
      successEl.style.display = 'block';

      // GTM event
      window.dataLayer = window.dataLayer || [];
      window.dataLayer.push({
        event: 'promo_signup_success',
        form_name: 'promo_popup',
        page_path: location.pathname,
      });

      if (typeof trackEvent === 'function') {
        trackEvent('promo_popup_submitted', {
          lang: getPromoLang(),
          source: 'promo',
        });
      }

      // Auto-close after 3 seconds
      setTimeout(() => {
        localStorage.setItem(STORAGE_KEY, '1');
        overlay.classList.remove('is-visible');
        overlay.classList.add('is-hiding');
        setTimeout(() => overlay.remove(), 500);
      }, 3000);

    } catch (error) {
      console.error('Promo popup form error:', error);

      const existingErr = form.querySelector('.form-error-alert');
      if (existingErr) existingErr.remove();

      const errAlert = document.createElement('div');
      errAlert.className = 'form-error-alert';
      errAlert.setAttribute('role', 'alert');
      errAlert.textContent = error.message || t.submitError;
      errAlert.style.cssText = 'padding:0.75rem;background:#FEE2E2;border:1px solid #FCA5A5;border-radius:0.5rem;color:#991B1B;font-size:0.875rem;margin-bottom:0.75rem;text-align:center;';
      form.insertBefore(errAlert, form.firstChild);
      setTimeout(() => errAlert.remove(), 5000);
    } finally {
      ctaBtn.classList.remove('loading');
      ctaBtn.disabled = false;
    }
  });

  // Show after delay
  setTimeout(openPopup, DELAY_MS);
}

// Auto-initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initPromoPopup);
} else {
  initPromoPopup();
}
