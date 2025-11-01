/**
 * SVG Flow Editor Hook for Phoenix LiveView
 * 
 * Simple node-based editor for the Living Web system.
 * Uses vanilla JS with DOM manipulation - no React needed.
 */

const GRID_SIZE = 20;

function snapToGrid(position) {
  return {
    x: Math.round(position.x / GRID_SIZE) * GRID_SIZE,
    y: Math.round(position.y / GRID_SIZE) * GRID_SIZE
  };
}

// Collision detection helper using spiral search and grid snapping
function findNonOverlappingPosition(x, y, existingNodes) {
  const SPACING = 50; // minimum distance between nodes
  let finalX = Math.round(x / GRID_SIZE) * GRID_SIZE;
  let finalY = Math.round(y / GRID_SIZE) * GRID_SIZE;
  let attempts = 0;
  const maxAttempts = 20;

  const isTooClose = (px, py) => {
    return existingNodes.some((node) => {
      const nx = typeof node.x === 'number' ? node.x : (node.position && node.position.x) || 0;
      const ny = typeof node.y === 'number' ? node.y : (node.position && node.position.y) || 0;
      const dx = nx - px;
      const dy = ny - py;
      const distance = Math.sqrt(dx * dx + dy * dy);
      return distance < SPACING;
    });
  };

  while (attempts < maxAttempts && isTooClose(finalX, finalY)) {
    const angle = (attempts / maxAttempts) * Math.PI * 2;
    const radius = 50 + attempts * 20;
    finalX = x + Math.cos(angle) * radius;
    finalY = y + Math.sin(angle) * radius;
    const snapped = snapToGrid({ x: finalX, y: finalY });
    finalX = snapped.x;
    finalY = snapped.y;
    attempts++;
  }

  return { x: finalX, y: finalY };
}

const XyflowEditorHook = {
  mounted() {
    console.log("=== XyflowEditor Hook Mounted ===");
    console.log("Container element:", this.el);
    this.container = this.el;
    this.nodes = [];
    this.edges = [];
    this.selectedNode = null;
      this.selectedNodes = new Set();
      this.isDraggingNode = false; // Flag to prevent bounds updates during drag
      this.isMarqueeSelecting = false; // Flag for marquee selection box
      this.marqueeBox = null; // DOM element for selection box
      this.marqueeStartX = 0;
      this.marqueeStartY = 0;
      this.isPanningCanvas = false; // Flag to distinguish canvas panning from marquee selection
      
      // Load initial nodes, edges, and projects from data attributes
      this.loadInitialData();
    
    // Log container dimensions
    console.log("Container dimensions:", { width: this.el.offsetWidth, height: this.el.offsetHeight });

    // Render the nodes
    this.renderNodes();
    
      // Setup drag and drop
      this.setupDragAndDrop();
      // Setup marquee selection
      this.setupMarqueeSelection();
      // Setup toolbar action buttons
      this.setupToolbarButtons();
    
    // Setup library item drag handlers
    this.setupLibraryItemDrag();
    
    // Setup server event listeners
    this.setupServerEvents();

    // Debug: log nodes_updated events pushed from server
    this.handleEvent("nodes_updated", ({ nodes, edges }) => {
      console.log("Nodes updated:", nodes);
      console.log("Node count:", Array.isArray(nodes) ? nodes.length : (nodes && Object.keys(nodes).length) || 0);
      if (Array.isArray(nodes) && nodes.length > 0) {
        console.log("First node structure:", JSON.stringify(nodes[0], null, 2));
      }
    });

    // Listen for successful nodes deletion
    this.handleEvent("nodes_deleted_success", ({ node_ids }) => {
      if (!Array.isArray(node_ids)) return;
      node_ids.forEach((nodeId) => {
        const nodeEl = document.querySelector(`[data-node-id="${nodeId}"]`);
        if (nodeEl) {
          nodeEl.remove();
        }
        // Remove from nodes array
        this.nodes = (this.nodes || []).filter((n) => n.id !== nodeId);
        // Remove from selection
        if (this.selectedNodes) {
          this.selectedNodes.delete(nodeId);
        }
      });
      if (this.updateSelectionCount) {
        this.updateSelectionCount();
      }
      // Update canvas bounds after nodes are deleted
      this.updateCanvasBounds();
      console.log(`Deleted ${node_ids.length} nodes`);
    });

    // Listen for nodes hidden success
    this.handleEvent("nodes_hidden_success", ({ node_ids }) => {
      if (!Array.isArray(node_ids)) return;
      node_ids.forEach((nodeId) => {
        const nodeEl = document.querySelector(`[data-node-id="${nodeId}"]`);
        if (nodeEl) {
          nodeEl.remove();
        }
        if (this.selectedNodes) {
          this.selectedNodes.delete(nodeId);
        }
      });
      if (this.updateSelectionCount) {
        this.updateSelectionCount();
      }
      // Update canvas bounds after nodes are hidden
      this.updateCanvasBounds();
      console.log(`Hidden ${node_ids.length} nodes`);
    });

    // Listen for show all success (server will trigger LV re-render)
    this.handleEvent("show_all_success", ({ nodes }) => {
      console.log('Showing all nodes, will trigger re-render');
    });

    // Listen for canvas cleared
    this.handleEvent("canvas_cleared", () => {
      if (this.canvas) {
        this.canvas.innerHTML = '';
      }
      this.nodes = [];
      this.selectedNodes = new Set();
      if (this.updateSelectionCount) {
        this.updateSelectionCount();
      }
      // Update canvas bounds after canvas is cleared
      this.updateCanvasBounds();
      console.log('Canvas cleared');
    });
  },

  updated() {
    // Update nodes and edges when server sends new data
    this.loadInitialData();
    this.renderNodes();
    this.setupLibraryItemDrag();

    // Inspect rendered nodes in DOM
    const reactNodes = document.querySelectorAll('.react-flow__node');
    console.log("Rendered .react-flow__node in DOM:", reactNodes.length);
    if (reactNodes.length > 0) {
      const cs = window.getComputedStyle(reactNodes[0]);
      console.log("First RF node HTML:", reactNodes[0].innerHTML);
      console.log("First RF node computed styles:", { border: cs.border, background: cs.backgroundColor, padding: cs.padding });
    }
    const domNodes = this.container.querySelectorAll('.flow-node');
    console.log("Rendered .flow-node in DOM:", domNodes.length);
    if (domNodes.length > 0) {
      const cs2 = window.getComputedStyle(domNodes[0]);
      console.log("First flow-node HTML:", domNodes[0].innerHTML);
      console.log("First flow-node computed styles:", { border: cs2.border, background: cs2.backgroundColor, padding: cs2.padding });
    }
  },

  destroyed() {
    // Clean up
    if (this.dragStartHandler) {
      document.removeEventListener('dragstart', this.dragStartHandler);
    }
    if (this.dragEndHandler) {
      document.removeEventListener('dragend', this.dragEndHandler);
    }
  },

  loadInitialData() {
    // Parse nodes, edges, and projects from data attributes
    const nodesData = this.el.dataset.nodes;
    const edgesData = this.el.dataset.edges;
    const projectsData = this.el.dataset.projects;

    if (nodesData) {
      try {
        const parsed = JSON.parse(nodesData);
        this.nodes = typeof parsed === 'object' ? Object.entries(parsed).map(([id, data]) => ({ id, ...data })) : [];
      } catch (e) {
        console.error('Error parsing nodes:', e);
        this.nodes = [];
      }
    } else {
      this.nodes = [];
    }

    if (edgesData) {
      try {
        const parsed = JSON.parse(edgesData);
        this.edges = typeof parsed === 'object' ? Object.entries(parsed).map(([id, data]) => ({ id, ...data })) : [];
      } catch (e) {
        console.error('Error parsing edges:', e);
        this.edges = [];
      }
    } else {
      this.edges = [];
    }

    if (projectsData) {
      try {
        const parsed = JSON.parse(projectsData);
        // Normalize to an array of projects with id, name, category, icon_name
        this.projects = Array.isArray(parsed) ? parsed : [];
      } catch (e) {
        console.error('Error parsing projects:', e);
        this.projects = [];
      }
    } else {
      this.projects = [];
    }
  },

  renderNodes() {
    // Clear existing nodes
    this.container.innerHTML = '';
    
    // Create a canvas wrapper
    this.canvas = document.createElement('div');
    this.canvas.className = 'flow-canvas';
    // Use explicit positioning - don't rely on percentages that might constrain
    this.canvas.style.position = 'relative';
    // Start with explicit dimensions instead of percentages
    // These will be updated by updateCanvasBounds()
    const scrollArea = this.container.closest('.canvas-scroll-area');
    const viewport = scrollArea || this.container;
    const initialWidth = viewport.clientWidth || 800;
    const initialHeight = viewport.clientHeight || 600;
    this.canvas.style.width = `${initialWidth}px`;
    this.canvas.style.height = `${initialHeight}px`;
    this.canvas.style.background = 'transparent'; // Background is on .canvas-scroll-area
    
    // Create a nodes container that can be transformed for negative positions
    // This container should be transparent so the canvas background shows through
    this.nodesContainer = document.createElement('div');
    this.nodesContainer.style.position = 'absolute';
    this.nodesContainer.style.top = '0';
    this.nodesContainer.style.left = '0';
    this.nodesContainer.style.width = '100%';
    this.nodesContainer.style.height = '100%';
    this.nodesContainer.style.background = 'transparent';
    this.nodesContainer.style.pointerEvents = 'none'; // Allow clicks to pass through to nodes
    this.canvas.appendChild(this.nodesContainer);
    
    this.container.appendChild(this.canvas);
    
    // Create marquee selection box (recreate if renderNodes() was called and cleared it)
    // Place it in nodesContainer so it uses the same coordinate system as nodes
    if (!this.marqueeBox || (!this.nodesContainer.contains(this.marqueeBox) && !this.canvas.contains(this.marqueeBox))) {
      // Remove from old location if it exists
      if (this.marqueeBox && this.marqueeBox.parentNode) {
        this.marqueeBox.parentNode.removeChild(this.marqueeBox);
      }
      
      this.marqueeBox = document.createElement('div');
      this.marqueeBox.className = 'marquee-selection-box';
      this.marqueeBox.style.position = 'absolute';
      this.marqueeBox.style.border = '2px dashed #000';
      this.marqueeBox.style.background = 'rgba(0, 0, 0, 0.1)';
      this.marqueeBox.style.pointerEvents = 'none';
      this.marqueeBox.style.zIndex = '1000';
      this.marqueeBox.style.display = 'none';
      
      // Add to nodesContainer (same coordinate system as nodes)
      if (this.nodesContainer) {
        this.nodesContainer.appendChild(this.marqueeBox);
      } else if (this.canvas) {
        this.canvas.appendChild(this.marqueeBox);
      }
    }

    // Render each node
    this.nodes.forEach(node => {
      this.renderNode(node);
    });

    // Update canvas size based on node bounds
    this.updateCanvasBounds();

    // Ensure selection count reflects current state after re-render
    if (this.updateSelectionCount) {
      this.updateSelectionCount();
    }
  },

  renderNode(node) {
    console.log("Creating node (renderNode):", node);
    // Create node element
    const nodeEl = document.createElement('div');
    const category = (node.category || '').toLowerCase();
    const categoryClass = category ? `node-${category}` : '';
    const statusClass = node.status === 'planned' ? 'node-planned' : (node.status === 'problem' ? 'node-problem' : '');
    nodeEl.className = ['flow-node', categoryClass, statusClass].filter(Boolean).join(' ');
    nodeEl.style.position = 'absolute';
    nodeEl.style.left = `${node.x}px`;
    nodeEl.style.top = `${node.y}px`;
    nodeEl.style.width = '140px';
    nodeEl.style.minHeight = '80px';
    nodeEl.style.height = 'auto';
    nodeEl.style.border = '2px solid #000';
    nodeEl.style.borderRadius = '0';
    nodeEl.style.padding = '12px';
    nodeEl.style.background = getCategoryBackground(category);
    nodeEl.style.cursor = 'move';
    nodeEl.style.userSelect = 'none';
    nodeEl.dataset.nodeId = node.id;
    nodeEl.dataset.category = category;

    // Add HyperCard styling
    nodeEl.style.boxShadow = '2px 2px 0 rgba(0,0,0,0.3)';
    nodeEl.style.fontFamily = "'Chicago', 'Geneva', 'Monaco', monospace";
    nodeEl.style.fontSize = '11px';
    nodeEl.style.color = '#000';

    // Selection checkbox (top-right)
    const checkbox = document.createElement('input');
    checkbox.type = 'checkbox';
    checkbox.className = 'node-select-checkbox';
    checkbox.style.position = 'absolute';
    checkbox.style.top = '4px';
    checkbox.style.right = '4px';
    checkbox.style.width = '16px';
    checkbox.style.height = '16px';
    checkbox.style.border = '1px solid #000';
    checkbox.style.background = '#FFF';
    checkbox.style.cursor = 'pointer';
    checkbox.addEventListener('click', (e) => {
      e.stopPropagation();
      const id = nodeEl.dataset.nodeId;
      if (checkbox.checked) {
        this.selectedNodes.add(id);
        nodeEl.classList.add('selected');
        nodeEl.style.zIndex = '10';
        nodeEl.style.border = '5px solid #000';
        nodeEl.style.background = '#FFF';
        nodeEl.style.boxShadow = '4px 4px 0 #000';
      } else {
        this.selectedNodes.delete(id);
        nodeEl.classList.remove('selected');
        nodeEl.style.zIndex = '';
        nodeEl.style.border = '2px solid #000';
        nodeEl.style.background = getCategoryBackground(nodeEl.dataset.category);
        nodeEl.style.boxShadow = '2px 2px 0 rgba(0,0,0,0.3)';
      }
      // Update selection counter in toolbar
      if (this.updateSelectionCount) {
        this.updateSelectionCount();
      }
    });
    nodeEl.appendChild(checkbox);

    // Icon
    const iconDiv = document.createElement('div');
    iconDiv.className = 'node-icon';
    iconDiv.textContent = getCategoryIcon(node);
    iconDiv.style.fontSize = '28px';
    iconDiv.style.lineHeight = '1';
    iconDiv.style.marginBottom = '8px';
    iconDiv.style.display = 'block';
    iconDiv.style.filter = 'grayscale(100%) contrast(1000%) brightness(1.2)';
    iconDiv.style.color = '#FFF';
    iconDiv.style.textShadow = '-1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000, 0 -1px 0 #000, -1px 0 0 #000, 1px 0 0 #000, 0 1px 0 #000';
    nodeEl.appendChild(iconDiv);

    // Name
    const nameDiv = document.createElement('div');
    nameDiv.className = 'node-name';
    // Prefer stored node.name; otherwise look up from projects by project_id
    const fallbackProject = getProjectById(this.projects, node.project_id);
    nameDiv.textContent = node.name || (fallbackProject && fallbackProject.name) || 'Node';
    nameDiv.style.fontWeight = 'bold';
    nameDiv.style.fontSize = '11px';
    nameDiv.style.lineHeight = '1.3';
    nodeEl.appendChild(nameDiv);

    // Make node draggable
    this.makeDraggable(nodeEl);

    // Append to nodes container instead of canvas directly
    // Nodes need pointer events enabled to be draggable (container has pointer-events: none)
    nodeEl.style.pointerEvents = 'auto';
    if (this.nodesContainer) {
      this.nodesContainer.appendChild(nodeEl);
    } else {
      this.canvas.appendChild(nodeEl);
    }
    // Restore selection state for this node
    this.syncCheckboxState(nodeEl);
    return nodeEl;
  },

  makeDraggable(element) {
    let isDragging = false;
    let startX, startY, initialX, initialY;
    let dragScrollLeft = 0;
    let dragScrollTop = 0;
    let selectedNodesInitialPositions = new Map(); // Store initial positions for multi-node drag
    let dragStartMouseX = 0; // Track mouse position at drag start for cumulative offset
    let dragStartMouseY = 0;

    element.addEventListener('mousedown', (e) => {
      if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;
      
      // Check if this node is selected and if we have multiple nodes selected
      const nodeId = element.dataset.nodeId;
      const isNodeSelected = this.selectedNodes && this.selectedNodes.has(nodeId);
      const hasMultipleSelected = this.selectedNodes && this.selectedNodes.size > 1;
      
      // If multiple nodes are selected and this node is one of them, prepare multi-node drag
      if (hasMultipleSelected && isNodeSelected) {
        selectedNodesInitialPositions.clear();
        
        // Store initial positions of all selected nodes
        this.selectedNodes.forEach(selectedId => {
          const selectedNodeEl = this.canvas.querySelector(`[data-node-id="${selectedId}"]`);
          if (selectedNodeEl) {
            const x = parseInt(selectedNodeEl.style.left) || 0;
            const y = parseInt(selectedNodeEl.style.top) || 0;
            selectedNodesInitialPositions.set(selectedId, { x, y });
          }
        });
      } else if (!isNodeSelected) {
        // If clicking on an unselected node, clear selection first
        // (User can hold Shift to add to selection, but for now we'll just select this one)
        this.clearSelection();
        this.selectedNodes.add(nodeId);
        this.syncCheckboxState(element);
        this.updateSelectionCount();
      }
      
      isDragging = true;
      element.style.cursor = 'grabbing';
      
      // Store mouse position at drag start (for cumulative offset calculation)
      dragStartMouseX = e.clientX;
      dragStartMouseY = e.clientY;
      
      startX = e.clientX;
      startY = e.clientY;
      
      const rect = element.getBoundingClientRect();
      initialX = rect.left;
      initialY = rect.top;
      
      // Save scroll position at start of drag
      const scrollArea = this.container.closest('.canvas-scroll-area');
      if (scrollArea) {
        dragScrollLeft = scrollArea.scrollLeft;
        dragScrollTop = scrollArea.scrollTop;
      }
      
      // Set flag to prevent bounds updates during drag
      this.isDraggingNode = true;

      e.preventDefault();
      e.stopPropagation(); // Prevent marquee selection from starting
    });

    document.addEventListener('mousemove', (e) => {
      if (!isDragging) return;

      const nodeId = element.dataset.nodeId;
      const hasMultipleSelected = this.selectedNodes && this.selectedNodes.size > 1 && this.selectedNodes.has(nodeId);
      
      if (hasMultipleSelected && selectedNodesInitialPositions.size > 0) {
        // Multi-node drag: use cumulative offset from drag start
        const cumulativeDx = e.clientX - dragStartMouseX;
        const cumulativeDy = e.clientY - dragStartMouseY;
        
        // Move all selected nodes by the same cumulative offset from their initial positions
        selectedNodesInitialPositions.forEach((initialPos, selectedId) => {
          const selectedNodeEl = this.canvas.querySelector(`[data-node-id="${selectedId}"]`);
          if (selectedNodeEl) {
            const newX = initialPos.x + cumulativeDx;
            const newY = initialPos.y + cumulativeDy;
            selectedNodeEl.style.left = `${newX}px`;
            selectedNodeEl.style.top = `${newY}px`;
          }
        });
      } else {
        // Single node drag: use incremental offset (standard drag behavior)
        const dx = e.clientX - startX;
        const dy = e.clientY - startY;
        
        const currentLeft = parseInt(element.style.left || '0');
        const currentTop = parseInt(element.style.top || '0');
        const newX = currentLeft + dx;
        const newY = currentTop + dy;
        element.style.left = `${newX}px`;
        element.style.top = `${newY}px`;
        
        startX = e.clientX;
        startY = e.clientY;
      }
    });

    document.addEventListener('mouseup', () => {
      if (!isDragging) return;
      
      isDragging = false;
      element.style.cursor = 'move';

      const nodeId = element.dataset.nodeId;
      const hasMultipleSelected = this.selectedNodes && this.selectedNodes.size > 1 && this.selectedNodes.has(nodeId);
      
      if (hasMultipleSelected && selectedNodesInitialPositions.size > 0) {
        // Multi-node drag: send position updates for all selected nodes
        const updates = [];
        selectedNodesInitialPositions.forEach((initialPos, selectedId) => {
          const selectedNodeEl = this.canvas.querySelector(`[data-node-id="${selectedId}"]`);
          if (selectedNodeEl) {
            let x = parseInt(selectedNodeEl.style.left) || 0;
            let y = parseInt(selectedNodeEl.style.top) || 0;
            
            // Snap to grid on drop
            const snapped = snapToGrid({ x, y });
            x = snapped.x;
            y = snapped.y;
            selectedNodeEl.style.left = `${x}px`;
            selectedNodeEl.style.top = `${y}px`;
            
            updates.push({ node_id: selectedId, position_x: x, position_y: y });
          }
        });
        
        // Send all updates to server
        updates.forEach(update => {
          this.pushEvent('node_moved', update);
        });
        
        selectedNodesInitialPositions.clear();
      } else {
        // Single node drag
        let x = parseInt(element.style.left);
        let y = parseInt(element.style.top);

        // Snap to grid on drop
        const snapped = snapToGrid({ x, y });
        x = snapped.x;
        y = snapped.y;
        element.style.left = `${x}px`;
        element.style.top = `${y}px`;

        this.pushEvent('node_moved', {
          node_id: nodeId,
          position_x: x,
          position_y: y
        });
      }

      // Clear dragging flag
      this.isDraggingNode = false;
      
      // Update canvas bounds after node is moved, but preserve scroll position
      // Get current scroll position relative to the dragged node
      const scrollArea = this.container.closest('.canvas-scroll-area');
      const nodeScrollLeft = scrollArea ? scrollArea.scrollLeft : dragScrollLeft;
      const nodeScrollTop = scrollArea ? scrollArea.scrollTop : dragScrollTop;
      
      // Store scroll position that should be maintained
      this.pendingScrollLeft = nodeScrollLeft;
      this.pendingScrollTop = nodeScrollTop;
      
      // Delay bounds update slightly to avoid interrupting user interaction
      setTimeout(() => {
        this.updateCanvasBounds();
      }, 100);
    });
  },

  setupDragAndDrop() {
    const container = this.container;
    this.isDragging = false;

    // Show visual feedback when dragging over canvas
    container.addEventListener('dragover', (e) => {
      e.preventDefault();
      container.classList.add('xyflow-drag-over');
      container.style.cursor = 'copy';
      this.isDragging = true;
    });

    // Hide visual feedback when leaving canvas
    container.addEventListener('dragleave', (e) => {
      if (e.target === container || !container.contains(e.relatedTarget)) {
        container.classList.remove('xyflow-drag-over');
        container.style.cursor = '';
        this.isDragging = false;
      }
    });

    container.addEventListener('drop', (e) => {
      e.preventDefault();
      
      container.classList.remove('xyflow-drag-over');
      container.style.cursor = '';
      this.isDragging = false;

      const projectId = e.dataTransfer.getData('text/plain');
      if (!projectId) return;

      const rect = container.getBoundingClientRect();
      let rawX = e.clientX - rect.left;
      let rawY = e.clientY - rect.top;

      // Collision-avoidance with spiral + grid snapping
      const finalPos = findNonOverlappingPosition(rawX, rawY, this.nodes);
      let x = finalPos.x;
      let y = finalPos.y;
      console.log('Drop requested at', { rawX, rawY }, 'adjusted to', { x, y });

      const tempId = 'temp_' + Date.now();
      
      // Create temporary node
      this.addTemporaryNode(tempId, x, y, 'Loading...');

      // Push event to server
      this.pushEvent('node_added', {
        project_id: projectId,
        x: Math.round(x),
        y: Math.round(y),
        temp_id: tempId
      });
    });
  },

  setupMarqueeSelection() {
    const container = this.container;
    const scrollArea = container.closest('.canvas-scroll-area');
    
    let isMarqueeActive = false;
    let startX = 0;
    let startY = 0;
    
    // Create marquee selection box element (if it doesn't exist)
    // Place it in nodesContainer so it uses the same coordinate system as nodes
    if (!this.marqueeBox) {
      this.marqueeBox = document.createElement('div');
      this.marqueeBox.className = 'marquee-selection-box';
      this.marqueeBox.style.position = 'absolute';
      this.marqueeBox.style.border = '2px dashed #000';
      this.marqueeBox.style.background = 'rgba(0, 0, 0, 0.1)';
      this.marqueeBox.style.pointerEvents = 'none';
      this.marqueeBox.style.zIndex = '1000';
      this.marqueeBox.style.display = 'none';
      
      // Add to nodesContainer (same coordinate system as nodes)
      if (this.nodesContainer) {
        this.nodesContainer.appendChild(this.marqueeBox);
      } else if (this.canvas) {
        this.canvas.appendChild(this.marqueeBox);
      }
    }
    
    container.addEventListener('mousedown', (e) => {
      // Only start marquee if clicking directly on canvas (not on a node, toolbar, etc.)
      if (e.target.closest('.flow-node') || 
          e.target.closest('.living-web-toolbar') ||
          e.target.closest('.library-header') ||
          e.target.closest('.library-content')) {
        return;
      }
      
      // Don't start marquee if user is holding a modifier key (for future multi-select)
      // For now, we'll allow it, but can check e.shiftKey, e.ctrlKey, etc. later
      
      isMarqueeActive = true;
      this.isMarqueeSelecting = true;
      
      // Get starting position relative to nodesContainer (accounting for transform and scroll)
      const scrollLeft = scrollArea ? scrollArea.scrollLeft : 0;
      const scrollTop = scrollArea ? scrollArea.scrollTop : 0;
      
      // Get the transform offset of nodesContainer (if any)
      const nodesContainerTransform = this.getNodesContainerTransform();
      
      // Calculate position relative to the actual canvas coordinate system (where nodes are)
      // Mouse position in viewport
      const viewportX = e.clientX;
      const viewportY = e.clientY;
      
      // Get canvas position in viewport
      const canvasRect = this.canvas.getBoundingClientRect();
      
      // Convert to canvas coordinates (accounting for scroll)
      const canvasX = viewportX - canvasRect.left + scrollLeft;
      const canvasY = viewportY - canvasRect.top + scrollTop;
      
      // Account for nodesContainer transform offset (reverse the transform)
      startX = canvasX - nodesContainerTransform.x;
      startY = canvasY - nodesContainerTransform.y;
      
      this.marqueeStartX = startX;
      this.marqueeStartY = startY;
      
      // Show and position marquee box
      if (this.marqueeBox) {
        this.marqueeBox.style.display = 'block';
        this.marqueeBox.style.left = `${startX}px`;
        this.marqueeBox.style.top = `${startY}px`;
        this.marqueeBox.style.width = '0px';
        this.marqueeBox.style.height = '0px';
      }
      
      e.preventDefault();
      e.stopPropagation();
    });
    
    document.addEventListener('mousemove', (e) => {
      if (!isMarqueeActive || !this.marqueeBox) return;
      
      // Calculate current position relative to nodesContainer (same coordinate system as nodes)
      const scrollLeft = scrollArea ? scrollArea.scrollLeft : 0;
      const scrollTop = scrollArea ? scrollArea.scrollTop : 0;
      
      // Get the transform offset of nodesContainer
      const nodesContainerTransform = this.getNodesContainerTransform();
      
      // Calculate position in canvas coordinate system
      const canvasRect = this.canvas.getBoundingClientRect();
      const viewportX = e.clientX;
      const viewportY = e.clientY;
      
      const canvasX = viewportX - canvasRect.left + scrollLeft;
      const canvasY = viewportY - canvasRect.top + scrollTop;
      
      // Account for nodesContainer transform offset
      const currentX = canvasX - nodesContainerTransform.x;
      const currentY = canvasY - nodesContainerTransform.y;
      
      // Calculate rectangle bounds
      const left = Math.min(startX, currentX);
      const top = Math.min(startY, currentY);
      const width = Math.abs(currentX - startX);
      const height = Math.abs(currentY - startY);
      
      // Update marquee box
      this.marqueeBox.style.left = `${left}px`;
      this.marqueeBox.style.top = `${top}px`;
      this.marqueeBox.style.width = `${width}px`;
      this.marqueeBox.style.height = `${height}px`;
    });
    
    document.addEventListener('mouseup', (e) => {
      if (!isMarqueeActive) return;
      
      isMarqueeActive = false;
      this.isMarqueeSelecting = false;
      
      // Hide marquee box
      if (this.marqueeBox) {
        this.marqueeBox.style.display = 'none';
      }
      
      // Calculate final selection rectangle in node coordinate system
      const scrollLeft = scrollArea ? scrollArea.scrollLeft : 0;
      const scrollTop = scrollArea ? scrollArea.scrollTop : 0;
      
      // Get the transform offset of nodesContainer
      const nodesContainerTransform = this.getNodesContainerTransform();
      
      // Calculate end position in canvas coordinates
      const canvasRect = this.canvas.getBoundingClientRect();
      const canvasX = e.clientX - canvasRect.left + scrollLeft;
      const canvasY = e.clientY - canvasRect.top + scrollTop;
      
      // Convert to node coordinate system (accounting for transform)
      const endX = canvasX - nodesContainerTransform.x;
      const endY = canvasY - nodesContainerTransform.y;
      
      const left = Math.min(startX, endX);
      const top = Math.min(startY, endY);
      const right = Math.max(startX, endX);
      const bottom = Math.max(startY, endY);
      
      // Find all nodes that intersect with selection rectangle
      const selectedNodesInBox = [];
      const nodeElements = this.canvas.querySelectorAll('.flow-node:not(.temp-node)');
      
      nodeElements.forEach(nodeEl => {
        const nodeX = parseInt(nodeEl.style.left) || 0;
        const nodeY = parseInt(nodeEl.style.top) || 0;
        const nodeWidth = nodeEl.offsetWidth || 140;
        const nodeHeight = nodeEl.offsetHeight || 80;
        
        const nodeLeft = nodeX;
        const nodeRight = nodeX + nodeWidth;
        const nodeTop = nodeY;
        const nodeBottom = nodeY + nodeHeight;
        
        // Check if node intersects with selection rectangle
        if (!(nodeRight < left || nodeLeft > right || nodeBottom < top || nodeTop > bottom)) {
          const nodeId = nodeEl.dataset.nodeId;
          if (nodeId) {
            selectedNodesInBox.push(nodeId);
          }
        }
      });
      
      // Update selection
      if (selectedNodesInBox.length > 0) {
        // Clear existing selection if not holding Shift (for future enhancement)
        // For now, replace selection
        this.clearSelection();
        
        // Add nodes in box to selection
        selectedNodesInBox.forEach(nodeId => {
          this.selectedNodes.add(nodeId);
          
          // Update checkbox and visual state
          const nodeEl = this.canvas.querySelector(`[data-node-id="${nodeId}"]`);
          if (nodeEl) {
            this.syncCheckboxState(nodeEl);
          }
        });
        
        // Update selection count
        this.updateSelectionCount();
      }
    });
  },

  clearSelection() {
    // Clear all selections
    this.selectedNodes.clear();
    
    // Update all node checkboxes and visual states
    const nodeElements = this.canvas.querySelectorAll('.flow-node');
    nodeElements.forEach(nodeEl => {
      const checkbox = nodeEl.querySelector('.node-select-checkbox');
      if (checkbox) {
        checkbox.checked = false;
      }
      nodeEl.classList.remove('selected');
      const category = nodeEl.dataset.category;
      nodeEl.style.zIndex = '';
      nodeEl.style.border = '2px solid #000';
      nodeEl.style.background = getCategoryBackground(category);
      nodeEl.style.boxShadow = '2px 2px 0 rgba(0,0,0,0.3)';
    });
    
    this.updateSelectionCount();
  },

  getNodesContainerTransform() {
    // Extract transform offset from nodesContainer's CSS transform
    // Format: translate(Xpx, Ypx) or empty string
    if (!this.nodesContainer) {
      return { x: 0, y: 0 };
    }
    
    const transform = this.nodesContainer.style.transform || '';
    if (!transform) {
      return { x: 0, y: 0 };
    }
    
    // Parse translate(x, y) format
    const match = transform.match(/translate\(([^,]+)px,\s*([^)]+)px\)/);
    if (match) {
      return {
        x: parseFloat(match[1]) || 0,
        y: parseFloat(match[2]) || 0
      };
    }
    
    return { x: 0, y: 0 };
  },

  // Toolbar buttons for actions on selected nodes
  setupToolbarButtons() {
    // Delete Selected button
    const deleteBtn = document.getElementById('delete-selected-btn');
    if (deleteBtn) {
      deleteBtn.addEventListener('click', () => {
        if (!this.selectedNodes || this.selectedNodes.size === 0) {
          alert('No nodes selected');
          return;
        }
        // No confirmation - just delete immediately
        // Send selected node ids to server
        this.pushEvent('nodes_deleted', {
          node_ids: Array.from(this.selectedNodes)
        });
      });
    }

    // Hide Selected button
    const hideBtn = document.getElementById('hide-selected-btn');
    if (hideBtn) {
      hideBtn.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();
        if (!this.selectedNodes || this.selectedNodes.size === 0) {
          alert('No nodes selected');
          return;
        }
        this.pushEvent('nodes_hidden', {
          node_ids: Array.from(this.selectedNodes)
        });
      });
    }

    // Show All button
    const showAllBtn = document.getElementById('show-all-btn');
    if (showAllBtn) {
      showAllBtn.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();
        this.pushEvent('show_all_nodes', {});
      });
    }

    // Deselect All button
    const deselectAllBtn = document.getElementById('deselect-all-btn');
    if (deselectAllBtn) {
      deselectAllBtn.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();
        this.clearSelection();
      });
    }

    // Clear All button
    const clearAllBtn = document.getElementById('clear-all-btn');
    if (clearAllBtn) {
      clearAllBtn.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();
        this.pushEvent('clear_canvas', {});
      });
    }
  },

  addTemporaryNode(id, x, y, label) {
    const nodeEl = document.createElement('div');
    nodeEl.className = 'flow-node temp-node';
    nodeEl.style.position = 'absolute';
    nodeEl.style.left = `${x}px`;
    nodeEl.style.top = `${y}px`;
    nodeEl.style.width = '140px';
    nodeEl.style.minHeight = '80px';
    nodeEl.style.height = 'auto';
    nodeEl.style.background = '#FFF';
    nodeEl.style.border = '2px dashed #000';
    nodeEl.style.borderRadius = '0';
    nodeEl.style.padding = '12px';
    nodeEl.style.opacity = '0.7';
    nodeEl.style.fontFamily = "'Chicago', 'Geneva', 'Monaco', monospace";
    nodeEl.style.fontSize = '11px';
    nodeEl.style.color = '#000';
    nodeEl.style.boxShadow = '2px 2px 0 #666';
    nodeEl.dataset.nodeId = id;
    nodeEl.style.textAlign = 'center';
    nodeEl.innerHTML = `
      <div style="font-size: 28px; line-height:1; margin-bottom: 8px;">⌛</div>
      <div style="font-weight: bold; font-size: 11px; line-height: 1.3;">${label}</div>
    `;
    nodeEl.id = id;

    // Append to nodes container if it exists, otherwise canvas
    // Nodes need pointer events enabled to be draggable (container has pointer-events: none)
    nodeEl.style.pointerEvents = 'auto';
    if (this.nodesContainer) {
      this.nodesContainer.appendChild(nodeEl);
    } else {
      this.canvas.appendChild(nodeEl);
    }
    return nodeEl;
  },

  setupLibraryItemDrag() {
    if (this.libraryDragSetup) return;
    this.libraryDragSetup = true;

    this.dragStartHandler = (e) => {
      if (e.target.classList.contains('draggable-project-item')) {
        const projectId = e.target.dataset.projectId;
        if (projectId) {
          e.dataTransfer.setData('text/plain', projectId);
          e.target.classList.add('dragging');
        }
      }
    };

    this.dragEndHandler = (e) => {
      if (e.target.classList.contains('draggable-project-item')) {
        e.target.classList.remove('dragging');
      }
    };

    document.addEventListener('dragstart', this.dragStartHandler);
    document.addEventListener('dragend', this.dragEndHandler);
  },

  // Setup server event listeners using LiveView's handleEvent API
  setupServerEvents() {
    // Listen for successful node addition
    this.handleEvent('node_added_success', (payload) => {
      console.log('Server created node successfully:', payload);
      
      // Remove temporary node
      if (payload.temp_id) {
        const tempNode = document.getElementById(payload.temp_id);
        if (tempNode) {
          tempNode.remove();
        }
      }

      // Add real node
      this.addRealNode(payload);
    });

    // Listen for node addition errors
    this.handleEvent('node_add_error', (payload) => {
      console.error('Server failed to create node:', payload);
      
      if (payload.temp_id) {
        const tempNode = document.getElementById(payload.temp_id);
        if (tempNode) {
          tempNode.remove();
        }
      }
      
      alert('Failed to add node: ' + (payload.message || 'Unknown error'));
    });
  },

  addRealNode(nodeData) {
    console.log("Creating node (addRealNode):", nodeData);
    const nodeEl = document.createElement('div');
    const category = (nodeData.category || '').toLowerCase();
    const categoryClass = category ? `node-${category}` : '';
    const statusClass = nodeData.status === 'planned' ? 'node-planned' : (nodeData.status === 'problem' ? 'node-problem' : '');
    nodeEl.className = ['flow-node', categoryClass, statusClass].filter(Boolean).join(' ');
    nodeEl.style.position = 'absolute';
    nodeEl.style.left = `${nodeData.position.x}px`;
    nodeEl.style.top = `${nodeData.position.y}px`;
    nodeEl.style.width = '140px';
    nodeEl.style.minHeight = '80px';
    nodeEl.style.height = 'auto';
    nodeEl.style.border = '2px solid #000';
    nodeEl.style.borderRadius = '0';
    nodeEl.style.padding = '12px';
    nodeEl.style.background = getCategoryBackground(category);
    nodeEl.style.cursor = 'move';
    nodeEl.style.userSelect = 'none';
    nodeEl.style.fontFamily = "'Chicago', 'Geneva', 'Monaco', monospace";
    nodeEl.style.fontSize = '11px';
    nodeEl.style.color = '#000';
    nodeEl.style.boxShadow = '2px 2px 0 rgba(0,0,0,0.3)';
    nodeEl.dataset.nodeId = nodeData.id;
    nodeEl.dataset.category = category;
    nodeEl.id = nodeData.id;

    // Selection checkbox (top-right)
    const checkbox = document.createElement('input');
    checkbox.type = 'checkbox';
    checkbox.className = 'node-select-checkbox';
    checkbox.style.position = 'absolute';
    checkbox.style.top = '4px';
    checkbox.style.right = '4px';
    checkbox.style.width = '16px';
    checkbox.style.height = '16px';
    checkbox.style.border = '1px solid #000';
    checkbox.style.background = '#FFF';
    checkbox.style.cursor = 'pointer';
    checkbox.addEventListener('click', (e) => {
      e.stopPropagation();
      const id = nodeEl.dataset.nodeId;
      if (checkbox.checked) {
        this.selectedNodes.add(id);
        nodeEl.classList.add('selected');
        nodeEl.style.zIndex = '10';
        nodeEl.style.border = '5px solid #000';
        nodeEl.style.background = '#FFF';
        nodeEl.style.boxShadow = '4px 4px 0 #000';
      } else {
        this.selectedNodes.delete(id);
        nodeEl.classList.remove('selected');
        nodeEl.style.zIndex = '';
        nodeEl.style.border = '2px solid #000';
        nodeEl.style.background = getCategoryBackground(nodeEl.dataset.category);
        nodeEl.style.boxShadow = '2px 2px 0 rgba(0,0,0,0.3)';
      }
      // Update selection counter in toolbar
      if (this.updateSelectionCount) {
        this.updateSelectionCount();
      }
    });
    nodeEl.appendChild(checkbox);

    // Icon
    const iconDiv = document.createElement('div');
    iconDiv.className = 'node-icon';
    iconDiv.textContent = getCategoryIcon(nodeData);
    iconDiv.style.fontSize = '28px';
    iconDiv.style.lineHeight = '1';
    iconDiv.style.marginBottom = '8px';
    iconDiv.style.display = 'block';
    iconDiv.style.filter = 'grayscale(100%) contrast(1000%) brightness(1.2)';
    iconDiv.style.color = '#FFF';
    iconDiv.style.textShadow = '-1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000, 0 -1px 0 #000, -1px 0 0 #000, 1px 0 0 #000, 0 1px 0 #000';
    nodeEl.appendChild(iconDiv);

    // Name
    const nameDiv = document.createElement('div');
    nameDiv.className = 'node-name';
    // For server-pushed ReactFlow nodeData, resolve name/category from projects if missing
    const projId = nodeData.data && nodeData.data.project_id;
    const fallbackProject = getProjectById(this.projects, projId);
    const resolvedName = nodeData.name || (fallbackProject && fallbackProject.name) || 'Node';
    const resolvedCategory = nodeData.category || (fallbackProject && fallbackProject.category) || undefined;
    nameDiv.textContent = resolvedName;
    nameDiv.style.fontWeight = 'bold';
    nameDiv.style.fontSize = '11px';
    nameDiv.style.lineHeight = '1.3';
    nodeEl.appendChild(nameDiv);

    this.makeDraggable(nodeEl);
    // Append to nodes container if it exists, otherwise canvas
    // Nodes need pointer events enabled to be draggable (container has pointer-events: none)
    nodeEl.style.pointerEvents = 'auto';
    if (this.nodesContainer) {
      this.nodesContainer.appendChild(nodeEl);
    } else {
      this.canvas.appendChild(nodeEl);
    }
    // Restore selection state for this node
    this.syncCheckboxState(nodeEl);

    // Track in nodes array
    this.nodes.push({
      id: nodeData.id,
      name: resolvedName,
      category: resolvedCategory,
      status: nodeData.status,
      x: nodeData.position.x,
      y: nodeData.position.y
    });

    // Update canvas bounds after new node is added
    this.updateCanvasBounds();
  },

  updateCanvasBounds() {
    const scrollArea = this.container.closest('.canvas-scroll-area');
    
    // Preserve scroll position to prevent viewport snapping
    // Use pending scroll position if set (from recent drag), otherwise use current
    let scrollLeft = this.pendingScrollLeft !== undefined ? this.pendingScrollLeft : (scrollArea ? scrollArea.scrollLeft : 0);
    let scrollTop = this.pendingScrollTop !== undefined ? this.pendingScrollTop : (scrollArea ? scrollArea.scrollTop : 0);
    
    // Clear pending scroll positions after use
    if (this.pendingScrollLeft !== undefined) {
      this.pendingScrollLeft = undefined;
      this.pendingScrollTop = undefined;
    }
    
    // If currently dragging, don't update bounds (wait until drag completes)
    if (this.isDraggingNode) {
      return;
    }
    
    // Debug: Log container hierarchy
    console.log('Container hierarchy:', {
      container: this.container,
      containerId: this.container?.id,
      containerHeight: this.container?.style?.height,
      scrollArea: scrollArea,
      canvas: this.canvas,
      canvasHeight: this.canvas?.style?.height
    });
    
    if (!this.canvas || !this.nodes || this.nodes.length === 0) {
      // If no nodes, set canvas to viewport size (no scrollbars)
      if (scrollArea) {
        scrollArea.style.overflowX = 'hidden';
        scrollArea.style.overflowY = 'hidden';
      }
      // Reset canvas to viewport size
      if (this.canvas) {
        const viewport = scrollArea || this.container;
        const viewportWidth = viewport.clientWidth || 800;
        const viewportHeight = viewport.clientHeight || 600;
        
        // Also reset parent container to match
        if (this.container) {
          this.container.style.setProperty('width', `${viewportWidth}px`, 'important');
          this.container.style.setProperty('height', `${viewportHeight}px`, 'important');
          this.container.style.setProperty('min-width', `${viewportWidth}px`, 'important');
          this.container.style.setProperty('min-height', `${viewportHeight}px`, 'important');
        }
        
        this.canvas.style.width = `${viewportWidth}px`;
        this.canvas.style.height = `${viewportHeight}px`;
        this.canvas.style.minWidth = `${viewportWidth}px`;
        this.canvas.style.minHeight = `${viewportHeight}px`;
        
        // Update nodesContainer to match canvas size
        if (this.nodesContainer) {
          this.nodesContainer.style.width = `${viewportWidth}px`;
          this.nodesContainer.style.height = `${viewportHeight}px`;
          this.nodesContainer.style.minWidth = `${viewportWidth}px`;
          this.nodesContainer.style.minHeight = `${viewportHeight}px`;
        }
      }
      return;
    }

    // Get all node elements (exclude temporary nodes)
    const nodeElements = this.canvas.querySelectorAll('.flow-node:not(.temp-node)');
    if (nodeElements.length === 0) {
      if (scrollArea) {
        scrollArea.style.overflowX = 'hidden';
        scrollArea.style.overflowY = 'hidden';
      }
      // Reset canvas to viewport size
      if (this.canvas) {
        const viewport = scrollArea || this.container;
        const viewportWidth = viewport.clientWidth || 800;
        const viewportHeight = viewport.clientHeight || 600;
        
        // Also reset parent container to match
        if (this.container) {
          this.container.style.setProperty('width', `${viewportWidth}px`, 'important');
          this.container.style.setProperty('height', `${viewportHeight}px`, 'important');
          this.container.style.setProperty('min-width', `${viewportWidth}px`, 'important');
          this.container.style.setProperty('min-height', `${viewportHeight}px`, 'important');
        }
        
        this.canvas.style.width = `${viewportWidth}px`;
        this.canvas.style.height = `${viewportHeight}px`;
        this.canvas.style.minWidth = `${viewportWidth}px`;
        this.canvas.style.minHeight = `${viewportHeight}px`;
        
        // Update nodesContainer to match canvas size
        if (this.nodesContainer) {
          this.nodesContainer.style.width = `${viewportWidth}px`;
          this.nodesContainer.style.height = `${viewportHeight}px`;
          this.nodesContainer.style.minWidth = `${viewportWidth}px`;
          this.nodesContainer.style.minHeight = `${viewportHeight}px`;
        }
      }
      return;
    }

    // Calculate bounds from all nodes
    let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
    
    nodeElements.forEach(nodeEl => {
      const x = parseInt(nodeEl.style.left) || 0;
      const y = parseInt(nodeEl.style.top) || 0;
      const rect = nodeEl.getBoundingClientRect();
      const width = rect.width || 140; // Default node width
      const height = rect.height || 80; // Default node height
      
      minX = Math.min(minX, x);
      minY = Math.min(minY, y);
      maxX = Math.max(maxX, x + width);
      maxY = Math.max(maxY, y + height);
    });

    // Get the scroll area container (viewport)
    const viewport = scrollArea || this.container;
    
    // Get viewport dimensions (visible area)
    const viewportWidth = viewport.clientWidth || 800;
    const viewportHeight = viewport.clientHeight || 600;

    // Small margin (20px) - scrollbars appear when nodes are this close to viewport edge
    const edgeMargin = 20;
    
    // Calculate canvas dimensions based on node bounds
    // Handle negative positions by transforming the nodes container
    const canvasPadding = 50;
    
    // If we have negative positions, calculate offset to shift nodes right/down
    // This makes negative-positioned nodes accessible via scroll
    const offsetX = minX < 0 ? -minX + canvasPadding : 0;
    const offsetY = minY < 0 ? -minY + canvasPadding : 0;
    
    // Check if any nodes extend close to or beyond the visible viewport edges
    // Account for transform offset when checking positions
    let needsHorizontalScroll = false;
    let needsVerticalScroll = false;
    
    nodeElements.forEach(nodeEl => {
      const x = parseInt(nodeEl.style.left) || 0;
      const y = parseInt(nodeEl.style.top) || 0;
      const rect = nodeEl.getBoundingClientRect();
      const width = rect.width || 140;
      const height = rect.height || 80;
      
      // Account for transform offset - nodes at negative positions are shifted right/down
      const adjustedX = x + offsetX;
      const adjustedY = y + offsetY;
      
      // Node edges in adjusted canvas coordinates
      const nodeRightEdge = adjustedX + width;
      const nodeBottomEdge = adjustedY + height;
      
      // Check if node extends beyond right edge of viewport (with small margin)
      if (nodeRightEdge > viewportWidth - edgeMargin) {
        needsHorizontalScroll = true;
      }
      // Check if node extends beyond left edge (after offset adjustment)
      if (adjustedX < edgeMargin) {
        needsHorizontalScroll = true;
      }
      // Check if node extends beyond bottom edge of viewport (with small margin)
      if (nodeBottomEdge > viewportHeight - edgeMargin) {
        needsVerticalScroll = true;
      }
      // Check if node extends beyond top edge (after offset adjustment)
      if (adjustedY < edgeMargin) {
        needsVerticalScroll = true;
      }
    });
    
    // Transform the nodes container to shift nodes if needed
    // Only update transform if it actually changed to prevent visual jumps
    if (this.nodesContainer) {
      const currentTransform = this.nodesContainer.style.transform || '';
      const newTransform = (offsetX > 0 || offsetY > 0) ? `translate(${offsetX}px, ${offsetY}px)` : '';
      
      // Only apply transform if it's different from current to prevent unnecessary reflows
      if (currentTransform !== newTransform) {
        this.nodesContainer.style.transform = newTransform;
      }
    }
    
    // Calculate canvas dimensions including offset space for negative positions
    // The canvas needs to be large enough to contain all nodes including the offset
    const adjustedMinX = offsetX > 0 ? 0 : minX;
    const adjustedMinY = offsetY > 0 ? 0 : minY;
    const adjustedMaxX = maxX + offsetX;
    const adjustedMaxY = maxY + offsetY;
    
    const contentMinX = Math.min(0, adjustedMinX - canvasPadding);
    const contentMinY = Math.min(0, adjustedMinY - canvasPadding);
    const contentMaxX = adjustedMaxX + canvasPadding;
    const contentMaxY = adjustedMaxY + canvasPadding;
    
    const contentWidth = contentMaxX - contentMinX;
    const contentHeight = contentMaxY - contentMinY;

    // Canvas should be at least viewport size, but larger if nodes extend beyond
    const canvasWidth = Math.max(viewportWidth, contentWidth);
    const canvasHeight = Math.max(viewportHeight, contentHeight);

    // Debug logging - check actual DOM dimensions
    const actualContainerHeight = this.container ? this.container.offsetHeight : 0;
    const actualCanvasHeight = this.canvas ? this.canvas.offsetHeight : 0;
    const computedContainerHeight = this.container ? window.getComputedStyle(this.container).height : '0';
    const computedCanvasHeight = this.canvas ? window.getComputedStyle(this.canvas).height : '0';
    
    console.log('Canvas bounds calculation:', {
      viewportWidth,
      viewportHeight,
      contentWidth,
      contentHeight,
      canvasWidth,
      canvasHeight,
      maxY,
      adjustedMaxY,
      contentMaxY,
      minY,
      nodesCount: nodeElements.length,
      actualContainerHeight,
      actualCanvasHeight,
      computedContainerHeight,
      computedCanvasHeight
    });

    // Also update the parent container (#xyflow-container) to match canvas size
    // This is critical - the container must expand to allow canvas to grow
    // The container currently has height: 100% which constrains it - we need to override that
    if (this.container) {
      // Remove ALL constraints first
      this.container.style.setProperty('position', 'relative', 'important');
      this.container.style.setProperty('right', 'auto', 'important');
      this.container.style.setProperty('bottom', 'auto', 'important');
      
      // Set explicit dimensions that override the 100% constraint
      this.container.style.setProperty('width', `${canvasWidth}px`, 'important');
      this.container.style.setProperty('height', `${canvasHeight}px`, 'important');
      this.container.style.setProperty('min-width', `${canvasWidth}px`, 'important');
      this.container.style.setProperty('min-height', `${canvasHeight}px`, 'important');
      this.container.style.setProperty('max-width', 'none', 'important');
      this.container.style.setProperty('max-height', 'none', 'important');
      
      // Also apply background to container to ensure it's visible everywhere
      // Background is handled by .canvas-scroll-area CSS, container should be transparent
      this.container.style.setProperty('background', 'transparent', 'important');
      
      console.log('Updated container styles:', {
        setWidth: `${canvasWidth}px`,
        setHeight: `${canvasHeight}px`,
        computedWidth: window.getComputedStyle(this.container).width,
        computedHeight: window.getComputedStyle(this.container).height,
        offsetWidth: this.container.offsetWidth,
        offsetHeight: this.container.offsetHeight
      });
    }
    
    // Set canvas size - use explicit pixel values with !important to override CSS
    // This ensures the canvas expands beyond the viewport when needed
    // We need to use setProperty with important flag to override CSS rules
    this.canvas.style.setProperty('width', `${canvasWidth}px`, 'important');
    this.canvas.style.setProperty('height', `${canvasHeight}px`, 'important');
    this.canvas.style.setProperty('min-width', `${canvasWidth}px`, 'important');
    this.canvas.style.setProperty('min-height', `${canvasHeight}px`, 'important');
    // Remove any max-height constraints that might prevent expansion
    this.canvas.style.setProperty('max-width', 'none', 'important');
    this.canvas.style.setProperty('max-height', 'none', 'important');
    // Override position constraints that might limit expansion
    this.canvas.style.setProperty('bottom', 'auto', 'important');
    this.canvas.style.setProperty('right', 'auto', 'important');
    
    // Ensure background is always visible and covers the full canvas
    // Re-apply background styles to ensure they persist after size changes
    // Force background to cover entire area with explicit attachment
    this.canvas.style.background = 'transparent'; // Background is on .canvas-scroll-area
    
    // Update nodesContainer size to match canvas - it must cover the full canvas area
    // This ensures the background is always visible everywhere
    if (this.nodesContainer) {
      this.nodesContainer.style.width = `${canvasWidth}px`;
      this.nodesContainer.style.height = `${canvasHeight}px`;
      this.nodesContainer.style.minWidth = `${canvasWidth}px`;
      this.nodesContainer.style.minHeight = `${canvasHeight}px`;
    }

    if (scrollArea) {
      // Set overflow based on whether scrollbars are needed
      scrollArea.style.overflowX = needsHorizontalScroll ? 'auto' : 'hidden';
      scrollArea.style.overflowY = needsVerticalScroll ? 'auto' : 'hidden';
      
      // Also ensure scrollArea doesn't constrain the container
      // The scrollArea should allow its content (container) to expand
      scrollArea.style.setProperty('min-height', '0', 'important');
      scrollArea.style.setProperty('max-height', 'none', 'important');
    }
    
    // Force a reflow to ensure styles are applied
    // Sometimes the browser needs a nudge to recalculate
    if (this.container) {
      void this.container.offsetHeight; // Trigger reflow
    }
    if (this.canvas) {
      void this.canvas.offsetHeight; // Trigger reflow
    }
    
    // Restore scroll position to prevent viewport snapping
    // This ensures the user's view remains stable when nodes are moved
    // Use multiple restoration attempts to ensure it sticks
    if (scrollArea) {
      // Immediate restoration
      scrollArea.scrollLeft = scrollLeft;
      scrollArea.scrollTop = scrollTop;
      
      // Delayed restoration after layout
      requestAnimationFrame(() => {
        scrollArea.scrollLeft = scrollLeft;
        scrollArea.scrollTop = scrollTop;
        
        // One more after next frame to ensure it persists
        requestAnimationFrame(() => {
          scrollArea.scrollLeft = scrollLeft;
          scrollArea.scrollTop = scrollTop;
        });
      });
    }
  }
};

// Sync checkbox and selected styling from this.selectedNodes after (re)render
XyflowEditorHook.syncCheckboxState = function(nodeEl) {
  if (!nodeEl) return;
  const nodeId = nodeEl.dataset.nodeId;
  const checkbox = nodeEl.querySelector('.node-select-checkbox');
  if (!checkbox) return;

  if (this.selectedNodes && this.selectedNodes.has(nodeId)) {
    checkbox.checked = true;
    nodeEl.classList.add('selected');
    nodeEl.style.zIndex = '10';
    nodeEl.style.border = '5px solid #000';
    nodeEl.style.background = '#FFF';
    nodeEl.style.boxShadow = '4px 4px 0 #000';
  } else {
    checkbox.checked = false;
    nodeEl.classList.remove('selected');
    nodeEl.style.zIndex = '';
    nodeEl.style.border = '2px solid #000';
    nodeEl.style.background = getCategoryBackground(nodeEl.dataset.category);
    nodeEl.style.boxShadow = '2px 2px 0 rgba(0,0,0,0.3)';
  }
};

// Update the toolbar selection counter based on current selection set
XyflowEditorHook.updateSelectionCount = function() {
  const countEl = document.getElementById('selection-count');
  if (countEl && this.selectedNodes) {
    const count = this.selectedNodes.size;
    countEl.textContent = count === 1 ? '1 selected' : `${count} selected`;
  }
};

function getCategoryIcon(node) {
  if (node.icon) return node.icon;
  const category = (node.category || '').toLowerCase();
  switch (category) {
    case 'food': return '🌱';
    case 'water': return '💧';
    case 'waste': return '♻️';
    case 'energy': return '⚡';
    case 'processing': return '⚙️';
    case 'storage': return '📦';
    default: return '▣';
  }
}

export default XyflowEditorHook;

// Helpers appended to hook
function getCategoryBackground(category) {
  switch ((category || '').toLowerCase()) {
    case 'food': return '#FAFAFA';
    case 'water': return '#FBFBFB';
    case 'waste': return '#F9F9F9';
    case 'energy': return '#FCFCFC';
    case 'processing': return '#FAFAFA';
    case 'storage': return '#FBFBFB';
    default: return '#FAFAFA';
  }
}

function getProjectById(projects, projectId) {
  if (!projects || !projectId) return null;
  const idNum = typeof projectId === 'string' ? parseInt(projectId, 10) : projectId;
  return projects.find((p) => p.id === idNum) || null;
}

function isPositionOccupied(x, y, existingNodes, threshold = 50) {
  return existingNodes.some((n) => {
    const nx = typeof n.x === 'number' ? n.x : (n.position && n.position.x) || 0;
    const ny = typeof n.y === 'number' ? n.y : (n.position && n.position.y) || 0;
    const dx = nx - x;
    const dy = ny - y;
    const distance = Math.sqrt(dx * dx + dy * dy);
    return distance < threshold;
  });
}

XyflowEditorHook.findAvailablePosition = function(initialX, initialY) {
  let finalX = initialX;
  let finalY = initialY;
  let attempts = 0;
  while (isPositionOccupied(finalX, finalY, this.nodes) && attempts < 10) {
    finalX += 30;
    finalY += 30;
    attempts++;
  }
  return { x: finalX, y: finalY };
};
