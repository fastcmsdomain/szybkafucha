# Skill: Creating New Components for Szybka Fucha

**Purpose**: Guide for creating new sections/components for the Szybka Fucha landing page (`index.html`)

**When to use**: When adding new sections, features, or components to the landing page

---

## Overview

The landing page (`index.html`) is a static HTML5 page with vanilla CSS and JavaScript. It follows a mobile-first, responsive design with WCAG 2.2 accessibility compliance. All components must maintain consistency across three language versions (Polish, English, Ukrainian).

## Component Structure Pattern

Every new section should follow this standard structure:

```html
<!-- Section Name -->
<section id="section-id" class="section-class" aria-labelledby="section-heading">
  <div class="container">
    <!-- Optional: Section Header -->
    <div class="section-header">
      <span class="section-tag">Optional Tag</span>
      <h2 id="section-heading" class="section-title">
        Section Title
        <span class="gradient-text">Highlighted Text</span>
      </h2>
      <p class="section-text">Section description text</p>
    </div>
    
    <!-- Section Content -->
    <div class="section-content">
      <!-- Your component content here -->
    </div>
  </div>
</section>
```

## Naming Conventions

### HTML IDs and Classes

**Section IDs**: Use kebab-case, descriptive, unique
- ✅ Good: `id="how-it-works"`, `id="newsletter"`, `id="for-who"`
- ❌ Bad: `id="section1"`, `id="content"`, `id="new"`

**CSS Classes**: Use BEM-like naming with component prefix
- ✅ Good: `.hero__title`, `.faq-item`, `.audience-card__content`
- ❌ Bad: `.title`, `.card`, `.content`

**Class Naming Pattern**:
```
.component-name
.component-name__element
.component-name--modifier
.component-name__element--modifier
```

**Examples from existing code**:
- `.hero` - Main component
- `.hero__title` - Element within hero
- `.hero__title-line` - Nested element
- `.btn--primary` - Modifier variant
- `.form-group--compact` - Modifier variant

### Section Class Names

Use semantic, descriptive names:
- `.hero` - Hero/landing section
- `.how-it-works` - Process explanation
- `.for-who` - Target audience
- `.our-app` - App features showcase
- `.signup` - Newsletter/form section
- `.faq` - FAQ accordion
- `.final-cta` - Call-to-action section

## Standard Section Components

### 1. Section Header (Optional)

Used for sections that need a title, subtitle, and optional tag:

```html
<div class="section-header">
  <span class="section-tag">Optional Tag Text</span>
  <h2 id="section-heading" class="section-title">
    Main Title
    <span class="gradient-text">Highlighted Part</span>
  </h2>
  <p class="section-text">Description text here</p>
</div>
```

**Variants**:
- `.section-tag` - Small tag above title
- `.section-tag--light` - Light variant for dark backgrounds
- `.section-subtitle` - Alternative to tag (e.g., "Proste jak 1-2-3")
- `.section-title` - Main heading (h2)
- `.section-text` - Description paragraph

### 2. Container

All sections must wrap content in `.container`:

```html
<div class="container">
  <!-- Section content -->
</div>
```

The container class provides:
- Max-width constraints
- Horizontal padding
- Responsive breakpoints

### 3. Buttons

Use standard button classes:

```html
<!-- Primary CTA -->
<a href="#target" class="btn btn--primary btn--large">
  Button Text
  <svg width="20" height="20" viewBox="0 0 20 20" fill="none" aria-hidden="true">
    <!-- Icon SVG -->
  </svg>
</a>

<!-- Secondary/Ghost -->
<a href="#target" class="btn btn--ghost">Button Text</a>

<!-- Full Width -->
<button type="submit" class="btn btn--primary btn--full">Submit</button>
```

**Button Variants**:
- `.btn--primary` - Primary action (red/pink)
- `.btn--ghost` - Secondary/outline style
- `.btn--large` - Larger size
- `.btn--medium` - Medium size (default)
- `.btn--full` - Full width
- `.gradient-button` - Gradient background variant

### 4. Cards

Card components follow this pattern:

```html
<article class="card-class">
  <div class="card-class__image">
    <!-- Image or placeholder -->
  </div>
  <div class="card-class__content">
    <span class="card-class__tag">Tag</span>
    <h3 class="card-class__title">Card Title</h3>
    <p class="card-class__desc">Description</p>
    <ul class="card-class__list">
      <li>Feature item</li>
    </ul>
    <a href="#target" class="btn btn--primary card-class__cta">Action</a>
  </div>
</article>
```

**Example**: `.audience-card`, `.audience-card--client`, `.audience-card--contractor`

## Accessibility Requirements

### Required Attributes

1. **Section ARIA Labels**:
```html
<section id="section-id" class="section-class" aria-labelledby="section-heading">
```

2. **Headings Hierarchy**:
- Use proper heading levels (h1 → h2 → h3)
- Each section should have a unique heading ID
- Never skip heading levels

3. **Form Labels**:
```html
<label for="input-id" class="form-label">Label Text</label>
<input 
  type="text" 
  id="input-id" 
  name="inputName"
  class="form-input"
  required
  aria-describedby="input-id-error"
>
<span id="input-id-error" class="form-error" role="alert"></span>
```

4. **Icon Accessibility**:
```html
<svg width="20" height="20" viewBox="0 0 20 20" fill="none" aria-hidden="true">
  <!-- Icon content -->
</svg>
```

5. **Skip Links** (already in header):
```html
<a href="#main" class="skip-link">Przejdź do głównej treści</a>
```

6. **Navigation ARIA**:
```html
<nav class="header__nav" aria-label="Główna nawigacja">
```

## CSS Styling Guidelines

### Using CSS Variables

Always use CSS custom properties from `:root`:

```css
/* Colors */
color: var(--color-primary);
background: var(--color-gray-50);

/* Typography */
font-size: var(--font-size-lg);
line-height: var(--line-height-normal);

/* Spacing */
padding: var(--space-6) var(--space-4);
margin-bottom: var(--space-8);

/* Border Radius */
border-radius: var(--radius-lg);

/* Shadows */
box-shadow: var(--shadow-md);

/* Transitions */
transition: all var(--transition-base);
```

### Component CSS Structure

When adding new component styles to `styles.css`:

1. **Add to appropriate section** (Components or Sections)
2. **Follow BEM naming**:
```css
/* Component */
.component-name {
  /* Base styles */
}

/* Element */
.component-name__element {
  /* Element styles */
}

/* Modifier */
.component-name--modifier {
  /* Variant styles */
}

/* Element with modifier */
.component-name__element--modifier {
  /* Element variant */
}
```

3. **Mobile-first approach**:
```css
.component-name {
  /* Mobile styles (default) */
  padding: var(--space-4);
}

@media (min-width: 768px) {
  .component-name {
    /* Tablet styles */
    padding: var(--space-6);
  }
}

@media (min-width: 1024px) {
  .component-name {
    /* Desktop styles */
    padding: var(--space-8);
  }
}
```

4. **Use existing utility classes** when possible:
- `.container` - Content wrapper
- `.section-header` - Section title block
- `.btn` - Button styles
- `.form-group` - Form field wrapper
- `.gradient-text` - Gradient text effect

## Adding a New Section: Step-by-Step

### Step 1: Plan the Section

1. Determine section purpose and content
2. Choose appropriate ID (kebab-case, descriptive)
3. Decide on section structure (header, cards, list, etc.)
4. Identify required CSS classes

### Step 2: Add HTML to index.html

1. Find appropriate location in `<main id="main">` section
2. Add section with proper structure:
```html
<!-- New Section -->
<section id="new-section" class="new-section" aria-labelledby="new-section-heading">
  <div class="container">
    <!-- Content -->
  </div>
</section>
```

3. Add navigation link if needed:
```html
<a href="#new-section" class="nav-link">Section Name</a>
```

### Step 3: Add CSS to styles.css

1. Locate appropriate section in `styles.css` (Components or Sections)
2. Add component styles following BEM convention
3. Use CSS variables for consistency
4. Implement mobile-first responsive design
5. Test at multiple breakpoints

### Step 4: Add JavaScript (if needed)

1. Add functionality to `script.js` if component needs interactivity
2. Use event delegation for dynamic content
3. Follow existing patterns (form validation, smooth scroll, etc.)

### Step 5: Update All Language Versions

1. **Polish** (`index.html`) - Source of truth
2. **English** (`en/index.html`) - Translate all text
3. **Ukrainian** (`ua/index.html`) - Translate all text

**Important**: Maintain identical HTML structure and CSS classes across all versions. Only translate:
- Text content
- Meta tags
- ARIA labels (if language-specific)
- Form labels and placeholders

### Step 6: Test

1. **Visual Testing**:
   - Desktop (1920px, 1440px, 1280px)
   - Tablet (768px, 1024px)
   - Mobile (375px, 414px)

2. **Accessibility Testing**:
   - Keyboard navigation
   - Screen reader compatibility
   - Color contrast (WCAG AA minimum)
   - Focus indicators

3. **Cross-browser Testing**:
   - Chrome/Edge (latest)
   - Firefox (latest)
   - Safari (latest)

4. **Language Version Testing**:
   - Verify all three versions render correctly
   - Check language switcher links
   - Confirm translations are complete

## Common Component Patterns

### Feature List

```html
<ul class="feature-list">
  <li class="feature-item">
    <svg class="feature-icon" aria-hidden="true">...</svg>
    <div class="feature-text">
      <strong>Feature Title</strong>
      <span>Feature description</span>
    </div>
  </li>
</ul>
```

### Step-by-Step Process

```html
<div class="steps">
  <article class="step">
    <div class="step__number">1</div>
    <h3 class="step__title">Step Title</h3>
    <p class="step__desc">Step description</p>
  </article>
</div>
```

### FAQ Accordion

```html
<div class="faq-list">
  <details class="faq-item">
    <summary class="faq-question">
      <span>Question Text</span>
      <svg class="faq-icon" aria-hidden="true">...</svg>
    </summary>
    <div class="faq-answer">
      <p>Answer text</p>
    </div>
  </details>
</div>
```

### Form Groups

```html
<div class="form-group">
  <label for="field-id" class="form-label">Label</label>
  <input 
    type="text" 
    id="field-id" 
    name="fieldName"
    class="form-input"
    required
    aria-describedby="field-id-error"
  >
  <span id="field-id-error" class="form-error" role="alert"></span>
</div>
```

## Best Practices

### DO ✅

1. **Use semantic HTML5 elements**: `<section>`, `<article>`, `<nav>`, `<header>`, `<footer>`
2. **Follow BEM naming convention** for CSS classes
3. **Use CSS variables** for colors, spacing, typography
4. **Implement mobile-first** responsive design
5. **Add proper ARIA labels** for accessibility
6. **Maintain consistent structure** across language versions
7. **Test on multiple devices** and browsers
8. **Use existing utility classes** when possible
9. **Keep JavaScript minimal** - prefer CSS solutions
10. **Comment complex CSS** for future maintainers

### DON'T ❌

1. **Don't use inline styles** - use CSS classes
2. **Don't skip heading levels** (h1 → h2 → h3)
3. **Don't use generic IDs** like "section1" or "content"
4. **Don't hardcode colors** - use CSS variables
5. **Don't forget accessibility** attributes
6. **Don't break responsive design** with fixed widths
7. **Don't add JavaScript frameworks** - keep it vanilla
8. **Don't forget to update** all language versions
9. **Don't use non-semantic divs** when semantic elements exist
10. **Don't ignore mobile experience** - test on real devices

## Integration with Navigation

When adding a new section, update navigation:

1. **Header Navigation** (desktop):
```html
<nav class="header__nav" aria-label="Główna nawigacja">
  <a href="#new-section" class="nav-link">Section Name</a>
</nav>
```

2. **Mobile Navigation**:
```html
<div class="mobile-nav" aria-hidden="true">
  <nav aria-label="Menu mobilne">
    <a href="#new-section" class="mobile-nav__link">Section Name</a>
  </nav>
</div>
```

3. **Footer Navigation** (if appropriate):
```html
<div class="footer__col">
  <h4>Category</h4>
  <ul>
    <li><a href="#new-section">Section Name</a></li>
  </ul>
</div>
```

## Example: Complete New Section

Here's a complete example of adding a new "Testimonials" section:

### HTML (index.html)

```html
<!-- Testimonials Section -->
<section id="testimonials" class="testimonials" aria-labelledby="testimonials-heading">
  <div class="container">
    <div class="section-header">
      <span class="section-tag">Zaufanie użytkowników</span>
      <h2 id="testimonials-heading" class="section-title">
        Co mówią o nas
        <span class="gradient-text">nasi użytkownicy</span>
      </h2>
      <p class="section-text">Poznaj opinie osób, które już korzystają z Szybkiej Fuchy</p>
    </div>
    
    <div class="testimonials__grid">
      <article class="testimonial-card">
        <div class="testimonial-card__header">
          <img src="assets/testimonial-1.jpg" alt="Anna K." class="testimonial-card__avatar">
          <div class="testimonial-card__info">
            <h3 class="testimonial-card__name">Anna K.</h3>
            <span class="testimonial-card__rating">★★★★★</span>
          </div>
        </div>
        <p class="testimonial-card__text">"Szybka Fucha uratowała mi weekend! Znalazłam pomocnika w 10 minut."</p>
        <span class="testimonial-card__date">2 dni temu</span>
      </article>
      
      <!-- More testimonial cards -->
    </div>
  </div>
</section>
```

### CSS (styles.css)

Add to Sections section:

```css
/* ========================================
   Testimonials Section
   ======================================== */

.testimonials {
  padding: var(--space-16) 0;
  background: var(--color-gray-50);
}

.testimonials__grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--space-6);
  margin-top: var(--space-12);
}

@media (min-width: 768px) {
  .testimonials__grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (min-width: 1024px) {
  .testimonials__grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

.testimonial-card {
  background: var(--color-white);
  padding: var(--space-6);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-md);
  transition: transform var(--transition-base), box-shadow var(--transition-base);
}

.testimonial-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-lg);
}

.testimonial-card__header {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  margin-bottom: var(--space-4);
}

.testimonial-card__avatar {
  width: 48px;
  height: 48px;
  border-radius: var(--radius-full);
  object-fit: cover;
}

.testimonial-card__info {
  flex: 1;
}

.testimonial-card__name {
  font-size: var(--font-size-lg);
  font-weight: 600;
  color: var(--color-gray-900);
  margin-bottom: var(--space-1);
}

.testimonial-card__rating {
  color: var(--color-warning);
  font-size: var(--font-size-sm);
}

.testimonial-card__text {
  font-size: var(--font-size-base);
  line-height: var(--line-height-relaxed);
  color: var(--color-gray-700);
  margin-bottom: var(--space-4);
}

.testimonial-card__date {
  font-size: var(--font-size-sm);
  color: var(--color-gray-500);
}
```

### Navigation Update

Add to header nav:
```html
<a href="#testimonials" class="nav-link">Opinie</a>
```

## Checklist for New Components

Before considering a component complete:

- [ ] HTML structure follows standard pattern
- [ ] Section has unique, descriptive ID
- [ ] Proper ARIA labels and accessibility attributes
- [ ] CSS uses BEM naming convention
- [ ] CSS uses CSS variables (no hardcoded values)
- [ ] Mobile-first responsive design implemented
- [ ] Tested on mobile, tablet, and desktop
- [ ] Navigation links added (if needed)
- [ ] All three language versions updated
- [ ] Keyboard navigation works
- [ ] Screen reader compatible
- [ ] Color contrast meets WCAG AA
- [ ] No console errors
- [ ] Performance optimized (no layout shifts)
- [ ] Cross-browser tested

## Related Documentation

- **CLAUDE.md** - Main project documentation
- **styles.css** - Complete stylesheet reference
- **script.js** - JavaScript functionality
- **ARCHITECTURE.md** - Project architecture overview

## Quick Reference

### Common CSS Classes

- `.container` - Content wrapper
- `.section-header` - Section title block
- `.section-title` - Main heading
- `.section-text` - Description text
- `.section-tag` - Small tag above title
- `.btn` - Button base class
- `.btn--primary` - Primary button
- `.btn--ghost` - Secondary button
- `.gradient-text` - Gradient text effect
- `.form-group` - Form field wrapper
- `.form-label` - Form label
- `.form-input` - Form input
- `.form-error` - Error message

### Common CSS Variables

- Colors: `var(--color-primary)`, `var(--color-gray-50)`, etc.
- Spacing: `var(--space-4)`, `var(--space-8)`, etc.
- Typography: `var(--font-size-lg)`, `var(--line-height-normal)`
- Border radius: `var(--radius-lg)`
- Shadows: `var(--shadow-md)`
- Transitions: `var(--transition-base)`

---

**Last Updated**: 2026-01-24
**Maintained By**: Development Team
