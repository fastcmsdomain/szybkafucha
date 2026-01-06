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
    return 'http://localhost:3000/api/v1/newsletter/subscribe';
  }
  
  // Production - use same domain with /api path, or configure custom API domain
  // Option 1: Same domain (recommended for simple setup)
  // return `${protocol}//${hostname}/api/v1/newsletter/subscribe`;
  
  // Option 2: Custom API subdomain (recommended for production)
  // Replace 'szybkafucha.pl' with your actual domain
  const apiDomain = hostname.replace('www.', 'api.'); // www.szybkafucha.pl -> api.szybkafucha.pl
  return `${protocol}//${apiDomain}/api/v1/newsletter/subscribe`;
};

const CONFIG = {
  // API endpoint for newsletter signup (auto-detected)
  apiEndpoint: getApiEndpoint(),
  
  // Validation patterns
  patterns: {
    email: /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/,
    name: /^[a-zA-ZąćęłńóśźżĄĆĘŁŃÓŚŹŻ\s-]{2,100}$/,
  },
  
  // Error messages in Polish
  messages: {
    nameRequired: 'Proszę podać imię i nazwisko',
    nameInvalid: 'Imię i nazwisko może zawierać tylko litery',
    emailRequired: 'Proszę podać adres e-mail',
    emailInvalid: 'Proszę podać poprawny adres e-mail',
    typeRequired: 'Proszę wybrać jedną z opcji',
    consentRequired: 'Wymagana jest zgoda na przetwarzanie danych',
    submitError: 'Wystąpił błąd. Spróbuj ponownie później.',
    submitSuccess: 'Dziękujemy za zapisanie się!',
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
    source: 'landing_page',
  };
  
  try {
    // Call backend API
    const response = await fetch(CONFIG.apiEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(formData),
    });
    
    const result = await response.json();
    
    if (!response.ok) {
      throw new Error(result.message || 'Network response was not ok');
    }
    
    // Log for debugging
    console.log('Newsletter signup successful:', result);
    
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
 * Initialize form with real-time validation
 */
function initNewsletterForm() {
  const form = document.querySelector(SELECTORS.newsletterForm);
  
  if (!form) {
    return;
  }
  
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
  };
  
  try {
    // Call backend API
    const response = await fetch(CONFIG.apiEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(formData),
    });
    
    const result = await response.json();
    
    if (!response.ok) {
      throw new Error(result.message || 'Network response was not ok');
    }
    
    // Log for debugging
    console.log('Hero form signup successful:', result);
    
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
  
  // Clear errors on interaction
  const userTypeInputs = form.querySelectorAll(SELECTORS.heroUserTypeInputs);
  userTypeInputs.forEach((input) => {
    input.addEventListener('change', () => {
      const errorElement = document.getElementById('hero-type-error');
      if (errorElement) {
        errorElement.textContent = '';
      }
    });
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
  
  // Track page view
  trackEvent('page_view', {
    page: 'landing',
  });
  
  console.log('🚀 Szybka Fucha Landing Page initialized');
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
