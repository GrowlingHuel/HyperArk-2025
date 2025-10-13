module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/green_man_tavern_web.ex",
    "../lib/green_man_tavern_web/**/*.*ex"
  ],
  theme: {
    extend: {
      colors: {
        'pure-black': '#000000',
        'dark-grey': '#333333',
        'medium-grey': '#666666',
        'neutral-grey': '#999999',
        'light-grey': '#CCCCCC',
        'off-white': '#EEEEEE',
        'pure-white': '#FFFFFF',
      },
      fontFamily: {
        'mac': ['Chicago', 'Monaco', 'Courier New', 'monospace'],
        'system': ['Geneva', 'Helvetica', 'Arial', 'sans-serif'],
      },
      spacing: {
        '1': '4px',
        '2': '8px',
        '3': '12px',
        '4': '16px',
        '6': '24px',
        '8': '32px',
      }
    },
  },
  plugins: [
    require("@tailwindcss/forms")
  ]
}
