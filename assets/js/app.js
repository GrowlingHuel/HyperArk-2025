// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/green_man_tavern"
import ChatFormHook from "./hooks/chat_form_hook.js"
import XyflowEditorHook from "./hooks/xyflow_editor.js"

// Initialize topbar directly (inline to avoid import issues)
const topbar = {
  config: () => {},
  show: () => {},
  hide: () => {}
};

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
// Simple stepped animation hook for thinking dots (no smooth transitions)
const ThinkingDotsHook = {
  mounted() {
    const dots = Array.from(this.el.querySelectorAll('.dot'))
    let index = 0
    this._interval = setInterval(() => {
      dots.forEach((dot, i) => {
        const active = i === index
        dot.style.background = active ? '#000' : '#CCC'
        dot.style.border = '1px solid #000'
        dot.style.width = dot.style.width || '8px'
        dot.style.height = dot.style.height || '8px'
        dot.style.display = 'inline-block'
      })
      index = (index + 1) % dots.length
    }, 300)
  },
  destroyed() {
    if (this._interval) clearInterval(this._interval)
  }
}

// Hook to only show scrollbars when content actually overflows
const ScrollableContentHook = {
  mounted() {
    this.checkAndSetScrollbar()
    // Recheck on window resize and content updates
    window.addEventListener('resize', () => this.checkAndSetScrollbar())
    this.el.addEventListener('phx:update', () => this.checkAndSetScrollbar())
  },
  updated() {
    this.checkAndSetScrollbar()
  },
  checkAndSetScrollbar() {
    // Skip if this is a living-web-container or journal-container (they handle their own scrolling)
    if (this.el.classList.contains('living-web-container') || this.el.classList.contains('journal-container')) {
      return
    }
    
    // Check if content actually overflows
    const needsScroll = this.el.scrollHeight > this.el.clientHeight
    
    // Only enable scrolling if content overflows
    if (needsScroll) {
      this.el.style.overflowY = 'auto'
      this.el.classList.add('scrollable')
    } else {
      this.el.style.overflowY = 'hidden'
      this.el.classList.remove('scrollable')
    }
  }
}

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {
    ...colocatedHooks,
    ChatForm: ChatFormHook,
    XyflowEditor: XyflowEditorHook,
    ThinkingDots: ThinkingDotsHook,
    ScrollableContent: ScrollableContentHook,
    redirect: {
      mounted() {
        this.handleEvent("redirect", (data) => {
          window.location.href = data.to
        })
      }
    }
  },
})

// Show progress bar on live navigation and form submits (disabled for now)
// topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
// window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
// window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

