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
    
    // Load initial nodes and edges from data attributes
    this.loadInitialData();
    
    // Log container dimensions
    console.log("Container dimensions:", { width: this.el.offsetWidth, height: this.el.offsetHeight });

    // Render the nodes
    this.renderNodes();
    
    // Setup drag and drop
    this.setupDragAndDrop();
    
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
    // Parse nodes and edges from data attributes
    const nodesData = this.el.dataset.nodes;
    const edgesData = this.el.dataset.edges;

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
  },

  renderNodes() {
    // Clear existing nodes
    this.container.innerHTML = '';
    
    // Create a canvas wrapper
    this.canvas = document.createElement('div');
    this.canvas.className = 'flow-canvas';
    this.canvas.style.position = 'relative';
    this.canvas.style.width = '100%';
    this.canvas.style.height = '100%';
    this.canvas.style.background = '#F8F8F8';
    this.container.appendChild(this.canvas);

    // Render each node
    this.nodes.forEach(node => {
      this.renderNode(node);
    });
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

    // Icon
    const iconDiv = document.createElement('div');
    iconDiv.className = 'node-icon';
    iconDiv.textContent = getCategoryIcon(node);
    iconDiv.style.fontSize = '28px';
    iconDiv.style.lineHeight = '1';
    iconDiv.style.marginBottom = '8px';
    iconDiv.style.display = 'block';
    nodeEl.appendChild(iconDiv);

    // Name
    const nameDiv = document.createElement('div');
    nameDiv.className = 'node-name';
    nameDiv.textContent = node.name || 'Node';
    nameDiv.style.fontWeight = 'bold';
    nameDiv.style.fontSize = '11px';
    nameDiv.style.lineHeight = '1.3';
    nodeEl.appendChild(nameDiv);

    // Make node draggable
    this.makeDraggable(nodeEl);

    this.canvas.appendChild(nodeEl);
    return nodeEl;
  },

  makeDraggable(element) {
    let isDragging = false;
    let startX, startY, initialX, initialY;

    element.addEventListener('mousedown', (e) => {
      if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;
      
      isDragging = true;
      element.style.cursor = 'grabbing';
      
      startX = e.clientX;
      startY = e.clientY;
      
      const rect = element.getBoundingClientRect();
      initialX = rect.left;
      initialY = rect.top;

      e.preventDefault();
    });

    document.addEventListener('mousemove', (e) => {
      if (!isDragging) return;

      const dx = e.clientX - startX;
      const dy = e.clientY - startY;

      const newX = parseInt(element.style.left) + dx;
      const newY = parseInt(element.style.top) + dy;

      element.style.left = `${newX}px`;
      element.style.top = `${newY}px`;

      startX = e.clientX;
      startY = e.clientY;
    });

    document.addEventListener('mouseup', () => {
      if (!isDragging) return;
      
      isDragging = false;
      element.style.cursor = 'move';

      // Send position update to server
      const nodeId = element.dataset.nodeId;
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

    this.canvas.appendChild(nodeEl);
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

    // Icon
    const iconDiv = document.createElement('div');
    iconDiv.className = 'node-icon';
    iconDiv.textContent = getCategoryIcon(nodeData);
    iconDiv.style.fontSize = '28px';
    iconDiv.style.lineHeight = '1';
    iconDiv.style.marginBottom = '8px';
    iconDiv.style.display = 'block';
    nodeEl.appendChild(iconDiv);

    // Name
    const nameDiv = document.createElement('div');
    nameDiv.className = 'node-name';
    nameDiv.textContent = nodeData.name || 'Node';
    nameDiv.style.fontWeight = 'bold';
    nameDiv.style.fontSize = '11px';
    nameDiv.style.lineHeight = '1.3';
    nodeEl.appendChild(nameDiv);

    this.makeDraggable(nodeEl);
    this.canvas.appendChild(nodeEl);

    // Track in nodes array
    this.nodes.push({
      id: nodeData.id,
      name: nodeData.name,
      category: nodeData.category,
      status: nodeData.status,
      x: nodeData.position.x,
      y: nodeData.position.y
    });
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
    case 'food': return '#E8E8E8';
    case 'water': return '#D0D0D0';
    case 'waste': return '#BABABA';
    case 'energy': return '#F0F0F0';
    case 'processing': return '#C8C8C8';
    case 'storage': return '#DCDCDC';
    default: return '#E8E8E8';
  }
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
