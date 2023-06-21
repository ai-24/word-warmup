module.exports = {
  content: [
    './app/views/**/*.html.slim',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.vue'
  ],
  theme: {
    extend: {
      colors: {
        'golden-yellow': {
          50: '#FFFDF7',
          400: '#FFE177',
          800: '#ffd12a'
        },
        lavender: {
          50: '#F7F1F6',
          600: '#C8A2C8',
          800: '#C683C6'
        }
      },
      maxWidth: {
        800: '800px'
      }
    }
  }
}
