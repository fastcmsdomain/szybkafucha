/**
 * Szybka Fucha - Landing Page JavaScript
 * Vanilla JS - no frameworks, optimized for performance
 * 
 * Features:
 * - Mobile navigation toggle
 * - Newsletter form validation & submission
 * - Smooth scroll behavior
 * - Analytics event tracking (optional)
 */

// ========================================
// Configuration
// ========================================
// Auto-detect API endpoint based on environment
const getApiEndpoint = () => {
  const hostname = window.location.hostname;
  const protocol = window.location.protocol;

  // Development (localhost)
  if (hostname === 'localhost' || hostname === '127.0.0.1') {
    return 'http://localhost:8000/api/subscribe.php';
  }

  // Production - PHP API on same domain
  return `${protocol}//${hostname}/api/subscribe.php`;
};

// ========================================
// Language Detection & i18n
// ========================================

/**
 * Detect current page language from <html lang=""> attribute
 * @returns {string} - Language code ('pl', 'en', 'uk')
 */
const getPageLanguage = () => {
  const htmlLang = document.documentElement.lang || 'pl';
  // Normalize language codes (e.g., 'en-GB' -> 'en', 'pl' -> 'pl')
  const lang = htmlLang.split('-')[0].toLowerCase();
  return ['pl', 'en', 'uk'].includes(lang) ? lang : 'pl';
};

/**
 * Multilingual error messages
 */
const MESSAGES = {
  pl: {
    nameRequired: 'Proszę podać imię i nazwisko',
    nameInvalid: 'Imię i nazwisko może zawierać tylko litery',
    emailRequired: 'Proszę podać adres e-mail',
    emailInvalid: 'Proszę podać poprawny adres e-mail',
    typeRequired: 'Proszę wybrać jedną z opcji',
    consentRequired: 'Wymagana jest zgoda na przetwarzanie danych',
    cityRequired: 'Wybierz miasto',
    submitError: 'Wystąpił błąd. Spróbuj ponownie później.',
    submitSuccess: 'Dziękujemy za zapisanie się!',
    promoPopup: {
      badge: 'OFERTA LIMITOWANA',
      title: 'Pierwsze 100 osób dostaje 2 zlecenia gratis!',
      subtitle: 'Dołącz do Szybka Fucha jako jeden z pierwszych i odbierz swój bonus powitalny.',
      dealLine1: '2 zlecenia o wartości',
      dealAmount: '20 PLN każde',
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
    },
  },
  en: {
    nameRequired: 'Please enter your name',
    nameInvalid: 'Name can only contain letters',
    emailRequired: 'Please enter your email address',
    emailInvalid: 'Please enter a valid email address',
    typeRequired: 'Please select one option',
    consentRequired: 'Consent is required',
    cityRequired: 'Please select a city',
    submitError: 'An error occurred. Please try again later.',
    submitSuccess: 'Thank you for signing up!',
    promoPopup: {
      badge: 'LIMITED OFFER',
      title: 'First 100 users get 2 free tasks!',
      subtitle: 'Join Szybka Fucha as one of the first members and claim your welcome bonus.',
      dealLine1: '2 tasks worth',
      dealAmount: '20 PLN each',
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
    },
  },
  uk: {
    nameRequired: "Будь ласка, введіть ім'я та прізвище",
    nameInvalid: "Ім'я може містити лише літери",
    emailRequired: 'Будь ласка, введіть адресу електронної пошти',
    emailInvalid: 'Будь ласка, введіть дійсну адресу електронної пошти',
    typeRequired: 'Будь ласка, виберіть один варіант',
    consentRequired: 'Потрібна згода на обробку даних',
    cityRequired: 'Виберіть місто',
    submitError: 'Сталася помилка. Спробуйте пізніше.',
    submitSuccess: 'Дякуємо за реєстрацію!',
    promoPopup: {
      badge: 'ОБМЕЖЕНА ПРОПОЗИЦІЯ',
      title: 'Перші 100 користувачів отримують 2 завдання безкоштовно!',
      subtitle: 'Приєднуйтесь до Szybka Fucha одними з перших і отримайте стартовий бонус.',
      dealLine1: '2 завдання вартістю',
      dealAmount: '20 PLN кожне',
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
    },
  },
};

/**
 * Get messages for current page language
 * @returns {Object} - Messages object for current language
 */
const getMessages = () => {
  const lang = getPageLanguage();
  return MESSAGES[lang] || MESSAGES.pl;
};

const CONFIG = {
  // API endpoint for newsletter signup (auto-detected)
  apiEndpoint: getApiEndpoint(),
  
  // Validation patterns
  patterns: {
    email: /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/,
    name: /^[a-zA-ZąćęłńóśźżĄĆĘŁŃÓŚŹŻіїєґІЇЄҐ\s-]{2,100}$/,
  },
  
  // Error messages - dynamically loaded based on page language
  get messages() {
    return getMessages();
  },
};

// ========================================
// DOM Elements - cached for performance
// ========================================
const SELECTORS = {
  mobileMenuBtn: '.mobile-menu-btn',
  mobileNav: '.mobile-nav',
  mobileNavLinks: '.mobile-nav__link',
  newsletterForm: '#newsletter-form',
  submitBtn: '#submit-btn',
  successMessage: '#success-message',
  nameInput: '#name',
  emailInput: '#email',
  userTypeInputs: 'input[name="userType"]',
  consentInput: 'input[name="consent"]',
  // Hero form selectors
  heroForm: '#hero-form',
  heroSubmitBtn: '#hero-submit-btn',
  heroSuccessMessage: '#hero-success-message',
  heroNameInput: '#hero-name',
  heroEmailInput: '#hero-email',
  heroCityInput: '#hero-city',
  heroUserTypeInputs: 'input[name="heroUserType"]',
  heroConsentInput: 'input[name="heroConsent"]',
};

// ========================================
// Mobile Navigation
// ========================================

/**
 * Initialize mobile navigation toggle functionality
 */
function initMobileNav() {
  const menuBtn = document.querySelector(SELECTORS.mobileMenuBtn);
  const mobileNav = document.querySelector(SELECTORS.mobileNav);
  
  if (!menuBtn || !mobileNav) {
    return;
  }
  
  // Toggle mobile menu
  menuBtn.addEventListener('click', () => {
    const isExpanded = menuBtn.getAttribute('aria-expanded') === 'true';
    
    menuBtn.setAttribute('aria-expanded', !isExpanded);
    mobileNav.classList.toggle('active');
    mobileNav.setAttribute('aria-hidden', isExpanded);
    
    // Prevent body scroll when menu is open
    document.body.style.overflow = isExpanded ? '' : 'hidden';
  });
  
  // Close menu when clicking on links
  const navLinks = document.querySelectorAll(SELECTORS.mobileNavLinks);
  navLinks.forEach((link) => {
    link.addEventListener('click', () => {
      menuBtn.setAttribute('aria-expanded', 'false');
      mobileNav.classList.remove('active');
      mobileNav.setAttribute('aria-hidden', 'true');
      document.body.style.overflow = '';
    });
  });
  
  // Close menu on escape key
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && mobileNav.classList.contains('active')) {
      menuBtn.setAttribute('aria-expanded', 'false');
      mobileNav.classList.remove('active');
      mobileNav.setAttribute('aria-hidden', 'true');
      document.body.style.overflow = '';
      menuBtn.focus();
    }
  });
}

// ========================================
// Form Validation
// ========================================

/**
 * Validate a single field
 * @param {HTMLElement} field - The input element to validate
 * @param {string} value - The field value
 * @param {string} type - Type of validation ('name', 'email', 'userType', 'consent')
 * @returns {Object} - { valid: boolean, message: string }
 */
function validateField(field, value, type) {
  const { patterns, messages } = CONFIG;
  
  switch (type) {
    case 'name': {
      if (!value || !value.trim()) {
        return { valid: false, message: messages.nameRequired };
      }
      if (!patterns.name.test(value.trim())) {
        return { valid: false, message: messages.nameInvalid };
      }
      return { valid: true, message: '' };
    }
    
    case 'email': {
      if (!value || !value.trim()) {
        return { valid: false, message: messages.emailRequired };
      }
      if (!patterns.email.test(value.trim())) {
        return { valid: false, message: messages.emailInvalid };
      }
      return { valid: true, message: '' };
    }
    
    case 'userType': {
      const checked = document.querySelector(`${SELECTORS.userTypeInputs}:checked`);
      if (!checked) {
        return { valid: false, message: messages.typeRequired };
      }
      return { valid: true, message: '' };
    }
    
    case 'consent': {
      if (!field.checked) {
        return { valid: false, message: messages.consentRequired };
      }
      return { valid: true, message: '' };
    }
    
    default:
      return { valid: true, message: '' };
  }
}

/**
 * Show validation error for a field
 * @param {HTMLElement} field - The input element
 * @param {string} message - Error message to display
 */
function showError(field, message) {
  const errorElement = document.getElementById(`${field.id || field.name}-error`);
  
  if (field.classList) {
    field.classList.add('error');
  }
  
  if (errorElement) {
    errorElement.textContent = message;
  }
}

/**
 * Clear validation error for a field
 * @param {HTMLElement} field - The input element
 */
function clearError(field) {
  const errorElement = document.getElementById(`${field.id || field.name}-error`);
  
  if (field.classList) {
    field.classList.remove('error');
  }
  
  if (errorElement) {
    errorElement.textContent = '';
  }
}

/**
 * Validate entire form
 * @param {HTMLFormElement} form - The form element
 * @returns {boolean} - Whether the form is valid
 */
function validateForm(form) {
  let isValid = true;
  
  // Validate name
  const nameInput = form.querySelector(SELECTORS.nameInput);
  const nameResult = validateField(nameInput, nameInput.value, 'name');
  if (!nameResult.valid) {
    showError(nameInput, nameResult.message);
    isValid = false;
  } else {
    clearError(nameInput);
  }
  
  // Validate email
  const emailInput = form.querySelector(SELECTORS.emailInput);
  const emailResult = validateField(emailInput, emailInput.value, 'email');
  if (!emailResult.valid) {
    showError(emailInput, emailResult.message);
    isValid = false;
  } else {
    clearError(emailInput);
  }

  // Validate user type
  const userTypeInputs = form.querySelectorAll(SELECTORS.userTypeInputs);
  const userTypeResult = validateField(null, null, 'userType');
  if (!userTypeResult.valid) {
    const errorElement = document.getElementById('type-error');
    if (errorElement) {
      errorElement.textContent = userTypeResult.message;
    }
    isValid = false;
  } else {
    const errorElement = document.getElementById('type-error');
    if (errorElement) {
      errorElement.textContent = '';
    }
  }
  
  // Validate consent
  const consentInput = form.querySelector(SELECTORS.consentInput);
  const consentResult = validateField(consentInput, null, 'consent');
  if (!consentResult.valid) {
    const errorElement = document.getElementById('consent-error');
    if (errorElement) {
      errorElement.textContent = consentResult.message;
    }
    isValid = false;
  } else {
    const errorElement = document.getElementById('consent-error');
    if (errorElement) {
      errorElement.textContent = '';
    }
  }
  
  return isValid;
}

// ========================================
// Form Submission
// ========================================

/**
 * Handle form submission
 * @param {Event} event - The submit event
 */
async function handleFormSubmit(event) {
  event.preventDefault();
  
  const form = event.target;
  const submitBtn = form.querySelector(SELECTORS.submitBtn);
  const successMessage = document.querySelector(SELECTORS.successMessage);
  
  // Validate form
  if (!validateForm(form)) {
    // Focus first invalid field
    const firstError = form.querySelector('.error');
    if (firstError) {
      firstError.focus();
    }
    return;
  }
  
  // Show loading state
  submitBtn.classList.add('loading');
  submitBtn.disabled = true;
  
  // Collect form data
  const formData = {
    name: form.querySelector(SELECTORS.nameInput).value.trim(),
    email: form.querySelector(SELECTORS.emailInput).value.trim(),
    userType: form.querySelector(`${SELECTORS.userTypeInputs}:checked`).value,
    consent: true,
    source: 'formularz_ulepszen_apki',
    website: (form.querySelector('input[name="website"]') || {}).value || '',
  };

  // Collect selected services
  const serviceCheckboxes = form.querySelectorAll('input[name="services[]"]:checked');
  if (serviceCheckboxes.length > 0) {
    formData.services = Array.from(serviceCheckboxes).map(cb => cb.value);
  }
  
  // Collect comments if provided
  const commentsInput = form.querySelector('textarea[name="comments"]');
  if (commentsInput && commentsInput.value.trim()) {
    formData.comments = commentsInput.value.trim();
  }
  
  try {
    // Call backend API
    const response = await fetch(CONFIG.apiEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(formData),
    });
    
    // Check if response is JSON before parsing
    const contentType = response.headers.get('content-type');
    let result;
    
    if (contentType && contentType.includes('application/json')) {
      result = await response.json();
    } else {
      // If not JSON, get text for error message
      const text = await response.text();
      console.error('Non-JSON response:', text.substring(0, 200));
      throw new Error('Serwer zwrócił nieprawidłową odpowiedź. Sprawdź konfigurację API.');
    }
    
    if (!response.ok) {
      throw new Error(result.message || `Błąd serwera: ${response.status}`);
    }
    
    // Log for debugging
    console.log('Newsletter signup successful:', result);
    
    // Push event to Google Tag Manager dataLayer
    window.dataLayer = window.dataLayer || [];
    window.dataLayer.push({
      event: 'newsletter_signup_success',
      form_name: 'newsletter',
      page_path: location.pathname,
      user_type: formData.userType,
    });
    
    // Show success message
    form.style.display = 'none';
    if (successMessage) {
      successMessage.hidden = false;
    }
    
    // Track conversion (if analytics is available)
    trackEvent('newsletter_signup', {
      user_type: formData.userType,
      source: 'landing_page',
    });
    
  } catch (error) {
    console.error('Form submission error:', error);
    
    // Show error message
    const errorAlert = document.createElement('div');
    errorAlert.className = 'form-error-alert';
    errorAlert.setAttribute('role', 'alert');
    errorAlert.textContent = error.message || CONFIG.messages.submitError;
    errorAlert.style.cssText = `
      padding: 1rem;
      background: #FEE2E2;
      color: #DC2626;
      border-radius: 0.5rem;
      margin-bottom: 1rem;
      text-align: center;
    `;
    
    const existingAlert = form.querySelector('.form-error-alert');
    if (existingAlert) {
      existingAlert.remove();
    }
    
    form.insertBefore(errorAlert, form.firstChild);
    
    // Remove alert after 5 seconds
    setTimeout(() => {
      errorAlert.remove();
    }, 5000);
    
  } finally {
    // Reset loading state
    submitBtn.classList.remove('loading');
    submitBtn.disabled = false;
  }
}

/**
 * Inject honeypot field into a form for bot protection.
 * Bots auto-fill all visible fields; real users never see this one.
 * @param {HTMLFormElement} form
 */
function injectHoneypot(form) {
  const hp = document.createElement('div');
  hp.className = 'form-field-website';
  hp.setAttribute('aria-hidden', 'true');
  hp.innerHTML = '<label for="website-' + form.id + '">Website</label><input type="text" id="website-' + form.id + '" name="website" tabindex="-1" autocomplete="off">';
  form.appendChild(hp);
}

/**
 * Initialize form with real-time validation
 */
function initNewsletterForm() {
  const form = document.querySelector(SELECTORS.newsletterForm);

  if (!form) {
    return;
  }

  // Inject honeypot for bot protection
  injectHoneypot(form);

  // Handle form submission
  form.addEventListener('submit', handleFormSubmit);
  
  // Real-time validation on blur
  const nameInput = form.querySelector(SELECTORS.nameInput);
  const emailInput = form.querySelector(SELECTORS.emailInput);
  
  if (nameInput) {
    nameInput.addEventListener('blur', () => {
      const result = validateField(nameInput, nameInput.value, 'name');
      if (!result.valid) {
        showError(nameInput, result.message);
      } else {
        clearError(nameInput);
      }
    });
    
    // Clear error on input
    nameInput.addEventListener('input', () => {
      clearError(nameInput);
    });
  }
  
  if (emailInput) {
    emailInput.addEventListener('blur', () => {
      const result = validateField(emailInput, emailInput.value, 'email');
      if (!result.valid) {
        showError(emailInput, result.message);
      } else {
        clearError(emailInput);
      }
    });

    // Clear error on input
    emailInput.addEventListener('input', () => {
      clearError(emailInput);
    });
  }

  // Clear radio error when selection is made
  const userTypeInputs = form.querySelectorAll(SELECTORS.userTypeInputs);
  userTypeInputs.forEach((input) => {
    input.addEventListener('change', () => {
      const errorElement = document.getElementById('type-error');
      if (errorElement) {
        errorElement.textContent = '';
      }
    });
  });
  
  // Clear consent error when checked
  const consentInput = form.querySelector(SELECTORS.consentInput);
  if (consentInput) {
    consentInput.addEventListener('change', () => {
      const errorElement = document.getElementById('consent-error');
      if (errorElement) {
        errorElement.textContent = '';
      }
    });
  }
}

/**
 * Validate hero form
 * @param {HTMLFormElement} form - The hero form element
 * @returns {boolean} - Whether the form is valid
 */
function validateHeroForm(form) {
  let isValid = true;
  
  // Validate name
  const nameInput = form.querySelector(SELECTORS.heroNameInput);
  const nameResult = validateField(nameInput, nameInput.value, 'name');
  if (!nameResult.valid) {
    showError(nameInput, nameResult.message);
    isValid = false;
  } else {
    clearError(nameInput);
  }
  
  // Validate email
  const emailInput = form.querySelector(SELECTORS.heroEmailInput);
  const emailResult = validateField(emailInput, emailInput.value, 'email');
  if (!emailResult.valid) {
    showError(emailInput, emailResult.message);
    isValid = false;
  } else {
    clearError(emailInput);
  }

  // Validate city (optional - only if city input exists on the page)
  const cityInput = form.querySelector(SELECTORS.heroCityInput);
  if (cityInput) {
    if (!cityInput.value || cityInput.value === '') {
      const errorElement = document.getElementById('hero-city-error');
      if (errorElement) {
        errorElement.textContent = CONFIG.messages.cityRequired;
      }
      isValid = false;
    } else {
      const errorElement = document.getElementById('hero-city-error');
      if (errorElement) {
        errorElement.textContent = '';
      }
    }
  }

  // Validate user type
  const checkedType = form.querySelector(`${SELECTORS.heroUserTypeInputs}:checked`);
  if (!checkedType) {
    const errorElement = document.getElementById('hero-type-error');
    if (errorElement) {
      errorElement.textContent = CONFIG.messages.typeRequired;
    }
    isValid = false;
  } else {
    const errorElement = document.getElementById('hero-type-error');
    if (errorElement) {
      errorElement.textContent = '';
    }
  }
  
  // Validate consent
  const consentInput = form.querySelector(SELECTORS.heroConsentInput);
  if (!consentInput.checked) {
    const errorElement = document.getElementById('hero-consent-error');
    if (errorElement) {
      errorElement.textContent = CONFIG.messages.consentRequired;
    }
    isValid = false;
  } else {
    const errorElement = document.getElementById('hero-consent-error');
    if (errorElement) {
      errorElement.textContent = '';
    }
  }
  
  return isValid;
}

/**
 * Handle hero form submission
 * @param {Event} event - The submit event
 */
async function handleHeroFormSubmit(event) {
  event.preventDefault();
  
  const form = event.target;
  const submitBtn = form.querySelector(SELECTORS.heroSubmitBtn);
  const successMessage = document.querySelector(SELECTORS.heroSuccessMessage);
  
  // Validate form
  if (!validateHeroForm(form)) {
    return;
  }
  
  // Show loading state
  submitBtn.classList.add('loading');
  submitBtn.disabled = true;
  
  // Collect form data
  const formData = {
    name: form.querySelector(SELECTORS.heroNameInput).value.trim(),
    email: form.querySelector(SELECTORS.heroEmailInput).value.trim(),
    userType: form.querySelector(`${SELECTORS.heroUserTypeInputs}:checked`).value,
    consent: true,
    source: 'landing_page_hero',
    website: (form.querySelector('input[name="website"]') || {}).value || '',
  };

  // Add city if present on the form
  const cityInput = form.querySelector(SELECTORS.heroCityInput);
  if (cityInput && cityInput.value) {
    formData.city = cityInput.value;
  }
  
  try {
    // Call backend API
    const response = await fetch(CONFIG.apiEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(formData),
    });
    
    // Check if response is JSON before parsing
    const contentType = response.headers.get('content-type');
    let result;
    
    if (contentType && contentType.includes('application/json')) {
      result = await response.json();
    } else {
      // If not JSON, get text for error message
      const text = await response.text();
      console.error('Non-JSON response:', text.substring(0, 200));
      throw new Error('Serwer zwrócił nieprawidłową odpowiedź. Sprawdź konfigurację API.');
    }
    
    if (!response.ok) {
      throw new Error(result.message || `Błąd serwera: ${response.status}`);
    }
    
    // Log for debugging
    console.log('Hero form signup successful:', result);
    
    // Push event to Google Tag Manager dataLayer
    window.dataLayer = window.dataLayer || [];
    window.dataLayer.push({
      event: 'newsletter_signup_success',
      form_name: 'hero',
      page_path: location.pathname,
      user_type: formData.userType,
    });
    
    // Show success message
    form.style.display = 'none';
    if (successMessage) {
      successMessage.style.display = 'flex';
    }
    
    // Track conversion
    trackEvent('newsletter_signup', {
      user_type: formData.userType,
      source: 'hero',
    });
    
  } catch (error) {
    console.error('Hero form submission error:', error);
    
    // Display error to user
    const errorAlert = document.createElement('div');
    errorAlert.className = 'form-error-alert';
    errorAlert.setAttribute('role', 'alert');
    errorAlert.textContent = error.message || 'Wystąpił błąd podczas wysyłania formularza. Spróbuj ponownie.';
    errorAlert.style.cssText = `
      padding: 0.75rem;
      background: #FEE2E2;
      border: 1px solid #FCA5A5;
      border-radius: 0.5rem;
      color: #991B1B;
      font-size: 0.875rem;
      margin-bottom: 1rem;
      text-align: center;
    `;
    
    // Remove existing error alert if any
    const existingAlert = form.querySelector('.form-error-alert');
    if (existingAlert) {
      existingAlert.remove();
    }
    
    // Insert error at the top of form
    form.insertBefore(errorAlert, form.firstChild);
    
    // Scroll to error
    errorAlert.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  } finally {
    submitBtn.classList.remove('loading');
    submitBtn.disabled = false;
  }
}

/**
 * Initialize hero form
 */
function initHeroForm() {
  const form = document.querySelector(SELECTORS.heroForm);

  if (!form) {
    return;
  }

  // Inject honeypot for bot protection
  injectHoneypot(form);

  // Handle form submission
  form.addEventListener('submit', handleHeroFormSubmit);
  
  // Real-time validation
  const nameInput = form.querySelector(SELECTORS.heroNameInput);
  const emailInput = form.querySelector(SELECTORS.heroEmailInput);
  
  if (nameInput) {
    nameInput.addEventListener('blur', () => {
      const result = validateField(nameInput, nameInput.value, 'name');
      if (!result.valid) {
        showError(nameInput, result.message);
      } else {
        clearError(nameInput);
      }
    });
    nameInput.addEventListener('input', () => clearError(nameInput));
  }
  
  if (emailInput) {
    emailInput.addEventListener('blur', () => {
      const result = validateField(emailInput, emailInput.value, 'email');
      if (!result.valid) {
        showError(emailInput, result.message);
      } else {
        clearError(emailInput);
      }
    });
    emailInput.addEventListener('input', () => clearError(emailInput));
  }

  // City dropdown validation
  const cityInput = form.querySelector(SELECTORS.heroCityInput);
  if (cityInput) {
    cityInput.addEventListener('change', () => {
      const errorElement = document.getElementById('hero-city-error');
      if (errorElement) {
        errorElement.textContent = '';
      }
    });
  }

  // Clear errors on interaction and update visual state
  const userTypeInputs = form.querySelectorAll(SELECTORS.heroUserTypeInputs);
  userTypeInputs.forEach((input) => {
    input.addEventListener('change', () => {
      const errorElement = document.getElementById('hero-type-error');
      if (errorElement) {
        errorElement.textContent = '';
      }
      
      // Update visual state for radio buttons (border color)
      const allRadioOptions = form.querySelectorAll('.radio-option--compact');
      allRadioOptions.forEach(option => {
        option.classList.remove('radio-option--checked');
      });
      
      // Add checked class to selected option
      const selectedOption = input.closest('.radio-option--compact');
      if (selectedOption) {
        selectedOption.classList.add('radio-option--checked');
      }
    });
    
    // Set initial state if radio is already checked
    if (input.checked) {
      const selectedOption = input.closest('.radio-option--compact');
      if (selectedOption) {
        selectedOption.classList.add('radio-option--checked');
      }
    }
  });
  
  const consentInput = form.querySelector(SELECTORS.heroConsentInput);
  if (consentInput) {
    consentInput.addEventListener('change', () => {
      const errorElement = document.getElementById('hero-consent-error');
      if (errorElement) {
        errorElement.textContent = '';
      }
    });
  }
}

// ========================================
// Analytics (Optional)
// ========================================

/**
 * Track analytics events
 * @param {string} eventName - Name of the event
 * @param {Object} eventData - Event data
 */
function trackEvent(eventName, eventData = {}) {
  // Google Analytics 4
  if (typeof gtag === 'function') {
    gtag('event', eventName, eventData);
  }
  
  // Facebook Pixel
  if (typeof fbq === 'function') {
    fbq('trackCustom', eventName, eventData);
  }
  
  // Console log for debugging
  console.log(`[Analytics] ${eventName}:`, eventData);
}

// ========================================
// Smooth Scroll
// ========================================

/**
 * Initialize smooth scroll for anchor links
 */
function initSmoothScroll() {
  document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
    anchor.addEventListener('click', function handleClick(event) {
      const targetId = this.getAttribute('href');
      
      if (targetId === '#') {
        return;
      }
      
      // Special handling for "Zapisz się" links - scroll to Hero form and focus first input
      if (targetId === '#zapisz-sie') {
        event.preventDefault();
        const heroForm = document.getElementById('hero-form');
        const heroNameInput = document.getElementById('hero-name');
        
        if (heroForm && heroNameInput) {
          // Calculate offset for fixed header
          const headerHeight = document.querySelector('.header')?.offsetHeight || 0;
          const heroFormPosition = heroForm.getBoundingClientRect().top + window.pageYOffset - headerHeight - 20;
          
          window.scrollTo({
            top: heroFormPosition,
            behavior: 'smooth',
          });
          
          // Set focus on first input after scroll animation
          setTimeout(() => {
            heroNameInput.focus();
          }, 500); // Wait for smooth scroll to complete
          
          // Track navigation event
          trackEvent('navigation', {
            target: 'hero_form',
            source: 'cta_button',
          });
          
          return;
        }
      }
      
      // Special handling for newsletter form anchor - scroll to newsletter form and focus first input
      if (targetId === '#newsletter-form') {
        event.preventDefault();
        const newsletterForm = document.getElementById('newsletter-form');
        const newsletterNameInput = document.getElementById('name');
        
        if (newsletterForm && newsletterNameInput) {
          // Calculate offset for fixed header
          const headerHeight = document.querySelector('.header')?.offsetHeight || 0;
          const newsletterFormPosition = newsletterForm.getBoundingClientRect().top + window.pageYOffset - headerHeight - 20;
          
          window.scrollTo({
            top: newsletterFormPosition,
            behavior: 'smooth',
          });
          
          // Set focus on first input after scroll animation
          setTimeout(() => {
            newsletterNameInput.focus();
          }, 500); // Wait for smooth scroll to complete
          
          // Track navigation event
          trackEvent('navigation', {
            target: 'newsletter_form',
            source: 'cta_button',
          });
          
          return;
        }
      }
      
      const targetElement = document.querySelector(targetId);
      
      if (targetElement) {
        event.preventDefault();
        
        // Calculate offset for fixed header
        const headerHeight = document.querySelector('.header')?.offsetHeight || 0;
        const targetPosition = targetElement.getBoundingClientRect().top + window.pageYOffset - headerHeight - 20;
        
        window.scrollTo({
          top: targetPosition,
          behavior: 'smooth',
        });
        
        // Update focus for accessibility
        targetElement.focus({ preventScroll: true });
        
        // Track navigation event
        trackEvent('navigation', {
          target: targetId,
        });
      }
    });
  });
}

// ========================================
// Header Scroll Effect
// ========================================

/**
 * Initialize header background change on scroll
 */
function initHeaderScroll() {
  const header = document.querySelector('.header');
  
  if (!header) {
    return;
  }
  
  let lastScrollY = 0;
  let ticking = false;
  
  const updateHeader = () => {
    const scrollY = window.scrollY;
    
    if (scrollY > 50) {
      header.style.boxShadow = '0 2px 10px rgba(0,0,0,0.1)';
    } else {
      header.style.boxShadow = 'none';
    }
    
    lastScrollY = scrollY;
    ticking = false;
  };
  
  window.addEventListener('scroll', () => {
    if (!ticking) {
      window.requestAnimationFrame(updateHeader);
      ticking = true;
    }
  }, { passive: true });
}

// ========================================
// FAQ Accordion
// ========================================

/**
 * Initialize FAQ accordion functionality
 * Note: Using native <details> element, so this is mostly for analytics
 */
function initFAQ() {
  const faqItems = document.querySelectorAll('.faq-item');
  
  faqItems.forEach((item) => {
    item.addEventListener('toggle', () => {
      if (item.open) {
        const question = item.querySelector('.faq-question span')?.textContent;
        trackEvent('faq_opened', {
          question: question,
        });
      }
    });
  });
}

// ========================================
// Promo Popup
// ========================================

/**
 * Initialize promotional popup banner.
 * Shows after 5 seconds, collects name + email for promo list.
 * Remembers dismissal via localStorage.
 */
function initPromoPopup() {
  const STORAGE_KEY = 'sf_promo_dismissed';
  const DELAY_MS = 5000;

  // Don't show if already dismissed
  if (localStorage.getItem(STORAGE_KEY)) {
    return;
  }

  const t = getMessages().promoPopup;
  if (!t) return;

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
    // Fallback if transitionend doesn't fire
    setTimeout(onEnd, 500);
    localStorage.setItem(STORAGE_KEY, '1');
    trackEvent('promo_popup_dismissed', { lang: getPageLanguage() });
  }

  function openPopup() {
    // Force reflow
    overlay.getBoundingClientRect();
    overlay.classList.add('is-visible');
    const nameInput = overlay.querySelector('#promo-name');
    if (nameInput) nameInput.focus();
    trackEvent('promo_popup_shown', { lang: getPageLanguage() });
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
    const msgs = getMessages();

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
      err.textContent = msgs.nameRequired;
      nameInput.parentNode.appendChild(err);
      valid = false;
    }

    // Validate email
    if (!emailInput.value.trim() || !CONFIG.patterns.email.test(emailInput.value.trim())) {
      emailInput.classList.add('error');
      const err = document.createElement('div');
      err.className = 'promo-popup__form-error';
      err.textContent = emailInput.value.trim() ? msgs.emailInvalid : msgs.emailRequired;
      emailInput.parentNode.appendChild(err);
      valid = false;
    }

    // Validate consent
    if (!consentInput.checked) {
      const err = document.createElement('div');
      err.className = 'promo-popup__form-error';
      err.textContent = msgs.consentRequired;
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
      const response = await fetch(CONFIG.apiEndpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      const contentType = response.headers.get('content-type');
      let result;

      if (contentType && contentType.includes('application/json')) {
        result = await response.json();
      } else {
        throw new Error(msgs.submitError);
      }

      if (!response.ok) {
        throw new Error(result.message || msgs.submitError);
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

      trackEvent('promo_popup_submitted', {
        lang: getPageLanguage(),
        source: 'promo',
      });

      // Auto-close after 3 seconds
      setTimeout(() => {
        localStorage.setItem(STORAGE_KEY, '1');
        overlay.classList.remove('is-visible');
        overlay.classList.add('is-hiding');
        setTimeout(() => overlay.remove(), 500);
      }, 3000);

    } catch (error) {
      console.error('Promo popup form error:', error);

      // Show error inline
      const existingErr = form.querySelector('.form-error-alert');
      if (existingErr) existingErr.remove();

      const errAlert = document.createElement('div');
      errAlert.className = 'form-error-alert';
      errAlert.setAttribute('role', 'alert');
      errAlert.textContent = error.message || msgs.submitError;
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

// ========================================
// Initialize App
// ========================================

/**
 * Initialize all functionality when DOM is ready
 */
function init() {
  initMobileNav();
  initNewsletterForm();
  initHeroForm();
  initSmoothScroll();
  initHeaderScroll();
  initFAQ();
  initFeatureSwitcher();
  initPromoPopup();

  // Track page view
  trackEvent('page_view', {
    page: 'landing',
  });

  console.log('🚀 Szybka Fucha Landing Page initialized');
  console.log('📡 API Endpoint:', CONFIG.apiEndpoint);
}

// ========================================
// Feature Switcher for Our App Section
// ========================================
/**
 * Initializes the feature switcher for the Our App section
 * Links feature list items to phone simulations
 */
function initFeatureSwitcher() {
  const featureItems = document.querySelectorAll('.our-app__feature-item[data-feature]');
  const visualContainers = document.querySelectorAll('.our-app__visual[data-feature]');
  
  if (featureItems.length === 0 || visualContainers.length === 0) {
    return;
  }
  
  featureItems.forEach(item => {
    item.addEventListener('click', function() {
      const featureId = this.getAttribute('data-feature');
      
      // Update active feature item
      featureItems.forEach(fi => {
        fi.classList.remove('our-app__feature-item--active');
      });
      this.classList.add('our-app__feature-item--active');
      
      // Update active visual container
      visualContainers.forEach(vc => {
        const vcFeatureId = vc.getAttribute('data-feature');
        if (vcFeatureId === featureId) {
          vc.classList.add('our-app__visual--active');
        } else {
          vc.classList.remove('our-app__visual--active');
        }
      });
      
      // Track feature view
      trackEvent('feature_view', {
        feature_id: featureId,
        feature_name: this.querySelector('.feature-text strong')?.textContent || '',
      });
    });
  });
}

// Run when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
