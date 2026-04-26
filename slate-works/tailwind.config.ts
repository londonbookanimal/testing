import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["var(--font-plus-jakarta)", "system-ui", "sans-serif"],
        serif: ["Georgia", "Times New Roman", "serif"],
      },
      colors: {
        slate: {
          950: "#0a0f1e",
        },
        ink: {
          DEFAULT: "#1a1a2e",
          light: "#2d2d44",
        },
        paper: {
          DEFAULT: "#f7f4ef",
          warm: "#faf8f4",
          dark: "#ede9e2",
        },
        status: {
          raw: "#e8d5a3",
          "raw-text": "#7a5c1e",
          "raw-bg": "#fdf6e3",
          developing: "#a8d5b5",
          "developing-text": "#2d6a4f",
          "developing-bg": "#f0faf4",
          parked: "#c9c9d4",
          "parked-text": "#5a5a72",
          "parked-bg": "#f5f5f8",
        },
        accent: {
          DEFAULT: "#c84b31",
          light: "#e85d3e",
          muted: "#f0ddd9",
        },
      },
      boxShadow: {
        card: "0 1px 3px rgba(0,0,0,0.06), 0 4px 12px rgba(0,0,0,0.04)",
        "card-hover": "0 4px 16px rgba(0,0,0,0.1), 0 1px 4px rgba(0,0,0,0.06)",
        modal: "0 20px 60px rgba(0,0,0,0.15), 0 4px 16px rgba(0,0,0,0.08)",
      },
      borderRadius: {
        card: "12px",
      },
      animation: {
        "fade-in": "fadeIn 0.2s ease-out",
        "slide-up": "slideUp 0.25s ease-out",
        pulse: "pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite",
      },
      keyframes: {
        fadeIn: {
          "0%": { opacity: "0" },
          "100%": { opacity: "1" },
        },
        slideUp: {
          "0%": { opacity: "0", transform: "translateY(12px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
      },
      columns: {
        "2xs": "14rem",
      },
    },
  },
  plugins: [],
};

export default config;
