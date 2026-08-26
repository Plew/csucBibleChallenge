const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}',
    './app/components/**/*.{erb,haml,html,slim, rb}'
  ],
  safelist: [
    'w-1',
    'h-1',
    'w-2',
    'h-2',
    'w-3',
    'h-3',
    'bg-success',
    'bg-base-300',
    'bg-transparent',
    'border-2',
    'ring-2',
    'ring-primary',
    'ring-offset-1',
    'bg-white',
    'rounded-full',
    'rounded-sm',
    'absolute',
    'inset-0',
    'flex',
    'items-center',
    'justify-center',
    'border-purple-400',
    'bg-purple-500/20',
    'text-purple-400'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        'brand-dark': 'var(--brand-dark)',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
    require('daisyui')
  ],
  daisyui: {
    themes: [
      "light",
      "dark",
      "cupcake",
      "bumblebee",
      "emerald",
      "corporate",
      "synthwave",
      "retro",
      "cyberpunk",
      "valentine",
      "halloween",
      "garden",
      "forest",
      "aqua",
      "lofi",
      "pastel",
      "fantasy",
      "wireframe",
      "black",
      "luxury",
      "dracula",
      "cmyk",
      "autumn",
      "business",
      "acid",
      "lemonade",
      "night",
      "coffee",
      "winter",
      "dim",
      "nord",
      "sunset",
      {
        "andgodsaid": {
          "primary": "#6B7558",          // Muted Olive Green (Matches background shape)
          "primary-content": "#ffffff",  // White text on primary buttons
          "secondary": "#C79C46",        // Mustard Gold (Matches left background shape)
          "secondary-content": "#ffffff",
          "accent": "#A3B18A",           // Soft Sage Green
          "neutral": "#2F2C28",          // Deep Charcoal/Brown for text (softer than pure black)
          "base-100": "#FBF8F2",         // Warm Cream (Main Background)
          "base-200": "#F8F6F0",         // Subtle Soft Ivory Off-White (Card Backgrounds)
          "base-300": "#EBE5D8",         // Subtle border/divider color
          "info": "#4A6B82",             // Muted Slate Blue (Harmonious & elegant, not harsh)
          "info-content": "#ffffff",
          "success": "#556E3F",          // Warm Leaf / Moss Green (No blue undertone)
          "success-content": "#ffffff",
          "warning": "#C79C46",          // Warm Amber / Mustard Gold
          "warning-content": "#ffffff",
          "error": "#B05858",            // Muted Terracotta / Rust Red
          "error-content": "#ffffff",
          "--brand-dark": "#2B3824"      // Deep Dark Forest Green (darker than olive primary)
        },
        "andgodsaid-dark": {
          "primary": "#A3B18A",          // Lighter sage for contrast in dark mode
          "primary-content": "#1a1a1a",
          "secondary": "#C79C46",
          "accent": "#6B7558",
          "neutral": "#FBF8F2",          // Cream text on dark background
          "base-100": "#1C1A17",         // Very dark charcoal/brown background
          "base-200": "#25221E",         // Slightly lighter cards
          "base-300": "#38342E",         // Subtle border
          "info": "#6B8FA3",             // Soft Slate Blue
          "info-content": "#1C1A17",
          "success": "#88A270",          // Warm Sage / Leaf Green (No blue undertone)
          "success-content": "#1C1A17",
          "warning": "#D4AC5B",
          "warning-content": "#1C1A17",
          "error": "#C26D6D",            // Muted Rust
          "error-content": "#1C1A17",
          "--brand-dark": "#A3B18A"      // Luminous Sage for dark mode
        }
      }
    ],
  }
}
