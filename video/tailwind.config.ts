import type { Config } from 'tailwindcss'

export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Geist', 'SF Pro Display', 'SF Pro Text', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        glass: '0 24px 80px rgba(0, 0, 0, 0.55)',
      },
      colors: {
        ink: '#05070A',
        accent: '#6366F1',
      },
      keyframes: {
        drift: {
          '0%, 100%': { transform: 'translate3d(0, 0, 0)' },
          '50%': { transform: 'translate3d(0, -10px, 0)' },
        },
        pulseSoft: {
          '0%, 100%': { opacity: '0.42', transform: 'scale(1)' },
          '50%': { opacity: '0.78', transform: 'scale(1.035)' },
        },
      },
      animation: {
        drift: 'drift 9s ease-in-out infinite',
        pulseSoft: 'pulseSoft 4s ease-in-out infinite',
      },
    },
  },
  plugins: [],
} satisfies Config
