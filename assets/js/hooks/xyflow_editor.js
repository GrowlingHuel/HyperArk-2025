/**
 * SVG Flow Editor Hook for Phoenix LiveView
 * 
 * Simple node-based editor for the Living Web system.
 * Uses vanilla JS with DOM manipulation - no React needed.
 */

const XyflowEditorHook = {
  mounted() {
    this.container = this.el;
    this.nodes = [];
    this.edges = [];
    this.selectedNode = null;
    
    // Load initial nodes and edges from data attributes
    this.loadInitialData();
    
    // Render the nodes
    this.renderNodes();
    
    // Setup drag and drop
    this.setupDragAndDrop();
    
    // Setup library item drag handlers
    this.setupLibraryItemDrag();
    
    // Setup server event listeners
    this.setupServerEvents();
  },

  updated() {
    // Update nodes and edges when server sends new data
    this.loadInitialData();
    this.renderNodes();
    this.setupLibraryItemDrag();
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
    // Create node element
    const nodeEl = document.createElement('div');
    nodeEl.className = 'flow-node';
    nodeEl.style.position = 'absolute';
    nodeEl.style.left = `${node.x}px`;
    nodeEl.style.top = `${node.y}px`;
    nodeEl.style.width = '150px';
    nodeEl.style.height = 'auto';
    nodeEl.style.background = '#FFF';
    nodeEl.style.border = '2px solid #000';
    nodeEl.style.borderRadius = '0';
    nodeEl.style.padding = '10px';
    nodeEl.style.cursor = 'move';
    nodeEl.style.userSelect = 'none';
    nodeEl.dataset.nodeId = node.id;

    // Add HyperCard styling
    nodeEl.style.boxShadow = '3px 3px 0 #000, 6px 6px 0 #CCC';
    nodeEl.style.fontFamily = "'Chicago', 'Geneva', 'Monaco', monospace";
    nodeEl.style.fontSize = '11px';
    nodeEl.style.color = '#000';

    // Add node label
    const label = document.createElement('div');
    label.style.fontWeight = 'bold';
    label.style.marginBottom = '5px';
    label.style.borderBottom = '1px solid #000';
    label.textContent = node.name || 'Node';
    nodeEl.appendChild(label);

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
      const x = parseInt(element.style.left);
      const y = parseInt(element.style.top);

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
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;

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
    nodeEl.style.width = '150px';
    nodeEl.style.height = '60px';
    nodeEl.style.background = '#FFF';
    nodeEl.style.border = '2px dashed #000';
    nodeEl.style.borderRadius = '0';
    nodeEl.style.padding = '10px';
    nodeEl.style.opacity = '0.7';
    nodeEl.style.fontFamily = "'Chicago', 'Geneva', 'Monaco', monospace";
    nodeEl.style.fontSize = '11px';
    nodeEl.style.color = '#000';
    nodeEl.style.boxShadow = '2px 2px 0 #666';
    nodeEl.dataset.nodeId = id;
    nodeEl.textContent = label;
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
    const nodeEl = document.createElement('div');
    nodeEl.className = 'flow-node';
    nodeEl.style.position = 'absolute';
    nodeEl.style.left = `${nodeData.position.x}px`;
    nodeEl.style.top = `${nodeData.position.y}px`;
    nodeEl.style.width = '150px';
    nodeEl.style.height = 'auto';
    nodeEl.style.background = '#FFF';
    nodeEl.style.border = '2px solid #000';
    nodeEl.style.borderRadius = '0';
    nodeEl.style.padding = '10px';
    nodeEl.style.cursor = 'move';
    nodeEl.style.userSelect = 'none';
    nodeEl.style.fontFamily = "'Chicago', 'Geneva', 'Monaco', monospace";
    nodeEl.style.fontSize = '11px';
    nodeEl.style.color = '#000';
    nodeEl.style.boxShadow = '3px 3px 0 #000, 6px 6px 0 #CCC';
    nodeEl.dataset.nodeId = nodeData.id;
    nodeEl.id = nodeData.id;

    // Add node label
    const label = document.createElement('div');
    label.style.fontWeight = 'bold';
    label.style.marginBottom = '5px';
    label.style.borderBottom = '1px solid #000';
    label.textContent = nodeData.name || 'Node';
    nodeEl.appendChild(label);

    this.makeDraggable(nodeEl);
    this.canvas.appendChild(nodeEl);

    // Track in nodes array
    this.nodes.push({
      id: nodeData.id,
      name: nodeData.name,
      x: nodeData.position.x,
      y: nodeData.position.y
    });
  }
};

export default XyflowEditorHook;
