# Skill: Following the Design System Style Guide

**Purpose**: Guide for maintaining design consistency when creating or modifying components based on the Szybka Fucha design system

**When to use**: When creating new components, modifying existing styles, or ensuring design consistency across the landing page

---

## Overview

The Szybka Fucha landing page uses a comprehensive design system defined in `styles.css`. This system ensures visual consistency, accessibility (WCAG 2.2), and responsive design across all components. **Always use CSS custom properties (variables) instead of hardcoded values.**

## Core Design Principles

1. **Mobile-First**: Design for mobile, then enhance for larger screens
2. **Accessibility First**: WCAG 2.2 AA compliance minimum
3. **Consistency**: Use design tokens (CSS variables) for all values
4. **Performance**: Minimal animations, optimized for speed
5. **Semantic HTML**: Use proper HTML5 elements
6. **Progressive Enhancement**: Base styles work everywhere, enhancements for capable browsers

---

## 1. Color System

### Primary Colors

**Always use CSS variables, never hardcode colors:**

```css
/* ✅ CORRECT - Use variables */
background: var(--color-primary);
color: var(--color-white);

/* ❌ WRONG - Hardcoded values */
background: #E94560;
color: #FFFFFF;
```

**Available Primary Colors:**
- `--color-primary`: `#E94560` - Main brand color (red/pink)
- `--color-primary-dark`: `#D13A54` - Darker variant for hover states
- `--color-primary-light`: `#FF6B7A` - Lighter variant for gradients

**Usage Guidelines:**
- Use `--color-primary` for primary CTAs, links, and brand elements
- Use `--color-primary-dark` for hover states on primary buttons
- Use `--color-primary-light` in gradients with primary color

### Secondary Colors

- `--color-secondary`: `#1A1A2E` - Dark navy for backgrounds
- `--color-secondary-light`: `#16213E` - Lighter navy variant

**Usage:** Dark sections, footer backgrounds, hero backgrounds

### Accent Colors

- `--color-accent`: `#0F3460` - Deep blue accent
- `--color-success`: `#10B981` - Green for success states
- `--color-warning`: `#F59E0B` - Amber for warnings
- `--color-error`: `#EF4444` - Red for errors

**Usage Guidelines:**
- Success: Completed states, positive feedback, verified badges
- Warning: Important notices, pending states
- Error: Form validation errors, destructive actions

### Neutral Grayscale

**Available shades (50 = lightest, 900 = darkest):**
- `--color-white`: `#FFFFFF`
- `--color-gray-50` through `--color-gray-900`

**Usage Guidelines:**
- `gray-50/100`: Light backgrounds, subtle borders
- `gray-200/300`: Borders, dividers
- `gray-400/500`: Placeholder text, disabled states
- `gray-600/700`: Secondary text, descriptions
- `gray-800/900`: Primary text, headings

**Example:**
```css
/* Background */
background: var(--color-gray-50);

/* Text */
color: var(--color-gray-700);

/* Border */
border-color: var(--color-gray-200);
```

### Color Contrast Requirements

**WCAG 2.2 AA Minimum:**
- Normal text: 4.5:1 contrast ratio
- Large text (18px+): 3:1 contrast ratio
- UI components: 3:1 contrast ratio

**Always test contrast:**
- Primary text on white: `var(--color-gray-900)` ✅
- Secondary text: `var(--color-gray-600)` ✅
- Primary button text: `var(--color-white)` on `var(--color-primary)` ✅

---

## 2. Typography System

### Font Family

**Primary Font:**
```css
font-family: var(--font-family);
/* 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif */
```

**Logo Font:**
```css
font-family: 'Nunito', var(--font-family);
/* Used only for logo text */
```

### Font Sizes

**Always use CSS variables for font sizes:**

```css
/* ✅ CORRECT */
font-size: var(--font-size-lg);

/* ❌ WRONG */
font-size: 18px;
```

**Available Sizes:**
- `--font-size-xs`: `0.75rem` (12px) - Small labels, hints
- `--font-size-sm`: `0.875rem` (14px) - Secondary text, captions
- `--font-size-base`: `1rem` (16px) - Body text (WCAG minimum)
- `--font-size-m`: `1.06rem` (18px) - Enhanced body text
- `--font-size-lg`: `1.125rem` (18px) - Large body text
- `--font-size-xl`: `1.25rem` (20px) - Small headings
- `--font-size-2xl`: `1.5rem` (24px) - Section subheadings
- `--font-size-3xl`: `1.875rem` (30px) - Section headings
- `--font-size-4xl`: `2.25rem` (36px) - Large headings
- `--font-size-5xl`: `3rem` (48px) - Hero headings (desktop)
- `--font-size-6xl`: `3.75rem` (60px) - Extra large hero (desktop)

**Usage Guidelines:**
- Body text: `var(--font-size-base)` or `var(--font-size-lg)`
- Headings: Scale from `var(--font-size-xl)` to `var(--font-size-6xl)` based on hierarchy
- Labels: `var(--font-size-sm)` or `var(--font-size-xs)`
- Small UI text: `var(--font-size-xs)`

### Line Heights

**Available Line Heights:**
- `--line-height-tight`: `1.25` - Headings, short lines
- `--line-height-normal`: `1.5` - Body text (WCAG minimum)
- `--line-height-relaxed`: `1.75` - Long-form content, descriptions

**Usage:**
```css
/* Headings */
line-height: var(--line-height-tight);

/* Body text */
line-height: var(--line-height-normal);

/* Long paragraphs */
line-height: var(--line-height-relaxed);
```

**WCAG Requirement:** Body text must have at least 1.5 line height.

### Font Weights

**Standard weights:**
- `400` - Normal (default)
- `500` - Medium (labels, secondary text)
- `600` - Semi-bold (buttons, emphasis)
- `700` - Bold (headings, strong emphasis)
- `800` - Extra-bold (hero titles, logos)

**Usage:**
```css
/* Buttons */
font-weight: 600;

/* Headings */
font-weight: 700;

/* Hero titles */
font-weight: 800;
```

### Typography Patterns

**Section Headings:**
```css
.section-title {
  font-size: var(--font-size-3xl);
  font-weight: 700;
  line-height: var(--line-height-tight);
  color: var(--color-gray-900);
}
```

**Body Text:**
```css
.body-text {
  font-size: var(--font-size-base);
  line-height: var(--line-height-normal);
  color: var(--color-gray-700);
}
```

**Gradient Text:**
```css
.gradient-text {
  background-image: url('assets/rainbow_bg.jpg');
  background-size: 100% 100%;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}
```

---

## 3. Spacing System

### Spacing Scale

**Always use CSS variables for spacing:**

```css
/* ✅ CORRECT */
padding: var(--space-6) var(--space-4);
margin-bottom: var(--space-8);

/* ❌ WRONG */
padding: 24px 16px;
margin-bottom: 32px;
```

**Available Spacing Values:**
- `--space-1`: `0.25rem` (4px) - Tight spacing
- `--space-2`: `0.5rem` (8px) - Small gaps
- `--space-3`: `0.75rem` (12px) - Compact spacing
- `--space-4`: `1rem` (16px) - Base unit
- `--space-5`: `1.25rem` (20px)
- `--space-6`: `1.5rem` (24px) - Standard spacing
- `--space-8`: `2rem` (32px) - Medium spacing
- `--space-10`: `2.5rem` (40px)
- `--space-12`: `3rem` (48px) - Large spacing
- `--space-16`: `4rem` (64px) - Section padding
- `--space-20`: `5rem` (80px)
- `--space-24`: `6rem` (96px) - Extra large spacing

### Spacing Guidelines

**Component Padding:**
- Small components: `var(--space-3)` to `var(--space-4)`
- Standard components: `var(--space-4)` to `var(--space-6)`
- Large components: `var(--space-6)` to `var(--space-8)`
- Cards: `var(--space-6)`
- Forms: `var(--space-8)`

**Section Spacing:**
- Section padding (top/bottom): `var(--space-16)`
- Element gaps: `var(--space-6)` to `var(--space-8)`
- List item spacing: `var(--space-3)` to `var(--space-4)`

**Margin Guidelines:**
- Between sections: `var(--space-16)`
- Between related elements: `var(--space-4)` to `var(--space-6)`
- Between unrelated elements: `var(--space-8)` to `var(--space-12)`

**Example:**
```css
.card {
  padding: var(--space-6);
  margin-bottom: var(--space-8);
}

.card__header {
  margin-bottom: var(--space-4);
}

.card__list {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}
```

---

## 4. Border Radius System

**Always use CSS variables:**

```css
/* ✅ CORRECT */
border-radius: var(--radius-lg);

/* ❌ WRONG */
border-radius: 12px;
```

**Available Radius Values:**
- `--radius-sm`: `0.375rem` (6px) - Small elements, badges
- `--radius-md`: `0.5rem` (8px) - Buttons, inputs
- `--radius-lg`: `0.75rem` (12px) - Cards, containers
- `--radius-xl`: `1rem` (16px) - Large cards, sections
- `--radius-2xl`: `1.5rem` (24px) - Extra large containers
- `--radius-full`: `9999px` - Pills, circles

**Usage Guidelines:**
- Buttons: `var(--radius-lg)`
- Inputs: `var(--radius-lg)`
- Cards: `var(--radius-xl)` or `var(--radius-2xl)`
- Badges/Tags: `var(--radius-full)`
- Small UI elements: `var(--radius-md)`

---

## 5. Shadow System

**Always use CSS variables:**

```css
/* ✅ CORRECT */
box-shadow: var(--shadow-md);

/* ❌ WRONG */
box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
```

**Available Shadows:**
- `--shadow-sm`: Subtle elevation (1px blur)
- `--shadow-md`: Standard elevation (4-6px blur) - **Most common**
- `--shadow-lg`: Prominent elevation (10-15px blur)
- `--shadow-xl`: Strong elevation (20-25px blur)
- `--shadow-2xl`: Maximum elevation (25-50px blur)

**Usage Guidelines:**
- Cards: `var(--shadow-md)` or `var(--shadow-lg)`
- Hover states: Increase shadow (e.g., `md` → `lg`)
- Modals/Overlays: `var(--shadow-2xl)`
- Subtle elements: `var(--shadow-sm)`

**Example:**
```css
.card {
  box-shadow: var(--shadow-md);
  transition: box-shadow var(--transition-base);
}

.card:hover {
  box-shadow: var(--shadow-lg);
}
```

---

## 6. Transition System

**Always use CSS variables for transitions:**

```css
/* ✅ CORRECT */
transition: all var(--transition-base);

/* ❌ WRONG */
transition: all 0.2s ease;
```

**Available Transitions:**
- `--transition-fast`: `150ms ease` - Quick interactions
- `--transition-base`: `200ms ease` - **Standard** (most common)
- `--transition-slow`: `300ms ease` - Smooth animations

**Usage Guidelines:**
- Hover states: `var(--transition-base)`
- Quick feedback: `var(--transition-fast)`
- Smooth animations: `var(--transition-slow)`

**Example:**
```css
.button {
  transition: background var(--transition-base), 
              transform var(--transition-base);
}

.button:hover {
  background: var(--color-primary-dark);
  transform: translateY(-2px);
}
```

**Accessibility:** Respect `prefers-reduced-motion`:
```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## 7. Component Patterns

### Buttons

**Base Button:**
```css
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
  padding: var(--space-3) var(--space-6);
  font-size: var(--font-size-base);
  font-weight: 600;
  border: none;
  border-radius: var(--radius-lg);
  cursor: pointer;
  transition: all var(--transition-base);
}
```

**Button Variants:**
- `.btn--primary` - Primary action (red background)
- `.btn--ghost` - Secondary action (outline style)
- `.btn--large` - Larger size
- `.btn--full` - Full width
- `.gradient-button` - Rainbow border effect

**Button States:**
```css
.btn:hover {
  transform: translateY(-2px);
}

.btn--primary:hover {
  background: var(--color-primary-dark);
  box-shadow: var(--shadow-lg);
}
```

### Form Inputs

**Base Input:**
```css
.form-input {
  width: 100%;
  padding: var(--space-4);
  font-size: var(--font-size-base);
  border: 2px solid var(--color-gray-200);
  border-radius: var(--radius-lg);
  background: var(--color-white);
  transition: all var(--transition-base);
}
```

**Input States:**
```css
.form-input:hover {
  border-color: var(--color-gray-300);
}

.form-input:focus {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px rgba(233, 69, 96, 0.1);
  outline: none;
}

.form-input.error {
  border-color: var(--color-error);
}
```

### Cards

**Base Card:**
```css
.card {
  background: var(--color-white);
  border-radius: var(--radius-xl);
  padding: var(--space-6);
  box-shadow: var(--shadow-md);
  transition: all var(--transition-base);
}

.card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-lg);
}
```

### Section Headers

**Standard Pattern:**
```css
.section-header {
  text-align: center;
  margin-bottom: var(--space-12);
}

.section-title {
  font-size: var(--font-size-3xl);
  margin-bottom: var(--space-4);
}

.section-text {
  font-size: var(--font-size-xl);
  color: var(--color-gray-600);
}
```

---

## 8. Responsive Design

### Mobile-First Approach

**Always start with mobile styles, then enhance:**

```css
/* Mobile (default) */
.component {
  padding: var(--space-4);
  font-size: var(--font-size-base);
}

/* Tablet (640px+) */
@media (min-width: 640px) {
  .component {
    padding: var(--space-6);
  }
}

/* Desktop (768px+) */
@media (min-width: 768px) {
  .component {
    padding: var(--space-8);
    font-size: var(--font-size-lg);
  }
}

/* Large Desktop (1024px+) */
@media (min-width: 1024px) {
  .component {
    padding: var(--space-10);
  }
}
```

### Breakpoint Guidelines

**Standard Breakpoints:**
- Mobile: `< 640px` (default styles)
- Tablet: `≥ 640px` (`@media (min-width: 640px)`)
- Desktop: `≥ 768px` (`@media (min-width: 768px)`)
- Large Desktop: `≥ 1024px` (`@media (min-width: 1024px)`)
- Extra Large: `≥ 1280px` (`@media (min-width: 1280px)`)

**Common Responsive Patterns:**

**Flex Direction:**
```css
.container {
  display: flex;
  flex-direction: column; /* Mobile */
  gap: var(--space-4);
}

@media (min-width: 768px) {
  .container {
    flex-direction: row; /* Desktop */
    gap: var(--space-8);
  }
}
```

**Grid Layouts:**
```css
.grid {
  display: grid;
  grid-template-columns: 1fr; /* Mobile: single column */
  gap: var(--space-4);
}

@media (min-width: 640px) {
  .grid {
    grid-template-columns: repeat(2, 1fr); /* Tablet: 2 columns */
  }
}

@media (min-width: 1024px) {
  .grid {
    grid-template-columns: repeat(3, 1fr); /* Desktop: 3 columns */
  }
}
```

**Typography Scaling:**
```css
.heading {
  font-size: var(--font-size-2xl); /* Mobile */
}

@media (min-width: 768px) {
  .heading {
    font-size: var(--font-size-3xl); /* Desktop */
  }
}

@media (min-width: 1024px) {
  .heading {
    font-size: var(--font-size-4xl); /* Large Desktop */
  }
}
```

---

## 9. Accessibility Requirements

### Focus States

**Always provide visible focus indicators:**

```css
:focus-visible {
  outline: 3px solid var(--color-primary);
  outline-offset: 2px;
}
```

**Custom Focus for Interactive Elements:**
```css
.button:focus-visible {
  outline: 3px solid var(--color-primary);
  outline-offset: 2px;
}
```

### Color Contrast

**Minimum Requirements:**
- Normal text: 4.5:1 contrast ratio
- Large text (18px+): 3:1 contrast ratio
- UI components: 3:1 contrast ratio

**Test combinations:**
- Primary text: `var(--color-gray-900)` on `var(--color-white)` ✅
- Secondary text: `var(--color-gray-600)` on `var(--color-white)` ✅
- Button text: `var(--color-white)` on `var(--color-primary)` ✅

### Reduced Motion

**Always respect user preferences:**

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

### Semantic HTML

**Use proper HTML elements:**
- `<section>` for page sections
- `<article>` for card content
- `<nav>` for navigation
- `<header>`, `<footer>` for page structure
- `<button>` for interactive buttons
- `<a>` for links

### ARIA Labels

**Provide ARIA labels for:**
- Icon-only buttons: `aria-label="Description"`
- Decorative icons: `aria-hidden="true"`
- Form errors: `role="alert"`
- Navigation: `aria-label="Navigation name"`

---

## 10. Special Effects

### Rainbow Border Effect

**Used for:**
- Steps in "How It Works" section
- Open FAQ items
- Feature list items
- Gradient buttons

**Implementation Pattern:**
```css
.element {
  position: relative;
  z-index: 0;
}

.element::before {
  content: '';
  position: absolute;
  inset: -1px;
  border-radius: var(--radius-xl);
  background: linear-gradient(
    90deg,
    #E94560 0%,
    #F59E0B 16.66%,
    #10B981 33.33%,
    #3B82F6 50%,
    #8B5CF6 66.66%,
    #EC4899 83.33%,
    #E94560 100%
  );
  background-size: 200% 100%;
  animation: rainbow-border 3s linear infinite;
  z-index: -2;
}

.element::after {
  content: '';
  position: absolute;
  inset: 2px;
  background: var(--color-white);
  border-radius: calc(var(--radius-xl) - 1px);
  z-index: -1;
}
```

### Gradient Text

**Implementation:**
```css
.gradient-text {
  background-image: url('assets/rainbow_bg.jpg');
  background-size: 100% 100%;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}
```

---

## 11. Animation Patterns

### Standard Animations

**Float Animation:**
```css
@keyframes float {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-10px);
  }
}

.element {
  animation: float 3s ease-in-out infinite;
}
```

**Rainbow Border Animation:**
```css
@keyframes rainbow-border {
  0% {
    background-position: 0% 50%;
  }
  100% {
    background-position: 200% 50%;
  }
}
```

**Spin Animation (Loaders):**
```css
@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
```

### Animation Guidelines

1. **Keep animations subtle** - Don't distract from content
2. **Use appropriate duration** - 200-300ms for interactions, 3s+ for ambient
3. **Respect reduced motion** - Always include fallback
4. **Performance** - Use `transform` and `opacity` for smooth animations

---

## 12. Common Patterns & Examples

### Container Pattern

```css
.container {
  width: 100%;
  max-width: 1440px;
  margin: 0 auto;
  padding: 0 var(--space-4);
}

@media (min-width: 640px) {
  .container {
    padding: 0 var(--space-6);
  }
}

@media (min-width: 1024px) {
  .container {
    padding: 0 var(--space-8);
  }
}
```

### Section Pattern

```css
.section {
  padding: var(--space-16) 0;
}

.section--dark {
  background: var(--color-secondary);
  color: var(--color-white);
}

.section--light {
  background: var(--color-gray-50);
}
```

### Card with Hover

```css
.card {
  background: var(--color-white);
  padding: var(--space-6);
  border-radius: var(--radius-xl);
  box-shadow: var(--shadow-md);
  transition: all var(--transition-base);
}

.card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-lg);
}
```

### Form Group Pattern

```css
.form-group {
  margin-bottom: var(--space-5);
}

.form-label {
  display: block;
  font-size: var(--font-size-sm);
  font-weight: 600;
  color: var(--color-gray-700);
  margin-bottom: var(--space-2);
}

.form-input {
  width: 100%;
  padding: var(--space-4);
  border: 2px solid var(--color-gray-200);
  border-radius: var(--radius-lg);
  transition: all var(--transition-base);
}

.form-input:focus {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px rgba(233, 69, 96, 0.1);
  outline: none;
}
```

---

## 13. Checklist for New Components

Before completing a component, verify:

- [ ] **Colors**: All colors use CSS variables (no hardcoded hex/rgb)
- [ ] **Typography**: Font sizes, weights, and line heights use variables
- [ ] **Spacing**: All padding/margin uses spacing variables
- [ ] **Border Radius**: Uses radius variables
- [ ] **Shadows**: Uses shadow variables
- [ ] **Transitions**: Uses transition variables
- [ ] **Responsive**: Mobile-first with proper breakpoints
- [ ] **Accessibility**: Focus states, ARIA labels, semantic HTML
- [ ] **Contrast**: Text meets WCAG AA contrast requirements
- [ ] **Reduced Motion**: Animations respect `prefers-reduced-motion`
- [ ] **Hover States**: Interactive elements have hover feedback
- [ ] **Focus States**: Keyboard navigation has visible focus indicators
- [ ] **BEM Naming**: CSS classes follow BEM convention
- [ ] **No Inline Styles**: All styles in CSS file
- [ ] **Performance**: Uses `transform`/`opacity` for animations

---

## 14. Common Mistakes to Avoid

### ❌ DON'T:

1. **Hardcode values:**
   ```css
   /* ❌ WRONG */
   padding: 24px;
   color: #E94560;
   font-size: 18px;
   ```

2. **Skip responsive design:**
   ```css
   /* ❌ WRONG - Only desktop styles */
   .component {
     display: flex;
     flex-direction: row;
   }
   ```

3. **Ignore accessibility:**
   ```css
   /* ❌ WRONG - No focus state */
   .button:focus {
     outline: none;
   }
   ```

4. **Use inline styles:**
   ```html
   <!-- ❌ WRONG -->
   <div style="padding: 20px; color: red;">
   ```

5. **Break color contrast:**
   ```css
   /* ❌ WRONG - Low contrast */
   color: var(--color-gray-400); /* On white background */
   ```

### ✅ DO:

1. **Use variables:**
   ```css
   /* ✅ CORRECT */
   padding: var(--space-6);
   color: var(--color-primary);
   font-size: var(--font-size-lg);
   ```

2. **Mobile-first responsive:**
   ```css
   /* ✅ CORRECT */
   .component {
     display: flex;
     flex-direction: column; /* Mobile */
   }
   
   @media (min-width: 768px) {
     .component {
       flex-direction: row; /* Desktop */
     }
   }
   ```

3. **Accessible focus:**
   ```css
   /* ✅ CORRECT */
   .button:focus-visible {
     outline: 3px solid var(--color-primary);
     outline-offset: 2px;
   }
   ```

4. **Use CSS classes:**
   ```html
   <!-- ✅ CORRECT -->
   <div class="component">
   ```

5. **Maintain contrast:**
   ```css
   /* ✅ CORRECT - Good contrast */
   color: var(--color-gray-700); /* On white background */
   ```

---

## 15. Quick Reference

### Most Used Variables

**Colors:**
- `var(--color-primary)` - Primary brand color
- `var(--color-white)` - White background/text
- `var(--color-gray-900)` - Primary text
- `var(--color-gray-700)` - Secondary text
- `var(--color-gray-200)` - Borders

**Spacing:**
- `var(--space-4)` - Base unit
- `var(--space-6)` - Standard spacing
- `var(--space-8)` - Medium spacing
- `var(--space-16)` - Section padding

**Typography:**
- `var(--font-size-base)` - Body text
- `var(--font-size-lg)` - Large body text
- `var(--font-size-3xl)` - Section headings
- `var(--line-height-normal)` - Body line height

**Other:**
- `var(--radius-lg)` - Standard border radius
- `var(--shadow-md)` - Standard shadow
- `var(--transition-base)` - Standard transition

---

## 16. Testing Your Styles

### Visual Testing Checklist

1. **Mobile (375px)**: Component looks good, text readable
2. **Tablet (768px)**: Layout adapts correctly
3. **Desktop (1024px+)**: Full layout displays properly
4. **Large Desktop (1440px+)**: Content doesn't stretch too wide

### Accessibility Testing

1. **Keyboard Navigation**: Tab through all interactive elements
2. **Focus Indicators**: All focusable elements show clear focus
3. **Screen Reader**: Test with screen reader (VoiceOver/NVDA)
4. **Color Contrast**: Use contrast checker tool
5. **Reduced Motion**: Test with reduced motion preference enabled

### Browser Testing

- Chrome/Edge (latest)
- Firefox (latest)
- Safari (latest)
- Mobile Safari (iOS)
- Chrome Mobile (Android)

---

## Related Documentation

- **Creating Components Guide**: `docs/skills/creating-index-html-components.md`
- **CLAUDE.md**: Main project documentation
- **styles.css**: Complete stylesheet reference

---

**Last Updated**: 2026-01-24
**Maintained By**: Development Team
