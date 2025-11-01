/**
 * PanelResizerHook - Allows users to drag a divider to resize left/right panels
 * 
 * Implements HyperCard-style instant resize (no smooth transitions)
 * Stores width preference in localStorage for persistence
 */
export default {
  mounted() {
    this.container = document.querySelector('.dual-panel-container')
    this.leftPanel = this.container?.querySelector('.dual-left-panel')
    this.rightPanel = this.container?.querySelector('.dual-right-panel')
    this.leftHeader = document.querySelector('.panel-header-left')
    this.rightHeader = document.querySelector('.panel-header-right')
    this.resizer = this.el
    
    if (!this.container || !this.leftPanel || !this.rightPanel || !this.leftHeader || !this.rightHeader) {
      console.warn('[PanelResizer] Missing required elements')
      return
    }

    // Load saved width preference or default to 50%
    const savedWidth = localStorage.getItem('panelLeftWidth')
    const initialWidth = savedWidth ? `${savedWidth}%` : '50%'
    
    // Set initial width
    this.setPanelWidth(initialWidth)

    // Setup drag functionality
    this.isDragging = false
    this.startX = 0
    this.startLeftWidth = 0
    
    this.resizer.addEventListener('mousedown', (e) => {
      this.startDrag(e)
    })

    // Double-click to reset to 50/50 split
    this.resizer.addEventListener('dblclick', (e) => {
      e.preventDefault()
      e.stopPropagation()
      this.setPanelWidth('50%')
    })

    // Prevent text selection while dragging
    this.resizer.style.userSelect = 'none'
    this.resizer.style.cursor = 'col-resize'

    // Handle mouse move and mouse up globally (even outside resizer)
    document.addEventListener('mousemove', (e) => {
      if (this.isDragging) {
        this.handleDrag(e)
      }
    })

    document.addEventListener('mouseup', () => {
      if (this.isDragging) {
        this.endDrag()
      }
    })

    // Handle window resize to maintain ratio
    window.addEventListener('resize', () => {
      this.updateTitleBars()
    })
  },

  setPanelWidth(width) {
    // Ensure width is a string with % unit
    const widthValue = typeof width === 'string' ? width : `${width}%`
    
    // Extract percentage and enforce 50% maximum for left panel
    const percentMatch = widthValue.match(/([\d.]+)%/)
    let finalPercent = percentMatch ? parseFloat(percentMatch[1]) : 50
    
    // Enforce constraints: 15% minimum, 50% maximum for left panel
    const minWidth = 15
    const maxWidth = 50
    finalPercent = Math.max(minWidth, Math.min(maxWidth, finalPercent))
    
    const finalWidth = `${finalPercent}%`
    
    // Set left panel width
    this.leftPanel.style.width = finalWidth
    this.leftPanel.style.flexShrink = '0'
    this.leftPanel.style.flexGrow = '0'
    
    // Right panel takes remaining space
    this.rightPanel.style.width = 'auto'
    this.rightPanel.style.flexGrow = '1'
    this.rightPanel.style.flexShrink = '1'

    // Update title bars to match
    this.updateTitleBars()

    // Save to localStorage (clamped value)
    localStorage.setItem('panelLeftWidth', finalPercent.toString())
  },

  startDrag(e) {
    e.preventDefault()
    e.stopPropagation()
    
    this.isDragging = true
    this.startX = e.clientX
    
    // Get current left panel width as percentage
    const containerWidth = this.container.offsetWidth
    const leftPanelWidth = this.leftPanel.offsetWidth
    this.startLeftWidth = (leftPanelWidth / containerWidth) * 100

    // Add dragging class for visual feedback
    document.body.style.cursor = 'col-resize'
    document.body.style.userSelect = 'none'
    this.resizer.style.background = '#666'
  },

  handleDrag(e) {
    if (!this.isDragging) return

    const containerWidth = this.container.offsetWidth
    const deltaX = e.clientX - this.startX
    const deltaPercent = (deltaX / containerWidth) * 100
    
    // Calculate new width
    let newWidth = this.startLeftWidth + deltaPercent
    
    // Enforce constraints: 15% minimum, 50% maximum for left panel
    // (Right panel can grow larger by making left panel smaller)
    const minWidth = 15
    const maxWidth = 50  // Left panel cannot exceed 50%
    
    newWidth = Math.max(minWidth, Math.min(maxWidth, newWidth))
    
    // Update panels instantly (no smooth transitions for HyperCard aesthetic)
    this.setPanelWidth(`${newWidth}%`)
  },

  endDrag() {
    if (!this.isDragging) return

    this.isDragging = false
    
    // Reset cursor and selection
    document.body.style.cursor = ''
    document.body.style.userSelect = ''
    this.resizer.style.background = ''
    
    // Final update of title bars
    this.updateTitleBars()
  },

  updateTitleBars() {
    // Get actual pixel widths of panels
    const containerRect = this.container.getBoundingClientRect()
    const leftPanelRect = this.leftPanel.getBoundingClientRect()
    
    const leftWidthPx = leftPanelRect.width
    const rightWidthPx = containerRect.width - leftWidthPx
    
    // Update left title bar
    this.leftHeader.style.width = `${leftWidthPx}px`
    this.leftHeader.style.maxWidth = `${leftWidthPx}px`
    this.leftHeader.style.left = `${leftPanelRect.left - containerRect.left}px`
    
    // Update right title bar
    this.rightHeader.style.width = `${rightWidthPx}px`
    this.rightHeader.style.maxWidth = `${rightWidthPx}px`
    this.rightHeader.style.left = `${leftPanelRect.right - containerRect.left}px`
  },

  updated() {
    // Re-find elements if DOM changed
    this.container = document.querySelector('.dual-panel-container')
    this.leftPanel = this.container?.querySelector('.dual-left-panel')
    this.rightPanel = this.container?.querySelector('.dual-right-panel')
    this.leftHeader = document.querySelector('.panel-header-left')
    this.rightHeader = document.querySelector('.panel-header-right')
    
    // Re-apply width if we have saved preference
    const savedWidth = localStorage.getItem('panelLeftWidth')
    if (savedWidth) {
      this.setPanelWidth(`${savedWidth}%`)
    }
  }
}

